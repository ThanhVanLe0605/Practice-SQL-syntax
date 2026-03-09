USE AdventureWorks2019
GO

-- Đề bài thực tiễn
-- 1. Cấp quyền Đọc (SELECT) trên bảng thông tin cá nhân và bảng thông tin công việc cho nhóm Thực tập sinh Nhân sự (HR_Trainee).
-- 2. Cấp thêm quyền Cập nhật (UPDATE) chức danh trên bảng thông tin công việc cho nhóm này.
-- 3. Kết thúc đợt thực tập, thu hồi quyền Cập nhật (UPDATE) chức danh, chỉ giữ lại quyền Đọc.

-- Phân tích: Tại sao? & Làm sao?
/*
Tại sao không cấp quyền cho từng User? Trong một công ty có 100 thực tập sinh, cấp quyền cho từng người là thảm họa quản trị. 
Cách làm chuẩn: Tạo một Role (Vai trò - HR_Trainee), cấp quyền cho Role, sau đó tống các User vào Role đó

Làm sao để thực hiện? Sử dụng GRANT để mở khóa cửa (cấp quyền), và REVOKE để đòi lại chìa khóa (thu hồi quyền) trên các Object (bảng) cụ thể,
có chỉ định rõ Schema (Person hoặc HumanResources
*/

-- Bước 0: Tạo một Database Role (Vai trò) để dễ quản lý (Nghiệp vụ thực tế)
CREATE ROLE HR_Trainee
GO

-- Bước 1: Cấp quyền SELECT (Đọc) trên 2 bảng cần thiết
GRANT SELECT
ON Person.Person
TO HR_Trainee -- Chú thích: Cho phép HR_Trainee đọc thông tin cá nhân (Tên, Họ)

GRANT SELECT
ON HumanResources.Employee
TO HR_Trainee

-- Bước 2: Cấp quyền UPDATE (Cập nhật) trên bảng thông tin công việc
GRANT UPDATE 
ON HumanResources.Employee
TO HR_Trainee

-- Bước 3: Thu hồi quyền UPDATE khi hết hạn thực tập
REVOKE UPDATE 
ON HumanResources.Employee
FROM HR_Trainee

-- CÁC LỖI HAY GẶP
/* ------------------------------------------------------------------------------------------
   ❌ LỖI 1: QUÊN SCHEMA NAME (Lỗi ngớ ngẩn nhưng cực kỳ phổ biến)
   - Vấn đề: Viết lệnh: GRANT SELECT ON Employee TO HR_Trainee;
   - Tại sao lỗi? SSMS mặc định tìm bảng Employee trong schema 'dbo' -> Báo lỗi "Cannot find object".
   - Cách sửa: Luôn dùng danh pháp 2 phần: SchemaName.TableName.
------------------------------------------------------------------------------------------ */

/* ------------------------------------------------------------------------------------------
   ❌ LỖI 2: CẤP QUYỀN THẲNG CHO USER THAY VÌ ROLE (Lỗi tư duy hệ thống)
   - Vấn đề: Viết lệnh: GRANT UPDATE ON HumanResources.Employee TO UserA, UserB;
   - Tại sao lỗi? Khi UserA nghỉ việc, bạn phải rà soát lại toàn bộ code để thu hồi quyền. 
     Hệ thống lớn có hàng ngàn quyền, làm vậy sẽ vỡ hệ thống, sinh ra code rác và lỗ hổng bảo mật.
   - Cách sửa: Chỉ GRANT cho ROLE. Sau đó nhét User vào Role.
------------------------------------------------------------------------------------------ */

/* ------------------------------------------------------------------------------------------
   ❌ LỖI 3: NHẦM LẪN TAI HẠI GIỮA REVOKE VÀ DENY (Lỗi thủng bảo mật)
   - Vấn đề: Sếp bảo "Cấm thực tập sinh cập nhật". Bạn gõ: REVOKE UPDATE... 
     Nhưng hôm sau thực tập sinh vẫn sửa được dữ liệu!
   - Tại sao lỗi? REVOKE chỉ là "Rút lại quyền VỪA CẤP". Nếu thực tập sinh đó vô tình 
     được add vào một nhóm khác (VD: IT_Support) có quyền UPDATE, họ vẫn dùng quyền đó để sửa.
   - Cách sửa: 
     + Dùng REVOKE: Trả về trạng thái trung lập (Không cấm, không cho).
     + Dùng DENY: CẤM TUYỆT ĐỐI. DENY luôn được SSMS ưu tiên cao nhất, đè lên mọi quyền GRANT từ nhóm khác.
------------------------------------------------------------------------------------------ */
-- Tình huống 3A: Hết đợt thực tập, chỉ muốn lấy lại quyền UPDATE (Họ vẫn có thể được cấp quyền này nếu vào Role khác)
REVOKE UPDATE ON HumanResources.Employee FROM HR_Trainee;

-- Tình huống 3B: Sếp gắt "TUYỆT ĐỐI KHÔNG cho bọn thực tập sinh đụng vào dữ liệu này bất chấp chúng nó thuộc nhóm nào!"
DENY UPDATE ON HumanResources.Employee TO HR_Trainee;
GO
