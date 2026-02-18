
-- 3.1. DECIMAL and NUMERIC
-- Fixed precision and scale decimal numbers. DECIMAL and NUMERIC are functionally equivalent.
-- Syntax:
-- DECIMAL ( precision [ , scale] )
-- NUMERIC ( precision [ , scale] )

SELECT CAST(123 AS DECIMAL(5,2)) -- returns 123.00
SELECT CAST(12345.12 AS NUMERIC(10,5)) -- returns 12345.12000


-- 3.2. FLOAT and REAL
-- Approximate-number data types for use with floating point numeric data.

SELECT CAST( PI() AS FLOAT ) -- returns 3,14159265358979
SELECT CAST( PI() AS REAL )  -- returns 3,141593


-- 3.3. INTEGERS 

--- Data type   ||     Range        ||    Storage 
--------------------------------------------------
---  bigint     || -2^63 to 2^63 -1 ||    8 Bytes 
---  int        || -2^31 to 2^32 -1 ||    4 Bytes 
---  smallint   || -2^15 to 2^15 -1 ||    2 Bytes 
---  tinyint    ||   0   to 255     ||    1 Bytes 


-- 3.4. MONEY and SMALLMONEY
-- Data types that represent monetary or currency values.


--- Data type   ||     Range         ||    Storage 
--------------------------------------------------
--- money       || [-922, 922] tr tỷ ||    8 Bytes 
--- smallmoney  || [-214 , 214] tr   ||    4 Bytes 


-- 3.5. BINARY and VARBINARY 
-- Binary data types of either fixed length or variable length

-- Syntax:
-- BINARY [ (n_bytes) ]
-- VARBINARY[ (n_bytes | max ) ]

-- n_bytes can be any number from 1 to 8000 bytes
-- max indicates that the maximum storage space is 2^31-

SELECT CAST(12345 AS BINARY(10) ) -- 0x00000000000000003039
SELECT CAST(12345 AS VARBINARY(10) ) -- 0x00003039

-- 3.6. CHAR and VARCHAR
-- String data types of either fixed length or variable length.

-- Syntax:
-- CHAR [ (n_chars ) ]
-- VARCHAR [ (n_chars) ]

SELECT CAST('ABC' AS CHAR(10) ) -- ABC       (padded with spaces on the right)
SELECT CAST('ABC' AS VARCHAR(10) ) -- ABC    (no padding due to variable character)
SELECT CAST('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' AS CHAR(10)) -- AAAAAAAAAA (truncated to 10 characters)


-- 3.7. NCHAR and NVARCHAR
-- UNICODE string data types of either fixed length or variable length

-- Syntax:
-- NVARCHAR[ ( n_chars ) ]
-- NVARCHAR[ ( n_chars | MAX ) ] 
-- Use MAX for very long strings that may exceed 8000 characters

-- 3.8. UNIQUEIDENTIFIER 
-- A 16-byte GUID (Globally Unique Identifier) / UUID (Universally Unique Identifier)

DECLARE @GUID UNIQUEIDENTIFIER = NEWID() ; 
SELECT @GUID -- 6725AA74-BCD8-4073-92E1-322F0B31E91E

DECLARE @bad_GUID_string VARCHAR(100) = '6725AA74-BCD8-4073-92E1-322F0B31E91E_foobarbaz'
SELECT 
	@bad_GUID_string, -- 6725AA74-BCD8-4073-92E1-322F0B31E91E_foobarbaz
	CONVERT( UNIQUEIDENTIFIER, @bad_GUID_string) -- 6725AA74-BCD8-4073-92E1-322F0B31E91E
