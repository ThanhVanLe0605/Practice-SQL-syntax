USE AdventureWorks2019
GO

-- -- Tạo các bảng tạm chứa dữ liệu y hệt bảng gốc để luyện lệnh DELETE
SELECT * INTO #Employees FROM HumanResources.Employee
SELECT * INTO #ShoppingCart FROM Sales.ShoppingCartItem   
SELECT * INTO #OrderDetail  FROM Sales.SalesOrderDetail 
SELECT * INTO #OrderHeader FROM Sales.SalesOrderHeader 


-- 29.1. Xóa toàn bộ dữ liệu (DELETE ALL vs TRUNCATE)

-- Ý nghĩa bảng dữ liệu
-- #ShoppingCart (Copy từ Sales.ShoppingCartItem)
---- Chứa các mặt hàng khách hàng đang để trong giỏ hàng (chưa thanh toán).
-- Cột quan trọng: ShoppingCartItemID (Mã dòng giỏ hàng)
-- ShoppingCartID (Mã giỏ hàng của khách)
-- ProductID (Mã sản phẩm)

-- Nghiệp vụ: Xóa toàn bộ lịch sử giỏ hàng lưu tạm của khách hàng vào cuối ngày để giải phóng bộ nhớ.

------>> Cách 1: Dùng DELETE (Xóa từng dòng )
-- Ghi chú: Xóa tất cả các dòng trong bảng. 
-- Hệ thống sẽ quét qua từng dòng, ghi vào Transaction Log (nhật ký hệ thống) rồi mới xóa.
DELETE FROM #ShoppingCart;


------>> Cách 2: Dùng TRUNCATE (Cắt bỏ toàn bộ)
-- Ghi chú: Reset bảng về trạng thái trống trơn ban đầu. 
-- Không ghi nhật ký từng dòng, chạy cực nhanh và reset luôn các cột tự tăng (Identity) về 1.
TRUNCATE TABLE #ShoppingCart;


-- Lỗi hay gặp & Cách xử lý thông minh:
-- Vấn đề: Dùng TRUNCATE bị lỗi. Tại sao? Vì TRUNCATE không hoạt động nếu bảng đó đang bị bảng khác tham chiếu bằng Khóa ngoại (Foreign Key)
-- Vấn đề: Dùng DELETE FROM (quên WHERE) trên môi trường Production (Thực tế). Tại sao gặp? Do gõ vội, hoặc bôi đen thiếu dòng chữ WHERE khi ấn F5 trong SSMS.
-- Cách xử lý: Trong thực tế, luôn tạo thói quen bọc lệnh DELETE trong một TRANSACTION để có cơ hội "quay xe".


-- Cách code sạch và an toàn của chuyên gia:
BEGIN TRAN; -- Bắt đầu một phiên giao dịch

DELETE FROM #ShoppingCart; 
-- Nếu lỡ xóa nhầm, bôi đen dòng ROLLBACK TRAN; và ấn F5 để lấy lại dữ liệu.
-- Nếu chắc chắn đúng, bôi đen COMMIT TRAN; để lưu thay đổi.

-- ROLLBACK TRAN; 
-- COMMIT TRAN;

-- 29.2. Phần 29.2: Xóa các dòng cụ thể (DELETE with WHERE)
-- Ý nghĩa bảng dữ liệu:
-- #Employees (Copy từ HumanResources.Employee): Chứa thông tin nhân viên. Cột quan trọng: BusinessEntityID (Mã nhân viên), JobTitle (Chức danh), Gender (Giới tính).
-- Nghiệp vụ: Xóa các nhân viên có chức danh là 'Design Engineer' khỏi danh sách hiện tại

DELETE FROM #Employees 
WHERE JobTitle = 'Design Engineer'

-- Lỗi hay gặp & Cách xử lý thông minh:
-- Vấn đề: Chạy code báo "0 rows affected" (không xóa được dòng nào) dù bạn biết chắc chắn có nhân viên thiết kế.
-- Tại sao: Do sai chính tả, dư khoảng trắng (ví dụ 'Design Engineer ' thay vì 'Design Engineer'), hoặc dùng dấu ngoặc kép " " thay vì nháy đơn ' ' cho chuỗi trong SQL.
-- Cách sửa: Luôn dùng SELECT để kiểm tra dữ liệu trước khi DELETE.


-- Bước 1: SELECT kiểm tra trước xem nó trả ra cái gì
SELECT * FROM #Employees WHERE JobTitle LIKE '%Design Engineer%';

-- Bước 2: Chuyển chữ SELECT * thành DELETE
DELETE FROM #Employees WHERE JobTitle = 'Design Engineer';

-- 29.3: Xóa dựa trên sự so sánh với bảng khác
-- Đây là phần cực kỳ quan trọng và dùng rất nhiều trong thực tế (Hệ thống Data Warehouse, xử lý dữ liệu hàng ngày).
-- Ý nghĩa bảng dữ liệu
---- #OrderHeader: Bảng "Đầu hóa đơn", chứa thông tin tổng quan của đơn hàng (Ai mua, ngày nào, trạng thái đơn hàng). Cột quan trọng: SalesOrderID (Mã hóa đơn), Status (Trạng thái đơn: 4 là Bị từ chối/Hủy).
---- #OrderDetail: Bảng "Chi tiết hóa đơn", chứa các món hàng trong hóa đơn đó. Cột quan trọng: SalesOrderID (Khóa ngoại nối với Header).


-- Nghiệp vụ: Xóa toàn bộ các chi tiết hóa đơn (trong bảng OrderDetail) thuộc về các hóa đơn đã bị hủy (Status = 4 trong bảng OrderHeader).
DELETE d 
FROM	#OrderDetail d
INNER JOIN	#OrderHeader h  ON d.SalesOrderID = h.SalesOrderID 
WHERE h.[Status] = 4


DELETE FROM #OrderDetail 
WHERE EXISTS (
	  SELECT 1
	  FROM	#OrderHeader 
	  WHERE #OrderHeader.SalesOrderID = #OrderDetail.SalesOrderID 
	  AND	#OrderHeader.[Status] = 4
)


-- Lỗi hay gặp & Cách xử lý thông minh
-- Vấn đề: Xóa nhầm luôn cả dữ liệu của bảng B (Bảng dùng để tham chiếu)
-- Tại sao: Trong cú pháp DELETE FROM ... JOIN của T-SQL, nếu sau chữ DELETE bạn không ghi rõ cái Alias (tên viết tắt) của bảng muốn xóa, SQL Server có thể bối rối hoặc báo lỗi cú pháp.
-- Cách sửa: Luôn ghi rõ Alias ngay sau chữ DELETE. Đọc nhẩm trong đầu: "Xóa thằng OD, từ mớ OD nối với OH, nơi mà...".

----  Tiêu chí        |||       DELETE                          |||      TRUNCATE
----  Bản chất        ||| Xóa từng dòng, ghi log đầy đủ.		|||  Cắt đứt toàn bộ bảng, hầu như không ghi log.
----  Tốc độ		  ||| Chậm hơn (nếu dữ liệu lớn)			|||  Cực kỳ nhanh.
----  Có dùng WHERE?  ||| CÓ. Lọc thoải mái.					|||  KHÔNG. Xóa là sạch sành sanh.
----  Reset Identity? ||| KHÔNG. (Tự tăng từ số cũ tiếp theo).  |||  CÓ. (Cột tự tăng đếm lại từ số 1)