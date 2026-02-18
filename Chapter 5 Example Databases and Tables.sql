-- 5.1. Auto Shop Database 

-- In the following example - Database for an auto shop business, we have a list of departments, employees, customers and customer cars. 
-- We are using foreign keys to create relationships between the various tables.

-- Relationships between tables
---- Each Department may have 0 or more Employees
---- Each Employee may have 0 or 1 Manager
---- Each Customer may have 0 or more Cars

-- Departments
-- Id Name
-- 1 HR
-- 2 Sales
-- 3 Tech

CREATE DATABASE Auto_Shop
USE Auto_Shop

------------------------ TABLE Departments ----------------------------------
CREATE TABLE Departments (
	Id			INT NOT NULL IDENTITY(1,1),
	Name		VARCHAR(25) NOT NULL, 
	PRIMARY KEY (Id)
)

INSERT INTO Departments ([Name]) 
VALUES 
	('HR'),
	('Sales'),
	('Tech') ;   

------------------------ TABLE Employees   ----------------------------------
CREATE TABLE Employees (
	Id INT NOT NULL IDENTITY(1, 1),
	FName VARCHAR(35) NOT NULL, 
	LName VARCHAR(35) NOT NULL,
	PhoneNumber VARCHAR(11),
	ManagerId INT,
	DepartmentId INT NOT NULL, 
	Salary INT NOT NULL, 
	HireDate DATETIME NOT NULL, 
	PRIMARY KEY(Id),
	FOREIGN KEY(ManagerId) REFERENCES Employees(Id), 
	FOREIGN KEY(DepartmentId) REFERENCES Departments(Id) 
)


-- Check datetime format 
DBCC USEROPTIONS; 
-- dateformat	mdy

-- Change the style of the datetime 
SET DATEFORMAT dmy 

INSERT INTO Employees (FName, LName, PhoneNumber, ManagerId, DepartmentId, Salary, HireDate)
VALUES 
	('James', 'Smith', '1234567890', NULL, 1, 1000, '01-01-2002'),
	('John', 'Johnson','246801214', 1, 1, 400, '23-03-2005'),
	('Michael', 'Williams', '1357911131', 1, 2, 600, '12-05-2009'),
	('Johnathon', 'Smith', '1212121212', 2, 1, 500, '24-07-2016');


------------------------ TABLE Customers   ----------------------------------

CREATE TABLE Customers (
	Id INT NOT NULL IDENTITY(1, 1),
	FName VARCHAR(25) NOT NULL, 
	LName VARCHAR(25) NOT NULL, 
	Email VARCHAR(100) NOT NULL, 
	PhoneNumber VARCHAR(11), 
	PreferredContact VARCHAR(5) NOT NULL, 
	PRIMARY KEY(Id)
); 

INSERT INTO Customers( FName, LName, Email, PhoneNumber, PreferredContact)
VALUES 
	( 'William', 'Jones', 'william.jones@example.com', '347927472', 'PHONE'),
	('David', 'Miller', 'dmiller@example.net', '2137921892', 'EMAIL'),
	('Richard', 'Davis', 'richard0123@example.com', NULL, 'EMAIL')



------------------------ TABLE Cars   ----------------------------------

CREATE TABLE Cars (
	Id INT NOT NULL IDENTITY(1, 1), 
	CustomerId INT NOT NULL, 
	EmployeeId INT NOT NULL, 
	Model VARCHAR(50) NOT NULL, 
	Status VARCHAR(25) NOT NULL, 
	TotalCost INT NOT NULL, 
	
    PRIMARY KEY(Id),
	FOREIGN KEY (CustomerId) REFERENCES Customers(Id),
	FOREIGN KEY (EmployeeId) REFERENCES Employees(Id)
)

INSERT INTO Cars (CustomerId, EmployeeId, Model, Status, TotalCost)
VALUES 
	('1', '2', 'Ford F-150', 'READY', '230'),
	('1', '2', 'Ford F-150', 'READY', '200'),
	('2', '1', 'Ford Mustang', 'WAITING', '100'),
	('3', '3', 'Toyota Prius', 'WORKING', '1254')

