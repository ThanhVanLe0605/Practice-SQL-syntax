
-- Trong thực tế, bạn rất hiếm khi được phép TRUNCATE các bảng dữ liệu gốc đang chạy (như bảng Khách hàng, Hóa đơn) vì chúng dính chằng chịt Khóa ngoại (Foreign Key).
-- TRUNCATE thường được dùng nhiều nhất trong quá trình ETL (Trích xuất - Chuyển đổi - Tải dữ liệu), cụ thể là dọn dẹp các Bảng tạm / Bảng trung gian (Staging Tables).

-- Chúng ta sẽ mượn cấu trúc của bảng Tỷ giá hối đoái để làm ví dụ:
---- Bảng gốc: Sales.CurrencyRate (Lưu lịch sử tỷ giá quy đổi tiền tệ hàng ngày)
---- Bảng Staging (chúng ta sẽ tạo ra để luyện tập): dbo.Staging_CurrencyRate
-- Các cột quan trọng:
-- CurrencyRateID: Khóa chính, tự động tăng (Identity).
-- CurrencyRateDate: Ngày lấy tỷ giá
-- AverageRate: Tỷ giá trung bình.

-- Đề bài (Nghiệp vụ thực tiễn)
---- Yêu cầu:
-- Xóa toàn bộ dữ liệu cũ trong bảng trung gian dbo.Staging_CurrencyRate 
-- và đặt lại (reset) bộ đếm ID tự tăng về 1
-- để chuẩn bị cho luồng đổ dữ liệu tỷ giá hối đoái mới của ngày hôm nay vào hệ thống
-- Tối ưu hóa tốc độ xóa vì bảng này có thể chứa hàng triệu dòng từ các hệ thống khác đẩy về

-- Tại sao dùng TRUNCATE mà không dùng DELETE
---- Về cơ chế: DELETE sẽ đi qua từng dòng dữ liệu để xóa và ghi lại hành động đó vào file nhật ký (Transaction Log).
--   Nếu bảng có 1 triệu dòng, nó ghi log 1 triệu lần -> Rất chậm

---- Sự thông minh của TRUNCATE
-- Nó là lệnh DDL (Data Definition Language)
-- Nó không xóa từng dòng, mà nó giải phóng luôn các trang dữ liệu (Data Pages) chứa dữ liệu đó
-- Do đó, nó cực kỳ nhanh và tốn rất ít tài nguyên.

---- Về bộ đếm:
-- TRUNCATE sẽ reset cột Identity (ví dụ CurrencyRateID sẽ quay lại đếm từ 1 ở lần Insert tiếp theo)
-- DELETE thì không, xóa xong ID vẫn tăng tiếp từ mốc cũ

-- Bước phụ: Chạy code này để tạo bảng tạm và chèn dữ liệu mồi (để bạn có cái mà xóa)
-- Tạo bảng trung gian (Staging) copy cấu trúc từ bảng gốc
CREATE TABLE dbo.Staging_CurrencyRate (
    CurrencyRateID INT IDENTITY(1,1) PRIMARY KEY,
    CurrencyRateDate DATETIME,
    AverageRate MONEY
);
-- Thêm 3 dòng dữ liệu mồi
INSERT INTO dbo.Staging_CurrencyRate (CurrencyRateDate, AverageRate)
VALUES (GETDATE(), 1.5), (GETDATE(), 1.6), (GETDATE(), 1.7);

----- Lỗi 1: Bị chặn lại do Khóa Ngoại (Foreign Key constraint)
-- Vấn đề:
-- Nếu bạn thử chạy TRUNCATE TABLE Sales.CurrencyRate;
-- trên bảng gốc của AdventureWorks
-- SSMS sẽ báo lỗi đỏ chót: "Cannot truncate table ... because it is being referenced by a FOREIGN KEY constraint.
-- Tại sao:
-- Hệ thống bảo vệ dữ liệu
-- Bảng hóa đơn (Sales.SalesOrderHeader) đang dùng các CurrencyRateID này.
-- Mặc dù bảng Tỷ giá có thể đang trống không, nhưng hễ bảng đó bị bảng khác trỏ Khóa ngoại vào, SQL Server sẽ cấm bạn TRUNCATE
-- Cách xử lý thông minh:

-- Cách 1: Chấp nhận hi sinh tốc độ, dùng DELETE (nếu được phép xóa)
-- DELETE FROM Sales.CurrencyRate;

-- Cách 2 (Dành cho dọn dẹp DB môi trường Test): 
-- Bỏ khóa ngoại (DROP FK) -> TRUNCATE bảng -> Tạo lại khóa ngoại (ADD FK).


----- Lỗi 2: Cố gắng dùng WHERE với TRUNCATE
-- Vấn đề:
-- Muốn xóa nhanh 1 triệu dòng của năm 2018 nên viết:
-- TRUNCATE TABLE dbo.Staging_CurrencyRate WHERE YEAR(CurrencyRateDate) = 2018
-- -> Lỗi cú pháp ngay lập tức.


-- Tại sao:
-- Truncate giải phóng cả một block dữ liệu vật lý
-- nó không có khả năng đi vào xem xét từng dòng thỏa mãn điều kiện WHERE hay không
-- Hành động này giống như "đập bỏ cả tòa nhà" thay vì "đuổi từng người ra khỏi phòng".

-- Nếu bắt buộc phải lọc điều kiện để xóa, TRUNCATE vô dụng. Phải quay về DELETE.

--------------------------------------------------------------------------------------------

-- Bước đệm: Tạo một bảng nháp để bạn có cái mà xóa (không nên xóa bảng gốc của CSDL)
SELECT * INTO HumanResources.Department_Backup FROM HumanResources.Department;

-- ==========================================
-- CÚ PHÁP CŨ (Theo sách của bạn - Pre 2016):
-- Dùng để check các hệ thống quá cũ.
-- ==========================================
IF EXISTS (
    SELECT * FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_SCHEMA = 'HumanResources' 
    AND TABLE_NAME = 'Department_Backup'
)
DROP TABLE HumanResources.Department_Backup;

-- ==========================================
-- CÚ PHÁP MỚI THÔNG MINH (Khuyên dùng thực tế - Từ 2016+):
-- Gọn gàng, sạch sẽ, chuẩn xác.
-- ==========================================
DROP TABLE IF EXISTS HumanResources.Department_Backup; -- Xóa nếu bảng này tồn tại