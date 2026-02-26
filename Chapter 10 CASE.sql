
-- 10.1. Use CASE to COUNT the number of rows in a column match a condition 
-- Đề bài: Thống kê tổng số lượng sản phẩm hiện có trong hệ thống
-- và đếm xem có bao nhiêu sản phẩm thuộc phân khúc "Cao cấp" 

-- CÁCH 1
-- thống kê tổng số lượng sản phẩm hiện có trong hệ thống
SELECT 
	COUNT(p.ProductID )
FROM Production.[Product] p 

-- và đếm xem có bao nhiêu sản phẩm thuộc phân khúc "Cao cấp" (giá niêm yết từ 1000 trở lên).
SELECT 
	COUNT(p.ProductID )
FROM Production.[Product] p 
WHERE p.Class = 'H' 

-- CÁCH 2

SELECT 
	COUNT(p.ProductID ) AS TotalProducts ,
	SUM(
			CASE 
				WHEN p.Class ='H' THEN 1
				ELSE 0
			END 
	) AS PremiumProductsCount 
FROM Production.[Product] p 

-- Tại sao dùng SUM kết hợp CASE?
----- SQL Server không có hàm COUNTIF
----- Hàm CASE sẽ quét qua từng dòng. Nếu giá Class = 'H'  nó trả về 1 (đúng). Nếu không, trả về 0 (sai).
----- Sau đó, hàm SUM bọc bên ngoài sẽ cộng tất cả các số 1 và 0 lại. Việc cộng các số 1 chính là bản chất của phép đếm điều kiện.


----- Lỗi thường gặp & Cách xử lý thông minh
----- Vấn đề 1: Nhầm lẫn giữa COUNT và SUM khi dùng CASE
----- Tại sao gặp vấn đề này?
----- Hàm COUNT() trong SQL chỉ bỏ qua (không đếm) giá trị NULL
----- Số 0 đối với COUNT vẫn là một giá trị hợp lệ.
----- Nên nếu bạn dùng COUNT trong trường hợp trên, nó sẽ đếm LUÔN cả những dòng ELSE 0 (sản phẩm không cao cấp).
----- Kết quả trả ra sẽ bằng tổng toàn bộ sản phẩm, không phải đếm điều kiện.

----- Cách xử lý thông minh:
----- Cách 1 (Khuyên dùng): Dùng SUM(CASE ... THEN 1 ELSE 0 END) như code chuẩn ở trên. Rất rõ ràng, toán học, ai đọc cũng hiểu.
----- Cách 2 (Mẹo với COUNT): Nếu ép buộc phải dùng COUNT, bạn phải đổi ELSE 0 thành ELSE NULL (hoặc bỏ trống ELSE, SQL sẽ tự ngầm hiểu là NULL).


----- Vấn đề 2: Không lường trước dữ liệu NULL ở cột điều kiện
----- Trạng thái lỗi: Cột Class  trong một số hệ thống có thể chứa giá trị NULL 
----- Tại sao gặp vấn đề?
----- Khác với Excel, SQL có khái niệm 3 giá trị logic (True, False, Unknown).
----- Nếu bạn không có lệnh ELSE 0, lệnh CASE sẽ sinh ra giá trị NULL cho các dòng không thỏa mãn,
----- và hàm SUM sẽ hiện cảnh báo "Warning: Null value is eliminated by an aggregate or other SET operation".

----- Cách xử lý
----- Luôn luôn chốt chặt lệnh CASE bằng ELSE 0.
----- Nó đảm bảo kết quả đầu ra của CASE luôn là con số nguyên, giúp hàm SUM hoạt động trơn tru và code "sạch" không cảnh báo hệ thống.

-- Tóm tắt cần nhớ
----- Không có COUNTIF trong SQL: Hãy dùng combo SUM + CASE (1 và 0)
----- Tuyệt đối không: COUNT(CASE ... ELSE 0 END) vì số 0 vẫn bị COUNT đếm
----- Bảo vệ dữ liệu: Luôn luôn dùng ELSE 0 trong cấu trúc đếm này để tránh sinh ra NULL gây lỗi cảnh báo hệ thống.


