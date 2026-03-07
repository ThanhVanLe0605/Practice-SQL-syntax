USE AdventureWorks2019
GO

-- Chapter 28: CROSS APPLY và OUTER APPLY

-- HumanResources.Department: Chứa thông tin phòng ban (Cột quan trọng: DepartmentID, Name)
-- HumanResources.Employee: Chứa thông tin hồ sơ nghề nghiệp của nhân viên 
-- (Cột quan trọng: BusinessEntityID - mã định danh nhân viên, JobTitle - chức danh).

-- HumanResources.EmployeeDepartmentHistory: Bảng trung gian (Mapping table).
-- Nối nhân viên với phòng ban và ghi lại thời gian làm việc (StartDate, EndDate).
-- Nghiệp vụ cần nhớ: Nếu EndDate IS NULL, nghĩa là nhân viên đó hiện tại vẫn đang làm ở phòng ban này.


-- Tại sao lại cần APPLY?
-- Bạn có thể tự hỏi: "Tại sao phải đẻ ra APPLY trong khi JOIN làm được mọi thứ?"

-- JOIN:
-- Nối 2 tập dữ liệu (set) lại với nhau cùng một lúc.
-- Nó không thể lấy giá trị của bảng A, truyền vào làm tham số (parameter) 
-- cho một hàm (Function) sinh ra bảng B được.

-- APPLY:
-- Hoạt động như một vòng lặp FOR. Nó lấy từng dòng của bảng bên trái (Outer table)
-- truyền giá trị của dòng đó vào biểu thức/hàm ở bên phải 
-- (Inner expression / Table-Valued Function) để xử lý, rồi gộp kết quả lại.


-- 3.1: Dùng APPLY như một JOIN thông thường (Khởi động)

-- Đề bài:
-- Lấy danh sách tất cả các phòng ban và chức danh của các nhân viên đang làm việc tại đó.
-- (Dùng CROSS APPLY và OUTER APPLY).

-- Bảng trái là Department (D)

-- Biểu thức bên phải là một câu SELECT gom Employee (E) và EmployeeDepartmentHistory (EDH) lại,
-- lọc ra những người chưa nghỉ (EndDate IS NULL) và có DepartmentID khớp với bảng trái.


-- Dùng CROSS APPLY (Tương đương INNER JOIN - Chỉ lấy phòng ban CÓ nhân viên)
SELECT
		d.[Name] AS DepartmentName, 
		a.JobTitle 
FROM HumanResources.Department d
CROSS APPLY (
		SELECT	e.JobTitle 
		FROM	HumanResources.Employee e 
		JOIN	HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID 
		WHERE	edh.DepartmentID = d.DepartmentID   -- Nối với bảng D ở ngoài
				AND edh.EndDate IS NULL				-- Nghiệp vụ: Nhân viên hiện tại
) A;
GO 

-- Dùng OUTER APPLY (Tương đương LEFT JOIN - Lấy CẢ phòng ban KHÔNG CÓ nhân viên, trả về NULL ở bên phải)SELECT  d.[Name] AS DepartmentName,
		a.JobTitle
FROM	HumanResources.Department d
OUTER APPLY (
	SELECT  e.JobTitle 
	FROM	HumanResources.Employee e 
	JOIN	HumanResources.EmployeeDepartmentHistory edh  ON	e.BusinessEntityID = edh.BusinessEntityID 
	WHERE   edh.DepartmentID = d.DepartmentID 
			AND edh.EndDate IS NULL
) A;
GO

-- 3.2: Sức mạnh thực sự - Kết hợp với Table-Valued Function (TVF)

-- Đề bài 1:
-- Tạo một hàm (Function) nhận vào DepartmentID và trả về danh sách các nhân viên đang làm việc tại đó.

CREATE FUNCTION dbo.fn_GetCurrentEmployeesByDept (@DeptID INT)
RETURNS TABLE 
AS
RETURN 
(
		SELECT
				e.BusinessEntityID,
				e.JobTitle 
		FROM	HumanResources.Employee e 
		JOIN HumanResources.EmployeeDepartmentHistory d ON e.BusinessEntityID = d.BusinessEntityID 
		WHERE d.DepartmentID = @DeptID
			  AND d.EndDate IS NULL 
)


SELECT
		BusinessEntityID,
		JobTitle
FROM dbo.fn_GetCurrentEmployeesByDept(1);
GO 

-- Đề bài 2:
-- Xuất danh sách tất cả phòng ban và sử dụng hàm vừa tạo để lấy thông tin nhân viên của từng phòng ban.

-- Dùng CROSS APPLY gọi hàm: Truyền cột D.DepartmentID vào làm tham số.
SELECT
		d.[Name] AS DepartmentName,
		f.BusinessEntityID,
		f.JobTitle 
FROM	HumanResources.Department d
CROSS APPLY dbo.fn_GetCurrentEmployeesByDept(d.DepartmentID) f
GO 

-- Dùng OUTER APPLY: Tương tự, nhưng nếu hàm trả về rỗng,
-- phòng ban vẫn hiện lên với các cột NULL.
SELECT
		d.[Name] AS DepartmentName,
		f.BusinessEntityID,
		f.JobTitle
FROM	HumanResources.Department d 
OUTER APPLY dbo.fn_GetCurrentEmployeesByDept(d.DepartmentID) f
GO 

-- NOTES 

--Lỗi 1: Cố gắng dùng JOIN với Table-Valued Function (Lỗi kinh điển)
--Tình huống: Người học nghĩ hàm sinh ra bảng thì cứ JOIN như bảng bình thường là được.
--Mã lỗi thường gặp: "The multi-part identifier 'D.DepartmentID' could not be bound."
--Tại sao sai? Execution Context (Ngữ cảnh thực thi). JOIN đánh giá 2 vế độc lập rồi mới nối. Lúc nó biên dịch hàm, nó không biết D.DepartmentID là cái gì vì bảng D nằm ở một "không gian" khác.
--Cách xử lý: Luôn dùng CROSS APPLY hoặc OUTER APPLY khi cần truyền cột của bảng bên ngoài (outer query) vào một hàm.


--Lỗi 2: Lạm dụng APPLY thay cho JOIN
--Tình huống: Học xong APPLY thấy "ngầu" quá, bài nào cũng lôi APPLY ra viết thay cho JOIN.
--Tại sao sai? Về mặt bản chất, Execution Plan của SQL Server có thể tối ưu JOIN rất tốt. Nếu bạn dùng CROSS APPLY với Derived Table (như phần 3.1) chỉ để nối dữ liệu cơ bản, đôi khi Optimizer bị bối rối và sinh ra kế hoạch thực thi (Execution Plan) kém hiệu quả (dù không phải lúc nào cũng vậy).
--Cách xử lý (Tư duy chuyên gia): * Chỉ dùng JOIN khi logic chỉ là: "Tìm khóa chính/khóa ngoại khớp nhau thì ghép lại".
--Chỉ dùng APPLY cho 3 trường hợp:
--Gọi Table-Valued Function có tham số.
--Bóc tách dữ liệu JSON/XML (Sẽ học sau).
--Bài toán "TOP N" (Ví dụ: Lấy 3 đơn hàng mới nhất của mỗi nhân viên - JOIN cực kỳ khó làm vụ này, nhưng APPLY kết hợp TOP 3... ORDER BY làm trong 1 nốt nhạc).