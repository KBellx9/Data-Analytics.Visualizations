WITH tenure_cte AS(
	SELECT empl_id, YEAR(FROM_DAYS(DATEDIFF(current_date, start_date))) AS Years_of_Service,
	(SELECT AVG(YEAR(FROM_DAYS(DATEDIFF(current_date, start_date))))
	FROM job_history) AS Avg_Years_of_Service
FROM job_history)

SELECT empl_id, Years_of_Service
FROM tenure_cte;

SELECT e.EMP_ID, e.F_NAME, e.L_NAME, jh.Start_Date ,
	   d.Dep_Name,
       j.Job_Title
FROM employees e
LEFT JOIN job_history jh
ON jh.empl_id = e.emp_id
LEFT JOIN jobs j
ON j.JOB_IDENT = jh.JOBS_ID
LEFT JOIN departments d
ON d.DEPT_ID_DEP = e.DEP_ID;

#Exercise 1: Create a CTE containing; employee id, first name, last name, salary, department id
#Then, from that CTE, display only employees earning over 70,000.

WITH salary_cte AS(
	SELECT EMP_ID, F_NAME, L_NAME, SALARY, DEP_ID
    FROM employees)

SELECT *
FROM salary_cte
WHERE SALARY > 70000
;

#Exercise 2: Create a CTE that joins employees and departments, and contains employee name, department name, salary
#Then query the CTE to show only employees in the Software Group

WITH soft_cte AS(
	SELECT e.F_NAME, e.L_NAME, e.SALARY,
		   d.DEP_NAME
	FROM employees e
    LEFT JOIN departments d
    ON d.DEPT_ID_DEP = e.DEP_ID)
SELECT *
FROM soft_cte
WHERE DEP_NAME = 'Software Group'
;


#LEVEL 1 — BASIC CTEs
#--------------------

#C1 — Employees above a salary threshold
#Create a CTE called high_earners containing employees earning more than $60,000.
#Then query the CTE and return: employee name, salary, department

WITH high_earners AS(
	SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) as 'Employee Name', e.SALARY,
		   d.DEP_NAME AS 'Department'
	FROM employees e
    LEFT JOIN departments d
    ON d.DEPT_ID_DEP = e.DEP_ID
	WHERE e.SALARY > 60000)

SELECT `Employee Name`, SALARY, Department
FROM high_earners;


#C2 — Department salary totals
#Create a CTE calculating total salary for each department.
#Then use the CTE to return departments whose total payroll exceeds $150,000.
#Separate: 1. calculation, 2. filtering

with dept_sal AS(
	SELECT d.DEP_NAME,
		   SUM(e.SALARY) OVER(
		   PARTITION BY(e.DEP_ID)) AS 'Dept Total Salary'
    FROM departments d
    LEFT JOIN employees e
    ON e.DEP_ID = d.DEPT_ID_DEP)
SELECT DISTINCT(DEP_NAME), `Dept Total Salary`
FROM dept_sal
WHERE `Dept Total Salary` > 150000;

# OR

with dept_sal AS(
	SELECT d.DEP_NAME,
		   SUM(e.SALARY) AS 'Dept Total Salary'
    FROM departments d
    LEFT JOIN employees e
		ON e.DEP_ID = d.DEPT_ID_DEP
    GROUP BY d.DEP_NAME)
SELECT DEP_NAME, `Dept Total Salary`
FROM dept_sal
WHERE `Dept Total Salary` > 150000;


#C3 — Employees above department average
#Create a CTE containing: employee, department, salary, department average salary
#Then use the outer query to return only employees whose salary exceeds that average.
#This is an important bridge between aggregation and CTEs.

with dept_avg_sal AS(
	SELECT CONCAT(e.F_NAME, ' ', e.L_NAME) AS 'Employee', d.DEP_NAME, e.SALARY, 
    ROUND(AVG(e.SALARY) OVER(
    PARTITION BY e.DEP_ID), 2) AS 'Dept Avg Salary'
	FROM employees e
    LEFT JOIN departments d
		ON d.DEPT_ID_DEP = e.DEP_ID)
SELECT *
FROM dept_avg_sal das
WHERE das.SALARY > das.`Dept Avg Salary`;



#LEVEL 2 — MULTIPLE CTEs
#-----------------------

