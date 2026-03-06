
-- Chúng ta sẽ làm việc với bảng Production.Product.
-- Ý nghĩa bảng: Production.Product lưu trữ toàn bộ thông tin về các mặt hàng mà công ty sản xuất hoặc bán.
-- Các cột quan trọng cho bài này:
-- ProductID (INT): Khóa chính (Primary Key), mã định danh duy nhất của sản phẩm.
-- Name (NVARCHAR): Tên sản phẩm (VD: 'Adjustable Race').
-- ProductNumber (NVARCHAR): Mã vạch/Mã số kinh doanh của sản phẩm (VD: AR-5381, BA-8327).
-- Nhận xét: Mã ProductNumber luôn có một tiền tố (Prefix) đứng trước dấu gạch ngang (-). Tiền tố này đại diện cho Dòng sản phẩm (Product Line).

-- Đặt vấn đề & Giải quyết (Nghiệp vụ thực tiễn)
-- Nghiệp vụ: Tạo một hàm để tự động trích xuất mã dòng sản phẩm (ký tự trước dấu - đầu tiên) từ cột ProductNumber

-- Tại sao cần hàm này?
-- Trong các báo cáo doanh thu, người ta thường muốn gom nhóm (GROUP BY) theo dòng sản phẩm (ví dụ: dòng AR, dòng BA) thay vì từng mã sản phẩm lẻ tẻ.
-- Đóng gói logic cắt chuỗi vào Function giúp tái sử dụng code ở nhiều báo cáo khác nhau mà không cần viết lại hàm SUBSTRING lằng nhằng.

-- Làm sao để giải quyết? (Ghi chú tư duy trước khi code)
-- 1. Nhận một chuỗi đầu vào (@input).
-- 2. Tìm vị trí của dấu gạch ngang - bằng hàm CHARINDEX.
-- 3. Nếu không có dấu -, trả về toàn bộ chuỗi ban đầu.
-- 4. Nếu có dấu -, dùng SUBSTRING cắt từ vị trí đầu tiên (vị trí 1) đến ngay trước dấu -.
-- 5. Trả về kết quả.

-- Kiểm tra và xóa hàm nếu đã tồn tại (Thói quen code sạch trong dự án thực tế)
DROP FUNCTION IF EXISTS dbo.fnGetProductPrefix
GO

-- Tạo hàm mới 
CREATE FUNCTION dbo.fnGetProductPrefix (@ProductNumber VARCHAR(50))
RETURNS VARCHAR(50)
AS 
BEGIN 

	DECLARE @Prefix			VARCHAR(50)
	DECLARE @DashPosition   INT 

	-- Tìm vị trí của dấu '-' 
	SET @DashPosition = CHARINDEX('-', @ProductNumber )

	-------------------------------------------------------------------------
	-- Xử lý logic cắt chuỗi 
	SET @Prefix = CASE 

	-- Nếu không tìm thấy dấu '-' (CHARINDEX trả về 0), lấy nguyên chuỗi 
	WHEN @DashPosition = 0 THEN @ProductNumber 

	-- Nếu có, cắt từ đầu đến trước dấu '-' (DashPosition - 1)
	ELSE SUBSTRING(@ProductNumber, 1, @DashPosition - 1)       
	-- SUBSTRING(Chuỗi_gốc, Vị_trí_bắt_đầu_cắt, Số_lượng_ký_tự_muốn_lấy)

	-------------------------------------------------------------------------
	END

	RETURN @Prefix 

END 
GO 

---- Lỗi 1: Lỗi "Vô hình" khi gọi hàm (Lỗi cú pháp)
-- Vấn đề: Báo lỗi 'fnGetProductPrefix' is not a recognized built-in function name.
-- Tại sao? SQL Server yêu cầu bắt buộc phải gọi tên Schema (dbo.) trước tên Scalar Function do người dùng tự định nghĩa để phân biệt với hàm hệ thống.

---- Lỗi 2: Tràn bộ đệm hoặc lỗi cắt sai do không kiểm tra chuỗi rỗng/thiếu ký tự phân cách
-- Vấn đề: Báo lỗi Invalid length parameter passed to the LEFT or SUBSTRING function.
-- Tại sao? Nếu bạn dùng thẳng SUBSTRING(chuỗi, 1, CHARINDEX('-', chuỗi) - 1) mà không có CASE WHEN
-- Khi chuỗi không có dấu -, CHARINDEX trả về 0. Công thức trở thành SUBSTRING(..., 1, -1). SQL không thể cắt một chuỗi có độ dài âm.
-- Cách xử lý: Luôn dùng CASE WHEN hoặc logic bắt rủi ro như đoạn code tôi đã viết mẫu ở mục 2.

---- Lỗi 3 (Nâng cao): Vấn đề hiệu suất RBAR (Row-By-Agonizing-Row)
-- Tại sao? Scalar Function thực thi cực kỳ chậm trên các bảng dữ liệu lớn. Nếu bảng có 1 triệu dòng, hàm sẽ bị gọi (invoke) và chạy lại 1 triệu lần.
-- Cách xử lý thông minh:
-- Trong thực tế, nếu logic chỉ đơn giản là cắt chuỗi, chuyên gia thường bỏ luôn Function mà dùng Computed Column (Cột tính toán) ngay trên bảng, hoặc dùng Inline Table-Valued Function (iTVF)


-- Ứng dụng thực tiễn: JOIN bảng và gọi Function
-- Nghiệp vụ: Lấy danh sách tên sản phẩm, mã vạch, mã dòng sản phẩm (sử dụng hàm vừa tạo) và số lượng đã bán của từng mặt hàng.


SELECT
	p.[Name] AS ProductName, 
	p.ProductNumber, 
	-- Gọi function và truyền cột ProductNumber vào làm tham số 
	dbo.fnGetProductPrefix(p.ProductNumber) AS ProductLineCode, 
	s.OrderQty 
FROM Production.[Product] p 
INNER JOIN	Sales.SalesOrderDetail s ON p.ProductID = s.ProductID 
-- Giới hạn 10 dòng để xem kết quả 
ORDER BY s.OrderQty
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY 

-- Notes: Sử dụng OFFSET... FETCH thay vì TOP 10 là chuẩn mực SQL hiện đại để phân trang dữ liệu.


