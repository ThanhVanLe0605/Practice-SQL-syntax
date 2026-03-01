-- 18.1. SELF JOIN
-- Đề bài: Tìm các cặp sản phẩm (ProductID) khác nhau nhưng thường xuyên được khách hàng mua chung một đơn hàng 
-- Trích xuất mã đơn hàng và mã của 2 sản phẩm đó 

-- Logic Nối (Cách giải quyết):
-- Chúng ta sẽ "nhân bản" bảng SalesOrderDetail làm 2 (giả lập là Bảng A và Bảng B).
-- Điều kiện nối 1: Hai dòng phải có cùng SalesOrderID (để đảm bảo chúng nằm trong cùng một giỏ hàng).
-- Điều kiện nối 2: Cột ProductID ở Bảng A phải khác cột ProductID ở Bảng B (để tránh việc SQL tự ghép 1 sản phẩm với chính nó).

SELECT 
	A.SalesOrderID,
	A.ProductID AS Product1,
	B.ProductID AS Product2 
FROM Sales.SalesOrderDetail A 
JOIN Sales.SalesOrderDetail B  
	-- ĐK1:
	ON A.SalesOrderID = B.SalesOrderID 
	-- ĐK2: 
	AND  A.ProductID < B.ProductID 
ORDER BY 
	A.SalesOrderID 

-- Khi làm Self Join, cần chú ý tránh những điều sau :
------ Quên đặt Alias (Bí danh)
-- Đặt Alias (A và B) là BẮT BUỘC để SQL phân biệt được 2 "bản sao" của cùng một bảng.

------ Trùng lặp cặp kết quả (A-B và B-A)
-- Đơn hàng 1 có Sản phẩm 10 và 20.
-- Khớp <> sẽ ra 2 dòng: (10, 20) và (20, 10).
-- Thực tế đây chỉ là 1 cặp mua chung.
-- Thay vì A.ProductID <> B.ProductID, hãy dùng A.ProductID < B.ProductID
-- Nó ép SQL chỉ lấy tổ hợp theo một chiều từ nhỏ đến lớn. Code gọn hơn, kết quả sạch hơn!


------ Hiệu suất (Performance) kém
-- Thực tế Query Optimizer (Bộ tối ưu truy vấn) của SQL Server rất thông minh, nếu bạn nối trên các cột có Index (SalesOrderID), nó sẽ dùng thuật toán Hash Match hoặc Merge Join chứ không tạo tích Đề-các mù quáng
-- Luôn đảm bảo cột JOIN có Index.

-- Tóm tắt & Notes cần nhớ về Self Join
-- Bản chất: Là JOIN một bảng với chính nó.
-- Chìa khóa: Phải dùng Alias để tạo ra các "phiên bản" ảo của bảng.
-- Toán tử < là bạn thân: Khi cần tìm các "cặp" dữ liệu chéo nhau trong cùng một nhóm, dùng < (hoặc >) để loại bỏ các cặp trùng lặp ngược chiều.
-- Thông tin Nhân sự (Employee) trong các hệ thống hiện đại dùng HierarchyID thay cho Self-Join truyền thống để tăng tốc độ truy vấn cấu trúc cây.




-- 18.2. DIFFERENCES BETWEEN INNER/ OUTER JOINS


------------------- INNER JOIN (LOGIC 'AND')
-- Đề bài: Đi tìm sản phẩm đắt hàng 
-- Lấy danh sách các sp (Mã , Tên) đã từng phát sinh ít nhất một giao dịch mua bán 
-- INNER JOIN hoạt động như một màng lọc khắt khe. Nó yêu câu ProductID phải tồn tại CẢ HAI bảng (Production.Product , Sales.SalesOrderDetail )
-- Nếu sản phẩm nằm trong kho (Product) nhưng chưa từng có giao dịch (SalesOrderDetail), nó sẽ bị loại bỏ


SELECT DISTINCT -- Dùng DISTINCT vì một sản phẩm có thể được bán nhiều lần ở nhiều đơn khác nhau, ta chỉ cần lấy tên nó 1 lần
	p.ProductID, 
	p.[Name] AS ProductName
FROM Production.[Product] p
INNER JOIN Sales.SalesOrderDetail d ON p.ProductID = d.ProductID

