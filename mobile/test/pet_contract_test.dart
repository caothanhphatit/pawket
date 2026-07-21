import 'package:flutter_test/flutter_test.dart';
import 'package:pawket_mobile/features/pets/data/pet_dto.dart';

void main() {
  test('pet avatar media id resolves to an authenticated API URL', () {
    final dto = PetDto.fromJson(const {
      'id': '00000000-0000-0000-0000-000000000010',
      'name': 'Mit',
      'species': 'DOG',
      'avatarMediaId': '00000000-0000-0000-0000-000000000099',
    }, baseUri: Uri.parse('http://192.168.1.8:8080/api/v1'));

    expect(
      dto.toDomain().avatarUrl.toString(),
      'http://192.168.1.8:8080/api/v1/media/'
      '00000000-0000-0000-0000-000000000099/content',
    );
  });

  test('avatar update sends the media id and optimistic version', () {
    const request = UpdatePetRequest(avatarMediaId: 'media-id', version: 4);

    expect(request.toJson(), {'avatarMediaId': 'media-id', 'version': 4});
  });
}
