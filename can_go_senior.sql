/* can_go_senior.sql 							*/
/* This stand-alone procedure calculates when Circuit Judges may to go Senior.	*/
/* The 'Rule of 80' states that a judge's age plus years of service must	*/
/* add up to 80. Additionally: To be eligible, judges must be 65 years 		*/
/* old and have a minimum of 10 years of service.				*/
/*										*/
/* Algorithym in days:								*/
/* (Age) + (Length Service) + 2X = 29220 (80 x 365 1/4 days/ year)		*/
/* So days until can go Senior = (29220 - (Age + Length Service))/2		*/

/* Create a temporary table to store data for circuit judges */

create table tmpCircuitJudges
(
	FirstName varchar(14),
	Lastname varchar(18),
	DateofBirth datetime,
	AppointmentDate datetime,
	AgeinDays integer,
	DaysofService integer,
	DaysUntilCanGoSenior integer,
	Willbe65Date datetime,
	TenYearsServiceDate datetime,
	CanGoSeniorDate datetime,
)
go

insert into tmpCircuitJudges
select firstname, lastname, dateofbirth, appointeddate, datediff(day, dateofbirth, getdate()) as "Age",
	datediff(day, appointeddate, getdate()) as "DaysofService", null, null, null, null from person 
where (persontype = 'cj') and (circuitcode = '09CR')

/* Calculate date can go Senior providing they are 65 and have 10 years of service. */
update tmpCircuitJudges
set DaysUntilCanGoSenior = (29220 - (AgeinDays + DaysofService))/2

update tmpCircuitJudges
set WillBe65Date = dateadd(year, 65, DateofBirth)

update tmpCircuitJudges
set TenYearsServiceDate = dateadd(year, 10, AppointmentDate)

update tmpCircuitJudges
set CanGoSeniorDate = getdate() + DaysUntilCanGoSenior
/* where AgeInDays + DaysofService < 29220 */

/* If applying the 'Rule of 80' comes out to a date before a judge's 65th birthday, reset date to 65th birthday */
update tmpCircuitJudges
set CanGoSeniorDate = Willbe65Date
where datediff(day, CangoSeniorDate, WillBe65Date) > 0

/* If applying the 'Rule of 80' comes a date before a judge has completed 10 years of service, reset to 10 year service date */
update tmpCircuitJudges
set CangoSeniorDate = TenYearsServiceDate
where datediff(day, CanGoSeniorDate, TenYearsServiceDate) > 0

select FirstName, LastName, substring((convert(char,DateofBirth,101)),1,10) as "DOB",
	substring((convert(char, WillBe65DAte, 101)),1,10) as "Will be 65",
	substring((convert(char, AppointmentDate, 101)),1,10) as "Appointment",
	substring((convert(char, TenYearsServiceDate, 101)),1,10) as "10 years service",
	substring((convert(char, CanGoSeniorDate, 101)),1,10) as "Can go Senior"
from tmpCircuitJudges
order by CanGoSeniorDate

drop table tmpCircuitJuges