#C4 — Two-stage payroll analysis
#CTE #1: total payroll per department.
#CTE #2: average department payroll across all departments.
#Return departments whose payroll is above the overall department average.
#Conceptual flow: employee data -> department totals -> overall average -> final result

WITH tot_pay_dept AS(
	SELECT d.DEP_NAME,
		   SUM(e.SALARY) AS `Total Payroll per Dept`
	FROM employees e
    LEFT JOIN departments d
    ON d.DEPT_ID_DEP = e.DEP_ID
    GROUP BY d.DEP_NAME),
    
	 avg_dept_payroll AS(
	SELECT AVG(`Total Payroll per Dept`) AS `Average Dept Payroll`
	FROM tot_pay_dept totsal)
    
SELECT DEP_NAME AS 'Department', 
		CASE
			WHEN totpay.`Total Payroll per Dept` > 
				(SELECT `Average Dept Payroll`
				FROM avg_dept_payroll)
			THEN 'Above Average'
            WHEN totpay.`Total Payroll per Dept` =
				(SELECT `Average Dept Payroll`
				FROM avg_dept_payroll)
			THEN 'Average'
            ELSE 'Below Average'
		END AS "Relation to Average"
FROM tot_pay_dept totpay
;

#C5 — Department headcount and payroll
#Create one CTE containing: department, employee count, total payroll
#In the outer query calculate: average salary = total payroll / employee count
#Sort departments highest average salary to lowest.

WITH total_payroll AS(
	SELECT d.DEP_NAME, COUNT(e.EMP_ID) AS 'Employee Count', SUM(e.SALARY) AS 'Total Payroll'
	FROM employees e
    LEFT JOIN departments d
    ON d.DEPT_ID_DEP = e.DEP_ID
    GROUP BY d.DEP_NAME)

SELECT DEP_NAME, `Employee Count`, `Total Payroll`, (`Total Payroll` / `Employee Count`) AS "Average Salary"
FROM total_payroll
ORDER BY `Average Salary` DESC
;
    
#C6 — Three-stage analysis
#Build three CTEs: department payroll, department average salary, employees whose salary exceeds their department average
#Return the final employees.
#Practice breaking a problem into logical stages.

WITH dep_payroll AS(
		SELECT e.DEP_ID, d.DEP_NAME, SUM(e.SALARY) AS "Department Payroll"
		FROM employees e
		LEFT JOIN departments d
		ON d.DEPT_ID_DEP = e.DEP_ID
		GROUP BY d.DEP_NAME, e.DEP_ID
    ),
    dep_avg_sal AS(
		SELECT e.DEP_ID, d.DEP_NAME, (SUM(e.SALARY) / COUNT(e.EMP_ID)) AS "Dept Avg Salary"
		FROM employees e
		LEFT JOIN departments d
		ON d.DEPT_ID_DEP = e.DEP_ID
		GROUP BY e.DEP_ID, d.DEP_NAME
    ),
	emp_over_avg AS(
		SELECT e.EMP_ID
		FROM employees e
        LEFT JOIN dep_avg_sal das
        ON das.DEP_ID = e.DEP_ID
		WHERE e.SALARY > das.`Dept Avg Salary`
    )
SELECT EMP_ID AS 'Employee Salary Above Dept Average'
FROM emp_over_avg;


#LEVEL 3 — CTE + WINDOW FUNCTIONS
#--------------------------------

#C7 — Top 2 employees per department
#Inside the CTE, calculate each employee's salary rank within their department.
#Outer query: return only ranks 1 and 2.
#Pattern: CTE -> window function -> filter window result

WITH sal_rank AS(
	SELECT CONCAT(e.F_NAME,' ', e.L_NAME) AS 'Employee', d.DEP_NAME, e.SALARY,
		   RANK() OVER(
           PARTITION BY e.DEP_ID
           ORDER BY e.SALARY DESC) AS 'Dept. Salary Rank'
	FROM employees e
    LEFT JOIN departments d
    ON d.DEPT_ID_DEP = e.DEP_ID)
SELECT `Employee`, DEP_NAME AS 'Dept. Name', `Dept. Salary Rank`
FROM sal_rank
WHERE `Dept. Salary Rank` < 3
;

#C8 — Employees above department average
#Inside the CTE, calculate: salary, department average, difference from department average
#Outer query returns employees whose difference is positive.
#Add percentage_above_average.

