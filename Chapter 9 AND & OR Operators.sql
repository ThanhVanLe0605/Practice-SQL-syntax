-- Đề bài: Lấy danh sách tên sản phẩm , màu sắc và giá niêm yết của các sản phẩm có màu Đỏ ('Red') VÀ giá niêm yết lớn hơn 1000

SELECT 
		p.[Name], 
		p.Color,
		p.ListPrice
FROM Production.[Product] p
WHERE p.Color = 'Red'
	  AND p.ListPrice > 1000

--  Đề bài: Lấy danh sách tên và màu sắc của các sản phẩm có màu Đen ('Black') HOẶC Bạc ('Silver').
-- Cách 1
SELECT
		p.[Name],
		p.Color
FROM Production.[Product] p
WHERE p.Color = 'Black'
   OR p.Color = 'Silver'

-- Cách 2
SELECT
		p.[Name],
		p.Color
FROM Production.[Product] p
WHERE p.Color IN ('Black', 'Silver')

-- Đề bài: Lọc ra các sản phẩm màu Đen HOẶC Bạc,
-- VÀ bắt buộc các sản phẩm đó phải có giá lớn hơn 500.

SELECT
		p.[Name],
		p.Color,
		p.ListPrice 
FROM Production.[Product] p
WHERE 
	-- ĐK1: Về màu 
	( p.Color = 'Black' OR p.Color = 'Silver' )
	-- ĐK2: Về giá niêm yết 
	AND p.ListPrice > 500 
	
-- NOTES: 
-- LỖI LOGIC: Truy vấn chạy được nhưng ra kết quả SAI nghiệp vụ
SELECT Name, Color, ListPrice
FROM Production.Product
WHERE Color = 'Black' OR Color = 'Silver' AND ListPrice > 500;
-- Vì trong SQL, độ ưu tiên của AND cao hơn OR
-- WHERE Color = 'Black' OR ( Color = 'Silver' AND ListPrice > 500)
-- Đoạn code trên SQL sẽ tự hiểu là:
-- Lấy sản phẩm màu Đen (giá nào cũng được, 0 đồng cũng lấy) HOẶC (Lấy sản phẩm màu Bạc có giá > 500). -> Sai bét so với yêu cầu.

-- ✔️ Cách xử lý thông minh & Code sạch
-- Sử dụng dấu ngoặc đơn () để gom nhóm logic, ép SQL phải thực hiện việc kiểm tra OR trước, sau đó mới xét đến AND.

-- Tóm tắt & Ghi nhớ (Notes)
-- Quy tắc vàng: KHI KẾT HỢP cả AND và OR trong cùng một mệnh đề WHERE
-- LUÔN LUÔN dùng dấu ngoặc đơn () để nhóm các điều kiện OR lại.
-- Đừng bao giờ để SQL tự quyết định thứ tự ưu tiên.