------------------- LEFT OUTER JOIN: "Truy tìm hàng tồn kho, ế ẩm"
-- Đề bài: Lấy ra danh sách toàn bộ sản phẩm của công ty, đồng thời xác định xem sản phẩm nào CHƯA TỪNG được bán (Hàng ế).

-- Lấy TẤT CẢ từ bảng Left (Product).
-- Nếu không có dòng tương ứng ở Right (SalesOrderDetail), cột SalesOrderID sẽ bị ép thành NULL.
-- Lợi dụng tính chất này, ta lọc WHERE ... IS NULL để tìm hàng "ế".

SELECT
	p.ProductID, 
	p.[Name] AS ProductName, 
	d.SalesOrderID 
FROM Production.[Product] p
LEFT OUTER JOIN Sales.SalesOrderDetail d ON p.ProductID = d.ProductID
WHERE d.SalesOrderID IS NULL 

-- Còn RIGHT JOIN và FULL OUTER JOIN thì sao?
-- RIGHT JOIN: Về bản chất, nó chỉ là viết ngược lại của LEFT JOIN.
-- Trong thực tế, các Senior Developer thường có thói quen "đọc từ trái sang phải, từ trên xuống dưới", nên họ hiếm khi dùng RIGHT JOIN.
-- Họ sẽ lật ngược thứ tự bảng lại và dùng LEFT JOIN cho code dễ đọc

-- FULL OUTER JOIN: Rất nặng và tốn tài nguyên
-- Nó lấy tất cả của cả 2 bên. Thường chỉ dùng trong nghiệp vụ Đối soát (Reconciliation)
-- (Ví dụ: So sánh kho thực tế và kho kế toán xem bên nào lệch).

-- Cần chú ý: 

------------------- Vô tình biến LEFT JOIN thành INNER JOIN
-- Lọc dữ liệu của bảng bên Phải (Right table) bằng mệnh đề WHERE
-- thông thường (VD: WHERE SOD.OrderQty > 5). Nó sẽ vô tình ném đi các dòng NULL vốn dĩ được tạo ra bởi LEFT JOIN.
-- Khắc phục: Chuyển điều kiện lọc của bảng bên phải lên thẳng mệnh đề ON. (VD: ON P.ProductID = SOD.ProductID AND SOD.OrderQty > 5).


------------------- Bỏ quên từ khóa ON
-- Do gõ nhanh, hoặc nhầm lẫn với CROSS JOIN. Báo lỗi Incorrect syntax
-- Ghi nhớ: Với INNER/LEFT/RIGHT/FULL JOIN, mệnh đề ON là trái tim. Không có ON, SQL không biết cách ghép 2 bảng.

-- Tóm tắt & Notes cần nhớ
-- NNER JOIN: "Có qua có lại". Dữ liệu phải có ở cả 2 nơi mới được hiển thị.
-- LEFT/RIGHT JOIN: "Bảo vệ bảng chính". Giữ lại toàn bộ dữ liệu của một bảng chỉ định, những thông tin thiếu từ bảng kia sẽ biến thành NULL. Cực kỳ hữu dụng để tìm dữ liệu "mồ côi", dữ liệu bị thiếu.
-- Từ khóa OUTER: Chỉ là từ tùy chọn (optional). Bạn viết LEFT JOIN thì SQL cũng tự hiểu là LEFT OUTER JOIN


-- 18.3. JOIN Terminology: Inner, Outer, Semi, Anti..


------------------- SEMI JOIN: "Chỉ cần biết là CÓ tồn tại, không cần chi tiết"
-- Đề bài:
-- Marketing cần danh sách các Khách hàng (CustomerID) đã từng ít nhất 1 lần phát sinh đơn hàng, để gửi email tri ân.

-- Tại sao không dùng INNER JOIN?
-- Nếu bạn dùng INNER JOIN giữa bảng Khách hàng và bảng Đơn hàng, một ông khách VIP mua 100 lần sẽ bị in ra 100 dòng trùng lặp.
-- Bạn sẽ phải tốn công dùng DISTINCT.

-- Giải quyết bằng Semi Join (Dùng EXISTS hoặc IN)
-- Nó chỉ kiểm tra "có tồn tại hay không". Thấy khách này có đơn hàng đầu tiên là nó dừng tìm kiếm ngay và trả về tên khách đó (rất tối ưu hiệu suất).