-- 10.2. Searched CASE in SELECT (Matches a boolean expression)
-- Cách dùng CASE để tạo ra một cột phân loại dữ liệu mới dựa trên các biểu thức logic
-- Khác với Simple CASE (chỉ so sánh bằng), Searched CASE cho phép bạn quét các khoảng giá trị (ranges).

-- Đề bài: 
-- Lấy danh sách các sản phẩm đang kinh doanh (có nhóm hàng).
-- Hãy phân loại giá niêm yết (ListPrice) của chúng thành các phân khúc định vị:
---- Giá trị bằng 0: 'Hàng nội bộ/Tặng kèm'
---- Dưới 500: 'Bình dân'
---- Dưới 1500: 'Tầm trung'
---- Từ 1500 trở lên: 'Cao cấp'


SELECT
		p.ProductID,
		p.[Name] AS ProductName, 
		s.[Name] AS SubCategoryName, 
		p.ListPrice , 
		-- Bắt đầu phân loại bằng Searched CASE
		CASE
			WHEN p.ListPrice IS NULL THEN 'NULL'
			WHEN p.ListPrice = 0 THEN 'Internal/ Gift'
			WHEN p.ListPrice < 500  THEN  'Afforadable'
			WHEN p.ListPrice < 1500 THEN  'Mid-range'
			ELSE 'Premium'
		END AS PriceTier 
FROM Production.[Product] p
-- Chỉ lấy những sản phẩm có nhóm hàng (INNER JOIN lọc bỏ các sản phẩm mồ côi)
INNER JOIN Production.ProductSubcategory s ON p.ProductSubcategoryID = s.ProductSubcategoryID 
ORDER BY p.ListPrice DESC

-- Lỗi thường gặp & Cách xử lý thông minh
-- Vấn đề 1: Lỗi "Cạm bẫy thứ tự" (Order of Evaluation)
-- Trạng thái lỗi: Người viết SQL sắp xếp các mệnh đề WHEN không theo thứ tự tịnh tiến (từ nhỏ đến lớn, hoặc lớn đến nhỏ)
-- Tại sao gặp vấn đề này? Hàm CASE trong SQL hoạt động theo nguyên tắc "Top-to-Bottom, First Match Wins" (Chạy từ trên xuống, đụng điều kiện nào đúng đầu tiên là dừng luôn và bỏ qua các dòng dưới).
-- Nếu một sản phẩm giá 200, nó nhỏ hơn 1500 -> SQL gán ngay mác 'Mid-range' và kết thúc. Dòng < 500 vĩnh viễn không bao giờ được chạm tới.
-- Cách xử lý thông minh
-- Luôn sắp xếp điều kiện WHEN có tính phân lớp
-- Nếu dùng < thì phải xếp từ số nhỏ đến số lớn. Nếu dùng > thì phải xếp từ số lớn về số nhỏ.


-- Vấn đề 2: Dữ liệu rác lọt vào tập kết quả (Hardcoded ELSE)
-- Trạng thái lỗi: Đôi khi ListPrice bị lỗi nhập liệu thành số âm (VD: -50).
-- Lệnh CASE ở phần Code chuẩn sẽ tự động xếp nó vào nhóm < 500 ('Affordable').
-- Sếp nhìn vào báo cáo thấy một món nợ âm tiền mà lại bảo là hàng bình dân thì rất vô lý.
-- Cách xử lý: Luôn rào trước các giá trị phi logic bằng một mệnh đề kiểm tra đầu tiên.

-- ✔️ PHÒNG THỦ DỮ LIỆU
-- CASE 
--     WHEN p.ListPrice < 0 THEN 'Data Error' -- Chặn lỗi nhập liệu ngay lập tức
   
