--The OUTPUT Clause
/*Normally you would not expect a modification statement to do more than modify data. That is, 
you would not expect a modification statement to return any output. However, in some scenarios, 
being able to get back data from the modified rows can be useful.
For example, think about the ability to request from an UPDATE statement that besides modifying data, 
it also returns the old and new values of the updated columns. This can be useful for troubleshooting, auditing, and other purposes.

*/
USE MASTER 
GO
DROP DATABASE IF EXISTS dev_box;
GO
CREATE DATABASE dev_box
GO
USE dev_box
GO


--INSERT WITH OUTPUT
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1
(
  keycol  INT          NOT NULL IDENTITY(1, 1) CONSTRAINT PK_T1 PRIMARY KEY,
  datacol NVARCHAR(40) NOT NULL
);
INSERT INTO dbo.T1(datacol)
  OUTPUT inserted.keycol, inserted.datacol
    SELECT lastname
    FROM IPBC.HR.Employees
    WHERE country = N'USA';

--DELETE with OUTPUT
/*
The next example demonstrates using the OUTPUT clause with a DELETE statement. 
First, run the following code to create a copy of the Orders table from IPBC in dev_box:
*/
USE dev_box;
IF OBJECT_ID('dbo.Orders', 'U') IS NOT NULL DROP TABLE dbo.Orders;
SELECT * INTO dbo.Orders FROM IPBC.Sales.Orders;

/*
The following code deletes all orders that were placed prior to 2008 and, using the OUTPUT clause, returns attributes from the deleted rows:
*/

-- select * from dbo.Orders
DELETE FROM dbo.Orders
  OUTPUT
    deleted.orderid,
    deleted.orderdate,
    deleted.empid,
    deleted.custid
WHERE orderdate < '20080101';

--UPDATE with OUTPUT
/*
Before demonstrating how to use the OUTPUT clause in an UPDATE statement, first run the following code to 
create a copy of the Sales.OrderDetails table from IPBC in the dbo schema in dev_box:
*/
 

USE dev_box;
IF OBJECT_ID('dbo.OrderDetails', 'U') IS NOT NULL DROP TABLE dbo.OrderDetails;
SELECT * INTO dbo.OrderDetails FROM IPBC.Sales.OrderDetails;

/*					  
The following UPDATE statement increases the discount of all order details with product 51 by 5 percent, 
and using the OUTPUT clause returns the product ID, old discount, and new discount from the modified rows:
*/
UPDATE dbo.OrderDetails
  SET discount = discount + 0.05
OUTPUT
  inserted.productid,
  deleted.discount AS olddiscount,
  inserted.discount AS newdiscount
WHERE productid = 51;


select * from dbo.OrderDetails where productid = 51;
--MERGE with OUTPUT
/*
You can also use the OUTPUT clause with the MERGE statement, but remember that a single MERGE statement can invoke multiple, 
different DML actions based on conditional logic. This means that a single MERGE statement might return through the OUTPUT 
clause rows produced by different DML actions. To identify which DML action produced the output row, you can invoke a function 
called $action in the OUTPUT clause, and it will return a string representing the action ('INSERT,' 'UPDATE,' or 'DELETE'). 
To run this example, create the Customers and CustomersStage tables in dev_box and populate them with sample data.


USE dev_box;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL DROP TABLE dbo.Customers;
GO

CREATE TABLE dbo.Customers
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
  CONSTRAINT PK_Customers PRIMARY KEY(custid)
);

INSERT INTO dbo.Customers(custid, companyname, phone, address)
VALUES
  (1, 'cust 1', '(111) 111-1111', 'address 1'),
  (2, 'cust 2', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (4, 'cust 4', '(444) 444-4444', 'address 4'),
  (5, 'cust 5', '(555) 555-5555', 'address 5');
IF OBJECT_ID('dbo.CustomersStage', 'U') IS NOT NULL DROP TABLE dbo.CustomersStage;
GO

CREATE TABLE dbo.CustomersStage
(
  custid      INT         NOT NULL,
  companyname VARCHAR(25) NOT NULL,
  phone       VARCHAR(20) NOT NULL,
  address     VARCHAR(50) NOT NULL,
  CONSTRAINT PK_CustomersStage PRIMARY KEY(custid)
);

INSERT INTO dbo.CustomersStage(custid, companyname, phone, address)
VALUES
  (2, 'AAAAA', '(222) 222-2222', 'address 2'),
  (3, 'cust 3', '(333) 333-3333', 'address 3'),
  (5, 'BBBBB', 'CCCCC', 'DDDDD'),
  (6, 'cust 6 (new)', '(666) 666-6666', 'address 6'),
  (7, 'cust 7 (new)', '(777) 777-7777', 'address 7');

*/
SELECT 'Customers' AS Tbl,* FROM dbo.Customers;
SELECT 'CustomersStage' AS TBL, * FROM dbo.CustomersStage;
/*
The following code merges the contents of CustomersStage into Customers, updating the attributes 
of customers who already exist in the target and adding customers who don't:
*/
MERGE INTO dbo.Customers AS TGT
USING dbo.CustomersStage AS SRC
  ON TGT.custid = SRC.custid
WHEN MATCHED THEN
  UPDATE SET
    TGT.companyname = SRC.companyname,
    TGT.phone = SRC.phone,
    TGT.address = SRC.address
WHEN NOT MATCHED THEN
  INSERT (custid, companyname, phone, address)
  VALUES (SRC.custid, SRC.companyname, SRC.phone, SRC.address)
OUTPUT $action, inserted.custid,
  deleted.companyname AS oldcompanyname,
  inserted.companyname AS newcompanyname,
  deleted.phone AS oldphone,
  inserted.phone AS newphone,
  deleted.address AS oldaddress,
  inserted.address AS newaddress;
/*
This MERGE statement uses the OUTPUT clause to return the old and new values of the modified rows. 
Of course, with INSERT actions there were no old values, so all references to deleted attributes return NULLs. 
The $action function tells you whether an UPDATE or an INSERT action produced the output row. Here's the output of this MERGE statement:
*/