
-- 7.1. Basic GROUP BY example
-- Bài toán: Tính tổng giá trị (thành tiền) của từng đơn đặt hàng 
-- "MỖI" -> GROUP BY 
-- Bài toán trơ thành : "Cho 'mỗi' đơn hàng (SalesOrderID), tính tổng (SUM) của các dòng thành tiền (LineTotal = Số lượng*Đơn giá - Chiết khấu )


-- Lấy mã đơn hàng và tính tổng thành tiền của đơn hàng đó
SELECT 
		sod.SalesOrderID, 
		SUM(sod.LineTotal) AS TotaOrderValue  -- Dùng hàm SUM để cộng dồn
FROM Sales.SalesOrderDetail sod
GROUP BY sod.SalesOrderID -- Gom nhóm theo Mã đơn hàng

-- Tình huống: Bạn muốn hiển thị thêm ID của Sản phẩm (ProductID) ra xem
-- Khi ép SSMS gom n dòng của đơn hàng số nào đó  thành 1 dòng duy nhất.
-- Mã đơn thì giống nhau rồi, nhưng n dòng đó lại là n sản phẩm (ProductID) khác nhau!
-- SSMS sẽ "bối rối" không biết phải lấy ProductID nào để hiển thị lên cái dòng duy nhất vừa được gom đó.
-- Quy tắc cốt lõi:
-- Bất cứ cột nào nằm ở mệnh đề SELECT, mà không bọc trong các hàm tính toán (SUM, COUNT, MAX, MIN...), thì BẮT BUỘC phải nằm trong mệnh đề GROUP BY
SELECT 
		sod.SalesOrderID, 
		sod.ProductID,
		SUM(sod.LineTotal) AS TotaOrderValue  -- Dùng hàm SUM để cộng dồn
FROM Sales.SalesOrderDetail sod
GROUP BY sod.ProductID,
		 sod.SalesOrderID 
		  
-- Dùng Alias (tên giả) của SELECT trong GROUP BY
-- Tình huống: Bạn đặt tên cột rất đẹp ở SELECT, rồi đem xuống GROUP BY cho tiện

SELECT 
		sod.SalesOrderID AS OrderID, 
		SUM(sod.LineTotal) AS TotaOrderValue  -- Dùng hàm SUM để cộng dồn
FROM Sales.SalesOrderDetail sod
GROUP BY OrderID -- Invalid column name 'OrderID'.

-- Tại sao lỗi? Điều này liên quan đến Thứ tự thực thi của SQL.
-- SSMS đọc code của bạn theo thứ tự: FROM -> GROUP BY -> SELECT. Khi nó đang chạy ở bước GROUP BY, bước SELECT (nơi bạn đặt tên OrderID) chưa hề được chạy tới.
-- Nên nó không biết OrderID là cái gì.
-- Cách xử lý: Luôn dùng tên cột gốc ở mệnh đề GROUP BY

SELECT 
		sod.SalesOrderID AS OrderID, 
		SUM(sod.LineTotal) AS TotaOrderValue  -- Dùng hàm SUM để cộng dồn
FROM Sales.SalesOrderDetail sod
GROUP BY sod.SalesOrderID

-- Tóm tắt cần nhớ (Takeaways)
----- 1. Từ khóa tư duy cho GROUP BY là chữ "MỖI" (For each).
----- 2. Cột nào đứng chơi vơi ở SELECT thì bắt buộc phải có mặt ở GROUP BY
----- 3. SQL chạy GROUP BY trước khi chạy SELECT, nên đừng mang tên giả (Alias) xuống GROUP BY


-- 7.2. Filter GROUP BY results using a HAVING clause
-- Đề bài: Tìm các khách hàng có tổng số lượng đơn hàng lớn hơn 5 
-- Sales.Customer lưu trữ thông tin định danh của khách hàng, mỗi khách hàng có một mã CustomerID duy nhất 
-- Sales.SalesOrderHeader lưu thông tin chung của đơn hàng. Khác với bảng SalesOrderDetail (chi tiết từng món trong 1 đơn ), bảng này lưu: Mã đơn, Ngày đtawj, Ai đặt, Giao đi đâu 
-- Sự liên kết: Môt khách hàng có thể đặt nhiều đơn hàng. Do đó, CustomerID từ bảng Customer sẽ xuất hiện nhiều lần ở bảng SalesOrderHeader .


SELECT 
		c.CustomerID, 
		COUNT(s.SalesOrderID) AS TotalOrders
FROM Sales.SalesOrderHeader s
INNER JOIN Sales.Customer c ON s.CustomerID = c.CustomerID
GROUP BY c.CustomerID
HAVING COUNT(s.SalesOrderID) > 5

--  Đề bài: Đây là query cực kỳ phổ biến trong thực tế để phân loại khách hàng thân thiết (VIP) dựa trên tần suất mua hàng


-- Tìm những Đơn hàng có chứa nhiều hơn 10 dòng sản phẩm khác nhau
SELECT
		h.SalesOrderID, 
		h.OrderDate, 
		COUNT(d.ProductID) AS NumberOfProducts
