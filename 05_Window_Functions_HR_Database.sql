#"Show cumulative payroll by department."
SELECT
    d.DEP_NAME,
    e.F_NAME,
    e.SALARY,
    SUM(e.SALARY) OVER (
        PARTITION BY d.DEP_NAME
        ORDER BY e.SALARY DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Total
FROM EMPLOYEES e
LEFT JOIN DEPARTMENTS d
    ON e.DEP_ID = d.DEPT_ID_DEP
;

#Exercise 1: Within each department, rank employees from highest salary to lowest salary.
#Display: employee name, department, salary, rank. Use RANK().

SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS NAME, d.DEP_NAME, e.SALARY,
	   RANK() OVER (ORDER BY e.SALARY DESC)  AS SALARY_RANK
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID
;


#Exercise 2: For every employee, calculate the running total of salary within their department,
#ordered from highest salary to lowest salary.
#Display: employee name, department, salary, running total 
#(You'll need: SUM(), OVER(), PARTITION BY, ORDER BY)

SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) as Emp_Name, d.Dep_Name, e.Salary,
	   SUM(e.SALARY) OVER(
       PARTITION BY d.DEP_NAME
       ORDER BY e.SALARY DESC
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW # <- default frame is 'range' not 'rows'
       ) AS Running_Total
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID
;


#LEVEL 1 — FOUNDATIONS
#---------------------

#W1 — Number employees within each department
#Using the employee table, return: emp_id, first_name, last_name, dep_id, department_employee_number
#Number employees 1, 2, 3... within each department, ordering by salary highest to lowest.
#Requirements: Use ROW_NUMBER(), Use PARTITION BY, Do not use GROUP BY (Think about what PARTITION BY dep_id divides the window into)

SELECT e.EMP_ID, e.F_NAME, e.L_NAME, e.DEP_ID, 
	   ROW_NUMBER() OVER(
       PARTITION BY(e.DEP_ID) ORDER BY(e.SALARY) DESC) AS 'Employee Dept Ranking by Salary'	   
FROM employees e;



#W2 — Rank employees by salary
#Return: employee name, department, salary, salary rank within department
#Employees with the same salary receive the same rank, and the next rank skips accordingly.
#Use RANK() with PARTITION BY department. Then replace RANK() with DENSE_RANK() and observe what changes.
SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS 'Employee Name', d.DEP_NAME, e.SALARY,
	   RANK() OVER(
       PARTITION BY(d.DEP_NAME) ORDER BY(e.SALARY) DESC)  AS 'Salary Rank W/IN Dept'
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID;


#W3 — Department average beside every employee
#Return: employee name, department, salary, average salary for that employee's department
#Every employee should remain an individual row.
#Use AVG() OVER() with PARTITION BY. Compare this conceptually with GROUP BY.
SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS 'Employee Name', d.DEP_NAME, e.SALARY,
	   ROUND(AVG(e.SALARY) OVER(
       PARTITION BY(e.DEP_ID)), 2) AS 'Dept Average Salary'
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID;



#LEVEL 2 — WINDOWS THAT CALCULATE
#--------------------------------