-- Tóm tắt cần nhớ
-- Searched CASE dùng cho các phép toán logic (>, <, >=, <=, AND, OR), rất mạnh mẽ để phân chia các tập dữ liệu liên tục (như Giá, Tuổi tác, Doanh thu).
-- Nguyên tắc vàng: CASE đọc từ trên xuống và "ăn" ngay kết quả đúng đầu tiên. Hãy sắp xếp các dải điều kiện theo một chiều tăng/giảm nhất định
-- Hãy tận dụng ELSE như một "thùng rác" để gom tất cả những trường hợp còn sót lại, giúp bạn không bỏ sót bất kỳ dòng dữ liệu nào.


-- 10.3. CASE in a clause ORDER BY 

-- Đề bài: Xuất danh sách các phòng ban.
-- Tuy nhiên, khối kinh doanh (Sales and Marketing) phải luôn nằm trên cùng vì là tuyến đầu tạo ra tiền.
-- Tiếp theo là khối R&D (Research and Development) tạo ra sản phẩm.
-- Tiếp theo là Ban giám đốc (Executive General and Administration)
-- Các khối còn lại nằm phía dưới
-- Lưu ý: Nếu các phòng ban có cùng Khối, thì sắp xếp Tên phòng ban (Name) theo thứ tự chữ cái A-Z.


SELECT  
		d.DepartmentID, 
		d.[Name] AS DepartmentName,
		d.GroupName 
FROM HumanResources.Department d
ORDER BY 
		-- Tầng sắp xếp 1: Dùng CASE để đánh trọng số ưu tiên cho từng Khối
		CASE d.GroupName 
			WHEN  'Sales and Marketing' THEN 1
			WHEN  'Research and Development' THEN 2
			WHEN  'Executive General and Administration' THEN 3
			ELSE 4
		END ,
		-- Tầng sắp xếp 2: Chữ cái A-Z (Mặc định là ASC)
		d.[Name] ASC 

-- Vấn đề về Hiệu suất - Performance & Hardcode)-
-- Tại sao? Khi bạn dùng CASE trong ORDER BY, SQL Server không thể dùng Index (chỉ mục) có sẵn để sắp xếp nhanh
-- Nó bắt buộc phải quét qua toàn bộ bảng (Table Scan), tự tính toán ra các số 1, 2, 3, 4 ở trong bộ nhớ tạm (TempDB), rồi mới sắp xếp được.
-- Với bảng vài chục dòng thì siêu nhanh, nhưng với bảng hàng triệu dòng, truy vấn này sẽ làm "đứng" hệ thống (High Sort Cost).

-- Cách giải quyết thông minh trong dự án thật: Người ta rất hạn chế viết Hardcode logic sắp xếp vào trong câu SQL
-- Thay vào đó, một Database Designer giỏi sẽ tạo thêm một cột DisplayOrder (Kiểu số nguyên INT) ngay trong bảng HumanResources.Department
-- Khi đó query chỉ đơn giản là: ORDER BY DisplayOrder ASC, Name ASC. Siêu nhanh, siêu mượt và sếp muốn đổi thứ tự thì chỉ cần Update data, không cần sửa Code!
-- Tuy nhiên, cú pháp CASE này vẫn cực kỳ hữu dụng cho các báo cáo nhanh (Ad-hoc query)


-- 10.4. Shorthand CASE in SELECT 

-- Đề bài: Phòng Nhân sự & Chăm sóc khách hàng phàn nàn rằng cột PersonType chứa toàn mã code 2 chữ cái ('EM', 'IN'...) khiến họ không hiểu gì.
-- Hãy xuất danh sách con người và "dịch" mã code này ra từ ngữ dễ hiểu cho sếp đọc:
-- 'EM' -> Employee (Nhân viên)
-- 'SP' -> Sales Person (Nhân viên sale)
-- 'IN' -> Individual Customer (Khách lẻ)
-- 'SC' -> Store Contact (Liên hệ đại lý)
SELECT 
    BusinessEntityID,
    FirstName + ' ' + LastName AS FullName, -- Nối chuỗi để ra họ tên đầy đủ
    PersonType,
    -- Bắt đầu Simple CASE (Shorthand)
    CASE PersonType 
        WHEN 'EM' THEN 'Employee'
        WHEN 'SP' THEN 'Sales Person'
        WHEN 'IN' THEN 'Individual Customer'
        WHEN 'SC' THEN 'Store Contact'
        ELSE 'Other/Unknown' -- Gom tất cả các mã lạ (GC, VC...) vào đây
    END AS RoleDescription
