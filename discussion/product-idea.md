# Pawket - Product Idea

> V1 scope note (2026-07-21): the implemented MVP is camera-first and always
> works in the current-pet context. Pet switching lives inside Profile. The
> camera has no photo-library action; the optional 0-5 starter photos are only
> available while creating a pet. This note supersedes older `All pets` and
> camera-library references below.

## 1. Tong quan

Pawket la ung dung giup moi pet co mot profile ton tai trong suot cuoc doi. Chu nuoi co the ghi lai anh, video va cac cot moc moi ngay; chia se chung voi gia dinh, ban be theo trai nghiem gan giong Locket.

Gia tri cot loi khong nam o viec nhan dien pet bang AI trong giai doan dau. Chu nuoi se tu chon pet xuat hien trong anh. Theo thoi gian, moi lan dang anh se bo sung vao lifetime timeline cua pet.

> Chup hom nay. Giu ca mot cuoc doi.

## 2. Dinh huong san pham

Pawket ket hop hai lop gia tri:

- Gia tri moi ngay: chup nhanh, chia se khoanh khac va tuong tac voi nguoi than.
- Gia tri dai han: xay dung profile va timeline tron doi cho tung pet.

Pet profile la thuc the trung tam. User chi la nguoi dang co quyen quan ly profile. Cach thiet ke nay cho phep bo sung dong chu, nguoi cham soc va chuyen chu trong tuong lai ma khong lam mat lich su cua pet.

## 3. Doi tuong su dung ban dau

- Nguoi dang nuoi mot hoac nhieu cho, meo.
- Gia dinh co nhieu nguoi cung cham soc pet.
- Nhom ban than muon xem va tuong tac voi anh pet hang ngay.
- Nguoi muon luu ky uc cua pet lau dai, khong bi troi noi dung nhu mang xa hoi thong thuong.

## 4. Nguyen tac cot loi

### Pet-first

Moi pet co mot `Pet ID`, profile va timeline rieng. Profile khong bi gan chet vao mot tai khoan user.

### Tao profile that nhanh

Khong bat buoc user cung cap anh. Ngoai ten va loai pet, cac thong tin khac co the bo qua va cap nhat sau.

### Ho tro nhieu pet

Mot user co the so huu hoac quan ly nhieu pet profile va chuyen doi giua chung de dang.

### Ghi lai khong ma sat

User co the chup hoac upload anh, chon pet xuat hien trong anh, them caption neu muon va dang ngay.

### Rieng tu theo mac dinh

Profile va noi dung nen mac dinh o che do rieng tu. User chu dong moi gia dinh hoac ban be vao xem.

## 5. Pet profile

Thong tin profile ban dau:

- Ten pet.
- Loai: cho hoac meo.
- Avatar, khong bat buoc.
- Ngay sinh hoac tuoi uoc tinh, khong bat buoc.
- Gioi tinh, khong bat buoc.
- Giong, khong bat buoc.
- Ngay ve nha, khong bat buoc.
- Mo ta ngan, khong bat buoc.
- `Pet ID` do he thong tao.
- Chu hien tai va cac thanh vien co quyen truy cap.

Trang profile co the hien thi:

- Avatar, ten va tuoi cua pet.
- Cau `O ben ban tu...` neu co ngay ve nha.
- Chu va cac thanh vien trong gia dinh.
- Tong so ngay da duoc ghi lai.
- Timeline anh, video va milestone.

## 6. Quan ly nhieu pet va chuyen profile

Mot chu co the tao va quan ly nhieu pet profile:

```text
User
 |- Mit
 |- Mo
 `- Dau