-- Duyệt qua từng khách hàng trong bảng Customer.
-- Nếu EXISTS (tồn tại) dù chỉ 1 dòng tương ứng trong bảng SalesOrderHeader,
-- thì lấy khách hàng đó ra. Không tạo ra bản sao trùng lặp!

SELECT
		c.CustomerID, 
		c.StoreID 
FROM Sales.Customer c 
WHERE EXISTS (
		SELECT 1 
		FROM Sales.SalesOrderHeader h
		WHERE c.CustomerID = h.CustomerID 
)

------------------- ANTI SEMI JOIN : "Tìm những kẻ nói KHÔNG"
-- Đề bài: Hệ thống có rất nhiều tài khoản khách hàng ảo
-- Hãy tìm những CustomerID đã đăng ký nhưng CHƯA TỪNG mua bất kỳ đơn hàng nào để team Sale gọi điện chăm sóc.

-- Tư duy: Đây chính là Anti Semi Join. Chúng ta dùng NOT EXISTS hoặc NOT IN để loại bỏ đi phần giao nhau.
-- Vẫn duyệt bảng Customer. Nhưng lần này, nếu KHÔNG TỒN TẠI (NOT EXISTS)
-- bất kỳ đơn hàng nào khớp mã CustomerID, ta mới lấy khách hàng đó.

SELECT
		c.CustomerID
FROM Sales.Customer c 
WHERE NOT EXISTS (
		SELECT 1 
		FROM Sales.SalesOrderHeader h
		WHERE c.CustomerID = h.CustomerID 
)

------------------- CROSS JOIN: "Ma trận mọi khả năng"

-- Sếp muốn một bảng Báo cáo Ma trận doanh thu dự kiến: Cột dọc là "Khu vực bán hàng", Cột ngang là "Danh mục sản phẩm"
-- Kể cả khu vực đó chưa bán được sản phẩm đó, vẫn phải hiện ra để điền số 0
-- Hãy tạo khung ma trận này.

-- Tư duy:  Bạn cần ghép mỗi Khu vực với tất cả Danh mục. Đây là Tích Đề-các (Cartesian Product).

-- Lấy tất cả Khu vực nhân (CROSS JOIN) với tất cả Danh mục.
-- 10 Khu vực x 4 Danh mục = 40 dòng kết quả tạo thành bộ khung báo cáo.
-- Lưu ý: CROSS JOIN không có mệnh đề ON.


SELECT 
	  t.[Name] AS TerritoryName , 
	  c.[Name] AS CategoryName 
FROM Sales.SalesTerritory t 
CROSS JOIN
	 Production.ProductCategory c 
ORDER BY 
	 t.[Name], c.[Name]

-- Bắt Lỗi Kỹ Thuật & Tư Duy Thực Chiến

----- Bẫy NOT IN với giá trị NULL (Tử huyệt)
-- Giả sử bạn viết: WHERE X NOT IN (SELECT Y FROM B). Nếu trong danh sách Y trả về có chứa dù chỉ 1 giá trị NULL, toàn bộ truy vấn sẽ không trả về BẤT CỨ DÒNG NÀO (Trống trơn)
-- Lý do là vì trong SQL, không thể so sánh 1 NOT IN (NULL) (Nó ra kết quả là Unknown, không phải True).
-- Nguyên tắc sống còn:
-- Hãy tập thói quen dùng NOT EXISTS thay cho NOT IN
-- NOT EXISTS xử lý NULL cực kỳ an toàn và chuẩn xác. Nó đánh giá theo logic Boolean chuẩn


----- EXISTS vs IN (Hiệu suất)
-- Bạn nghĩ IN dễ đọc hơn EXISTS? Đúng, nhưng khi bảng con (Subquery) có hàng triệu dòng,
-- IN có thể bắt hệ thống phải tính toán xong toàn bộ tập hợp bên trong rồi mới so sánh.
-- Khắc phục: Mặc dù SQL Server ngày nay rất thông minh và tự tối ưu, nhưng với thói quen của Chuyên gia, hãy luôn ưu tiên cấu trúc EXISTS(SELECT 1 FROM...). Nó quét dữ liệu theo kiểu "thấy là dừng" (Short-circuit), rất nhẹ máy.

