USE AdventureWorks2019
GO

-- Trong thực tế, AW2019 là một CSDL chuẩn hóa (Normalized) rất cao.
-- Tức là để thêm 1 nhân viên (Employee), bạn không thể chỉ dùng 1 lệnh INSERT
-- Bạn phải INSERT vào bảng BusinessEntity -> lấy ID đó INSERT vào bảng Person -> rồi mới INSERT vào Employee

-- Vì vậy, để luyện tập cú pháp INSERT của Chapter 26 một cách trơn tru mà không bị "chặn" bởi các ràng buộc (Constraints) quá phức tạp của hệ thống cũ,
-- chúng ta sẽ tạo một bảng mới tên là MarketingLeads (Khách hàng tiềm năng) để thực hành thao tác đưa dữ liệu vào,
-- đồng thời dùng các bảng có sẵn của AW2019 để trích xuất dữ liệu (SELECT).

-- Đầu tiên, hãy chạy đoạn code này để tạo bảng thực hành:

-- Tạo bảng để luyện tập INSERT
CREATE TABLE dbo.MarketingLeads (
    LeadID INT IDENTITY(1,1) PRIMARY KEY, -- Tự động tăng từ 1
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NULL,
    PhoneNumber NVARCHAR(25) NULL,
    LeadSource NVARCHAR(50) DEFAULT 'Unknown' -- Nguồn khách hàng
);


--26.1. INSERT data from another table using SELECT

INSERT INTO dbo.MarketingLeads (FirstName, LastName, PhoneNumber, LeadSource)
SELECT
    p.FirstName,
    p.LastName,
    pp.PhoneNumber,
    'Internal Sales Team' -- Giá trị hard-code (gắn cứng) vì bảng gốc không có cột này
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Person.PersonPhone pp ON p.BusinessEntityID = pp.BusinessEntityID 
WHERE e.JobTitle LIKE '%Sales%';
-- LIKE '%Sales%' để quét những ai làm Sales Representative, Sales Manager...

-- Lỗi thường gặp & Cách xử lý thông minh:
-- Lỗi: The select list for the INSERT statement contains more/fewer items than the insert list.
----- Tại sao? Số lượng cột định Insert vào (vd: 4 cột) không khớp với số cột Select ra (vd: 3 cột)
----- Cách sửa: Đếm kỹ số lượng cột ở INSERT và SELECT. Map (ánh xạ) chúng theo đúng thứ tự (Cột 1 vào Cột 1, Cột 2 vào Cột 2)

-- Vấn đề hiệu năng:
---- Nếu bảng SELECT có hàng triệu dòng, câu lệnh này sẽ lock (khóa) bảng đích, gây treo hệ thống thực tế.
---- Cách xử lý: Lập trình viên giỏi sẽ chia nhỏ câu SELECT ra (batching) dùng lệnh TOP và WHILE loop, hoặc dùng kỹ thuật NOLOCK ở câu SELECT nếu chấp nhận đọc dữ liệu chưa commit.


--26.2. Insert New Row
-- Insert không cần chỉ định cột
-- Bạn phải truyền đủ giá trị cho tất cả các cột, đúng thứ tự (trừ cột Identity tự nhảy)
-- Rất nguy hiểm nếu sau này ai đó thêm/bớt cột trong bảng.
INSERT INTO dbo.MarketingLeads
VALUES ('BINH', 'Tran', 'binh.tran@example.com', '0901234567', 'Walk-in')

----- Lỗi 1: Cannot insert explicit value for identity column...
-- Tại sao? Cố tình điền số vào cột LeadID (ví dụ: VALUES (1, 'An',...)).
-- Cách sửa: Xóa giá trị đó đi, hệ thống tự lo.

----- Lỗi 2: String or binary data would be truncated.
-- Tại sao? Cố nhét 1 chuỗi dài 100 ký tự vào cột FirstName chỉ cho phép NVARCHAR(50)
-- Cách sửa: Cắt ngắn chuỗi trước khi INSERT hoặc dùng hàm SUBSTRING(), LEFT().

----- Lỗi 3: Cannot insert the value NULL into column...
-- Tại sao? Quên khai báo cột có ràng buộc NOT NULL (như FirstName, LastName) trong danh sách chèn.

-- 26.3: Insert Only Specified Columns
-- Chỉ định rõ các cột cần Insert (Cách LÀM CHUẨN nhất)
INSERT INTO dbo.MarketingLeads (FirstName, LastName, Email, LeadSource)
VALUES ('An', 'Nguyen', 'an.nguyen@example.com', 'Websie')

--26.4. Insert multiple rows at once
-- Nghiệp vụ: Nhập danh sách 3 đối tác thu thập được từ sự kiện "Tech Expo 2026" vào hệ thống.
INSERT INTO dbo.MarketingLeads (FirstName, LastName,PhoneNumber, LeadSource)
VALUES 
    ('Cuong', 'Le', '091222333', 'Tech Expo 2026'),
    ('Dung', 'Pham','0988777666', 'Tech Expo 2026'),
    ('Vy', 'Hoang', NULL, 'Tech Expo 2026'); -- Email và Phone có thể NULL do thiết kế bảng ban đầu

-- Lỗi thường gặp & Cách xử lý thông minh:
-- Vấn đề: "All or Nothing" (Tất cả hoặc không gì cả). Nếu dòng thứ 3 bị lỗi (ví dụ sai kiểu dữ liệu), 2 dòng đầu tiên cũng KHÔNG được chèn vào bảng.
-- Tại sao? SQL Server xử lý khối VALUES này trong cùng một Transaction (Giao dịch) ngầm định
-- Xử lý:
-- Để code điêu luyện, khi Insert hàng ngàn dòng
-- người ta thường dùng BULK INSERT hoặc đẩy dữ liệu vào một bảng tạm (#TempTable),
-- sau đó lọc lỗi trước khi INSERT vào bảng thật.