FROM Sales.SalesOrderHeader h
INNER JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
GROUP BY h.SalesOrderID,
		 h.OrderDate	-- Nhớ quy tắc bài trước: Cột ở SELECT phải có mặt ở GROUP BY
HAVING COUNT(d.ProductID) > 10 

-- Tóm tắt cần nhớ (Takeaways)
-- Chức năng: HAVING sinh ra để làm nhiệm vụ mà WHERE không làm được: Lọc trên kết quả của các hàm gom nhóm (SUM, COUNT, MAX...).
-- Vị trí đứng: Luôn đứng ngay DƯỚI GROUP BY.
-- Lưu ý "Vàng" trên SSMS: Tuyệt đối không dùng Tên giả (Alias) của SELECT ở trong HAVING. Hãy chịu khó gõ lại nguyên hàm COUNT(), SUM().


-- 7.3. USE GROUP BY to COUNT the number of rows for each unique entry in a given column 
-- Đề bài: Thống kê xem mỗi chức danh (Job Title) trong công ty có bao nhiêu nhân viên đảm nhận
-- và sắp xếp xem chức danh nào đông nhân viên nhất

-- Schema HumanResources: Cụm nghiệp vụ chuyên quản lý nhân sự.
-- Bảng Employee: Lưu trữ thông tin của nhân viên (không bao gồm ứng viên hay đối tác).
-- Cột BusinessEntityID: Mã nhân viên (Khóa chính, mỗi người 1 mã duy nhất).
-- Cột JobTitle: Chức danh công việc (Ví dụ: 'Design Engineer', 'Tool Designer', 'Vice President of Sales'...). Chức danh này sẽ lặp lại nếu có nhiều người cùng làm chung một vị trí.

-- Chỉ trả về 1 con số duy nhất là tổng số nhân viên toàn công ty
SELECT
		COUNT(*) AS Total_Employees
FROM HumanResources.Employee e

-- Trả về danh sách các chức danh và số người của mỗi chức danh
SELECT
		e.JobTitle,
		COUNT(*) AS Number_Of_Employees
FROM HumanResources.Employee e
GROUP BY e.JobTitle 

-- Đếm số nhân viên theo chức danh và xếp từ đông nhất xuống ít nhất
SELECT
		e.JobTitle,
		COUNT(*) AS Number_Of_Employees
FROM HumanResources.Employee e
GROUP BY e.JobTitle 
ORDER BY Number_Of_Employees DESC

-- Thứ tự thực thi (Order of Execution) của SQL Engine
-- FROM -> WHERE -> GROUP BY -> HAVING -> SELECT (Chọn cột và ĐẶT TÊN GIẢ ) -> ORDER BY (Sắp xếp ) 
-- Vì ORDER BY chạy SAU SELECT, lúc này Tên giả đã được tạo ra rồi! Nên ở ORDER BY, bạn hoàn toàn có thể (và nên) gọi Tên giả cho code ngắn gọn và sạch sẽ