WITH diff AS(
	SELECT EMP_ID, SALARY, `Dept Avg`, (SALARY - `Dept Avg`) AS 'Difference from Dept. Avg.'
    FROM (SELECT e.EMP_ID, e.SALARY,
				 AVG(e.SALARY) OVER(
				 PARTITION BY e.DEP_ID) AS 'Dept Avg'
		  FROM employees e) dept_avg
	)
SELECT EMP_ID, ROUND((((SALARY / `Dept Avg`) - 1) * 100), 2) AS 'Percentage Above Average',
	   CASE
		   WHEN `Difference from Dept. Avg.` > 0
           THEN 'Above Average'
           
           WHEN `Difference from Dept. Avg.` < 0
           THEN 'Below Average'
           
           ELSE 'Average'
	   END AS 'Salary Compared to Dept. Avg.'
FROM diff
WHERE `Difference from Dept. Avg.` > 0
;




#C9 — Department salary distribution
#Inside a CTE, calculate for every employee: salary, department total payroll, percentage of department payroll, salary rank
#Outer query returns employees who: rank in the top 3 OR account for at least 20% of department payroll.

WITH pay_stats AS(
	SELECT EMP_ID, DEP_ID, d.DEP_NAME AS 'Department', SALARY, `Dept. Total Payroll`, 
		   (SALARY / `Dept. Total Payroll`) * 100 AS `Pct of Dept Payroll`,
		   RANK() OVER(
           PARTITION BY DEP_ID
           ORDER BY SALARY DESC) AS 'Salary Rank'
	FROM
		(SELECT e.EMP_ID, e.SALARY, e.DEP_ID,
				SUM(e.SALARY) OVER(
                PARTITION BY e.DEP_ID) AS 'Dept. Total Payroll'
		 FROM employees e) AS dept_tot_pay
	LEFT JOIN departments d
    ON d.DEPT_ID_DEP = DEP_ID)

SELECT EMP_ID, `Department`, SALARY, `Dept. Total Payroll`, `Pct of Dept Payroll`, `Salary Rank`
FROM pay_stats
WHERE `Salary Rank` <= 3 OR `Pct of Dept Payroll` > 20
;




#LEVEL 4 — ADVANCED CTEs
#-----------------------

#C10 — Highest-paid employee(s) in each department
#Build a CTE that calculates maximum salary per department.
#Then return all employees tied for the highest salary.
#Do not use LIMIT 1.

WITH maxsal AS(
	SELECT DEP_ID, MAX(SALARY) AS `Max Salary`
	FROM employees
	GROUP BY DEP_ID)

SELECT e.EMP_ID, ms.DEP_ID, ms.`Max Salary`
FROM employees e
INNER JOIN maxsal ms
ON e.DEP_ID = ms.DEP_ID
WHERE e.SALARY = ms.`Max Salary`
;


#C11 — Department comparison
#Build CTEs calculating: Total payroll per department, Average payroll across departments, 
#Difference between each department's payroll and the overall average
#Return: department, payroll, overall average, difference, percentage above/below average

WITH dept_pay AS(
	SELECT DEP_ID, SUM(SALARY) AS `Dept Total Payroll`
	FROM employees
	GROUP BY DEP_ID),

	 avg_sal AS(
	SELECT AVG(`Dept Total Payroll`) AS `Avg of Dept Salaries`
	FROM dept_pay),

	 diff AS(
	SELECT dept_pay.DEP_ID, 
		   (dept_pay.`Dept Total Payroll` - avg_sal.`Avg of Dept Salaries` ) AS `Difference From Overall Avg`
	FROM dept_pay
    CROSS JOIN avg_sal)

SELECT diff.DEP_ID, dept_pay.`Dept Total Payroll`, avg_sal.`Avg of Dept Salaries`, diff.`Difference From Overall Avg`,
	   (diff.`Difference From Overall Avg` / avg_sal.`Avg of Dept Salaries`) AS `% Above/Below Avg`
FROM diff
INNER JOIN dept_pay
ON dept_pay.DEP_ID = diff.DEP_ID
CROSS JOIN avg_sal;

#C12 — Employees ranked against the entire company
#Create a CTE containing employee salary and department.
#In the outer query calculate: company-wide salary rank, department salary rank
#Return employees who are: Top 3 in their department BUT NOT top 3 company-wide.
#Think about two different window partitions.

