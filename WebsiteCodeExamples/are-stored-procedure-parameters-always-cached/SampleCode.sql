--NEED TO LOOK AT ESTIMATED PLANS!

CREATE TABLE TestTable (ID INT IDENTITY(1, 1) PRIMARY KEY, Value NVARCHAR(40))
INSERT INTO TestTable (Value)
VALUES
(N'Greg')
,(N'Non Greg')
,(N'Joe')

GO

--1. Send in parameter, don't use it at all
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	SELECT	*
	FROM	TestTable
END;
GO
EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--Parameter not cached
GO

--2. Send in parameter, select it straight back out
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	SELECT	@DisplayName
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--to trivial for a query plan
GO


--3. Send in parameter, select it straight back out with a table
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	SELECT	@DisplayName
			,*
	FROM	TestTable
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--includes the compiled plan
GO


--4. Send in parameter, use it in the where clause
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	SELECT	*
	FROM	TestTable
	WHERE	TestTable.Value = @DisplayName
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--includes the compiled plan
GO


--5. Send in parameter, set it to a local variable
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	DECLARE @DisplayName_Internal NVARCHAR(40)

	SET @DisplayName_Internal = @DisplayName
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--To trivial to create a plan
GO


--6. Send in parameter, set it to a local variable and use the variable in the select list
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	DECLARE @DisplayName_Internal NVARCHAR(40)
	SET @DisplayName_Internal = @DisplayName

	SELECT	@DisplayName_Internal
			,*
	FROM	TestTable
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--Doesn't include it in the params
GO



--7. Send in parameter, set it to a local variable and use the variable in the where clause
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN
	DECLARE @DisplayName_Internal NVARCHAR(40)
	SET @DisplayName_Internal = @DisplayName

	SELECT	*
	FROM	TestTable
	WHERE	TestTable.Value = @DisplayName_Internal
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--Doesn't include it in the params
GO



--8. Send in parameter, pass it to dynamic SQL
CREATE OR ALTER PROC dbo.usp_ParamTest
	@DisplayName NVARCHAR(40)
AS
BEGIN

	DECLARE @SQLString NVARCHAR(4000) = 'SELECT	*
	FROM	TestTable
	WHERE	TestTable.Value = @DisplayName';

	EXEC sys.sp_executesql @SQLString, N'@DisplayName NVARCHAR(40)', @DisplayName
END;
GO

EXEC dbo.usp_ParamTest @DisplayName = N'Greg'
--Doesn't include it in the params
GO

