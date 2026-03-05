-- Phần 1: Tạo bảng từ dữ liệu có sẵn

-- Đề bài (Nghiệp vụ)
-- Tạo một bảng lưu trữ độc lập chứa danh sách các nhân viên có mã định danh (ID) lớn hơn 10.
-- Bảng này cần chứa ID và Họ Tên đầy đủ, dùng để làm báo cáo cuối năm mà không ảnh hưởng đến bảng gốc.

-- GHI CHÚ: Dùng SELECT INTO để vừa định nghĩa cấu trúc bảng mới, vừa đổ dữ liệu vào.
-- Bảng mới sẽ được tạo ra ở Schema 'dbo' mặc định nếu không khai báo.

SELECT 
	p.BusinessEntityID AS EmployeeID,
	-- Dùng hàm CONCAT_WS để ghép chuỗi thông minh, tự động bỏ qua NULL nếu không có Tên đệm
	CONCAT_WS(' ', p.FirstName, p.MiddleName, p.LastName ) AS FullName 
INTO	dbo.Report_employees -- Tên bảng mới được tự động tạo ra
FROM Person.Person p 
WHERE p.BusinessEntityID > 10 

-- Các lỗi sai thường gặp (Bẫy kinh điển)
--- Lỗi 1: Tưởng rằng SELECT INTO sẽ copy cả Khóa chính (Primary Key) và Chỉ mục (Index).
-- Tại sao gặp: Hệ thống chỉ copy "Cấu trúc cột" và "Dữ liệu", không copy các Ràng buộc (Constraints) hay Index để tối ưu tốc độ tạo bảng.
-- Cách xử lý: Nếu bạn định dùng bảng dbo.Report_Employees này lâu dài, bạn phải tự add lại Primary Key sau khi tạo.

-- Code sửa/Bổ sung: Thêm PK cho bảng vừa tạo
ALTER TABLE dbo.Report_employees
ADD CONSTRAINT PK_ReportEmployees PRIMARY KEY (EmployeeID) 

-- Lỗi 2: Muốn copy nguyên cấu trúc bảng mà KHÔNG lấy dữ liệu (Phần 21.4 trong sách).
---- Cách xử lý thông minh: Dùng mệnh đề WHERE luôn sai.
SELECT * INTO dbo.Empty_Person_Clone 
FROM Person.Person
WHERE 1 = 0 -- Điều kiện luôn sai -> Không dòng nào được chọn, chỉ lấy cấu trúc


-- Phần 2: Tạo Bảng Mới & Ràng buộc Khóa Ngoại
-- Đề bài (Nghiệp vụ)
-- Phòng IT cần một hệ thống nhỏ để quản lý việc cấp phát Laptop cho nhân viên.
-- Yêu cầu:
-- Tạo bảng IT_Devices chứa thông tin thiết bị (Mã thiết bị tự tăng, Tên thiết bị).
-- Tạo bảng IT_Checkouts ghi nhận: Ai (Mã nhân viên) mượn Thiết bị nào (Mã thiết bị), vào Ngày nào. Bảng này phải liên kết chặt chẽ với bảng thiết bị và bảng danh sách con người của AW2019.

-- BƯỚC 1: Tạo bảng độc lập trước (Bảng cha - Bảng không chứa khóa ngoại)
CREATE TABLE dbo.IT_Devices (
	DeviceID INT IDENTITY(1, 1) NOT NULL, -- Bắt đầu từ 1, tăng lên 1 sau mỗi dòng
	DeviceName NVARCHAR(100) NOT NULL,	  -- Dùng NVARCHAR để lưu tiếng Việt (nếu cần) 

	-- Định nghĩa khóa chính ngay lúc tạo bảng 
	CONSTRAINT PK_IT_Devices PRIMARY KEY (DeviceID) 
)

-- BƯỚC 2: Tạo bảng liên kết (Bảng con - Bảng chứa khóa ngoại)
CREATE TABLE dbo.IT_Checkouts ( 
	CheckoutID INT IDENTITY(1,1) NOT NULL, 
	DeviceID INT NOT NULL, 
	EmployeeID INT NOT NULL, 
	CheckoutDate DATETIME DEFAULT GETDATE(), 

	CONSTRAINT PK_IT_Checkouts PRIMARY KEY (CheckoutID),

	-- Khóa ngoại 1: Nối với bảng IT_Devices vừa tạo 
	CONSTRAINT FK_Checkout_Device FOREIGN KEY (DeviceID) REFERENCES dbo.IT_Devices(DeviceID),

	-- Khóa ngoại 2: Nối với CSDL có sẵn AW2019 (Person.Person)
	CONSTRAINT FK_Checkout_Employee FOREIGN KEY (EmployeeID) REFERENCES Person.Person(BusinessEntityID) 
)

-- Các lỗi sai thường gặp

