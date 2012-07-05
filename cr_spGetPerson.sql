/*  cr_spGetPeople.sql 						*/
/* This sql script creates a stored procedure which is called from an	*/
/* ASP.NET web form. The user specifies search criteria including the	*/
/* possible selection of multiple court districts from a drop-down box.	*/
/* The results returned by the stored procedure are used to populate	*/
/* a results section on the web form.				*/

drop procedure spGetPeople
go

create procedure spGetPeople
(@PersonType	varchar(4) = '',
@TitleCode	varchar(4) = '',
@CircuitCode	varchar(4) = '',
@DistrictCodeString	varchar(200) = '',
@Name		varchar(80) = '',
@City		varchar(80) = '',
@OrderBy varchar(1) = "N") with recompile

as

/* Create temporary table to store selected district codes */
create table #tmpDistrictCodes
(
	Code char(3)
)

/* Only parse the district string if it's not empty */
if (@DistrictCodeString != '')

BEGIN
/* Variables for parsing out district codes: */
declare @pos Int;	/* position */
declare @code char(3);	/* district code */
declare @OriginalDistrictCodeString = @DistrictCodeString;	/* string to parse */

/* We have a non-empty district string - so parse delimited string to extract the district code values. */
SET @DistrictCodeString = @DistrictCodeString + '|'
SET @pos = CHARINDEX('|', @DistrictCodeString, 1)

	IF REPLACE(@DistrictCodeString, '|', '') <> ''
	BEGIN
		WHILE @pos > 0
		BEGIN
		SET @code = LEFT(@DistrictCodeString, @pos -1)
		IF @code <> ''
			BEGIN
			INSERT INTO #tmpDistrictCodes (Code) VALUES (@code)
			END
		/* look for next district code in remainder of string. */
		SET @DistrictCode = RIGHT(@DistrictCodeString, LEN(@DistrictCodeString) - @pos)
		SET @pos = CHARINDEX('|', @DistrictCodeString, 1)
		END
	END
END

/* Retrieve person records from the database which satisfy selection criteria. */
SELECT Person.PersonId, isnull(Person.Prefix + ' ', '') + isnull(Person.Firstname + ' ', ' ') + isnull(Person.Middlename + ' ', ' ')
+ isnull(Person.Lastname, '') + ' ' + isnull(Person.Suffix + ' ', '') AS Wholename,
Title.Title as "Title", Circuit.CircuitName as "Circuit", District.DistrictName as "District",
StreetAddrCity as "City",

FROM Person 
left outer join Title on Person.TitleCode = Title.TitleCode 
left outer join Circuit on Person.CircuitCode = Circuit.CircuitCode
left outer join District on Person.DistrictCode = District.DistrictCode

/* If a parameter has been specified for this field - use it. */
WHERE	(((Person.PersonType = @PersonType) OR (@PersonType = ''))
	and (Person.TitleCode = @TitleCode OR @TitleCode = '')
	and (Person.CircuitCode = @CircuitCode OR @CircuitCode = '')
	and ((Person.DistrictCode IN (Select Code from #tmpDistrictCodes)) OR (@OriginalDistictCodeString is null))
	and (Person.LastName like @Name + '%' OR @Name = '')
	and (StreetAddrCity like @City + '%' OR @City = '')
	and (Person.StatusCode = 'A'))
ORDER BY
CASE @OrderBy
	when 'N' then Person.LastName
	when 'C' then Person.StreetAddrCity
	when 'T' then Title.Title
	when 'D' then Person.DistrictCode
	when 'R' then Person.CircuitCode
END

drop table #tmpDistrictCodes

/*  To test: select people named Fletcher and sort by city

exec spGetPeople '', '', '', '', 'FLETCHER', 'C' 


*/