FROM Person.Person;

-- Lỗi thường gặp & Cách xử lý thông minh
----- Vấn đề 1: Lỗi áp dụng sai hoàn cảnh (Nhầm lẫn với Searched CASE)
----- Trạng thái lỗi: Bạn thấy Simple CASE viết ngắn quá, nên áp dụng nó để kiểm tra điều kiện Lớn hơn/Nhỏ hơn.

-- ❌ SAI CÚ PHÁP HOÀN TOÀN
--CASE ListPrice 
 --   WHEN < 500 THEN 'Cheap' 
--END

-- Tại sao: Simple CASE chỉ hỗ trợ duy nhất phép BẰNG (=)
-- Nếu có các dấu logic (>, <, LIKE), bạn BẮT BUỘC phải quay về dùng Searched CASE


----- Vấn đề 2 : Lỗi "Biến hình" của hàm Không Xác Định (Non-deterministic functions)
-- Khi bạn dùng một hàm sinh số ngẫu nhiên như NEWID() hoặc RAND() đưa vào sau chữ CASE (Ví dụ: CASE NEWID() WHEN ...), kết quả thỉnh thoảng sẽ văng ra NULL một cách khó hiểu.
-- TẠI SAO LẠI BỊ VẬY?
-- Trong SQL Server, "Bộ tối ưu hóa truy vấn" (Query Optimizer) sẽ ngầm dịch Simple CASE của bạn thành Searched CASE trước khi chạy.
-- Nó biến CASE NEWID() WHEN 1 THEN... WHEN 2 THEN... thành:
-- CASE WHEN NEWID() = 1 THEN... WHEN NEWID() = 2 THEN...
-- Bản chất của hàm NEWID() là "Mỗi lần gọi là ra một số mới".
-- Do đó, khi nó kiểm tra dòng 1 không đúng, nó chuyển sang dòng 2 kiểm tra, nhưng lúc này hàm NEWID() lại chạy thêm 1 lần nữa ra một con số khác!
-- Kết quả là nó chạy trượt qua tất cả các điều kiện WHEN và rơi tõm xuống ELSE (hoặc NULL).
-- Cách xử lý thông minh trong thực tiễn:
-- Nếu bạn cần đánh giá một biểu thức tính toán ngẫu nhiên hoặc phức tạp, hãy tính nó ra một biến tĩnh hoặc CTE (Common Table Expression) trước, sau đó mới lấy kết quả tĩnh đó ném vào CASE.

-- ✔️ XỬ LÝ THÔNG MINH CHO NEWID() / RAND() BẰNG CTE
-- Bước 1: Tính toán ngẫu nhiên 1 lần duy nhất và "đóng băng" kết quả vào cột RandomNumber
WITH RandomGenerator AS (
	SELECT ABS(CHECKSUM(NEWID())) % 4 AS RandomNumber
)
-- Bước 2: Truy vấn trên kết quả đã đóng băng
SELECT
	RandomNumber, 
	CASE RandomNumber 
		WHEN 0 THEN 'Dr'
		WHEN 1 THEN 'Master'
		WHEN 2 THEN 'Mr'
		WHEN 3 THEN 'Mrs'
		ELSE 'Unknown'
	END AS Title 
FROM RandomGenerator 