----- Sập Server vì CROSS JOIN
-- Khắc phục: Chỉ dùng CROSS JOIN cho các danh mục (Category, Status, Type, Territory) có số lượng dòng nhỏ (vài chục đến vài trăm dòng) để sinh dữ liệu mẫu hoặc khung báo cáo.

-- Tóm tắt & Notes cần nhớ
-- Semi Join (EXISTS): Dùng để lọc dữ liệu bảng A khi bảng A có liên quan đến bảng B, mà không làm nhân bản (duplicate) dòng của bảng A.
-- Anti Semi Join (NOT EXISTS): Tuyệt chiêu để tìm dữ liệu "Bị thiếu", "Chưa từng tham gia", "Không có mặt".
-- Luật Bất Thành Văn: Tránh xa NOT IN nếu cột trong Subquery có thể chứa giá trị NULL. Hãy dùng NOT EXISTS làm tiêu chuẩn.
-- Cross Join: Nhân mọi tổ hợp. Hãy dùng có ý thức, đừng để sập RAM hệ thống


-- 18.4. LEFT OUTER JOIN
-- Đề bài
-- Giám đốc kinh doanh (CSO) muốn xem danh sách TẤT CẢ các khu vực bán hàng của công ty, kèm theo mã số của nhân viên Sale đang phụ trách khu vực đó.
-- Nếu khu vực nào mới mở, chưa có nhân viên phụ trách, vẫn phải hiển thị tên khu vực lên báo cáo (để trống thông tin nhân viên).

-- Đặt SalesTerritory làm bảng LEFT (Bên trái) để chắc chắn KHÔNG mất khu vực nào.
-- Nối với SalesPerson dựa trên TerritoryID.
-- Nếu một Territory chưa được gán cho SalesPerson nào, mã nhân viên sẽ trả về NULL.

SELECT
		t.[Name] AS TerritoryName, 
		P.BusinessEntityID AS SalesPersonID 
FROM Sales.SalesTerritory t 
LEFT OUTER JOIN Sales.SalesPerson p 
	ON t.TerritoryID = p.TerritoryID 
ORDER BY t.[Name]

-- Chú ý: 
-- Lấy tất cả khu vực, và những nhân viên có chỉ tiêu (SalesQuota) > 250,000. Học viên thường viết thêm dòng: WHERE SP.SalesQuota > 250000
-- Cú pháp này bắt buộc cột SalesQuota phải có giá trị lớn hơn số đó, làm cho các dòng NULL (khu vực chưa có nhân viên) bị đá văng khỏi báo cáo!

-- Tuyệt chiêu: Dời điều kiện của bảng bên Phải lên thẳng mệnh đề ON.
SELECT
		t.[Name] AS TerritoryName, 
		P.BusinessEntityID AS SalesPersonID 
FROM Sales.SalesTerritory t 
LEFT OUTER JOIN Sales.SalesPerson p 
	ON t.TerritoryID = p.TerritoryID AND p.SalesQuota > 250000
ORDER BY t.[Name]
-- Lúc này SQL sẽ ưu tiên ghép dòng có Quota lớn, nếu không ghép được nó vẫn giữ lại tên Khu vực (trả về NULL).

----- Báo cáo tổng kết đếm sai số lượng (Lỗi COUNT)
-- Hãy đếm xem mỗi khu vực có bao nhiêu nhân viên. Bạn dùng COUNT(*). 
-- Đối với những khu vực NULL (chưa có nhân viên), COUNT(*) vẫn đếm dòng trống đó là 1, gây sai lệch số lượng sự thật là 0

-- Nguyên tắc sống còn
-- Khi đếm dữ liệu đi kèm LEFT JOIN, TUYỆT ĐỐI không dùng COUNT(*)
-- Hãy đếm trên một cột cụ thể của bảng bên Phải (Ví dụ: COUNT(SP.BusinessEntityID))
-- Hàm COUNT sẽ tự động bỏ qua các giá trị NULL và trả về số 0 tròn trĩnh chuẩn xác.