-- 5.2. Library Database
-- In this example database for a library, we have Authors, Books and BooksAuthors tables.
-- Authors and Books are known as base tables, since they contain column definition and data for the actual entities in the relational model
-- BooksAuthors is known as the relationship table, since this table defines the relationship between the Books and Authors table

-- Relationships between tables
-- Each author can have 1 or more books
-- Each book can have 1 or more authors
CREATE DATABASE Library
USE Library

------------------------ TABLE Authors   ----------------------------------
CREATE TABLE Authors (
	Id INT NOT NULL IDENTITY(1, 1), 
	Name VARCHAR(70) NOT NULL, 
	Country VARCHAR(100) NOT NULL, 
	
	PRIMARY KEY(Id)
)

INSERT INTO Authors (Name, Country)
VALUES 
	('J.D. Salinger', 'USA'),
	('F. Scott. Fitzgerald', 'USA'),
	('Jane Austen', 'UK'),
	('Scott Hanselman', 'USA'),
	('Jason N. Gaylord', 'USA'),
	('Pranav Rastogi', 'India'),
	('Todd Miranda', 'USA'),
	('Christian Wenz', 'USA')
	;

------------------------ TABLE Books   ----------------------------------
CREATE TABLE Books (
	Id INT NOT NULL IDENTITY(1, 1), 
	Title VARCHAR(50) NOT NULL, 
	
	PRIMARY KEY(Id)
)

INSERT INTO BooKs (Title)
VALUES 
	('The Catcher in the Rye'),
	('Nine Stories'),
	('Franny and Zooey'),
	('The Great Gatsby'),
	('Tender id the Night'),
	('Pride and Prejudice'),
	('Professional ASP.NET 4.5 in C# and VB')

	------------------------ TABLE BooksAuthors   ----------------------------------
	CREATE TABLE BooksAuthors(
		AuthorId INT NOT NULL,
		BookId INT NOT NULL, 

		FOREIGN KEY (AuthorId) REFERENCES Authors(Id), 
		FOREIGN KEY (BookId) REFERENCES Books(Id)
	)

	INSERT INTO BooksAuthors (BookId, AuthorId)
	VALUES 
			(1, 1),
			(2, 1),
			(3, 1),
			(4, 2),
			(5, 2),
			(6, 3),
			(7, 4),
			(7, 5),
			(7, 6),
			(7, 7),
			(7, 8)

SELECT * FROM Authors

SELECT * FROM Books

SELECT 
	ba.AuthorId, 
	a.Name As AuthorName, 
	ba.BookId, 
	b.Title As BookTitle
FROM BooksAuthors ba
	INNER JOIN Authors a ON a.Id = ba.AuthorId
	INNER JOIN Books b ON b.Id = ba.BookId


-- 5.3. Countries Table 
-- In this example, we have a Countries table. 
-- A table for countries has many uses, especially in Financial applications involving currencies and exchange rates.

CREATE DATABASE Countries
USE Countries

CREATE TABLE Countries (
	Id INT NOT NULL IDENTITY(1, 1), 
	ISO VARCHAR(2) NOT NULL, 
	ISO3 VARCHAR(3) NOT NULL, 
	ISONumeric INT NOT NULL, 
	CountryName VARCHAR(64) NOT NULL, 
	Capital VARCHAR(64) NOT NULL, 
	ContinentCode VARCHAR(2) NOT NULL, 
	CurrencyCode  VARCHAR(3) NOT NULL,
	
	PRIMARY KEY(Id)
)


INSERT INTO Countries
	(ISO, ISO3, ISONumeric, CountryName, Capital, ContinentCode, CurrencyCode)
VALUES
	('AU', 'AUS', 36, 'Australia', 'Canberra', 'OC', 'AUD'),
	('DE', 'DEU', 276, 'Germany', 'Berlin', 'EU', 'EUR'),
	('IN', 'IND', 356, 'India', 'New Delhi', 'AS', 'INR'),
	('LA', 'LAO', 418, 'Laos', 'Vientiane', 'AS', 'LAK'),
	('US', 'USA', 840, 'United States', 'Washington', 'NA', 'USD'),
	('ZW', 'ZWE', 716, 'Zimbabwe', 'Harare', 'AF', 'ZWL')
