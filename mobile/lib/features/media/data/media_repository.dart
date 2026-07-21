import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'media_dto.dart';

abstract interface class MediaRepository {
  Future<UploadIntentDto> createUploadIntent(
    CreateUploadIntentRequest request, {
    required String idempotencyKey,
  });

  Future<void> upload({
    required UploadIntentDto intent,
    required Object bytesOrStream,
    required String contentType,
    required int contentLength,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  });

  Future<CompletedMediaDto> completeUpload(String mediaId);
}

class RemoteMediaRepository implements MediaRepository {
  const RemoteMediaRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<UploadIntentDto> createUploadIntent(
    CreateUploadIntentRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post<Object>(
      '/media/upload-intents',
      data: request.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return UploadIntentDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'upload intent'),
    );
  }

  @override
  Future<void> upload({
    required UploadIntentDto intent,
    required Object bytesOrStream,
    required String contentType,
    required int contentLength,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    return _apiClient.uploadSignedUrl(
      url: intent.uploadUrl,
      data: bytesOrStream,
      contentType: contentType,
      contentLength: contentLength,
      headers: intent.requiredHeaders,
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<CompletedMediaDto> completeUpload(String mediaId) async {
    final response = await _apiClient.post<Object>(
      '/media/complete',
      data: {'mediaId': mediaId},
    );
    return CompletedMediaDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'completed media'),
    );
  }
}
