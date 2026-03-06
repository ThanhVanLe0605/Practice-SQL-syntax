USE AdventureWorks2019
GO

-- Đề bài (Nghiệp vụ thực tiễn)
-- Tạo một đơn hàng bán lẻ mới.
-- Cần ghi nhận thông tin chung của đơn hàng (ngày tạo, khách hàng) và thông tin chi tiết (sản phẩm, số lượng, giá tiền).
-- Nếu có bất kỳ lỗi nào xảy ra trong quá trình ghi nhận (ví dụ: sai kiểu dữ liệu, thiếu thông tin sản phẩm), toàn bộ thao tác phải bị hủy bỏ, không được lưu dữ liệu rác hay dữ liệu dang dở vào hệ thống.


-- Trong AdventureWorks2019, một "đơn hàng" không bao giờ nằm trong một bảng duy nhất. Nó được chia làm hai phần (chuẩn hóa dữ liệu Master-Detail):

-- Bảng Sales.SalesOrderHeader (Thông tin Master): Lưu thông tin chung của cả đơn hàng.
-- SalesOrderID (Primary Key): Mã đơn hàng, tự động tăng.
-- OrderDate: Ngày đặt hàng.
-- CustomerID: Mã khách hàng.

-- Bảng Sales.SalesOrderDetail (Thông tin Detail): Lưu chi tiết từng món hàng trong đơn.
-- SalesOrderID (Foreign Key): Nối với bảng Header để biết món hàng này thuộc đơn nào.
-- SalesOrderDetailID (Primary Key): Mã chi tiết dòng hàng. 
-- ProductID: Mã sản phẩm
-- OrderQty: Số lượng đặt
-- Mối quan hệ: 1 đơn hàng (SalesOrderHeader) có nhiều chi tiết món hàng (SalesOrderDetail). Nối với nhau qua cột SalesOrderID.


-- Tại sao? Làm sao? (Tư duy hệ thống) 

-- Tại sao phải dùng TRANSACTION?
-- Vì việc tạo đơn hàng đòi hỏi phải INSERT vào 2 bảng khác nhau.
-- Lỡ INSERT vào bảng Header thành công, nhưng INSERT vào bảng Detail thất bại (do lỗi typo, sai mã sản phẩm), hệ thống sẽ tồn tại một "đơn hàng rỗng" (có mã đơn nhưng không có hàng).
-- TRANSACTION đảm bảo tính chất "All or Nothing" (Thành công tất cả hoặc không có gì cả). 
-- Tại sao phải dùng TRY/CATCH? Để bắt lỗi một cách chủ động.
-- Thay vì để SQL Server tự văng lỗi đỏ lòm và dừng đột ngột, TRY/CATCH gom lỗi lại, đưa vào khối CATCH để ta dọn dẹp (Rollback) và thông báo lỗi một cách có kiểm soát


-------------------------------------------------------------------------------------
--BEGIN TRY
--...(BẮT ĐẦU GIAO DỊCH,.. )
--COMMIT TRANSACTION
--END TRY

--BEGIN CATCH
--	BEGIN
		--ROLLBACK TRANSACTION

--	END 

--	THROW 
--END CATCH 
-------------------------------------------------------------------------------------

DECLARE @CustomerID INT = 9990
DECLARE @ProductID INT = 890 
DECLARE @OrderQty SMALLINT = 1
DECLARE @NewOrderID INT 

BEGIN TRY 

	--1. BẮT ĐẦU GIAO DỊCH 
	BEGIN TRANSACTION 

	--2. INSERT thông tin chung của đơn hàng 
	INSERT INTO Sales.SalesOrderHeader (RevisionNumber, OrderDate, DueDate, Status, OnlineOrderFlag, CustomerID, BillToAddressID, ShipToAddressID, ShipMethodID, SubTotal, TaxAmt, Freight)
	VALUES (1, GETDATE(), GETDATE() + 7, 1, 1, @CustomerID, 985, 985, 5, 100.00, 8.00, 2.50)

	-- Lấy mã đơn hàng vừa được tạo tự động (SCOPE_IDENTITY) để gán cho chi tiết 
	SET @NewOrderID = SCOPE_IDENTITY()

	--3. INSERT chi tiết đơn hàng (Cố tình tạo lỗi ở đây để test CATCH)
	INSERT INTO Sales.SalesOrderDetail (SalesOrderID, OrderQty, ProductID, SpecialOfferID, UnitPrice)
	VALUES (@NewOrderID, @OrderQty, 'Lỗi sai kiểu dữ liệu', 1, 20.25) -- Cố tình gây lỗi
	
	--4. Nếu mọi thứ thành công, chốt giao dịch 
	COMMIT TRANSACTION
	PRINT N'Đã tạo đơn hàng thành công!'