#W4 — Running payroll total: Within each department, order employees by salary descending.
#Return: employee, department, salary, cumulative salary total
#Example:
#70,000 -> 70,000
#65,000 -> 135,000
#65,000 -> 200,000
#Use SUM(salary) OVER(...). Do this from scratch without looking at the previous running-total query.
SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS 'Employee', d.DEP_NAME, e.SALARY,
	   SUM(e.SALARY) OVER(
       PARTITION BY(d.DEP_NAME)
       ORDER BY e.SALARY DESC
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Cumulative Salary Total'
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID;

#W5 — Salary difference from previous employee: Within each department, order employees by salary descending.
#Return: employee, department, salary, previous employee's salary, difference between current and previous salary
#Use LAG().

SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS "Employee", d.DEP_NAME, e.SALARY,
	   LAG(e.SALARY) OVER(
       PARTITION BY(d.DEP_NAME)
       ORDER BY e.SALARY DESC) AS "Previous Employee's Salary",
	   e.SALARY - LAG(e.SALARY) OVER(
				  PARTITION BY(d.DEP_NAME)
				  ORDER BY e.SALARY DESC) AS "Difference Btx Current/Prev Salaries"
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID;

#W6 — Compare each employee with the next employee: Same basic setup as W5, but use LEAD().
#Return the next employee's salary and the difference.

SELECT CONCAT(e.F_NAME,' ', e.L_NAME) AS "Employee", d.DEP_NAME, e.SALARY,
	   LEAD(e.SALARY) OVER(
       PARTITION BY(d.DEP_NAME)
       ORDER BY e.SALARY DESC) AS "Next Employee's Salary",
       e.SALARY - LEAD(e.SALARY) OVER(
				  PARTITION BY(d.DEP_NAME)
                  ORDER BY e.SALARY DESC) AS "Difference Btx Current/Next Salaries"
FROM employees e
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID;



#LEVEL 3 — MORE COMPLICATED WINDOWS
#-----------------------------------

#W7 — Employees above their department's average
#Return only employees whose salary is greater than their department's average salary.
#Use a window function to calculate the department average.
#You cannot simply put a window function in WHERE.
#Figure out what SQL structure lets you calculate the window value first and then filter it.
#Do not use a CTE for this exercise.

SELECT *
FROM(SELECT e.EMP_ID,
			e.SALARY,
		    AVG(e.SALARY) OVER(
		    PARTITION BY e.DEP_ID)AS "Dept Avg Salary"
	 FROM employees e) AS deptavg
WHERE deptavg.SALARY > deptavg.`Dept Avg Salary`
;

#W8 — Top three salaries in every department
#Return employees whose salary is among the three highest salaries in their department.
#Use a window ranking function.
#Think carefully about ROW_NUMBER(), RANK(), and DENSE_RANK(), especially with tied salaries.

SELECT *
FROM (SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS 'Employee', e.EMP_ID, d.DEP_NAME, e.SALARY,
		    RANK() OVER(
			PARTITION BY e.DEP_ID
            ORDER BY e.SALARY DESC) AS 'Salary Rank by Dept'
	 FROM employees e
     LEFT JOIN departments d
     ON d.DEPT_ID_DEP = e.DEP_ID) AS Ranked
WHERE `Salary Rank by Dept` <=3
;



#W9 — Percent of department payroll
#For every employee, calculate: employee salary / total department salary
#Return it as a percentage.
#Use a windowed SUM().

SELECT `Employee`, `Employee ID`, `Dept Name`,
	   ROUND((SALARY / `Total Dept Salary`)* 100, 2) AS 'Percent of Dept Payroll'
FROM(SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS 'Employee', e.EMP_ID AS 'Employee ID', e.SALARY,
		   d.DEP_NAME AS 'Dept Name',
		   SUM(e.SALARY) OVER(
		   PARTITION BY e.DEP_ID) AS 'Total Dept Salary'
	 FROM employees e
     LEFT JOIN departments d
     ON d.DEPT_ID_DEP = e.DEP_ID) Total
;

#LEVEL 4 — WINDOW FRAMES
#-----------------------

#W10 — Three-employee moving average: Within each department, order employees by salary.
#Calculate the average of: the current employee, the employee immediately before, the employee immediately after
#Use an explicit frame such as: ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
#Observe what happens to the first and last rows.

SELECT *, 
	   AVG(SALARY) OVER(
       PARTITION BY DEP_ID
       ORDER BY SALARY DESC
       ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS 'Rolling 3 Emp Avg Salary'
	FROM 
		(SELECT EMP_ID, DEP_ID, SALARY#,
			    #LAG(EMP_ID) OVER(								# LAG() and LEAD() here are
				#PARTITION BY DEP_ID								# unnecessary here, purely to 'see if i can'
				#ORDER BY SALARY DESC) AS 'Employee Before',		# also verify why/when only really 2 emp
				#LEAD(EMP_ID) OVER(
				#PARTITION BY DEP_ID
				#ORDER BY SALARY DESC) AS 'Employee After'
		 FROM employees) AS emp_bef_aft
;


#W11 — Running average
#Calculate a running average salary within each department.

#Example:
#70,000 -> 70,000
#65,000 -> 67,500
#65,000 -> 66,666.67

#Use an explicit frame.
#Make sure UNBOUNDED PRECEDING has a concrete meaning to you.

SELECT EMP_ID, DEP_ID, SALARY,
	   AVG(SALARY) OVER(
       PARTITION BY DEP_ID
#       ORDER BY SALARY DESC
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 'Salary Running Avg.'
FROM employees;




#W12 — Salary relative to department extremes
#For every employee, return: salary, highest salary in department, lowest salary in department, difference from highest
#difference from lowest
#Use windowed MAX() and MIN().

SELECT *,
	   (`Dept. Highest Salary` - SALARY) AS 'Difference From Highest',
       (SALARY - `Dept. Lowest Salary`) AS 'Difference From Lowest'
FROM
	(SELECT EMP_ID, DEP_ID, SALARY,
			MAX(SALARY) OVER(
			PARTITION BY DEP_ID) AS 'Dept. Highest Salary',
			MIN(SALARY) OVER(
			PARTITION BY DEP_ID) AS 'Dept. Lowest Salary'
	 FROM employees) AS min_max_sal
;



#LEVEL 5 — ADVANCED WINDOW FUNCTIONS
#-----------------------------------

#W13 — Find the second-highest salary per department
#Return the employee(s) who have the second-highest salary in their department.
#The solution must correctly handle ties.
#Do not simply sort everything and take row 2.

SELECT EMP_ID, CONCAT(F_NAME, ' ', L_NAME)AS 'Employee with 2nd Highest Salary in Dept', d.DEP_NAME AS 'Dept. Name'
FROM (SELECT *,
	  RANK() OVER(
      PARTITION BY DEP_ID
      ORDER BY SALARY DESC) AS 'Dept. Salary Rank'
      FROM employees) AS salrank
LEFT JOIN departments d
ON d.DEPT_ID_DEP = salrank.DEP_ID
WHERE `Dept. Salary Rank` = 2
;


#W14 — Salary quartile within department
#Divide employees in each department into four salary groups:
#1 = lowest quarter, 2 = second quarter, 3 = third quarter, 4 = highest quarter
#Use NTILE(4).

SELECT EMP_ID, DEP_ID, SALARY,
	   NTILE(4) OVER(
       PARTITION BY DEP_ID
       ORDER BY SALARY) AS `Salary Group`
FROM employees;


#W15 — Employees whose salary increased relative to the previous salary
#Within each department, order employees by salary from lowest to highest.
#Using LAG(), return employees whose salary is greater than the salary of the employee immediately preceding them in that salary order.
#Add a column showing the percentage difference between their salary and the previous salary.
#Combine: LAG(), arithmetic, PARTITION BY, ORDER BY

SELECT EMP_ID, DEP_ID, SALARY, `Prev Salary`, ROUND(((SALARY/`Prev Salary`)-1)* 100, 2) AS `Pct Over Last Lowest Salary`
FROM (SELECT *,
	  LAG(SALARY) OVER(
      PARTITION BY DEP_ID
      ORDER BY SALARY) AS `Prev Salary`
	  FROM EMPLOYEES) lagged
WHERE SALARY > `Prev Salary`
;



#W16 — Multiple windows in one query
#For every employee, return: employee, department, salary, department average, department maximum, salary rank,
#percentage of department payroll, running payroll total
#This is your first realistic multi-window analytical query.

SELECT EMP_ID, DEP_ID, SALARY,
	   AVG(SALARY) OVER(
       PARTITION BY DEP_ID) AS `Dept Average Salary`,
       MAX(SALARY) OVER(
       PARTITION BY DEP_ID) AS `Dept Max Salary`,
       RANK() OVER(
       PARTITION BY DEP_ID
       ORDER BY SALARY DESC) AS `Salary Rank by Dept`,
       ROUND((SALARY / 
			(SUM(SALARY) OVER(
            PARTITION BY DEP_ID)))*100, 2) AS `Pct of Dept Payroll`,
	   SUM(SALARY) OVER(
       PARTITION BY DEP_ID
       ORDER BY SALARY DESC
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS `Dept. Salary Running Total`
FROM employees;