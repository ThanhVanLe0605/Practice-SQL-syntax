
-- The SELECT statement is at the heart of most SQL queries
-- It defines what result set should be returned by the query, and is almost always used in conjunction with the FROM clause, which defines what part(s) of the database should be queried.

-- 6.1. Using the wildcard character to select all columns in a query 

-- It will return all fields of all rows of the Employees table
SELECT * FROM HumanResources.Employee 

-- To select all values from a specific table, the wildcard character can be applied to the table with dot notation.
-- (Ví dụ: Lấy toàn bộ thông tin Sản phẩm, và chỉ lấy thêm Tên Mẫu mã từ bảng ProductModel)
SELECT
    p.*,
    m.Name AS ModelName
FROM Production.Product p
JOIN Production.ProductModel m
     ON p.ProductModelID = m.ProductModelID;

-- 6.2. SELECT Using Column Aliases

SELECT 
	FirstName  AS "First Name",
	LastName  AS "Last Name"
FROM Person.Person 

-- You can use single quotes ('), double quotes (") and square brackets ([]) to create an alias in Microsoft SQL Server.
SELECT 
    FirstName        AS "First Name",
    LastName         AS 'Last Name',
    BusinessEntityID AS [Employee ID] 
FROM Person.Person;


SELECT -- However, the explicit version (i.e., using the AS operator) is more readable.
    FirstName        "First Name",
    LastName         "Last Name",
    BusinessEntityID "Employee ID"
FROM Person.Person;

-- If the alias has a single word that is not a reserved word, we can write it without single quotes, double quotes or brackets
SELECT
    FirstName AS FirstName,
    LastName  AS LastName
FROM Person.Person;

-- A further variation available in MS SQL Server amongst others is <alias> = <column-or-calculation>, for instance
SELECT 
    FullName = FirstName + ' ' + LastName
FROM Person.Person;


-- Also, a column alias may be used any of the final clauses of the same query, such as an ORDER BY:
SELECT
    FirstName AS FirstName,
    LastName  AS LastName
FROM Person.Person
ORDER BY 
    LastName DESC;


-- 6.3. SELECT Individual Columns
SELECT 
    AccountNumber,
    Name, 
    CreditRating
FROM Purchasing.Vendor;

-- Lấy thông tin Khách hàng (Sales.Customer) và nối với Đơn hàng (Sales.SalesOrderHeader)
-- Để xem khách nào có đơn hàng, khách nào chưa (LEFT JOIN)
SELECT
    c.CustomerID,
    c.StoreID, 
    c.TerritoryID, 
    o.SalesOrderID AS OrderId
FROM Sales.Customer c
LEFT JOIN Sales.SalesOrderHeader o 
    ON o.CustomerID = c.CustomerID;

-- 6.4. Selecting specified number of records

-- 6.4.1. Dùng OFFSET ... FETCH : 
-- Như khi đội ngũ IT xây dựng website bán hàng, cần làm tính năng phân trang (Pagination)
-- Khách hàng đang ở trang 2, do đó hệ thống cần "Bỏ qua 5 sản phẩm đầu tiên (của trang 1) và lấy 10 sản phẩm tiếp theo"

SELECT p.ProductID,
	   p.Name AS ProductName, 
	   p.ListPrice, 
	   p.ProductNumber
FROM Production.Product p
-- Bắt buộc phải có ORDER BY khi dùng OFFSET ... FETCH trong SQL Server
ORDER BY p.ListPrice DESC 
OFFSET 5 ROWS -- Bỏ qua 5 dòng đầu 
FETCH NEXT 10 ROWS ONLY 


-- 6.4.2. Dùng TOP
SELECT TOP 10 
	   p.ProductID,
	   p.Name AS ProductName, 
	   p.ListPrice, 
	   p.ProductNumber
FROM Production.Product p
-- Sắp xếp theo giá giảm dần để các sản phẩm đắt nhất nằm trên cùng 
ORDER BY p.ListPrice DESC

-- NOTES: 
-- Mệnh đề TOP trong SQL Server chạy sau khi dữ liệu đã được lọc (WHERE) và sắp xếp (ORDER BY)
-- Tương tự, OFFSET... FETCH cũng bắt buộc phải đi kèm với ORDER BY thì SQL Server mới cho phép chạy, để đảm bảo tính nhất quán của dữ liệu khi phân trang


-- 6.5. Selecting with Condition

-- 6.5.1. Dùng ĐK lọc (WHERE) với   toán tử = 
-- Tìm tất cả các đơn hàng đã giao thành công (Status = 5)
SELECT
	s.SalesOrderID,
	s.OrderDate, 
	s.Status,
	s.TotalDue
FROM Sales.SalesOrderHeader s
WHERE s.Status = 5; -- Lọc chính xác các dòng có trạng thái là 5

-- 6.5.2. Dùng ĐK lọc (WHERE) với toán tử IN, BETWEEN , LIKE , AND 
-- Tìm các sản phẩm Road  màu đen/đỏ  trong tầm giá $500 - $1000
SELECT 
	p.ProductID, 
	p.Name AS ProductName,
	p.Color, 
	p.ListPrice 
FROM Production.Product p
WHERE 
	 -- Dùng LIKE với ký tự đại diện '%' để tìm tên có chứa chữ "Bike" 
	 p.Name LIKE '%Road%'

	 -- Dùng IN thay vì viết (Color = 'Black' OR Color ='Red')
	 AND p.Color IN ('Black', 'Red')

	 -- Dùng BETWEEN AND thay vì viết (ListPrice >= 500 AND ListPrice >= 1000)
	 AND p.ListPrice BETWEEN 500 AND 1000

-- NOTES:
-- Khi bạn dùng mệnh đề WHERE với các toán tử như =, >, <, hay BETWEEN, SQL Server có thể tận dụng Index (Chỉ mục) để tìm dữ liệu rất nhanh.
-- Nhưng nếu bạn dùng LIKE '%Bike%' (dấu % nằm ở đầu), hệ thống sẽ phải quét toàn bộ bảng (Table Scan), có thể làm chậm quá trình truy vấn đối với dữ liệu lớn.

-- 6.5.3. Dùng ĐK lọc (WHERE) với HAVING 

-- Phân biệt WHERE với HAVING 
-- WHERE   : Lọc từng dòng dữ liệu TRƯỚC KHI gom nhóm. KHÔNG DÙNG được với các hàm tính toán tổng hợp ( như SUM, COUNT, AVG ,...)
-- HAVING  : Loc kết quả SAU KHI đã gom nhóm (dùng GROUP BY). Luôn đi kèm với các hàm tính toán tổng hợp 

-- 6.5.3.1. Chỉ dùng HAVING 

-- Giám đốc chăm sóc khách hàng muốn tìm ra những "Khách hàng siêu VIP"
-- Định nghĩa VIP ở đây là những khách hàng đã từng đặt nhiều hơn 15 đơn hàng từ trước đến nay.

SELECT 
		s.CustomerID, 
		COUNT(s.SalesOrderID) AS TotalOrders -- Đếm số lượng đơn hàng của từng người 
FROM Sales.SalesOrderHeader s 
GROUP BY s.CustomerID -- Gom nhóm theo từng khách hàng  
HAVING COUNT( s.SalesOrderID) > 15 -- Chỉ giữ lại những ai có tổng số đơn đặt hàng > 15 
ORDER BY TotalOrders DESC

-- 6.5.3.2. Kết hợp cả WHERE và HAVING 

-- Trưởng phòng kinh doanh muốn khen thưởng các nhân viên Sale xuất sắc.
-- Tiêu chí: Chỉ xét doanh số trong năm 2013 (Lọc thời gian), và tổng doanh thu mà nhân viên đó mang lại phải lớn hơn 2 triệu đô la (Lọc tổng doanh số).

SELECT 
	s.SalesOrderID, -- --> ERROR 8120 
	SUM(s.TotalDue) AS TotalSalesAmount -- Tính tổng doanh thu 
FROM
	Sales.SalesOrderHeader s 
WHERE 
		s.SalesPersonID IS NOT NULL  -- Nhân viên phải tồn tại 
	AND YEAR(s.OrderDate) = 2013      -- Chỉ lấy hóa đơn trong năm 2013 
GROUP BY 
	s.SalesPersonID -- Gom nhóm lại theo từng nhân viên
HAVING 
	SUM(s.TotalDue) > 2000000 -- Lọc 3: SAU KHI cộng dồn, chỉ lấy người vượt chỉ tiêu 2 triệu $
ORDER BY 
	TotalSalesAmount DESC 

-- ERROR: 8120 
-- Đây là lỗi logic, khi GROUP BY sẽ có một số cột không thể đặt ở SELECT mà không đi kèm với các hàm tín toán như SUM, COUNT, MAX,.. 


SELECT 
	s.SalesPersonID, 
	SUM(s.TotalDue) AS TotalSalesAmount -- Tính tổng doanh thu 
FROM
	Sales.SalesOrderHeader s 
WHERE 
		s.SalesPersonID IS NOT NULL  -- Nhân viên phải tồn tại 
	AND YEAR(s.OrderDate) = 2013      -- Chỉ lấy hóa đơn trong năm 2013 
GROUP BY 
	s.SalesPersonID -- Gom nhóm lại theo từng nhân viên
HAVING 
	SUM(s.TotalDue) > 2000000 -- Lọc 3: SAU KHI cộng dồn, chỉ lấy người vượt chỉ tiêu 2 triệu $
ORDER BY 
	TotalSalesAmount DESC 


-- 6.6. Selecting with CASE ( Cấu trúc rẽ nhánh )

-- Bộ phận Marketing muốn phân loại các sản phẩm trong kho dựa trên giá niêm yết (ListPrice) để lên chiến dịch quảng cáo. Cụ thể:
-- Giá dưới $50 là "Budget" (Giá rẻ).
-- Từ $50 đến dưới $1000 là "Mid-Range" (Tầm trung).
-- Từ $1000 trở lên là "Premium" (Cao cấp).

-- Lấy danh sách sản phẩm và tự động gắn nhãn phân khúc giá

SELECT 
		p.ProductID, 
		p.Name AS ProductName, 
		p.ListPrice, 
		-- Bắt đầu cấu trúc rẽ nhánh rà soát từng dòng 
		CASE 
			WHEN p.ListPrice < 50 THEN 'Budget'
			WHEN p.ListPrice >= 50 AND p.ListPrice < 1000 THEN 'Mid-Range'
			ELSE 'Premium'
		END AS PriceCategory -- Tên cột hiển thị kết quả của lệnh CASE 
FROM Production.Product p 
-- Chỉ lấy những sản phẩm có giá lớn hơn 0 để biểu diễn cho rõ
WHERE p.ListPrice > 0 
ORDER BY p.ListPrice DESC 


-- 6.7. Selecting columns which are named after reserved keywords
-- Từ khóa dành riêng - Reserved Keywords 

-- Bộ phận kinh doanh cần xem danh sách các khu vực bán hàng (Territory) và nhóm châu lục của chúng
-- Đặc biệt, trong AdventureWorks có một cột tên là Group lưu thông tin châu lục (như Europe, North America)
-- Từ GROUP là một từ khóa hệ thống dùng cho GROUP BY, nên nếu viết thẳng vào SQL sẽ bị báo lỗi ngay.
-- Chúng ta phải dùng dấu ngoặc vuông [] của SQL Server để "bảo vệ" nó
-- "" cho chuẩn SQL, [] cho SQL Server, và ` cho MySQL

SELECT 
	t.TerritoryID , 
	t.[Name] AS TerritoryName, 
	-- Phải bọc từ khóa Group bằng [] vì GROUP là một lệnh trong SQL
    t.[Group] AS ContinentGroup,
	t.SalesYTD
FROM Sales.SalesTerritory t 


-- 6.8. Selecting with table alias

 -- Lợi ích 
 -- 1. Viết code nhanh hơn 
 -- 2. Tránh lỗi 'Ambiguous column name"
 -- 3. Đóng vai trò quan trọng trong Self-join 

 -- Lấy chức danh và họ tên của nhân viên
 SELECT 
		e.JobTitle, 
		p.FirstName, 
		p.LastName
 FROM HumanResources.Employee e
 JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 

 -- ERROR: Multi-part identifier could not be bound
 -- lý do: Một khi đã dùng bí danh, không được dùng tên bảng gốc nữa
  SELECT 
		HumanResources.Employee.JobTitle, -- ERROR !!! 
		p.FirstName, 
		p.LastName
 FROM HumanResources.Employee e
 JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 

 -- Nếu nối 2 bảng có một số cột của 2 bảng trùng tên, ta dùng alias để phân biệt khi SELECT 
 -- Nếu bỏ 'soh.' trước SalesOrderID, SQL Server sẽ báo lỗi Ambiguous (không rõ ràng)
 SELECT 
		soh.SalesOrderID, -- Bắt buộc phải chỉ rõ lấy mã đơn hàng từ bảng nào
		soh.OrderDate, 
		sod.ProductID, 
		sod.LineTotal 
 FROM Sales.SalesOrderHeader soh 
 JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID 

 -- NOTES: NATURAL JOIN
 -- Đây là kiểu JOIN mà SQL tự động tìm các cột trùng tên giữa 2 bảng để tự ghép nối mà không cần  viết chữ ON...
 -- SQL Server KHÔNG HỖ TRỢ NATURAL JOIN.
 -- MySQL hay Oracle (những hệ quản trị có hỗ trợ Natural Join), các chuyên gia dữ liệu vẫn khuyên không nên dùng nó


-- 6.9. Selecting with more than 1 condition
-- 6.9.1. Tất cả điều kiện phải đúng 
-- Phòng nhân sự cần tìm danh sách các nhân viên Nam VÀ sinh trước năm 1980 để rà soát chế độ bảo hiểm thâm niên. 
-- (Cả 2 điều kiện đều phải đúng).

SELECT 
	 p.FirstName,
	 p.LastName, 
	 e.Gender, 
	 e.BirthDate
FROM HumanResources.Employee e 
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 
WHERE e.Gender = 'M'					-- ĐK1 : là Nam (Male)
	  AND YEAR( e.BirthDate ) < 1980	-- Điều kiện 2: Sinh trước 1980

-- 6.9.2. Chỉ cần 1 điều kiện đúng 
-- Công ty có một đợt khám sức khỏe đặc biệt dành cho nhân viên Nữ HOẶC những ai làm vị trí Quản lý (Manager) bất kể nam nữ
-- (Chỉ cần 1 trong 2 điều kiện đúng là được lấy).

-- Tìm nhân viên là Nữ HOẶC làm vị trí Quản lý
SELECT 
	p.FirstName, 
    p.LastName, 
    e.Gender, 
    e.JobTitle	
FROM HumanResources.Employee e 
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 
WHERE e.Gender = 'F'
	  OR e.JobTitle LIKE '%Manager%' 


-- 6.9.3. Kết hợp phức tạp AND, OR với () 
-- Phòng Marketing muốn làm một khảo sát thế hệ.
-- Họ cần tìm những (Nhân viên Nam sinh sau năm 1990 - Gen Z/Millennials) HOẶC (Nhân viên Nữ sinh trước năm 1980 - Gen X).

-- Trong SQL, toán tử AND luôn được ưu tiên chạy trước toán tử OR (giống như nhân chia trước, cộng trừ sau).
-- Nếu không bọc chúng vào ngoặc (), SQL có thể hiểu sai hoàn toàn logic của bạn.


-- Tìm (Nam sinh sau 1990) HOẶC (Nữ sinh trước 1980)
SELECT 
	p.FirstName, 
    p.LastName, 
    e.Gender,
	YEAR(e.BirthDate) AS BirthYear 
FROM HumanResources.Employee e 
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID 
WHERE 
	(  e.Gender = 'M' AND YEAR(e.BirthDate) > 1990  )
	OR
	(  e.Gender = 'F' AND YEAR(e.BirthDate) < 1980  ) 

-- 6.10. Selecting without Locking the table 

-- Lợi :  Khi làm việc với Big data cần " Tối ưu hóa hiệu suất (Performance Tuning) và Cơ chế Khóa (Locking) " 
-- Nhược: Dirty reads - đọc dữ liệu bẩn 

-- Tại sao hệ thống lại bị "Khóa" (Lock)?
----- Bình thường, khi một nhân viên đang cập nhật (UPDATE) đơn hàng số #123, SQL Server sẽ tự động "khóa" dòng dữ liệu đó lại.
----- Nếu lúc đó bạn chạy lệnh SELECT để xuất báo cáo chứa đơn hàng #123, câu lệnh của bạn sẽ phải đứng chờ (bị treo) cho đến khi nhân viên kia cập nhật xong.

-- Kịch bản dùng NOLOCK (Hợp lý):
----- Ban giám đốc cần xuất một báo cáo tổng quan doanh thu của 10 năm qua (hàng triệu dòng dữ liệu) để vẽ biểu đồ.
----- Việc chờ đợi các giao dịch đang diễn ra sẽ làm sập hệ thống báo cáo.
----- Ban giám đốc chấp nhận sai số vài ngàn đô la, miễn là báo cáo xuất ra ngay lập tức
----- Lúc này, dùng NOLOCK là cứu cánh.

-- Rủi ro (Không hợp lý):
----- Bộ phận kế toán đang đối soát công nợ chi tiết đến từng đồng.
----- Nếu dùng NOLOCK, hệ thống có thể đọc phải một đơn hàng vừa bị hủy nhưng chưa kịp hoàn tất thủ tục lưu trữ (rollback), dẫn đến sai lệch sổ sách.


-- Xuất báo cáo tổng số lượng sản phẩm đã bán và tổng tiền
-- Bỏ qua mọi cơ chế khóa của hệ thống để báo cáo chạy nhanh nhất có thể

SELECT 
		s.ProductID,
		SUM(s.OrderQty) AS TotalQuantitySold, 
		SUM(s.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail s WITH (NOLOCK) -- Báo cho SQL Server: "Cứ đọc đi, không cần chờ ai cả!" 
GROUP BY s.ProductID
ORDER BY TotalRevenue DESC 

-- Nếu bạn JOIN nhiều bảng và muốn bỏ qua khóa cho tất cả, bạn phải viết WITH (NOLOCK) ở từng bảng một. 
-- Ví dụ: FROM TableA a WITH (NOLOCK) JOIN TableB b WITH (NOLOCK) ON...

-- 6.11. Selecting with Aggregate functions

-- "Báo cáo tổng quan doanh thu toàn công ty "
-- Cụ thể :
			-- 1. Tổng doanh thu từ trước đến nay là bao nhiêu (SUM) ? Giá trị trung bình của mỗi đơn hàng là bao nhiêu ? 
			-- 2. Đơn hàng có giá trị thấp nất (MIN) và cao nhất (MAX) là bao nhiêu ?
			-- 3. Có tổng cộng bao nhiêu đơn hàng được tạo ra ( COUNT(*) ) ? Trong đó, bao nhiêu đơn là nhhaan viên Sale trực tiếp chốt (bỏ qua dơn tự đặt online) 
			-- 4. Đã bán hàng được cho tổng cộng bao nhiêu khu vực ( COUNT DISTINCT )
			-- 5. Tính doanh thu trung bình của từng khu vực (GROUP BY )

-- 6.11.1. Xem tổng quan bức tranh tài chính của công ty
SELECT 
		SUM(s.TotalDue)  AS TongDoanThu,
		AVG(s.TotalDue)	 AS DoanhThuTrungBinh_MoiDon,
		MIN(s.TotalDue)  AS DonHang_GiaTriNhoNhat,
		MAX(s.TotalDue)  AS DonHang_GiaTriLonNhat
FROM Sales.SalesOrderHeader s 


-- 6.11.2.  Sự khác biệt quan trọng giữa các loại COUNT
SELECT 
		-- Đếm Mọi dòng dưx liệu có trong bảng (Bao gồm cả đơn khách tự mua trên Web)
		COUNT(*) AS	TongSo_TatCaDonHang, 

		-- Chỉ đếm những dòng mà cột SalesPersonID không bị Null (Chỉ tính đơn do Sale chốt)
		COUNT(SalesPersonID) AS SoDonHang_DoSaleChot,

		-- (Chỉ tính đơn do Sale chốt)
		COUNT( DISTINCT s.TerritoryID) AS SoKhuVucDaBanHang
FROM Sales.SalesOrderHeader s

-- 6.11.3. Kết hợp Hàm tổng hợp (Aggregate functions) với WHERE và GROUP BY

-- Tính doanh thu trung bình của từng khu vực, chỉ tính các đơn do Sale bán 
SELECT
	  s.TerritoryID , 
	  AVG(s.TotalDue) AS DoanhThuTrungBinh_KhuVuc 
FROM Sales.SalesOrderHeader s 
WHERE s.SalesPersonID IS NOT NULL 
GROUP BY s.TerritoryID 
ORDER BY DoanhThuTrungBinh_KhuVuc DESC

-- 6.12. Select with condition of multiple values from column 


-- Giám đốc Marketing đang chuẩn bị một chiến dịch quảng cáo cực lớn cho các dịp lễ cuối năm.
-- Sếp yêu cầu bạn xuất danh sách tất cả các sản phẩm trong kho đang có màu Đỏ (Red), Đen (Black), hoặc Bạc (Silver).

-- Cách 1
SELECT 
	p.ProductID, 
	p.Name AS ProductName, 
	p.Color, 
	p.ListPrice 
FROM Production.Product p
WHERE p.Color = 'Red' 
	  OR p.Color = 'Black'
	  OR p.Color = 'Silver'

-- Cách 2
SELECT 
	p.ProductID, 
	p.Name AS ProductName, 
	p.Color, 
	p.ListPrice 
FROM Production.Product p
WHERE p.Color IN( 'Red', 'Black', 'Silver') 

-- Mênh đề ngược NOT IN
-- "Hãy lấy tất cả các sản phẩm, TRỪ màu Đỏ và Đen"
-- Cách 2
SELECT 
	p.ProductID, 
	p.Name AS ProductName, 
	p.Color, 
	p.ListPrice 
FROM Production.Product p
WHERE p.Color NOT IN( 'Red', 'Black') 

-- 6.13. Get aggregated result for row groups 

-- Giám đốc Kinh doanh muốn xem Số lượng đơn hàng và Giá trị trung bình mỗi đơn của từng nhân viên Sale. Sếp có 2 yêu cầu:
----- Lọc bỏ các đơn hàng khách tự mua trên web
----- Chỉ hiển thị những nhân viên "Ngôi sao" có giá trị đơn hàng trung bình lớn hơn $4,000

-- Thống kê hiệu suất của các nhân viên Sale xuất sắc
SELECT 
	s.SalesPersonID, 
	COUNT(s.SalesOrderID) AS TotalOrders,
	AVG(s.TotalDue) AS AverageOrderValue 
FROM Sales.SalesOrderHeader  s
WHERE s.SalesPersonID IS NOT NULL 
GROUP BY s.SalesPersonID
HAVING AVG(s.TotalDue) > 4000


-- 6.14. Selection with sorted Results

-- Nghệ thuật sắp xếp
-----  Phòng nhân sự cần xuất danh bạ công ty.
-----  Họ muốn sắp xếp theo thứ tự từ điển: Ưu tiên Họ (LastName) trước, nếu trùng Họ thì xếp theo Tên (FirstName).
-----  Đặc biệt, sếp lớn yêu cầu đẩy tất cả những người mang họ "Smith" lên trên cùng của danh sách!
-- 6.14.1. Sắp xếp nhiều cột 
SELECT 
	p.BusinessEntityID, 
	p.FirstName, 
	p.LastName
FROM Person.Person p
ORDER BY 
	p.LastName ASC,  -- Sắp xếp cột Họ tăng dần (A-Z) trước
	p.FirstName ASC  -- Nếu có nhiều người cùng một Họ, tiếp tục xếp Tên từ A-Z

--6.14.2. Sắp xếp theo số thứ tự cột
-- Nhanh hơn khi viết câu lệnh nhưng nếu au này ai đó thêm/bớt cột vào câu SELECT, số thứ tự sẽ bị lệch và làm sai toàn bộ logic sắp xếp của báo cáo
SELECT 
	p.BusinessEntityID, 
	p.FirstName, 
	p.LastName
FROM Person.Person p
ORDER BY 3 ASC -- Số 3 đại diện cho cột thứ 3 trong câu SELECT (chính là LastName)

-- 6.14.3. Đưa cấu trúc rẽ nhánh CASE vào sắp xếp 
-- Nhanh hơn khi viết câu lệnh nhưng nếu au này ai đó thêm/bớt cột vào câu SELECT, số thứ tự sẽ bị lệch và làm sai toàn bộ logic sắp xếp của báo cáo
SELECT 
	p.BusinessEntityID, 
	p.FirstName, 
	p.LastName
FROM Person.Person p
ORDER BY
	-- Bất kỳ ai họ Smith sẽ bị gán giá trị 0 (Nhỏ nhất -> Nằm trên cùng)
    -- Những người còn lại gán giá trị 1 (Nằm bên dưới)
	CASE
		WHEN p.LastName = 'Smith' THEN 0 
		ELSE 1 
	END ASC ,

	-- Đối với phần còn lại (hoặc những người cùng họ Smith), tiếp tục xếp theo A-Z
	p.LastName ASC,
	p.FirstName ASC 

-- 6.15. Selecting with null

-- 6.15.1. Tìm các sản phẩm không có màu sắc (IS NULL)
SELECT 
	p.ProductID, 
	p.Name AS ProductName, 
	p.Color 
FROM Production.[Product] p
WHERE p.Color IS NULL 

-- 6.15.2. Tìm các đơn hàng do Sale bán (IS NOT NULL)
SELECT 
	h.SalesOrderID, 
	h.OrderDate, 
	h.SalesPersonID, 
	h.TotalDue 
FROM Sales.SalesOrderHeader h
WHERE h.SalesPersonID IS NOT NULL 
-- 6.15.3. ISNULL và COALESCE() 

-- Trong SQL Server có một hàm cực hay tên là ISNULL() (viết liền) hoặc hàm chuẩn COALESCE()
-- Các hàm này giúp bạn biến giá trị NULL thành một chữ khác khi in ra báo cáo. Ví dụ: In chữ "Chưa cập nhật" thay vì để ô trống trơn.

-- Bộ phận Content của công ty đang rà soát danh mục sản phẩm đưa lên Website
-- Rất nhiều sản phẩm (như ốc vít, linh kiện) không có màu sắc (Color bị NULL)
-- Nếu để nguyên, web sẽ bị lỗi hiển thị.
-- Bạn cần xuất danh sách và thay thế chữ NULL thành "Chưa cập nhật" (hoặc "Không có màu")

-- 6.15.3.1. Dùng ISNULL()

SELECT 
		p.ProductID, 
		p.Name AS ProductName, 
		p.Color AS MauGoc_Bi_Null, -- Cột gốc để so sánh 

		-- Nếu cột Color bị NULL, thay ngay chữ "Chưa cập nhật"
		ISNULL(p.Color, N'Chưa cập nhật') AS MauSac_HienThi 
FROM Production.[Product] p
ORDER BY p.ProductID 

-- NOTES:KHI DUNFG ISNULL() thì giá trị thay thế bắt buộc phải cùng kiểu dữ liệu với cột gốc

-- VD: cột SalesPersonID (Mã nhân viên) là kiểu Số nguyên (INT)
-- Những đơn khách tự mua trên web sẽ có mã này là NULL

SELECT 
	ISNULL(SalesPersonID, N'Khách tự mua') 
FROM Sales.SalesOrderHeader

-- Msg 245, Level 16, State 1, Line 557
-- Conversion failed when converting the nvarchar value 'Khách tự mua' to data type int.

-- Cách sửa:
SELECT 
	SalesPersonID,
	ISNULL( CAST( SalesPersonID AS NVARCHAR ) , N'Khách tự mua') AS NguoiBanHang
FROM Sales.SalesOrderHeader

-- 6.15.3.2. Dùng COALESCE()
-- Kết quả của đoạn code này sẽ y hệt như trên, nhưng code này có thể mang sang các hệ quản trị CSDL khác chạy mà không bị lỗi.
SELECT 
		p.ProductID, 
		p.Name AS ProductName, 
		p.Color AS MauGoc_Bi_Null, -- Cột gốc để so sánh 

		-- Nếu cột Color bị NULL, thay ngay chữ "Chưa cập nhật"
		COALESCE(p.Color, N'Chưa cập nhật') AS MauSac_HienThi 
FROM Production.[Product] p
ORDER BY p.ProductID 

-- 6.16. Select distinct (unique values only)

-- 6.16.1. DISTINCT 1 cột

-- Giám đốc Nhân sự muốn lấy danh sách tất cả các chức danh công việc (Job Title) hiện có trong công ty để làm biểu mẫu tuyển dụng
SELECT DISTINCT 
		e.JobTitle
FROM HumanResources.Employee e 
ORDER BY e.JobTitle ASC 

-- 6.16.2. DISTINCT nhiều cột
-- Giám đốc muốn biết chi tiết hơn: Với mỗi chức danh, hiện đang có những giới tính nào đảm nhận? 
-- (Ví dụ: Vị trí "Kế toán" có cả Nam và Nữ, nhưng vị trí "Bảo vệ" có thể chỉ có Nam).

-- Lấy danh sách các tổ hợp (Chức danh + Giới tính) không trùng lặp
SELECT DISTINCT 
		e.JobTitle, 
		e.Gender
FROM HumanResources.Employee e 
ORDER BY e.JobTitle ASC 

-- 6.17. Select rows from multiple tables 

-- Phòng Kế hoạch muốn tạo một "Khung báo cáo trống" (Matrix) cho năm sau. 
-- Họ muốn liệt kê danh sách tất cả các Khu vực bán hàng (Territory) kết hợp với tất cả các Danh mục sản phẩm (Product Category), để sau này điền chỉ tiêu doanh số cho từng tổ hợp đó.

-- AdventureWorks có 10 Khu vực.
-- AdventureWorks có 4 Danh mục sản phẩm chính.
-- Kết quả mong đợi: Khung báo cáo có 10 X 4 = 40  dòng.


-- 6.17.1. Dùng dấu phẩy ở mệnh đề FROM
SELECT 
		t.Name AS TerritoryName , 
		c.Name AS CategoryName 
FROM Sales.SalesTerritory t, 
	 Production.ProductCategory c
ORDER BY 
	 t.Name ASC


-- Bản chất: Đây là cú pháp cổ điển theo chuẩn SQL cũ (ANSI-89).
-- Ưu điểm: Gõ nhanh
-- Nhược điểm (Rất nguy hiểm): Rất dễ bị nhầm lẫn giữa việc "Cố tình tạo Tích Đề-các" và "Quên viết điều kiện WHERE để nối bảng".
-- Trong thực tế, nếu bạn nối 2 bảng lớn mà dùng dấu phẩy rồi quên điều kiện WHERE, câu lệnh sẽ sinh ra hàng tỷ dòng rác (M X N) làm sập máy chủ (Crash Server).
-- Lời khuyên: Tuyệt đối hạn chế dùng trong môi trường doanh nghiệp hiện đại.


-- 6.17.2. Dùng CROSS JOIN
SELECT 
		t.Name AS TerritoryName , 
		c.Name AS CategoryName 
FROM Sales.SalesTerritory t
CROSS JOIN Production.ProductCategory c
ORDER BY 
	 t.Name ASC

-- Bản chất: Đây là cú pháp chuẩn hiện đại (ANSI-92).

-- Ưu điểm: 
-- Cực kỳ minh bạch và rõ ràng. 
-- Khi bạn (hoặc đồng nghiệp) đọc vào code, từ khóa CROSS JOIN đóng vai trò như một lời khẳng định:
-- "Tôi hoàn toàn tỉnh táo và tôi thực sự CỐ TÌNH muốn nhân chéo 2 bảng này với nhau chứ không hề quên điều kiện!".
-- Lời khuyên: Luôn luôn sử dụng cách này khi bạn cần tạo ma trận dữ liệu (ví dụ: tạo bảng Size x  Màu sắc, hoặc Khu vực x  Tháng).