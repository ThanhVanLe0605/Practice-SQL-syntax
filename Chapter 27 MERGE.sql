USE AdventureWorks2019
GO

-- 27.1: MERGE to make Target match Source

-- Tại sao dùng MERGE (UPSERT)
-- Trong thực tế, khi đồng bộ dữ liệu từ một nguồn ngoài (ví dụ: file Excel kiểm kê cuối ngày, hoặc dữ liệu từ App đẩy về), ta luôn đối mặt với vấn đề:
---- Nếu dữ liệu đã tồn tại -> Cần Cập nhật (UPDATE).
---- Nếu dữ liệu chưa có -> Cần Thêm mới (INSERT).
---- Nếu dữ liệu có trong hệ thống nhưng nguồn ngoài không còn -> Cần Xóa (DELETE) (Tùy nghiệp vụ)

-- Thay vì viết 3 câu lệnh INSERT, UPDATE, DELETE rời rạc, gọi nhiều lần gây giảm hiệu suất (overhead)
-- MERGE gom tất cả vào một giao dịch duy nhất (atomic)
-- đảm bảo tính toàn vẹn dữ liệu và chạy cực kỳ nhanh.

-- Để thực hành MERGE, nghiệp vụ "Đồng bộ số lượng tồn kho" là ví dụ kinh điển nhất
-- Chúng ta sẽ dùng bảng Production.ProductInventory làm bảng đích (Target).

-- Bảng này lưu trữ thông tin về số lượng tồn kho thực tế của từng sản phẩm tại các vị trí/nhà kho khác nhau.
-- ProductID (PK): Mã sản phẩm.
-- LocationID (PK): Mã vị trí lưu trữ (kho nào, khu vực nào). (Lưu ý: Bảng này dùng Primary Key kép - kết hợp 2 cột).
-- Shelf (Kệ) & Bin (Thùng): Vị trí chi tiết để dễ tìm. Hai cột này cho phép giá trị NULL (không xác định).
-- Quantity: Số lượng tồn kho hiện tại.

-- Yêu cầu: Đồng bộ dữ liệu kiểm kê cuối ngày từ bảng tạm #Staging_DailyInventory vào bảng chính Production.ProductInventorZ
----1. Nếu sản phẩm tại vị trí đó đã có: Cập nhật lại số lượng (Quantity), kệ (Shelf), thùng (Bin) chỉ khi có sự thay đổi.
----2. Nếu sản phẩm tại vị trí đó chưa có: Thêm mới dữ liệu.
----3. Bỏ qua tác vụ XÓA (DELETE) vì trong tồn kho, nếu không có trong file kiểm kê không có nghĩa là vứt bỏ dòng đó (thường người ta sẽ update số lượng về 0, nhưng để bám sát bài học cơ bản, ta chỉ dùng Insert/Update).

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Trước khi chạy lệnh MERGE, hãy bôi đen và chạy đoạn code tạo dữ liệu giả lập (Source) này trước để có cái map vào Target.

-- 1. Tạo và chèn dữ liệu vào bảng tạm (SOURCE)
CREATE TABLE #Staging_DailyInventory (
    ProductID INT,
    LocationID SMALLINT,
    Shelf NVARCHAR(10),
    Bin TINYINT,
    Quantity SMALLINT
);

INSERT INTO #Staging_DailyInventory (ProductID, LocationID, Shelf, Bin, Quantity)
VALUES 
(1, 1, 'A', 1, 400),   -- Sản phẩm đã có, thay đổi số lượng thành 400
(1, 2, NULL, 5, 100),  -- Sản phẩm đã có, thay đổi Bin thành 5, Shelf là NULL
(9999, 1, 'Z', 9, 50); -- Sản phẩm hoàn toàn mới, cần INSERT

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------- CÁCH XỬ LÝ NGHIỆP VỤ NÀY -----------------------------------------------

----00  Bản chất của chữ MATCH là gì? 00-----
-- MATCH (Khớp) chỉ áp dụng duy nhất cho CỘT CHÌA KHÓA (Primary Key) mà ta khai báo ở mệnh đề ON.
-- Ví dụ: ON Target.ProductID = Source.ProductID
-- Hệ thống sẽ rà soát hai bảng và kết luận:
---- MATCHED: Tìm thấy một mã sản phẩm (ví dụ: ProductID = 1) tồn tại ở CẢ HAI BẢNG.
---- NOT MATCHED: Mã sản phẩm này chỉ có ở bên này, mà không có ở bên kia.


