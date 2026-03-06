USE AdventureWorks2019
GO
----------------------------------------------------------------------------------------
-- Phần 1: UNION ALL - Gộp dữ liệu "Bao trọn gói"

-- Nghiệp vụ (Business Requirement)
-- Phòng Marketing cần một danh sách gồm Họ Tên và Email của hai nhóm đối tượng:
-- Nhân viên công ty (Employees) và Người đại diện của các cửa hàng đối tác (Store Contacts)
-- để gửi email thông báo sự kiện cuối năm.

-- Tại sao lại dùng UNION ALL ở đây?
-- Vì mục đích là gửi email sự kiện, và giả sử một người vừa làm nhân viên, vừa là đại diện cho một cửa hàng (trường hợp hiếm nhưng có thể xảy ra),
-- Marketing vẫn muốn danh sách đầy đủ không bỏ sót, gộp kết quả từ 2 tập truy vấn khác nhau.

-- TRUY VẤN 1: Lấy danh sách Nhân viên (PersonType = 'EM')
SELECT
	-- Trước SELECT, kiểm tra data type ở truy vấn 1 này có khớp với truy vấn 2 sắp tới không
	-- Nếu có thì dùng CAST() để chỉnh sửa 
	-- Làm có chọn lọc không làm tràn lan 
	p.FirstName,
	p.LastName,
	e.EmailAddress,
	-- Ép kiểu tường minh cho cột giả để tạo 'khuôn' chuẩn cho câu lệnh bên dưới 
	CAST('Internal Employee' AS NVARCHAR(50)) AS 'Role'
FROM Person.Person p
INNER JOIN Person.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID 
WHERE p.PersonType  = 'EM'

-----------------------------------
UNION ALL 
-----------------------------------

-- TRUY VẤN 2: Lấy danh sách Người liên hệ cửa hàng (PersonType = 'SC')
SELECT
	p.FirstName,
	p.LastName,
	e.EmailAddress,
-- Phải CAST cùng kiểu NVARCHAR(50) như câu trên để "lắp" vừa vặn vào khuôn	CAST('Internal Employee' AS NVARCHAR(50)) AS 'Role'
	CAST('Store Contact' AS	NVARCHAR(50))
FROM Person.Person p 
JOIN Person.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID 
WHERE p.PersonType = 'SC'

-- NOTES: Các lỗi sai hay gặp & Cách xử lý thông minh
---- Lỗi sai 1: "Conversion failed..." (Sai kiểu dữ liệu)
-- Tại sao gặp: Số lượng cột ở 2 câu SELECT bằng nhau, nhưng kiểu dữ liệu không tương thích.
-- Ví dụ: Cột thứ 3 ở trên là chuỗi (EmailAddress), nhưng cột thứ 3 ở dưới bạn lỡ để là số (BusinessEntityID).

---- Lỗi sai 2: Lệch số lượng cột
-- Cách xử lý: Luôn gióng hàng các cột khi code.
-- Nếu một bảng không có cột tương ứng, hãy dùng giá trị NULL hoặc ép kiểu (CAST/CONVERT)
-- Ví dụ: SELECT Name, Age UNION SELECT Name, NULL


----------------------------------------------------------------------------------------
-- Phần 2: UNION vs UNION ALL - Bài toán Tối ưu hóa

-- Nghiệp vụ (Business Requirement)
-- Phòng Kiểm toán (Audit) cần rà soát lại các hóa đơn bán hàng.
-- Họ cần danh sách mã hóa đơn (SalesOrderID) và Tổng tiền (TotalDue) thỏa mãn 1 trong 2 điều kiện:
---- 1. Là đơn hàng được đặt Online.
---- 2. Là đơn hàng có Tổng tiền > 100,000

--Bảng Sales.SalesOrderHeader: Lưu thông tin chung của từng đơn hàng (như phần "Header" của tờ hóa đơn).
--SalesOrderID: Mã đơn hàng.
--OnlineOrderFlag: Cờ đánh dấu. 1 là đặt qua web, 0 là nhân viên sale tạo.
--TotalDue: Tổng tiền khách phải trả.

