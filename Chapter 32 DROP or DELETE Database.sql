-- DROP DATABASE (Xóa Cơ sở dữ liệu)

-- Nghiệp vụ:
-- Xóa cơ sở dữ liệu AdventureWorks_Test đã hoàn thành việc thử nghiệm tính năng mới của team Dev
-- trả lại tài nguyên RAM và Disk cho máy chủ.


-- Luôn có thói quen đứng ở DB hệ thống 'master' khi thao tác ở cấp độ Database
USE master
GO

-- B1: TAO DB NHÁP
CREATE DATABASE AdventureWorks_Test
GO

USE AdventureWorks_Test
GO

CREATE TABLE BangDuLieuRac (ID INT, NoiDung NVARCHAR(50));
INSERT INTO BangDuLieuRac VALUES (1, N'Dữ liệu quan trọng của Dev');
GO

-- B2: BACKUP CSDL 
USE master
GO

-- Cú pháp sao lưu toàn bộ (Full Backup) ra một file .bak trên ổ cứng 
BACKUP DATABASE AdventureWorks_Test
TO DISK = 'C:\BACKUP\ AdventureWorks_Test_TruocKhiXoa.bak'
WITH 
	FORMAT, -- Khởi tạo lại file mới (Ghi đè nếu file có tên này đã tồn tại)
	NAME = 'Full Backup Of AdventureWorks_Test';
GO 
-- GHI CHÚ: Thư mục 'C:\Backup' phải được TẠO SẴN trên Windows trước khi chạy lệnh này.

-- B3: Xóa DB an toàn
-- Đá tất cả những ai đang dùng DB này ra ngoài (ngay cả chính tab code này)
ALTER DATABASE AdventureWorks_Test 
SET SINGLE_USER WITH ROLLBACK IMMEDIATE 
GO

-- XÓA DB
DROP DATABASE IF EXISTS AdventureWorks_Test

PRINT N'Đã hoàn tất: Tạo nháp -> Backup -> Xóa thành công!';

-- 📌 Nhắc nhở & Tóm tắt (Takeaways)
-- Quy trình vàng: Không bao giờ gõ DROP mà không có BACKUP trước đó, trừ khi dữ liệu đó 100% sinh ra chỉ để test trong vài phút. Mất dữ liệu là lỗi "tử hình" của ngành CSDL.
-- Đuôi mở rộng: File sao lưu của SQL Server luôn có chuẩn đuôi là .bak
-- WITH FORMAT: Giúp làm sạch file backup cũ nếu bạn chạy đi chạy lại đoạn script này nhiều lần.
---- Nó tránh việc nối file (append) làm dung lượng file .bak phình to không kiểm soát.
-- Luôn nhớ vị trí đứng: Muốn chặt cái cây (DB), bạn không thể trèo lên cành của nó (USE DB_Name) để chặt.
---- Bạn phải tụt xuống đất (USE master) rồi mới chặt được.