--- Lỗi 1: Xóa bảng (DROP TABLE) báo lỗi rành buộc.
-- Tại sao: Bạn đang cố xóa bảng Cha (IT_Devices) trong khi bảng Con (IT_Checkouts) vẫn đang chĩa khóa ngoại vào nó
--SQL Server sẽ chặn lại để bảo vệ toàn vẹn dữ liệu.
-- Cách xử lý: Luôn tuân thủ quy tắc: Tạo Cha trước, Tạo Con sau. Xóa Con trước, Xóa Cha sau.


--- Lỗi 2: Kiểu dữ liệu không khớp giữa Primary Key và Foreign Key.
-- Tại sao: Bảng Person.Person quy định cột BusinessEntityID là kiểu INT
-- Nếu ở bảng IT_Checkouts bạn khai báo EmployeeID là BIGINT hoặc VARCHAR
-- hệ thống sẽ báo lỗi khi tạo Ràng buộc (Foreign Key).
-- Cách xử lý: Khi tham chiếu khóa ngoại, kiểu dữ liệu của 2 cột ở 2 bảng phải giống hệt nhau 100%.


-- Phần 3: Bảng Tạm - Xử lý tính toán trung gian
-- Đề bài (Nghiệp vụ)
-- Lọc ra danh sách hóa đơn của năm 2011, lưu tạm vào bộ nhớ
-- Sau đó dựa vào bảng tạm này để đếm xem có tổng cộng bao nhiêu hóa đơn. (Làm mô phỏng để quen cú pháp tạo bảng tạm).

-- Bảng Sales.SalesOrderHeader: Đây là bảng cực kỳ quan trọng, chứa "Phần đầu" của mọi hóa đơn bán hàng (Mã hóa đơn, Ngày lập, Tổng tiền, Mã khách hàng...).
-- Cột quan tâm: SalesOrderID (Mã HĐ), OrderDate (Ngày mua)

-- Trong SQL Server có 2 loại lưu tạm phổ biến nhất: Local Temp Table (#) và Table Variable (@)
----- Cách 1: Bảng tạm cục bộ (Local Temp Table) - Khuyên dùng cho dữ liệu lớn
-- Dấu # chỉ định đây là bảng tạm. Nó được lưu vật lý trong CSDL hệ thống 'tempdb'
-- Bảng này sẽ TỰ ĐỘNG BIẾN MẤT khi bạn tắt tab query (kết thúc session).

CREATE TABLE #TempSales_2011 (
	SalesOrderID INT,
	OrderDate    DATETIME
)

-- Đổ dữ liệu vào bảng tạm 
INSERT INTO #TempSales_2011 (SalesOrderID, OrderDate)
SELECT SalesOrderID, OrderDate 
FROM Sales.SalesOrderHeader 
WHERE YEAR(OrderDate) = 2011 

-- Lấy dữ liệu ra xem
SELECT COUNT(*) AS TotalOrders_2011
FROM #TempSales_2011


----- Cách 2: Biến bảng (Table Variable) - Khuyên dùng cho dữ liệu rất nhỏ (vài nghìn dòng đổ lại)
DECLARE @TempMemory TABLE (
	SalesOrdereID	INT,
	OrderDate		DATETIME
	)
-- Phải bôi đen chạy cùng 1 lúc toàn bộ từ chữ DECLARE đến chữ SELECT
INSERT INTO @TempMemory
SELECT  SalesOrderID, OrderDate 
FROM	Sales.SalesOrderHeader 
WHERE   YEAR(OrderDate) = 2011

SELECT COUNT(*) AS TotalOrders_2011 
FROM @TempMemory


-- Lỗi 1: Chạy lại đoạn code tạo bảng #Temp bị báo lỗi "There is already an object named '#Temp...' in the database."

-- Chạy lại đoạn code tạo bảng #Temp bị báo lỗi "There is already an object named '#Temp...' in the database."
-- Tại sao: Như đã nói, bảng # sống cho tới khi bạn tắt tab SSMS. Nếu bạn bôi đen chạy lại lệnh CREATE TABLE #... lần 2, nó sẽ báo lỗi vì bảng đã tồn tại trong tempdb.
-- Cách xử lý chuyên nghiệp: Luôn kiểm tra và xóa nếu tồn tại trước khi tạo. Đặt đoạn code này ngay trên lệnh CREATE.

--IF OBJECT_ID('tempdb..#TempSales_2011') IS NOT NULL
--    DROP TABLE #TempSales_2011;

--CREATE TABLE #TempSales_2011 ( ... );



-- Lỗi 2: Lạm dụng Table Variable (@) cho dữ liệu hàng triệu dòng.
-- Tại sao: SQL Server thường mặc định @TableVariable chỉ có 1 dòng khi lập Execution Plan (kế hoạch thực thi).
-- Nếu bạn nhét hàng triệu dòng vào đó rồi đem JOIN với bảng khác, query sẽ chạy cực kỳ chậm (chết dở hệ thống).

-- Cách xử lý: Nếu dữ liệu lớn, hãy dùng #TempTable. #TempTable cho phép tạo Index và SQL Server tính toán thống kê (statistics) chính xác hơn.

