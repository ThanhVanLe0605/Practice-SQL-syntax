-- 8.1. Sorting by column number (instead of name)
-- Đề bài: Trích xuất danh sách nhân viên bao gồm : Tên (FirstName), Chức danh (JobTitle), và Ngày vào làm (HireDate) 
-- Sắp xếp danh sách hiển thị theo thứ tự Ngày vào làm từ cũ nhất đến mới nhất 

-- Bảng Person.Person: 
-- Lưu trữ thông tin cá nhân cốt lõi của mọi con người liên quan đến công ty (nhân viên, khách hàng, nhà cung cấp).
----- Cột quan trọng: BusinessEntityID (Mã định danh duy nhất - Khóa chính), FirstName (Tên

-- Bảng HumanResources.Employee: Chỉ lưu trữ các thông tin nghiệp vụ dành riêng cho Nhân viên công ty
----- Cột quan trọng: BusinessEntityID (Khóa ngoại tham chiếu về bảng Person), JobTitle (Chức danh), HireDate (Ngày thuê/Ngày vào làm).

-- Logic nối bảng: Bản chất Nhân viên (Employee) cũng là một Con người (Person)
-- Do đó, hai bảng này có mối quan hệ 1-1, liên kết với nhau qua chìa khóa là cột BusinessEntityID.

-- ORDER BY dùng tên cột 
SELECT 
	p.FirstName, 
	e.JobTitle, 
	e.HireDate 
FROM HumanResources.Employee e
INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 
ORDER BY e.HireDate 

-- ORDER BY dùng số thứ tự cột 
-- Cột 1: FirstName | Cột 2: JobTitle | Cột 3: HireDate
SELECT 
	p.FirstName, 
	e.JobTitle, 
	e.HireDate  
FROM HumanResources.Employee e
INNER JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 
ORDER BY 3 

-- Tóm tắt cần nhớ
-- Cú pháp: ORDER BY N (N là vị trí cột tính từ trái sang phải trong SELECT, bắt đầu từ 1).
-- Ưu điểm: Viết nhanh, không bị ảnh hưởng nếu bạn thay đổi Tên hiển thị (Alias) của cột (ví dụ: e.HireDate AS [Ngày ký HĐ]).
-- Nhược điểm: Readability (tính dễ đọc) cực kém. Phải ngồi đếm ngón tay xem số 3 là cột nào. Dễ sinh lỗi ngầm khi cấu trúc bảng/câu SELECT thay đổi.


-- 8.2. Use ORDER BY with TOP to return the top x rows based on a column's value 
-- Đề bài: rích xuất danh sách 5 sản phẩm có giá bán niêm yết (ListPrice) đắt đỏ nhất để đưa vào catalogue quảng cáo dòng hàng cao cấp.
-- Thông tin cần lấy: Tên sản phẩm, Mã sản phẩm và Giá bán.

-- Để lấy "5 sản phẩm cao nhất", chúng ta cần kết hợp TOP 5 và ORDER BY ... DESC (Sắp xếp giảm dần).
-- Nếu bạn CHỈ dùng TOP 5 mà KHÔNG dùng ORDER BY:
-- Hệ thống sẽ bốc đại 5 dòng đầu tiên nó tìm thấy trong ổ cứng (thường là theo thứ tự Khóa chính - ProductID)
-- Kết quả trả về sẽ là 5 sản phẩm ngẫu nhiên, hoàn toàn sai nghiệp vụ.

-- Bảng Production.Product: Lưu trữ toàn bộ danh mục sản phẩm mà công ty Adventure Works sản xuất hoặc bán
----- Name: Tên sản phẩm.
----- ProductNumber: Mã sản phẩm (ví dụ: 'BK-M68B-42').
----- ListPrice: Giá niêm yết (giá bán ra cho khách hàng). 
----- Lưu ý nghiệp vụ: Sẽ có những sản phẩm có ListPrice = 0 (đây có thể là linh kiện nội bộ không bán ra ngoài, hoặc hàng tặng kèm).

SELECT TOP 5 
	p.[Name], 
	p.ProductNumber,
	p.ListPrice
FROM Production.[Product] p
ORDER BY p.ListPrice DESC 



SELECT TOP 5 WITH TIES 
	p.[Name], 
	p.ProductNumber,
	p.ListPrice
FROM Production.[Product] p
ORDER BY p.ListPrice DESC 
-- Sử dụng thêm từ khóa WITH TIES trong SSMS. 
-- Cú pháp này yêu cầu SQL: "Nếu những dòng tiếp theo có giá trị bằng với dòng chót cùng của Top, hãy lấy luôn chúng".

-- Tóm tắt cần nhớ
-- 1. TOP + ORDER BY: Bộ đôi không thể tách rời. TOP quyết định "Số lượng", ORDER BY quyết định "Chất lượng" của dữ liệu được cắt ra.
-- 2. DESC / ASC: DESC (Descending) để tìm Top Cao nhất / Lớn nhất / Mới nhất. 
----- ASC (Ascending) để tìm Top Thấp nhất / Nhỏ nhất / Cũ nhất. (Mặc định nếu không ghi gì là ASC).
-- 3. WITH TIES: Vũ khí sắc bén để xử lý công bằng các trường hợp "đồng hạng" ở mép giới hạn.
-- 4. SQL Server dùng TOP (đầu câu), MySQL dùng LIMIT (cuối câu).


-- 8.3. Customized sorting order

-- Các sếp thường không quan tâm bảng chữ cái tiếng Anh hoạt động thế nào, họ chỉ quan tâm đến Logic kinh doanh (Business Logic).
-- Kỹ thuật dùng CASE trong ORDER BY chính là cầu nối để ép SQL Server phải sắp xếp theo "luật chơi" của con người thay vì luật của máy tính.


-- bảng Production.Product (Sản phẩm).
----- 'H': High (Phân khúc Cao cấp)
----- 'M': Medium (Phân khúc Tầm trung)
----- 'L': Low (Phân khúc Bình dân)
----- (Và có cả những sản phẩm mang giá trị NULL - tức là chưa/không được phân loại).

-- Tại sao sắp xếp bình thường lại thất bại?
-- Nếu bạn dùng ORDER BY Class ASC (theo Alphabet), thứ tự trả về sẽ là: H -> L -> M (Vì chữ L đứng trước chữ M trong bảng chữ cái).
-- Logic kinh doanh lập tức gãy vụn! Bạn đang báo cáo: "Cao cấp -> Bình dân -> Tầm trung".

-- Đề bài: Lấy danh sách sản phẩm gồm
----- Tên (Name), Mã SP (ProductNumber), Giá bán (ListPrice) và Phân khúc (Class).
----- Trình bày danh sách sao cho các sản phẩm Cao cấp ('H') nằm trên cùng, kế đến là Tầm trung ('M'), rồi đến Bình dân ('L').
----- Những sản phẩm không thuộc phân khúc nào (NULL) thì đẩy hết xuống cuối cùng.

----- Để "nắn" lại thứ tự, chúng ta dùng CASE (Cấu trúc rẽ nhánh) để gán ngầm cho mỗi chữ cái một con số, sau đó SQL sẽ sắp xếp dựa trên các con số đó.

SELECT 
		p.[Name],
		p.ProductNumber , 
		p.ListPrice, 
		p.Class
FROM Production.[Product] p
ORDER BY 
	CASE P.Class
		WHEN 'H' THEN 1 -- Nếu là 'H' (High), gán ngầm là số 1 (Đứng đầu)
		WHEN 'M' THEN 2 -- Nếu là 'M' (Medium), gán ngầm là số 2
		WHEN 'L' THEN 3 -- Nếu là 'L' (Low), gán ngầm là số 3
		ELSE 4          -- Nếu là NULL hoặc giá trị khác, gán số 4 (Đẩy xuống cuối)
	END

-- Vấn đề thực tiễn thường gặp (Bắt bệnh & Xử lý)
-- Lỗi 1: Quên mệnh đề ELSE (Sự cố hiển thị NULL)
----- Tại sao gặp? Bạn chỉ viết WHEN 'H' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 END; và bỏ qua ELSE.
----- Hậu quả: Đối với các dòng Class là NULL, mệnh đề CASE sẽ trả về NULL
----- trong SQL Server, khi sắp xếp ASC (tăng dần), giá trị NULL luôn được đẩy lên đầu tiên.
----- Kết quả: Các sản phẩm chưa phân loại lại chễm chệ nằm chèn lên trên cả hàng Cao cấp ('H').
----- Cách xử lý: Luôn phải có ELSE [Một_số_lớn] (như ELSE 4 ở trên) để gom rác/dữ liệu ngoại lệ và "đá" chúng xuống đáy bảng.


-- Lỗi 2: Hiệu ứng "Bầy đàn" (Thiếu Secondary Sort)
----- Tại sao gặp? Trong CSDL có 100 sản phẩm hạng 'H'
----- Vì bạn ép tất cả chúng thành số 1, SQL Server coi 100 sản phẩm này là "Đồng hạng"
----- Kết quả là bên trong nội bộ nhóm 'H', thứ tự hiển thị cực kỳ lộn xộn, không theo quy tắc nào.
----- Cách xử lý : Luôn kết hợp sắp xếp tùy chỉnh (CASE) với một tiêu chí sắp xếp phụ (Secondary Sort).


SELECT 
		p.[Name],
		p.ProductNumber , 
		p.ListPrice, 
		p.Class
FROM Production.[Product] p
ORDER BY 
	-- Tiêu chí 1: Ép nhóm theo Phân khúc
	CASE P.Class
		WHEN 'H' THEN 1 -- Nếu là 'H' (High), gán ngầm là số 1 (Đứng đầu)
		WHEN 'M' THEN 2 -- Nếu là 'M' (Medium), gán ngầm là số 2
		WHEN 'L' THEN 3 -- Nếu là 'L' (Low), gán ngầm là số 3
		ELSE 4          -- Nếu là NULL hoặc giá trị khác, gán số 4 (Đẩy xuống cuối)
	END,
	-- Tiêu chí 2 (Secondary Sort): Trong cùng 1 nhóm phân khúc, xếp theo Giá giảm dần
	p.ListPrice DESC 

-- Lúc này, :
-- Hàng Cao cấp ('H') hiện ra trước, và trong đám Cao cấp đó, món nào đắt nhất hiện lên đầu. 

-- Tóm tắt cần nhớ
-- Chữ cái # Logic kinh doanh: 
----- Dùng CASE trong ORDER BY khi cần sắp xếp theo trạng thái, mức độ ưu tiên, quy trình vòng đời (VD: Đang chờ duyệt -> Đã duyệt -> Đang giao -> Hoàn tất -> Hủy).

-- Luôn lót sẵn đường lui với ELSE
----- Để kiểm soát các giá trị NULL hoặc dữ liệu rác, không cho chúng ngoi lên phá hỏng trật tự.

-- Secondary Sort (Sắp xếp phụ)
----- Không bao giờ để các dòng dữ liệu "đồng hạng" hiển thị ngẫu nhiên
----- Luôn phẩy (,) thêm một cột nữa (như Tên, Giá, Ngày tháng) sau hàm CASE


-- 8.4. Order by Alias +  8.5. Sorting by multiple columns 

-- bảng Sales.SalesOrderHeader
-- Cột quan trọng: * SalesOrderID: Mã đơn hàng (Khóa chính).
----- OrderDate: Ngày khách đặt hàng.
----- TotalDue: Tổng tiền khách phải trả (đã bao gồm thuế, phí vận chuyển)

-- Đề bài

----- Trích xuất báo cáo doanh thu gồm: Mã đơn hàng, Ngày đặt hàng (đặt tên cột là NgayGiaoDich) và Tổng tiền (đặt tên cột là DoanhThu)
----- cần sắp xếp báo cáo sao cho các đơn hàng có cùng Ngày đặt hàng nằm cạnh nhau từ cũ tới mới.
----- Trong cùng một ngày, đơn hàng nào có Tổng tiền lớn hơn phải ưu tiên xếp lên trên.



SELECT 
	s.SalesOrderID, 
	s.OrderDate AS NgayGiaoDich,
	s.TotalDue AS DoanhThu
FROM Sales.SalesOrderHeader s
ORDER BY NgayGiaoDich , -- MẶC ĐỊNH LÀ ASC 
		 DoanhThu DESC


SELECT 
	s.SalesOrderID, 
	s.OrderDate AS NgayGiaoDich,
	s.TotalDue AS DoanhThu
FROM Sales.SalesOrderHeader s
ORDER BY NgayGiaoDich DESC , -- VIẾT TƯỜNG MINH, CỤ THỂ 
		 DoanhThu DESC

-- Tóm tắt cần nhớ
----- Thứ tự thực thi: SELECT chạy trước ORDER BY. Nhờ đó ORDER BY xài được Alias.
----- WHERE không biết Alias: Đừng bao giờ đem Alias vào mệnh đề WHERE hay GROUP BY (trong SQL Server).
----- Tie-breaker (Kẻ phá vỡ thế hòa): Sắp xếp nhiều cột hoạt động theo cơ chế ưu tiên từ trái sang phải. Cột thứ 2 chỉ nhảy vào phân xử khi cột thứ 1 có các giá trị trùng nhau.
----- Chỉ định tường minh: Từ khóa ASC / DESC đi kèm độc lập với từng cột. Không có chuyện "khuyến mãi" dùng chung.