-- Tóm tắt & Notes cần nhớ
-- Vị trí quyết định tất cả: Bảng nào quan trọng, bắt buộc phải lên báo cáo đầy đủ 100% -> Đặt nó ở phía SAU chữ FROM (Bảng bên trái).
-- NULL là tín hiệu: Trong LEFT JOIN, NULL không phải là lỗi. Nó là tín hiệu báo cho bạn biết: "Bên trái có dữ liệu, nhưng bên phải không tìm thấy thứ tương ứng".
-- Cẩn thận với WHERE: Mọi bộ lọc áp dụng vào cột của bảng bên phải (Right table) trong mệnh đề WHERE đều có nguy cơ phá hủy tác dụng của LEFT JOIN. Hãy xem xét đặt nó ở ON


-- 18.5. IMPLICIT JOIN

-- Implicit Join là cách nối bảng kiểu cũ (trước chuẩn ANSI SQL-92). Bạn ném tất cả các bảng vào mệnh đề FROM cách nhau bằng dấu phẩy ,, và dùng mệnh đề WHERE để làm điều kiện nối.

-- [ CÁCH CŨ TRONG SÁCH - IMPLICIT JOIN - KHÔNG KHUYÊN DÙNG]
SELECT 
    p.FirstName, 
    p.LastName, 
    e.JobTitle
FROM 
    Person.Person p, 
    HumanResources.Employee e -- Nối ngầm định bằng dấu phẩy
WHERE 
    p.BusinessEntityID = e.BusinessEntityID; -- Điều kiện nối nằm ở WHERE

-------------------------------------------------------------------

-- [ CÁCH XỬ LÝ THÔNG MINH - EXPLICIT JOIN (ANSI STANDARD)]
SELECT 
    p.FirstName, 
    p.LastName, 
    e.JobTitle
FROM Person.Person p
INNER JOIN HumanResources.Employee e -- Khai báo rõ ràng loại JOIN
    ON p.BusinessEntityID = e.BusinessEntityID; -- Điều kiện nối nằm ở ON

-- Luôn luôn dùng INNER JOIN ... ON .... Nó tách bạch rõ ràng giữa "Điều kiện để nối bảng" 
-- (nằm ở ON) và "Điều kiện để lọc dữ liệu" (nằm ở WHERE). Đọc code dễ bảo trì hơn rất nhiều.


-- 18.6. CROSS JOIN 
-- đã trình bày ở 18.3. 

-- 18.7. CROSS APPLY & LATERAL JOIN 
-- Đề bài (Nghiệp vụ): Lấy danh sách toàn bộ nhân viên, đi kèm với mức lương được cập nhật gần đây nhất của mỗi người.

-- Bảng HumanResources.Employee (e): Danh sách nhân viên.
-- Bảng HumanResources.EmployeePayHistory (eph): Lịch sử thay đổi lương.
-- Một nhân viên có thể có nhiều lần đổi lương (nhiều dòng).Cột RateChangeDate (Ngày đổi lương), Rate (Mức lương)
-- Mối quan hệ: 1-N. Khóa nối: BusinessEntityID.


-- Nếu dùng LEFT JOIN bình thường, 1 nhân viên có 3 lần tăng lương sẽ bị nhân bản thành 3 dòng
-- Nghiệp vụ chỉ yêu cầu lấy 1 dòng mới nhất
-- APPLY cho phép bạn chạy một subquery nhỏ (lọc lấy TOP 1 xếp giảm dần theo ngày) cho TỪNG dòng của bảng nhân viên.

SELECT 
	e.BusinessEntityID, 
	e.JobTitle,
	LatestPay.Rate AS CurrtentSalary, 
	LatestPay.RateChangeDate AS LastUpdated 
FROM HumanResources.Employee e 
-- Dùng OUTER APPLY (Tương đương LEFT JOIN) để nếu NV chưa có lương vẫn hiện ra
OUTER APPLY (
	SELECT TOP 1  
		p.Rate, 
		p.RateChangeDate
	FROM HumanResources.EmployeePayHistory p 
	WHERE p.BusinessEntityID = e.BusinessEntityID 
	ORDER BY p.RateChangeDate DESC  -- Sắp xếp ngày giảm dần để lấy ngày mới nhất
) AS LatestPay 