```

Tren cac man hinh chinh, app hien thi pet switcher:

```text
[ Tat ca ] [ Mit ] [ Mo ] [ Dau ] [ + ]
```

Quy tac tuong tac:

- Bam avatar de mo danh sach pet.
- Vuot ngang hoac bam avatar de chuyen nhanh sang pet khac.
- `Tat ca pet` hien thi noi dung tong hop cua nhung pet user co quyen xem.
- `Them pet` luon nam cuoi danh sach.
- App ghi nho pet duoc su dung gan nhat.

### Che do Tat ca pet

- Hien thi feed tong hop cua ca nha.
- Cho biet pet nao da hoac chua co anh trong ngay.
- Khi dang anh, user chon mot hoac nhieu pet xuat hien trong anh.

### Che do Mot pet

- Hien thi profile va timeline rieng cua pet dang chon.
- Camera mac dinh tag pet dang mo.
- Cac thong ke va milestone chi thuoc pet do.

`active_pet_id` dai dien cho pet dang duoc chon. Gia tri rong dai dien cho che do Tat ca pet.

## 7. Daily loop

Trai nghiem hang ngay nen dien ra trong vai giay:

1. App gui nhac nho: `Hom nay be Mit the nao?`
2. User chup anh hoac chon anh trong thu vien.
3. User chon pet xuat hien trong anh.
4. User them caption hoac bo qua.
5. Anh duoc chia se voi nhom duoc chon.
6. Anh dong thoi duoc luu vao lifetime timeline cua pet.

Neu user chup tu profile cua Mit:

```text
Mit -> Camera -> Chup -> Mac dinh tag Mit -> Dang
```

Neu user chup tu Tat ca pet:

```text
Tat ca pet -> Camera -> Chup -> Chon Mit va/hoac Mo -> Dang
```

Mot anh co the duoc gan cho nhieu pet, nhung he thong chi luu mot media asset.

## 8. Lifetime timeline

Moi timeline entry co the bao gom:

- Anh hoac video.
- Caption ngan.
- Ngay chup va ngay dang.
- Mot hoac nhieu pet duoc tag.
- Nguoi dang.
- Quyen rieng tu.
- Milestone neu co.

Cac milestone don gian co the ho tro sau MVP:

- Ngay ve nha.
- Sinh nhat.
- Lan dau di choi.
- Tiem vaccine.
- Chuyen nha.
- Thanh vien moi.
- Ky niem dac biet.

Pawket chua can tro thanh ho so y te trong giai doan dau. Su kien suc khoe co the duoc luu nhu mot milestone thong thuong.

## 9. Thanh vien va quyen truy cap

Data model can san sang cho nhieu nguoi cung lien ket voi mot pet:

- `Owner`: quan ly profile, thanh vien va quyen so huu.
- `Caretaker`: dang noi dung va cap nhat cac thong tin duoc cho phep.
- `Follower`: xem va tuong tac voi noi dung duoc chia se.

Tinh nang chuyen chu chua can xuat hien trong MVP, nhung profile va du lieu khong nen phu thuoc truc tiep vao `owner_id` duy nhat. Sau nay co the them quy trinh chuyen chu ma van giu nguyen timeline.

## 10. Pham vi MVP

### Can co

- Dang ky va dang nhap.
- Tao, xem va chinh sua pet profile.
- Anh profile la tuy chon.
- Mot user quan ly nhieu pet.
- Pet switcher va che do Tat ca pet.
- Chup anh hoac chon anh tu thu vien.
- Tag pet thu cong vao anh.
- Mot anh co the tag nhieu pet.
- Timeline rieng cua tung pet.
- Feed tong hop cho tat ca pet.
- Moi thanh vien bang link.
- Reaction don gian.
- Quyen rieng tu co ban: private, family, friends.

### Chua lam

- AI nhan dien pet hoac nhan dien giong.
- Bat buoc cung cap nam anh khi tao profile.
- Marketplace, mua ban va thanh toan.
- Public discovery feed.
- Chat.
- Ho so y te phuc tap.
- Gamification nang.

## 11. Data model so bo

```text
User
- id
- name
- avatar_url
- created_at

Pet
- id
- name
- species
- avatar_url
- birth_date
- estimated_age
- gender
- breed
- adoption_date
- bio
- created_at

