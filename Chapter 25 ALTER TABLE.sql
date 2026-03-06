USE AdventureWorks2019
GO

-- Phần 25.1: Add Column(s) (Thêm cột)
-- Thêm 2 cột: Ngày thử việc (mặc định là hôm nay) và Số thẻ bảo hiểm (cho phép rỗng)
ALTER TABLE HumanResources.Employee 
ADD ProbationStartDate DATE NOT NULL DEFAULT GETDATE(),
	SocialInsuranceNum VARCHAR(20) NULL 

--Lỗi thường gặp & Cách xử lý thông minh:
--Vấn đề: Lỗi ALTER TABLE only allows columns to be added that can contain nulls...
--Tại sao: Bảng đã có sẵn dữ liệu (hàng ngàn nhân viên). Bạn thêm một cột cấm rỗng (NOT NULL) nhưng lại KHÔNG cung cấp giá trị mặc định (DEFAULT). SQL Server không biết điền gì vào các dòng dữ liệu cũ nên báo lỗi.
--Cách sửa: Luôn gắn DEFAULT khi thêm cột NOT NULL vào bảng đã có dữ liệu

-- Phần 25.2: Drop Column (Xóa cột)
-- Nghiệp vụ: Xóa bỏ cột "Số thẻ bảo hiểm" vì công ty quyết định chuyển dữ liệu này sang một CSDL bảo mật khác.
-- Xóa cột không còn sử dụng để giải phóng không gian lưu trữ
ALTER TABLE HumanResources.Employee 
DROP COLUMN SocialInsuranceNum

-- Lỗi thường gặp & Cách xử lý thông minh:
-- Vấn đề: Báo lỗi không thể xóa cột vì cột đang bị ràng buộc (Constraint) hoặc được dùng trong View/Index.

-- Tại sao: SQL Server bảo vệ tính toàn vẹn 
-- Nếu cột đó đang có DEFAULT constraint, CHECK constraint hoặc là Khóa ngoại (Foreign Key), bạn không thể xóa cột cái rụp.
-- Cách sửa: Bắt buộc phải drop Constraint trước, sau đó mới drop Column (Xem Phần 25.5 bên dưới)


-- Phần 25.3: Add Primary Key (Thêm Khóa chính)
-- Nghiệp vụ: Tạo một bảng phụ theo dõi "Nhân viên tham gia Dự án"
-- sau đó thiết lập Khóa chính để đảm bảo một nhân viên không bị chèn trùng lặp vào cùng một dự án
-- Bảng tác động: Khởi tạo bảng mới HumanResources.EmployeeProject

-- Giải thích CSDL: Trong thực tế, bảng Employee đã có sẵn Khóa chính.
-- Để luyện tập, ta tạo bảng trung gian (Mapping table) để luyện cú pháp tạo Composite Primary Key (Khóa chính tổ hợp từ 2 cột).

-- Bước 1: Tạo bảng phụ chưa có khóa chính 
CREATE TABLE HumanResources.EmployeeProject (
	BusinessEntityID	INT NOT NULL , 
	ProjectID			INT NOT NULL,
	AssignmentDate		DATE 
)

-- Bước 2: Thêm khóa chính tổ hợp 
ALTER TABLE HumanResources.EmployeeProject 
ADD CONSTRAINT PK_EmployeeProject PRIMARY KEY (BusinessEntityID, ProjectID)


-- Lỗi thường gặp & Cách xử lý thông minh:
-- Vấn đề: Lỗi Cannot define PRIMARY KEY constraint on nullable column...
-- Tại sao: Khóa chính không bao giờ được phép chứa giá trị NULL. Nếu lúc CREATE TABLE bạn để cột là NULL, lệnh thêm PK sẽ thất bại ngay lập tức.
-- Cách sửa: Đảm bảo các cột dự định làm PK phải có thuộc tính NOT NULL ngay từ đầu.


-- Phần 25.4: Alter Column (Sửa đổi cột)
-- Nghiệp vụ: Thay đổi kiểu dữ liệu của cột "Ngày bắt đầu thử việc" để ghi nhận chi tiết đến từng giờ/phút thay vì chỉ lưu ngày.

ALTER TABLE HumanResources.Emloyee 
ALTER COLUMN ProbationStartDate DATETIME NOT NULL 

-- Lỗi thường gặp & Cách xử lý thông minh:
-- Vấn đề: Lỗi String or binary data would be truncated
-- Tại sao: Xảy ra khi bạn bóp nhỏ kích thước cột (ví dụ: đang VARCHAR(50) mà ALTER xuống VARCHAR(10)), trong khi dữ liệu cũ có dòng dài 20 ký tự.
-- Dùng câu lệnh SELECT MAX(LEN(TenCot)) để kiểm tra độ dài dữ liệu thực tế lớn nhất trước khi quyết định giảm kích thước cột.


-- Phần 25.5: Drop Constraint (Xóa Ràng buộc)
-- Nghiệp vụ: Xóa ràng buộc mặc định (GETDATE()) của cột "Ngày bắt đầu thử việc" do quy trình mới yêu cầu HR phải nhập tay ngày này, không được tự động lấy ngày hệ thống nữa.

-- Xóa ràng buộc DEFAULT. Tên Constraint được đặt tự động bởi hệ thống nếu bạn không đặt tên rõ ràng lúc đầu.
-- Cú pháp chuẩn:
ALTER TABLE HumanResources.Employee 
DROP CONSTRAINT [Tên_Của_Constraint]

-- Lỗi thường gặp & Cách xử lý thông minh:
-- Vấn đề: Làm sao biết cái [Tên_Của_Constraint] là gì mà xóa? Khi dùng DEFAULT GETDATE() ở phần 25.1, SQL đã tự sinh ra một cái tên ngẫu nhiên (VD: DF__Employee__Proba__12345678).
-- Tại sao: Đây là sai lầm kinh điển của người mới học: Lười đặt tên cho Constraint.
-- Cách sửa: 
-- 1. Cách tìm tên để xóa: Vào Object Explorer của SSMS -> HumanResources.Employee -> Mở rộng mục Constraints để xem tên.
-- 2. Tư duy thiết kế đúng: Luôn tự đặt tên Constraint khi tạo để dễ kiểm soát sau này.

ALTER TABLE HumanResources.Employee 
DROP CONSTRAINT [DF__Employee__Probat__4BCC3ABA]

-- Code sạch: Thêm Constraint có đặt tên đàng hoàng
ALTER TABLE HumanResources.Employee 
ADD CONSTRAINT DF_Employee_Probation DEFAULT GETDATE() FOR ProbationStartDate

-- Tóm tắt
-- Thêm Cột:		ADD ColumnName DataType:			Cột NOT NULL phải đi kèm DEFAULT nếu bảng đã có data.
-- Xóa Cột :		DROP COLUMN ColumnName :			Phải xóa các Ràng buộc (Constraint) dính tới cột đó trước.
-- Sửa Cột :		ALTER COLUMN ColumnName DataType:   Coi chừng mất dữ liệu (Truncate) khi giảm kích thước data type.
-- Thêm/Xóa Khóa:	ADD/DROP CONSTRAINT ConstraintName: Luôn chủ động đặt tên Constraint (VD: PK_..., DF_...) để dễ quản trị.