-- Lỗi hay gặp
-- Vấn đề: Không phân biệt được khi nào dùng CROSS APPLY và khi nào dùng OUTER APPLY
-- Giải thích: * CROSS APPLY hoạt động giống INNER JOIN:
-- Nếu subquery không trả về dòng nào (nhân viên chưa có lịch sử lương), nhân viên đó sẽ BỊ LOẠI khỏi kết quả cuối cùng.
----- OUTER APPLY hoạt động giống LEFT JOIN: Lấy tất cả nhân viên, ai không có lịch sử lương thì cột lương để NULL.
-- Cách xử lý: Luôn đặt câu hỏi nghiệp vụ: "Sếp có muốn xem cả những người chưa có dữ liệu ở bảng phụ không?"
-- Nếu CÓ -> OUTER APPLY. Nếu KHÔNG -> CROSS APPLY


-- 18.8. FULL JOIN

-- Bảng 1: Purchasing.Vendor (Nhà cung cấp)
---- Ý nghĩa: Chứa thông tin các công ty bán nguyên vật liệu/hàng hóa cho chúng ta.
---- Cột quan trọng: BusinessEntityID (Mã định danh đối tác), Name (Tên đối tác), ActiveFlag (1: Đang giao dịch, 0: Đã ngừng giao dịch)


-- Bảng 2: Sales.Store (Cửa hàng / Đại lý)
-- Ý nghĩa: Chứa thông tin các đại lý mua hàng của chúng ta để bán lẻ.
-- Cột quan trọng: BusinessEntityID (Mã định danh), Name (Tên cửa hàng).


-- Tại sao lại nối 2 bảng này?
-- Trong thực tế ERP (hệ thống quản trị doanh nghiệp), một đối tác (BusinessEntityID) có thể chỉ là Nhà cung cấp, chỉ là Khách hàng đại lý, hoặc vừa là Nhà cung cấp vừa là Đại lý.
-- Trong thực tế ERP (hệ thống quản trị doanh nghiệp), một đối tác (BusinessEntityID) có thể chỉ là Nhà cung cấp, chỉ là Khách hàng đại lý, hoặc vừa là Nhà cung cấp vừa là Đại lý.

-- Đề bài
-- Xuất ra danh sách toàn bộ các đối tác (bao gồm cả Nhà cung cấp và Cửa hàng đại lý).
-- Trả về Mã đối tác, Tên đối tác, và phân loại xem họ là Nhà cung cấp, Đại lý, hay Cả hai.
-- Ràng buộc: Chỉ lấy các Nhà cung cấp đang còn hoạt động (ActiveFlag = 1), hoặc các đối tác chỉ là Đại lý.


-- Tại sao dùng FULL JOIN? Ta cần lấy TẤT CẢ từ bảng Vendor và TẤT CẢ từ bảng Store.
-- Làm sao để hiển thị Tên?
-- Khi FULL JOIN, nếu đối tác chỉ là Vendor, cột Store.Name sẽ bị NULL và ngược lại.
-- Ta phải dùng COALESCE (hàm trả về giá trị non-NULL đầu tiên) để gộp tên lại thành một cột duy nhất.

SELECT
	-- 1. Dùng COALESCE để lấy ID và Name từ bảng nào có dữ liệu (không bị NULL)
	COALESCE(v.BusinessEntityID, s.BusinessEntityID) AS PartnerID, 
	COALESCE(v.[Name], s.[Name])					 AS PartnerName,
	
	-- 2. Đánh dấu phân loại bằng CASE WHEN (Ứng dụng thực tiễn rất cao)
	CASE 
		WHEN v.BusinessEntityID IS NOT NULL AND s.BusinessEntityID IS NOT NULL THEN 'Both (Vendor & Store)'
		WHEN v.BusinessEntityID IS NOT NULL THEN 'Vendor Only'
		WHEN s.BusinessEntityID IS NOT NULL THEN'Store Only'
	END AS PartnerType 
FROM Purchasing.Vendor v 
FULL OUTER JOIN Sales.Store s ON v.BusinessEntityID = s.BusinessEntityID 
-- 3. BẪY WHERE: Cách xử lý đúng chuẩn khi lọc dữ liệu trên bảng FULL JOIN
WHERE ( 1=1)
	-- Lấy Vendor đang hoạt động (1) HOẶC nó không phải là Vendor (IS NULL)
	AND (v.ActiveFlag = 1 OR v.ActiveFlag IS NULL )



-- 18.9. RECURSIVE JOINS
-- 18.10.BASIC EXPLICIT INNER JOIN 
 -- 18.1. 