-----00  Khi 2 bên có dữ liệu (MATCHED) thì làm gì? Tại sao? 00-----
-- Khi SQL tìm thấy ProductID = 1 ở cả Source và Target, nó biết là "À, hàng này có trong kho rồi". Lúc này, ta phải đối mặt với 2 kịch bản nhỏ:

---------->>> Kịch bản A: Dữ liệu các cột còn lại (Số lượng, Vị trí) GIỐNG HỆT NHAU
-- Làm gì? KHÔNG LÀM GÌ CẢ (Bỏ qua).
-- Tại sao?
-- Nếu bạn cố tình gọi lệnh UPDATE để ghi đè số lượng 100 bằng một số lượng 100 mới, kết quả bề ngoài không đổi.
-- NHƯNG, bên dưới hệ thống, SQL Server vẫn phải ghi chép lại hành động này vào "Nhật ký giao dịch" (Transaction Log), ổ cứng vẫn phải thực hiện tác vụ I/O ghi nhận.
-- Việc này vô cùng lãng phí tài nguyên, làm chậm Database nếu có hàng triệu dòng.

---------->>> Kịch bản B: Dữ liệu các cột còn lại KHÁC NHAU (bị lệch).
-- Làm gì? Dùng lệnh UPDATE.
-- Tại sao?
-- Dữ liệu ở Target là dữ liệu cũ của ngày hôm qua. Dữ liệu ở Source là file kiểm kê mới nhất.
-- Ta phải lấy Source đè lên Target để đảm bảo kho được cập nhật đúng thực tế (Ví dụ: Tồn kho thực tế đã giảm từ 100 xuống 80).
-- Đây chính là lý do đoạn code của bạn có cụm: WHEN MATCHED AND NOT EXISTS (... INTERSECT ...)


-----00  Khi 2 bên KHÁC NHAU (NOT MATCHED) thì làm gì? Tại sao?00-----
---------->>> Kịch bản C: NOT MATCHED BY TARGET (Có ở Source, KHÔNG CÓ ở Target)
----- Tình huống: Trong file kiểm kê mới (Source) xuất hiện ProductID = 999, nhưng trong kho hiện tại (Target) rà mỏi mắt không thấy mã này.
----- Làm gì? Dùng lệnh INSERT.
----- Tại sao? Đây chắc chắn là một mặt hàng mới nhập về, hệ thống cũ chưa từng biết tới. Phải thêm dòng này vào CSDL để quản l

---------->>> Kịch bản D: NOT MATCHED BY SOURCE (Có ở Target, KHÔNG CÓ ở Source)
----- Tình huống: Trong kho (Target) đang lưu ProductID = 5, nhưng file kiểm kê mới nhất (Source) lại hoàn toàn vắng bóng mã này.
----- Làm gì? Dùng lệnh DELETE (hoặc UPDATE trạng thái thành 'Ngưng bán').
----- Tại sao? Điều này có nghĩa là mặt hàng đó đã bị thanh lý, vứt bỏ, hoặc không còn được theo dõi nữa. Ta cần xóa nó đi để dọn dẹp hệ thống, tránh "rác" dữ liệu

-----  Trong TH2, có nhiều cách giải quyết sau ( nhưng chỉ có 1 cách là tối ưu nhất )
 
-----> Cấp độ 1: Cách viết "Ngây thơ" (Chỉ dùng MATCHED)
--WHEN MATCHED 
--THEN UPDATE SET t.Quantity = s.Quantity, t.Shelf = s.Shelf
-- Vấn đề gì xảy ra? Cứ thấy ID khớp (ví dụ ProductID = 1) là SQL sẽ vác lệnh UPDATE ra chạy, bất kể số lượng cũ và mới đều đang là 100, kệ cũ và mới đều là 'A'.
-- Hậu quả: Hệ thống ghi nhận hàng triệu giao dịch "Update rác" (Dummy Update), làm phình to Transaction Log, giảm hiệu năng Database thê thảm.


-----> Cấp độ 2: Cách viết "Đau thương" (Dùng dấu <>)
--WHEN MATCHED AND (t.Quantity <> s.Quantity OR t.Shelf <> s.Shelf)
--THEN UPDATE...