UserPet
- user_id
- pet_id
- role: owner | caretaker | follower
- status
- joined_at

Post
- id
- author_id
- caption
- visibility: private | family | friends
- captured_at
- created_at

Media
- id
- post_id
- type: image | video
- storage_url
- width
- height
- created_at

PostPet
- post_id
- pet_id

Reaction
- id
- post_id
- user_id
- type
- created_at
```

Quan he nhieu-nhieu qua `UserPet` va `PostPet` dam bao:

- Mot user co the quan ly nhieu pet.
- Mot pet co the co nhieu thanh vien.
- Mot anh co the thuoc timeline cua nhieu pet.
- Profile va timeline van ton tai khi quyen quan ly thay doi.

## 12. Navigation de xuat

MVP co the bat dau voi bon khu vuc:

```text
Home | Camera | Timeline | Profile
```

- `Home`: daily feed va trang thai ghi lai hom nay.
- `Camera`: chup nhanh va tag pet.
- `Timeline`: xem lich su theo pet dang chon hoac tat ca pet.
- `Profile`: thong tin pet, thanh vien va cai dat.

Pet switcher nam gan dau giao dien de user luon biet minh dang thao tac voi pet nao.

## 13. Chi so san pham

North Star Metric de xuat:

> So pet co it nhat ba ngay duoc ghi lai moi tuan.

Chi so nay do duoc ca tan suat su dung lan gia tri lifetime profile dang duoc bo sung deu dan.

Mot so chi so bo tro:

- Ty le user tao pet dau tien.
- So pet trung binh tren moi owner.
- Ty le user dang anh dau tien trong ngay onboarding.
- So ngay co anh tren moi pet moi tuan.
- Ty le moi thanh vien thanh cong.
- Retention ngay 7 va ngay 30.

## 14. Dinh huong tuong lai

Sau khi daily loop va lifetime profile co retention tot, co the mo rong theo thu tu:

1. Milestone va ky niem tu dong.
2. Dong chu, nguoi cham soc va phan quyen chi tiet.
3. Chuyen quyen so huu profile.
4. Ho so vaccine, microchip va giay to xac minh.
5. AI goi y pet trong anh de giam thao tac tag thu cong.
6. Quy trinh tim chu moi hoac chuyen giao co trach nhiem.

Marketplace khong nam trong giai doan hien tai.

## 15. Cau hoi can chot truoc khi development

- Mobile app se dung Flutter de phat trien iOS va Android tu mot codebase.
- Feed chi danh cho thanh vien cua pet hay co them nhom ban be rieng?
- Moi user co the co vai tro khac nhau tren tung pet khong?
- Anh co can bat buoc gan it nhat mot pet khong?
- Timeline sap xep theo ngay chup hay ngay dang?
- Khi xoa pet profile, media va bai dang dung chung voi pet khac se duoc xu ly the nao?
- Co cho phep export toan bo timeline va media cua pet khong?

## 16. Quyet dinh cong nghe

Pawket se bat dau voi hai thanh phan chinh:

```text
pawket/
|- mobile/     Flutter, iOS va Android
|- backend/    Java 21 va Quarkus
`- discussion/ Tai lieu san pham va ky thuat
```

Backend duoc xay dung theo modular monolith, chua tach microservices.

Stack ban dau:

- Mobile: Flutter va Dart.
- Backend: Java 21 va Quarkus.
- API: REST va OpenAPI.
- Database: PostgreSQL.
- Database migration: Flyway.
- Media storage: S3-compatible object storage.
- Authentication: managed OIDC provider; se chot provider khi trien khai login.
- Push notification: Firebase Cloud Messaging.
- Backend testing: JUnit, RestAssured va Testcontainers.
- Deployment: Docker.

Flutter upload media truc tiep len object storage bang signed URL do Quarkus cap. Quarkus quan ly metadata, quyen truy cap va lien ket media voi post/pet, thay vi nhan toan bo file upload qua API server.