WITH sal_dep AS(
	SELECT EMP_ID, SALARY, DEP_ID
	FROM employees)

SELECT * 
FROM   (SELECT EMP_ID, DEP_ID, 
	   RANK() OVER(
       ORDER BY SALARY DESC) AS `Company Salary Rank`,
       RANK() OVER(
       PARTITION BY DEP_ID
       ORDER BY SALARY DESC) AS `Dept Salary Rank`
       FROM sal_dep) rnk

WHERE `Dept Salary Rank` <= 3 AND `Company Salary Rank` > 3
;

#LEVEL 5 — ADVANCED / MULTI-STAGE
#---------------------------------

#C13 — Department ranking
#Build a multi-CTE query: department payroll and headcount, average salary per department, rank departments by average salary
#Final output: department, headcount, payroll, average salary, department rank
#Return only the top three departments.

WITH dep_emp_pay AS(
	 SELECT DEP_ID, COUNT(EMP_ID) AS `Dept. Headcount`, SUM(SALARY) AS `Dept. Payroll`
	 FROM employees
	 GROUP BY DEP_ID),

	 avg_sal_dept AS(
     SELECT dep_emp_pay.DEP_ID, AVG(e.SALARY) AS `Dept. Avg Salary`,
			`Dept. Headcount`, `Dept. Payroll`
     FROM dep_emp_pay
     LEFT JOIN employees e
     ON e.DEP_ID = dep_emp_pay.DEP_ID
     GROUP BY dep_emp_pay.DEP_ID),

	 dept_rank_sal AS(
     SELECT DEP_ID, `Dept. Headcount`, `Dept. Payroll`, `Dept. Avg Salary`,
			RANK() OVER(
            ORDER BY `Dept. Avg Salary` DESC) AS `Dept. Salary Rank`
     FROM avg_sal_dept)

SELECT DEP_ID, `Dept. Headcount`, `Dept. Payroll`, `Dept. Avg Salary`, `Dept. Salary Rank`
FROM dept_rank_sal
WHERE `Dept. Salary Rank` <= 3
;



#C14 — Recursive CTE: numbers
#Create a recursive CTE generating:

#0
#1
#2
#3
#...
#29

#Then modify it to generate:
#1
#3
#5
#7
#...
#29

#Then:
#2
#4
#6
#8
#...
#30

#Understand: anchor query, recursive query, termination condition

WITH RECURSIVE numbers AS (
    SELECT 1 AS n	#anchor member
    UNION ALL		#set operator
    SELECT n + 1 	#recursive member
    FROM numbers 
    WHERE n < 29	#termination condition
)
SELECT n 
FROM numbers;

WITH RECURSIVE numbers AS (
    SELECT 1 AS n	#anchor member
    UNION ALL		#set operator
    SELECT n + 2	#recursive member
    FROM numbers 
    WHERE n < 29	#termination condition
)
SELECT n 
FROM numbers;

WITH RECURSIVE numbers AS (
    SELECT 2 AS n	#anchor member
    UNION ALL		#set operator
    SELECT n + 2 	#recursive member
    FROM numbers 
    WHERE n < 30	#termination condition
)
SELECT n 
FROM numbers;

#C15 — Recursive CTE: employee hierarchy
#Using the employee_hierarchy table, recursively walk down the hierarchy starting with the highest-level employees.
#Return: employee ID, employee name, manager ID, hierarchy level
#Conceptual result:

#CEO              level 0
#  Manager A      level 1
#    Employee A   level 2
#    Employee B   level 2
#  Manager B      level 1
#    Employee C   level 2

#This is a genuinely recursive problem because the data is hierarchical.

SELECT * FROM departments;
SELECT * FROM EMPLOYEES
LEFT JOIN JOBS
ON JOBS.JOB_IDENT = EMPLOYEES.JOB_ID
ORDER BY DEP_ID;










#FINAL CAPSTONE — WINDOW FUNCTIONS + MULTIPLE CTEs
#=================================================

#C16/W17 — Employee compensation analysis

#Build a query producing one row per employee containing:
#- employee name
#- department
#- salary
#- department average salary
#- department maximum salary
#- salary rank within department
#- company-wide salary rank
#- percentage of department payroll
#- cumulative department payroll
#- difference from department average
#- percentage difference from department average

#Use at least one CTE and multiple window functions.
#Then filter to employees who meet BOTH: Top 3 in their department, Salary above their department average