--Trong cơ sở dữ liệu (đặc biệt là cột Shelf - Kệ hàng, rất hay bị bỏ trống tức là NULL).
--Theo chuẩn SQL, bất kỳ cái gì so sánh với NULL đều trả về UNKNOWN (không phải TRUE, cũng chả phải FALSE).
----- Nếu t.Shelf đang là NULL (chưa xếp lên kệ).
----- s.Shelf là 'A' (mới xếp lên kệ A).
----- Khi SQL chạy NULL <> 'A', kết quả là UNKNOWN. Câu lệnh UPDATE bị bỏ qua. Thế là dữ liệu thực tế đã đổi, nhưng Database của bạn thì không!


-----> Cấp độ 3: Cách viết "Chuyên gia" (Dùng NOT EXISTS ... INTERSECT)

----- INTERSECT (Phép Giao) làm nhiệm vụ gì?
-- INTERSECT lấy tập dữ liệu của Source so sánh với Target, và chỉ giữ lại những gì giống hệt nhau.
-- Điều tuyệt vời nhất: INTERSECT coi NULL bằng NULL.

----- Phân tích logic của màng lọc:
----- Giả sử ta đang xét ProductID = 1 (Đã MATCHED). Chúng ta bốc 2 cột Quantity và Shelf ra để soi:
--Kịch bản A (Dữ liệu y chang nhau): Target là (100, 'A'), Source cũng là (100, 'A').
--Phép INTERSECT tìm thấy sự trùng khớp -> Trả về 1 dòng dữ liệu: (100, 'A').
--Lệnh EXISTS (Có tồn tại dòng nào không?) -> Trả về TRUE (Vì có 1 dòng kết quả-).
--Lệnh NOT EXISTS (Phủ định lại) -> Trả về FALSE.
--Kết quả: Mệnh đề WHEN MATCHED AND FALSE -> KHÔNG THỰC HIỆN UPDATE. (Đúng ý đồ tiết kiệm hiệu năng!)
--Kịch bản B (Dữ liệu bị lệch / thay đổi): Target là (100, NULL), Source là (100, 'A').
--Phép INTERSECT đối chiếu thấy khác nhau -> Không có điểm chung -> Trả về Rỗng (0 dòng).
--Lệnh EXISTS -> Trả về FALSE (Vì chả có dòng nào).
--Lệnh NOT EXISTS -> Trả về TRUE.

--Kết quả: Mệnh đề WHEN MATCHED AND TRUE -> KÍCH HOẠT UPDATE! (Đúng ý đồ cập nhật dữ liệu mới an toàn với NULL!).

-----------------------------------------------------------------------------------------------

-- THỰC THI MERGE 
MERGE INTO Production.ProductInventory AS t -- t (Target): bảng đích 


USING (
        SELECT s.* 
        FROM #Staging_DailyInventory s 
        INNER JOIN Production.[Product] p ON s.ProductID = p.ProductID 
) AS s 
        ON t.ProductID    = s.ProductID
        AND t.LocationID   = s.LocationID
 

-- TRƯỜNG HỢP 1: Tồn tại cả 2 bên (MATCHED)
WHEN MATCHED AND NOT EXISTS (
    -- [MẸO THÔNG MINH]: Xử lý cột NULL an toàn bằng INTERSECT
    SELECT  ISNULL(s.Shelf, 'N/A'), s.Bin, s.Quantity 
    INTERSECT 
    SELECT  t.Shelf, t.Bin, t.Quantity 
)
THEN UPDATE SET 
    t.Shelf    = ISNULL(s.Shelf, 'N/A'),
    t.Bin      = s.Bin, 
    t.Quantity = s.Quantity 

-- TRƯỜNG HỢP 2: Có ở nguồn nhưng không có ở đích (NOT MATCHED BY TARGET)
WHEN NOT MATCHED BY TARGET 
THEN INSERT (ProductID, LocationID, Shelf, Bin, Quantity)
VALUES (s.ProductID, s.LocationID, ISNULL(s.Shelf, 'N/A') , s.Bin, s.Quantity )
-- BẮT BUỘC PHẢI CÓ DẤU CHẤM PHẨY KẾT THÚC
;

-- Xóa bảng tạm sau khi xong việc 
DROP TABLE #Staging_DailyInventory