-- Tóm tắt cần nhớ
-- Simple CASE (Shorthand): Gọn, đẹp, dễ đọc, nhưng CHỈ dùng cho so sánh bằng (=).
-- Đừng lười với ELSE: Dù là Shorthand, vẫn luôn đính kèm ELSE để hứng các mã lạ phát sinh trong tương lai.
-- Cạm bẫy NEWID()
---- Không bao giờ đặt các hàm có kết quả thay đổi liên tục (Non-deterministic) trực tiếp sau từ khóa CASE.
---- Hãy sinh ra giá trị đó trước (qua Variable hoặc CTE), rồi mới đưa vào so sánh.

-- 10.5. Using CASE in UPDATE 

-- Sử dụng bảng: Production.Product
-- Chứa thông tin sản phẩm và giá niêm yết (ListPrice). Mỗi sản phẩm thuộc về một nhóm hàng (ProductSubcategoryID).
-- ID = 1: Mountain Bikes (Xe đạp địa hình)
-- ID = 2: Road Bikes (Xe đạp đua)
-- ID = 3: Touring Bikes (Xe đạp đường dài)

-- Yêu cầu nghiệp vụ:
-- Lạm phát tăng cao, Ban giám đốc yêu cầu điều chỉnh giá niêm yết (ListPrice) của các dòng xe đạp như sau:
-- Xe Mountain Bikes (SubcategoryID = 1): Tăng 5% (nhân 1.05)
-- Xe Road Bikes (SubcategoryID = 2): Tăng 10% (nhân 1.10)
-- Xe Touring Bikes (SubcategoryID = 3): Tăng 15% (nhân 1.15)
-- Các sản phẩm khác: Giữ nguyên giá.


-- BƯỚC 1: TẠO LƯỚI AN TOÀN (Bắt đầu một giao dịch)
BEGIN TRAN;

-- BƯỚIC 2: THỰC THI UPDATE VS CASE
UPDATE Production.[Product]  
SET ListPrice   = ListPrice * CASE ProductSubCategoryID 
		WHEN 1 THEN 1.05 
		WHEN 2 THEN 1.1
		WHEN 3 THEN 1.15
		ELSE 1
	END
-- BƯỚC 3: BỘ LỌC TỐI ƯU (Bắt buộc phảo có trong thực tế)
WHERE ProductSubcategoryID IN (1 , 2, 3)

-- BƯỚC 4: KIỂM TRA LẠI 
SELECT p.ProductID,
	   p.ProductSubcategoryID, 
	   p.ListPrice 
FROM Production.[Product] p
WHERE p.ProductSubcategoryID IN (1, 2, 3)
-- BƯỚC 5: CHỐT DỮ LIỆU HOẶC QUAY XE
-- COMMIT TRAN;   -- Bôi đen chạy dòng này nếu dữ liệu đã ĐÚNG.
-- ROLLBACK TRAN; -- Bôi đen chạy dòng này nếu dữ liệu SAI, muốn khôi phục lại giá cũ.

-- Vấn đề 1: "Sát thủ thầm lặng" - Cập nhật toàn bộ bảng (Thiếu WHERE)
-- Tại sao đây là thảm họa?
-- Nếu bảng của bạn có 10 triệu dòng sản phẩm, mà chỉ có 3 mã Item được tăng giá.
-- Việc bạn thiếu WHERE sẽ ép SQL Server phải chạy lệnh UPDATE trên toàn bộ 10 triệu dòng.
-- Những dòng không đổi giá, nó vẫn thực hiện phép toán Giá * 1.00 và ghi đè lại vào ổ cứng.
-- Hậu quả 1: Server bị quá tải IO (Đọc/Ghi ổ cứng).
-- Hậu quả 2: Dung lượng File Nhật ký giao dịch (Transaction Log) phình to khổng lồ.
-- Hậu quả 3: Toàn bộ bảng bị khóa (Table Lock), người dùng khác không thể mua hàng hay xem giá được.
-- Cách xử lý thông minh
-- Dù CASE đã có ELSE 1.00, bạn bắt buộc phải có WHERE để chỉ khoanh vùng những dòng thực sự cần thay đổi.
-- Lệnh ELSE 1.00 lúc này chỉ mang tính chất phòng hờ an toàn (Fallback) cho logic, chứ không nên dùng để bỏ qua cập nhật.


