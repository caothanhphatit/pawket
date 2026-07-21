package com.pawket.media;

import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import java.net.URI;
import java.time.Duration;
import java.util.Map;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.S3Exception;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

@ApplicationScoped
class StoragePresigner {
    private final S3Presigner presigner;
    private final S3Client client;
    private final String bucket;
    private final Duration uploadTtl;

    StoragePresigner(
            @ConfigProperty(name = "pawket.storage.endpoint") URI endpoint,
            @ConfigProperty(name = "pawket.storage.public-endpoint") URI publicEndpoint,
            @ConfigProperty(name = "pawket.storage.region") String region,
            @ConfigProperty(name = "pawket.storage.bucket") String bucket,
            @ConfigProperty(name = "pawket.storage.access-key") String accessKey,
            @ConfigProperty(name = "pawket.storage.secret-key") String secretKey,
            @ConfigProperty(name = "pawket.storage.upload-ttl") Duration uploadTtl) {
        this.bucket = bucket;
        this.uploadTtl = uploadTtl;
        var credentials = StaticCredentialsProvider.create(AwsBasicCredentials.create(accessKey, secretKey));
        var serviceConfiguration = S3Configuration.builder().pathStyleAccessEnabled(true).build();
        this.presigner = S3Presigner.builder()
                .endpointOverride(publicEndpoint)
                .region(Region.of(region))
                .credentialsProvider(credentials)
                .serviceConfiguration(serviceConfiguration)
                .build();
        this.client = S3Client.builder()
                .endpointOverride(endpoint)
                .region(Region.of(region))
                .credentialsProvider(credentials)
                .serviceConfiguration(serviceConfiguration)
                .build();
    }

    PresignedUpload create(String storageKey, String contentType) {
        var put = PutObjectRequest.builder()
                .bucket(bucket)
                .key(storageKey)
                .contentType(contentType)
                .build();
        var request = PutObjectPresignRequest.builder()
                .signatureDuration(uploadTtl)
                .putObjectRequest(put)
                .build();
        var result = presigner.presignPutObject(request);
        return new PresignedUpload(
                result.url().toString(), Map.of("Content-Type", contentType), uploadTtl);
    }

    String downloadUrl(String storageKey) {
        var request = GetObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(15))
                .getObjectRequest(GetObjectRequest.builder().bucket(bucket).key(storageKey).build())
                .build();
        return presigner.presignGetObject(request).url().toString();
    }

    UploadedObject uploadedObject(String storageKey) {
        try {
            var response = client.headObject(HeadObjectRequest.builder().bucket(bucket).key(storageKey).build());
            return new UploadedObject(response.contentLength(), response.contentType());
        } catch (S3Exception exception) {
            if (exception.statusCode() == 404) return null;
            throw exception;
        }
    }

    @PreDestroy
    void close() {
        presigner.close();
        client.close();
    }

    record PresignedUpload(String url, Map<String, String> headers, Duration ttl) {}

    record UploadedObject(long size, String contentType) {}
}