-- Tư duy: Dùng OR hay dùng UNION?
-- Thông thường, bạn sẽ viết: WHERE OnlineOrderFlag = 1 OR TotalDue > 100000.
-- Tại sao gặp vấn đề?
-- Khi bảng quá lớn (hàng triệu dòng), câu lệnh OR làm Engine của SQL bối rối, nó thường từ bỏ việc dùng Index (mục lục) và chọn cách quét toàn bộ bảng (Table Scan) -> Rất chậm!
-- Cách xử lý thông minh:
-- Tách thành 2 câu SELECT nhỏ tìm kiếm trên từng điều kiện (để tận dụng Index của từng cột), sau đó dùng UNION để gộp lại.
-- Vì một đơn hàng có thể vừa mua online vừa > 100,000, nếu dùng UNION ALL nó sẽ bị nhân đôi. Ở đây bắt buộc dùng UNION để loại bỏ trùng lặp.

-- Vấn đề hay gặp:
-- Giả sử sếp yêu cầu bạn gộp bảng SalesOrderHeader (lưu Tổng tiền kiểu MONEY) với một bảng Lịch sử hóa đơn cũ lấy từ hệ thống khác (lưu Tổng tiền kiểu FLOAT hoặc DECIMAL)
-- Nếu bạn gộp trực tiếp, quá trình làm tròn số ngầm định giữa FLOAT và MONEY sẽ dẫn đến sai lệch vài đồng lẻ.
-- Trong kế toán, sai 1 đồng là sai toàn bộ báo cáo!

-- Cách xử lý thông minh:
-- Ép tất cả các cột liên quan đến tiền tệ về một chuẩn chung,
-- thường là DECIMAL(18,2) hoặc DECIMAL(19,4) trước khi UNION. Ở đây tôi dùng thêm CONVERT để bạn làm quen cú pháp.


-- TRUY VẤN 1: Lấy các đơn hàng Online
SELECT
		CAST(SalesOrderID AS INT) AS 'OrderID',
		-- Dùng CONVERT ép kiểu tiền tệ về chuẩn DECIMAL(18, 2)
		CONVERT(DECIMAL(18, 2), TotalDue) AS 'TotalAmount'
FROM	Sales.SalesOrderHeader 
WHERE   OnlineOrderFlag = 1
------------------------------------------------------
UNION
------------------------------------------------------
-- TRUY VẤN 2:
SELECT
		CAST(SalesOrderID AS INT) AS 'OrderID',
		-- Dùng CONVERT ép kiểu tiền tệ về chuẩn DECIMAL(18, 2)
		CONVERT(DECIMAL(18, 2), TotalDue) AS 'TotalAmount'
FROM	Sales.SalesOrderHeader 
WHERE TotalDue > 100000 



--Cảnh báo "Chết người" về Hiệu suất (Performance)
--Vấn đề lớn nhất của học viên/Dev mới: Cứ gộp bảng là nhắm mắt gõ UNION.
--Tại sao? UNION (không có ALL) yêu cầu SQL Server thực hiện một phép Sort (Sắp xếp) ngầm định toàn bộ dữ liệu kết quả để tìm và xóa dòng trùng lặp. Phép Sort này cực kỳ tốn CPU và RAM.
--Luật bất thành văn: Mặc định luôn dùng UNION ALL. Chỉ dùng UNION khi bạn THỰC SỰ cần lọc trùng lặp và biết chắc chắn dữ liệu có sự giao nhau.

-- Nhắc nhở, tóm tắt cần nhớ
-- 1. Chủ động chặn lỗi ép kiểu: Đừng để SQL Server tự đoán kiểu dữ liệu khi dùng UNION. Hãy ép kiểu tường minh.
-- 2. Bảo vệ Index: Ép kiểu sai cách (nhất là ở mệnh đề WHERE hoặc JOIN) sẽ làm hỏng Index. Ép kiểu ở mệnh đề SELECT trong UNION như trên giúp giữ an toàn cho dữ liệu đầu ra.
-- 3. CAST vs CONVERT: Tập thói quen dùng CAST(Tên_Cột AS Kiểu_Dữ_Liệu) cho mọi bài toán ép kiểu cơ bản để code dễ port (chuyển đổi) sang các hệ quản trị CSDL khác sau này.