-- Vấn đề 2: Chạy UPDATE "tay không bắt giặc"

-- Trạng thái lỗi: Viết thẳng UPDATE ... SET ... rồi nhấn nút F5 (Execute) cái rụp.
-- Tại sao: Nếu bạn lỡ gõ nhầm WHEN 1 THEN 10.5 (tăng gấp 10 lần thay vì 5%), dữ liệu giá sẽ hỏng toàn bộ. Không có lệnh Undo (Ctrl+Z) trong SQL thuần túy.
-- Cách xử lý:
-- Luôn dùng BEGIN TRAN (Bắt đầu giao dịch).
-- Sau khi chạy UPDATE, dùng SELECT kiểm tra lại.
-- Nếu chuẩn, chạy COMMIT để lưu vĩnh viễn.
-- Nếu sai, chạy ROLLBACK để mọi thứ hoàn về trạng thái trước khi UPDATE.

-- Tóm tắt cần nhớ
-- Sức mạnh gộp: Dùng CASE trong UPDATE giúp bạn cập nhật nhiều logic phức tạp khác nhau chỉ trong 1 lần chạy (1 câu lệnh) thay vì phải viết 3-4 câu UPDATE rời rạc.
-- Quy tắc sinh tử (WHERE): Không bao giờ dùng ELSE của CASE để làm bình phong cho việc thiếu WHERE trong lệnh UPDATE. Phải lọc tập dữ liệu cần đổi trước.
-- An toàn là bạn: Hãy hình thành thói quen BEGIN TRAN -> UPDATE -> Kiểm tra -> COMMIT/ROLLBACK. Đi làm thực tế mà thiếu bước này, bạn sẽ rất dễ làm "bay màu" database của công ty.



-- 10.6. CASE use for NULL values ordered last 

-- Đề bài: Lấy danh sách tất cả nhân viên kinh doanh, bao gồm
-- mã nhân viên, họ tên, doanh số năm nay (SalesYTD) và Tên vùng phụ trách (Territory Name)

-- Yêu cầu sắp xếp: Sắp xếp danh sách theo tên vùng phụ trách theo thứ tự chữ cái (A-Z).
-- Tuy nhiên, những nhân viên chưa được phân bổ vùng (NULL) phải bị đẩy xuống dưới cùng của báo cáo.

-- Để giải quyết bài toán trên, chúng ta cần kết nối 3 bảng sau:
-- 1. Sales.SalesPerson (Bảng gốc): Chứa thông tin đặc thù của nhân viên sales.
-- BusinessEntityID: Mã định danh nhân viên.
-- TerritoryID: Mã vùng phụ trách.
----- Lưu ý: Cột này cho phép NULL (đại diện cho người mới hoặc người quản lý chung chưa gắn vùng cụ thể).
-- SalesYTD: Doanh số tính từ đầu năm đến hiện tại.


-- 2. Sales.SalesTerritory (Bảng từ điển/Lookup): Chứa tên chi tiết của các vùng.
-- TerritoryID: Mã vùng (Dùng để nối với bảng trên).
-- Name: Tên vùng kinh doanh (vd: Northwest, Southwest...). Cột này sẽ thay thế cho cột REGION trong sách của bạn.

-- 3. Person.Person (Bảng thông tin chung): * Chứa FirstName, LastName. Liên kết với SalesPerson qua cột BusinessEntityID.
-- Chứa FirstName, LastName. Liên kết với SalesPerson qua cột BusinessEntityID.

