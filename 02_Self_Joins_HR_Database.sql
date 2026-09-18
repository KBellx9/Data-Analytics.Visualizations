#Exercise 1: Employee and Manager
#Display: Employee first name, Employee last name, Manager first name, Manager last name (Include everyone, even the CEO)

SELECT e.first_name AS 'Employee First Name', e.last_name AS 'Employee Last Name',
	   m.first_name AS 'Manager First Name', m.last_name AS 'Manager Last Name'
FROM employee_hierarchy e
LEFT JOIN employee_hierarchy AS m
	ON m.emp_id = e.manager_id
;

	# used this to view entire table after join
SELECT *
FROM employee_hierarchy e
LEFT JOIN employee_hierarchy AS m
	ON m.emp_id = e.manager_id;

#Exercise 2: Number of Direct Reports
#For every manager, display: Manager first name, Manager last name, Number of employees who report directly to them
#Sort from most reports to fewest. (Hint: You'll need a self join and GROUP BY.)
SELECT r.first_name AS 'Manager First Name', r.last_name AS 'Manager Last Name',
       COUNT(m.manager_id) 'Number of Reports'
FROM employee_hierarchy m
LEFT JOIN employee_hierarchy AS r
	ON r.emp_id = m.manager_id
GROUP BY  m.manager_id 
ORDER BY `Number of Reports` DESC
;



#Exercise 3: Employees Who Earn More Than Their Manager
#Display: Employee name, Employee salary, Manager name, Manager salary
#Show only employees whose salary is greater than their manager's.
#This is a classic interview problem because it forces you to think of the same table as representing two different people.
SELECT CONCAT(e.first_name, ' ', e.last_name) AS 'Employee Name',
	   e.SALARY AS 'Employee Salary',
	   CONCAT(m.first_name, ' ', m.last_name) AS 'Manager Name',
	   m.SALARY AS 'Manager Salary'
FROM employee_hierarchy e
LEFT JOIN employee_hierarchy m
ON m.emp_id = e.manager_id
WHERE e.SALARY > m.SALARY
;

#Exercise 4: Two Levels of Management
#Display: Employee, Their manager, Their manager's manager (You'll need to join the same table three times)
SELECT CONCAT(e.first_name, ' ', e.last_name) AS 'Employee Name',
	   CONCAT(m.first_name, ' ', m.last_name) AS 'Manager Name',
       CONCAT(s.first_name, ' ', s.last_name) AS "Manager's Manager's Name"
FROM employee_hierarchy e
LEFT JOIN employee_hierarchy m
ON m.emp_id = e.manager_id
LEFT JOIN employee_hierarchy s
ON s.emp_id = m.manager_id
;