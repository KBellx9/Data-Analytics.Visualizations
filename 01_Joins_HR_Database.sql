SELECT E.f_name, E.l_name, D.dep_name
FROM employees E
LEFT JOIN departments D
ON E.dep_id = D.dept_id_dep
UNION
SELECT E.f_name, E.l_name, D.dep_name
FROM employees E 
RIGHT JOIN departments D
ON E.dep_id = D.dept_id_dep
;

SELECT E.f_name, E.l_name, JH.start_date, J.job_title
FROM employees E
INNER JOIN jobs J
	ON E.job_id = J.job_ident
INNER JOIN job_history JH
	ON J.job_ident = JH.jobs_id
WHERE dept_id = 5
;

select E.F_NAME,E.L_NAME, JH.START_DATE, J.JOB_TITLE 
from EMPLOYEES as E 
INNER JOIN JOB_HISTORY as JH on E.EMP_ID=JH.EMPL_ID 
INNER JOIN JOBS as J on E.JOB_ID=J.JOB_IDENT
where E.DEP_ID ='5';

SELECT E.emp_id, E.l_name, E.dep_id, D.dep_name
FROM employees E
LEFT JOIN departments D
	ON E.dep_id = D.dept_id_dep
AND YEAR(E.b_date) < 1980
;
SELECT E.EMP_ID, E.L_NAME, E.DEP_ID, D.DEP_NAME
FROM EMPLOYEES AS E
LEFT OUTER JOIN DEPARTMENTS AS D
ON E.DEP_ID = D.DEPT_ID_DEP
AND YEAR(E.B_DATE) < 1980;

#Retrieve the first name and last name of all employees but department ID and department names only for male employees.

SELECT E.f_name, E.l_name, D.dept_id_dep, D.dep_name
FROM employees E
LEFT JOIN departments D
	ON E.dep_id = D.dept_id_dep
    AND E.sex = 'M'
;
SELECT E.F_NAME, E.L_NAME, D.DEPT_ID_DEP, D.DEP_NAME
FROM EMPLOYEES AS E
LEFT OUTER JOIN DEPARTMENTS AS D
ON E.DEP_ID=D.DEPT_ID_DEP AND E.SEX = 'M'
UNION
SELECT E.F_NAME, E.L_NAME, D.DEPT_ID_DEP, D.DEP_NAME
from EMPLOYEES AS E
RIGHT OUTER JOIN DEPARTMENTS AS D
ON E.DEP_ID=D.DEPT_ID_DEP AND E.SEX = 'M';