-- Vấn đề khi COUNT(*) 
-- COUNT(*) so với COUNT(Tên_Cột)
-- COUNT(*): Đếm số lượng dòng dữ liệu, bất chấp dòng đó chứa rác hay NULL.
-- COUNT(Tên_Cột) (ví dụ COUNT(EmailAddress)): Chỉ đếm những dòng mà cột đó CÓ DỮ LIỆU (bỏ qua NULL
-- Hãy rèn thói quen dùng COUNT(Khóa_Chính) (như COUNT(BusinessEntityID)) thay vì COUNT(*) để tăng tính logic và chính xác của nghiệp vụ.

SELECT
		e.JobTitle,
		COUNT(e.BusinessEntityID) AS Number_Of_Employees
FROM HumanResources.Employee e
GROUP BY e.JobTitle 
ORDER BY Number_Of_Employees DESC


-- Tóm tắt cần nhớ (Takeaways)
-- GROUP BY kết hợp với COUNT là combo vạn năng để làm báo cáo thống kê số lượng (ví dụ: đếm đơn hàng theo ngày, đếm nhân viên theo phòng ban).
-- ORDER BY luôn nằm CUỐI CÙNG trong câu lệnh SQL.
-- Bí danh (Alias) ở SELECT: Bị cấm dùng ở WHERE, GROUP BY, HAVING nhưng được phép dùng ở ORDER BY.

-- 7.4 ROLAP aggregation (DATA MINING)
-- Đề bài: Báo cáo Tổng doanh thu bán hàng theo từng Châu lục và từng Quốc gia/Khu vực.
----- Đồng thời, tính luôn Tổng doanh thu của từng Châu lục và Tổng doanh thu của toàn cầu (Grand Total).

-- Bảng cần sử dụng: Sales.SalesOrderHeader và Sales.SalesTerritory

-- Bảng Sales.SalesTerritory (Khu vực bán hàng): 
----- Cột Group: Nhóm khu vực / Châu lục (VD: North America, Europe, Pacific).
---------- Cột Name: Tên khu vực / Quốc gia cụ thể (VD: Northwest, Canada, France)

-- Bảng Sales.SalesOrderHeader: Chứa cột SubTotal (Doanh thu trước thuế của đơn hàng)

-- Kết nối: Nối 2 bảng qua cột TerritoryID.

-- Tại sao lại sinh ra ROLLUP và CUBE?
----- Bình thường, nếu dùng GROUP BY thông thường, bạn chỉ ra được doanh thu của từng Quốc gia
----- Nếu sếp muốn dòng "Tổng của toàn Châu Âu" và "Tổng Toàn Cầu", bạn sẽ phải viết 3 câu lệnh SQL khác nhau rồi ghép lại (UNION). Rất cực!

-- Làm sao nó hoạt động ? ROLLUP và CUBE ?
-- ROLLUP  
----- Tính tổng theo Phân cấp từ trái sang phải.
----- Nó sẽ tính: Doanh thu từng Quốc gia -> Cấp cao hơn là Tổng từng Châu lục -> Tổng Toàn cầu.
-- CUBE
----- Xoay mọi góc độ, tính Tất cả các tổ hợp có thể có.
----- Nó tính: Doanh thu từng Quốc gia, Tổng từng Châu lục, Tổng của từng Quốc gia trên toàn cầu (bỏ qua Châu lục), và Tổng Toàn cầu.


-- Ví dụ 1: Sử dụng ROLLUP (Tính tổng phân cấp)
-- -- Báo cáo doanh thu có kèm Tổng phụ (Châu lục) và Tổng cộng (Toàn cầu)


-- Bảng Sales.SalesTerritory (Khu vực bán hàng): 
----- Cột Group: Nhóm khu vực / Châu lục (VD: North America, Europe, Pacific).
---------- Cột Name: Tên khu vực / Quốc gia cụ thể (VD: Northwest, Canada, France)


SELECT 
		t.[Group] AS Continent , 
		t.[Name]  AS Region,
		SUM(h.SubTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader h 
INNER JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID 
GROUP BY 
	ROLLUP (t.[Group], t.[Name])

-- Ví dụ 2: Sử dụng CUBE (Tính mọi tổ hợp)
-- Phân tích chéo toàn diện mọi góc độ


SELECT 
		t.[Group] AS Continent , 
		t.[Name]  AS Region,
		SUM(h.SubTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader h 
INNER JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID 
GROUP BY 
	CUBE (t.[Group], t.[Name])

-- Vấn đề: dòng tổng cộng hiển thị chữ ALL . Nhưng khi bạn chạy trên SSMS, chỗ nào là dòng Tổng cộng, SSMS sẽ in ra giá trị NULL.
-- Tại sao? Trong SQL Server, khi nó gộp tất cả các Vùng (Region) lại để tính tổng cho Châu lục (Continent), cột Region tại dòng đó không đại diện cho vùng nào cụ thể cả, nên hệ thống trả về NULL.
-- Cách xử lý thông minh: Các chuyên gia SQL không bao giờ để chữ NULL chình ình trên báo cáo nộp cho sếp. Chúng ta dùng hàm COALESCE() hoặc ISNULL() để "trang điểm" lại kết quả.


SELECT 
		ISNULL( t.[Group]  , N'GRAND TOTAL (TOÀN CẦU)') AS Continent,
		ISNULL( t.[Name] , N'Sub-Total (Tổng phụ)')  AS Region,
		SUM(h.SubTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader h 
INNER JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID 
GROUP BY 
	ROLLUP (t.[Group], t.[Name])


-- Vấn đề : Dùng CUBE sai mục đích (Gây phình to dữ liệu)
-- Tình huống: Bạn có 10 cột trong GROUP BY và bạn bọc tất cả bằng CUBE().
-- Tại sao lỗi? 
-- CUBE sẽ tạo ra 2^n tổ hợp (với n là số lượng cột). 
-- Nếu bạn CUBE 10 cột, nó sẽ quét và sinh ra 1024 tổ hợp báo cáo. Server của bạn sẽ "treo" hoặc chạy cực kỳ chậm.
-- Giải pháp: Chỉ dùng CUBE khi thực sự cần phân tích chéo mọi góc. 
-- Trong 90% các báo cáo kinh doanh thông thường (đi từ Năm -> Tháng -> Ngày, hoặc Châu lục -> Quốc gia -> Thành phố), hãy ưu tiên dùng ROLLUP.


-- Tóm tắt cần nhớ (Takeaways)
-- ROLLUP: Tính tổng theo phân cấp chiều dọc (Từ to xuống nhỏ). Rất phù hợp cho Dữ liệu thời gian (Năm/Tháng/Ngày) hoặc Địa lý (Quốc gia/Tỉnh thành).
-- CUBE: Xoay dữ liệu 360 độ, tính tổng mọi tổ hợp. Chỉ dùng cho các báo cáo phân tích đa chiều (Data Warehouse).
-- Thay đổi cú pháp: Quên WITH ROLLUP đi, hãy chuyển sang dùng GROUP BY ROLLUP (Cột 1, Cột 2).
-- Bản chất của NULL: Chữ NULL sinh ra từ ROLLUP/CUBE mang ý nghĩa là "TỔNG CỘNG" chứ không phải là "Dữ liệu trống".