END TRY 
BEGIN CATCH
	--5 Xử lý khi có lỗi xảy ra 
	-- KIỂM TRA: Chỉ Rollback nếu đang có một transaction đang mở
	IF @@TRANCOUNT > 0 
	BEGIN
		ROLLBACK TRANSACTION
		PRINT N'Đã hủy bỏ giao dịch do có lỗi!'; 
	END ; -- Nhớ có ';' ở đây 



	-- 6. ĐIỀU TRA VÀ GHI LOG 
	INSERT INTO dbo.ErrorLog (
		ErrorTime, UserName, ErrorNumber, ErrorSeverity, 
		ErrorState, ErrorProcedure, ErrorLine, ErrorMessage
	)
	VALUES (
		GETDATE(),				-- Thời gian lỗi
		SYSTEM_USER,		    -- User nào đang chạy code
		ERROR_NUMBER(),		    -- Lấy mã lỗi
		ERROR_SEVERITY(),		-- Độ nghiêm trọng
		ERROR_STATE(),			-- Trạng thái
		ERROR_PROCEDURE(),	    -- Nơi xảy ra lỗi
		ERROR_LINE(),		    -- Dòng bao nhiêu
		ERROR_MESSAGE()         -- Bê nguyên câu chửi của SQL Server vào đây
	);
	PRINT N'Đã ghi nhận lỗi vào hệ thống (Bảng dbo.ErrorLog)!';

		--7. Ném lỗi trả về cho ứng dụng (Application) để họ biết đường xử lý
	THROW 
END CATCH 






-- NOTES : Lỗi sai phổ biến & Cách sửa
-----1. Thứ tự của THROW

-- Lệnh THROW (không có tham số) dùng để ném lại lỗi gốc ra ngoài
-- NHƯNG, khi THROW được thực thi, nó lập tức chấm dứt batch (dừng ngay quá trình chạy code).
-- Do đó, lệnh ROLLBACK TRANSACTION nằm bên dưới sẽ KHÔNG BAO GIỜ được chạy.
-- Giao dịch sẽ bị treo (open transaction), gây khóa chết (deadlock) database.
-- Cách xử lý thông minh
-- Luôn luôn ROLLBACK trước, THROW sau. Code chuẩn:


-----2. Rollback mù quáng

-- Nếu có lỗi xảy ra trước khi BEGIN TRANSACTION kịp chạy (ví dụ lỗi khai báo biến)
-- nhảy vào CATCH và gọi ROLLBACK sẽ gây ra một lỗi mới: "The ROLLBACK TRANSACTION request has no corresponding BEGIN TRANSACTION".
--  Cách xử lý thông minh
-- Trước khi Rollback, hãy hỏi hệ thống: "Mình có đang mở giao dịch nào không?" bằng cách dùng:
-- IF @@TRANCOUNT > 0
-- ROLLBACK TRANSACTION;


-----3. Không lấy được ID vừa tạo
-- Trong quan hệ Master-Detail, bảng Detail cần ID của bảng Master. Nếu tự gõ tay số 1, 2 sẽ dễ gây lỗi trùng lặp.
-- Sử dụng hàm SCOPE_IDENTITY() ngay sau câu INSERT bảng Master để lấy ID vừa sinh ra tự động, rồi truyền vào lệnh INSERT bảng Detail


-- Tóm tắt & Notes cần nhớ
-- Transaction (BEGIN/COMMIT/ROLLBACK): Là chiếc kẹp ghim, ghim các hành động liên quan lại với nhau. Cùng sống, cùng chết.
-- TRY/CATCH: Là lưới bảo vệ. TRY chứa code có rủi ro, CATCH chứa code dọn dẹp hiện trường.
-- Quy tắc vàng: Trong CATCH, luôn dọn dẹp (ROLLBACK) trước khi la làng (THROW). Và nhớ kiểm tra @@TRANCOUNT > 0 trước khi dọn dẹp


----------------------------------------------------------
-- Error handling in SQL Server.
----------------------------------------------------------
-- Vị trí độc quyền
-- Các hàm như ERROR_MESSAGE(), ERROR_LINE()... CHỈ CÓ TÁC DỤNG khi nằm bên trong khối BEGIN CATCH ... END CATCH
-- Nếu bạn gọi nó bên ngoài, nó sẽ trả về NULL


-- Thứ tự thực hiện:
-- Trong CATCH, hãy nhớ thần chú: "Dọn dẹp (ROLLBACK) -> Chụp ảnh hiện trường (INSERT LOG) -> Báo cáo cấp trên (THROW)"









