SELECT empl_id, YEAR(FROM_DAYS(DATEDIFF(current_date, start_date))) AS Years_of_Service,
		(SELECT AVG(YEAR(FROM_DAYS(DATEDIFF(current_date, start_date))))
		FROM job_history) AS Avg_Years_of_Service
FROM job_history
;
select *
FROM job_history;
SELECT *
FROM employees;
SELECT *
FROM departments;
SELECT *
FROM locations;
select *
FROM jobs;