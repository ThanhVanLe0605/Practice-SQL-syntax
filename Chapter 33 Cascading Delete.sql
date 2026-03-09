USE AdventureWorks2019
GO 

-- ON DELETE CASCADE (Xóa Nối Tiếp)
-- CHỨC NĂNG CỐT LÕI (Cái này để làm gì?)
----Tự động dọn rác: Khi xóa 1 dòng dữ liệu ở bảng Cha, CSDL tự động tìm và xóa sạch các dòng dữ liệu liên quan ở bảng Con.
----Bảo vệ toàn vẹn dữ liệu: Tuyệt đối không để xảy ra tình trạng "dữ liệu mồ côi" (ví dụ: email tồn tại nhưng không thuộc về ai).
----Nhàn cho Backend: Lập trình viên không cần viết code lặp đi lặp lại để xóa từng bảng con trước khi xóa bảng cha.

----CÁC BƯỚC THỰC HIỆN BẰNG CÚ PHÁP SQL (How to code)

-- Bước 1: Kiểm tra và Xóa ràng buộc (Khóa ngoại) cũ nếu có
---- Lý do: Không thể sửa trực tiếp Khóa ngoại hiện tại, phải xóa cái cũ đi trước.

-- Bước 2: Tạo lại Khóa ngoại mới và gắn "phép thuật" Cascade
---- Lý do: Thiết lập luật mới cho CSDL hiểu.


-- Bước 3: Thực thi thao tác xóa (Chỉ cần làm trên bảng Cha)
---- Kết quả: Chạy 1 lệnh này, cả Cha lẫn Con đều bay màu gọn gàng.

--  NGUYÊN TẮC "SỐNG CÒN" CẦN NHỚ KHI LÀM VIỆC
---- Transaction (All-or-Nothing): Quá trình xóa này diễn ra trong 1 giao dịch ngầm. Cúp điện giữa chừng khi đang xóa bảng con? CSDL tự động khôi phục (Rollback) lại y nguyên như chưa từng có lệnh xóa.
---- Chống chỉ định: Tuyết đối KHÔNG dùng cho các dữ liệu mang tính lịch sử, kế toán, tài chính (Ví dụ: Xóa nhân viên -> Cascade xóa luôn cả hóa đơn họ từng bán). Những trường hợp này phải dùng Soft Delete (Chỉ ẩn đi chứ không xóa thật)

-- Đề bài / Nghiệp vụ (Business Requirement)
---- Yêu cầu: Công ty quyết định loại bỏ hoàn toàn một sản phẩm thử nghiệm thất bại (có ProductID = 319) khỏi hệ thống.
---- Khi xóa sản phẩm này, toàn bộ các bài đánh giá (Review) của người dùng liên quan đến nó cũng phải được dọn sạch tự động để tránh rác CSDL.

-- B1: Xóa ràng buộc khóa ngoại 
IF EXISTS (
	SELECT 1 
	FROM sys.foreign_keys 
	WHERE name = 'FK_ProductReview_Product_ProductID'
)
BEGIN 
		ALTER TABLE Production.ProductReview 
		DROP CONSTRAINT FK_ProductReview_Product_ProductID

		PRINT N'Đã xóa khóa ngoại cũ thành công!';
END 
GO

-- B2: Tạo lại Khóa ngoại mới và gắn "phép thuật" Cascade
/*
		Giải thích: Móc lại sợi dây liên kết giữa 2 bảng, nhưng lần này dặn CSDL thêm luật: 
		Hễ bảng Cha bị xóa, thì tự động xóa dòng tương ứng ở bảng Con này luôn nhé".
*/
ALTER TABLE Production.ProductReview 
ADD CONSTRAINT FK_ProductReview_Product_ProductID
	FOREIGN KEY (ProductID)
	REFERENCES Production.[Product] (ProductID)
	ON DELETE CASCADE 

PRINT N'Đã gắn ON DELETE CASCADE thành công!';
GO

-- B3: Thực thi nghiệp vụ xóa

DELETE FROM Production.Product
WHERE ProductID = 319;

PRINT N'Đã xóa Sản phẩm 319 và toàn bộ đánh giá liên quan!';
GO