-- Cách nối bảng (JOIN):
-- Dùng INNER JOIN giữa SalesPerson và Person vì ai làm sales cũng phải có tên.
-- Dùng LEFT JOIN từ SalesPerson sang SalesTerritory.
-- Tại sao? Vì nếu dùng INNER JOIN, những nhân viên có TerritoryID là NULL sẽ bị loại bỏ hoàn toàn khỏi tập kết quả.

-- TẠI SAO LẠI PHẢI DÙNG CASE TRONG ORDER BY?
-- Trong SQL Server (SSMS), mặc định các giá trị NULL được coi là nhỏ nhất. 
-- Nếu bạn chỉ viết ORDER BY TerritoryName ASC, các dòng có chữ NULL sẽ hiện lên đầu tiên.
-- Để ép NULL xuống cuối mà vẫn giữ nguyên thứ tự A-Z cho các vùng có tên, ta phải dùng một cột ảo (sinh ra từ mệnh đề CASE) để phân loại mức độ ưu tiên: Coi vùng có dữ liệu là 0 (xếp trước), vùng NULL là 1 (xếp sau).

SELECT 
	sp.BusinessEntityID AS EmployeeID, 
	p.FirstName + ' ' + p.LastName AS EmployeeName,
	st.Name AS TerritoryName,
	sp.SalesYTD 
FROM Sales.SalesPerson sp
	 INNER JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
	 LEFT JOIN Sales.SalesTerritory st ON sp.TerritoryID = st.TerritoryID 
ORDER BY 
	-- Bước 1: Sắp xếp theo 
	--( Nhóm có cùng = 0 xếp trước, nhóm NULL =1 xếp sau)
	CASE 
		WHEN st.[Name] IS NULL THEN 1
		ELSE 0
	END ASC,
	-- Bước 2: Trong nội bộ nhóm 0 (nhóm có vùng), tiếp tực xếp thứu tự A-Z 
	st.[Name] ASC 


-- 10.7. CASE in ORDER BY clause to sort records by lowest value of 2 columns 


SELECT 
    SalesOrderID,
    CAST(DueDate AS DATE) AS DueDate,   -- Ép kiểu DATE cắt bỏ giờ phút giây để dễ nhìn báo cáo
    CAST(ShipDate AS DATE) AS ShipDate
FROM Sales.SalesOrderHeader
ORDER BY 
    -- BƯỚC 1: Đánh giá từng dòng để tìm ngày nhỏ hơn
    CASE 
        -- Nếu DueDate < ShipDate (ép NULL thành năm 9999 để không bị cản trở phép tính)
        WHEN COALESCE(DueDate, '9999-12-31') < COALESCE(ShipDate, '9999-12-31') 
            THEN DueDate 
        
        -- Ngược lại, nếu ShipDate nhỏ hơn hoặc bằng
        ELSE ShipDate 
    END ASC; -- BƯỚC 2: Có được ngày nhỏ hơn rồi, đem ngày đó ra xếp tăng dần (sớm nhất lên đầu)

--TÓM TẮT & GHI NHỚ (TAKEAWAYS)
-- Chức năng của CASE: Không chỉ dùng để tạo cột mới trong SELECT, CASE còn là công cụ mạnh mẽ để tạo ra logic sắp xếp động (Dynamic Sorting) trong ORDER BY.
-- Row-level vs Column-level: 
-- Hàm MIN()/MAX() trong SQL dùng cho tính toán dọc (cột).
-- Muốn so sánh ngang (giữa các cột trên 1 dòng), phải dùng CASE hoặc các hàm đặc thù của từng hệ quản trị (ví dụ một số bản SQL có hàm LEAST(), nhưng viết bằng CASE thì chạy được trên mọi nền tảng chuẩn).
-- Nghệ thuật xài COALESCE
-- Khi dùng mốc ngày giả để xử lý NULL, phải tự hỏi: Mình muốn đẩy dữ liệu NULL này xuống đáy hay lên đỉnh?
-- Nếu muốn nó thua trong phép < (nhỏ hơn), hãy gán nó bằng '9999-12-31'
