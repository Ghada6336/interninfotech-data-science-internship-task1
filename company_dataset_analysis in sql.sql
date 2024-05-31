

--1. Retrieve the first name and last name of all employees.
select first_name , last_name from company..Employees$ 

--2.Find the department numbers and names.
select * from company..departments$

--3. Get the total number of employees.
select count(emp_no) from company..Employees$

--4. Find the average salary of all employees.
select AVG(salary) from company..salaries$

--5. Retrieve the birth date and hire date of employee with emp_no 10003.
select birth_date , hire_date
from company..Employees$
where emp_no = 10003

--6. Find the titles of all employees.
select title from company..employee_titles$

select t.title , b.first_name , b.last_name
from company..employee_titles$ t
join company..Employees$  b
on b.emp_no=t.emp_no

--7. Get the total number of departments.
select COUNT(dep_no) from company..departments$

--8. Retrieve the department number and name where employee with emp_no 10004 works.
select b.dep_name  , t.emp_no
from company..dept_emp$ t
join company..departments$  b
on b.dep_no=t.dept_no
where t.emp_no=10004

--9. Find the gender of employee with emp_no 10007.
select emp_no , gender from company..Employees$
where emp_no = 10007

--10. Get the highest salary among all employees.
select MAX(salary) from company..salaries$

--11. Retrieve the names of all managers along with their department names.
select a.first_name , a.last_name 
from company..employee_titles$ t
join company..Employees$ a
on a.emp_no=t.emp_no
where t.title= 'Manager';

--12. Find the department with the highest number of employees.
--//need to recheck it 
SELECT COUNT(DISTINCT a.emp_no) AS [Number of records], t.dep_name
FROM company..dept_emp$ a
JOIN company..departments$ t
ON a.dept_no = t.dep_no
GROUP BY t.dep_name;

--13. Retrieve the employee number, first name, last name, and salary of employees earning more than $60,000.
select a.emp_no , b.first_name ,b.last_name , a.salary
from company..salaries$ a
join company..Employees$ b
on a.emp_no = b.emp_no
where a.salary > 60000

--14. Get the average salary for each department.
SELECT AVG(a.salary) AS avg_salary, b.dept_no, c.dep_name
FROM company..salaries$ a
JOIN company..dept_emp$ b ON a.emp_no = b.emp_no
JOIN company..departments$ c ON b.dept_no = c.dep_no
GROUP BY b.dept_no, c.dep_name;

--15. Retrieve the employee number, first name, last name, and title of all employees who are currently managers.
select a.emp_no , a.first_name , a.last_name 
from company..Employees$ a
join company..employee_titles$ b on a.emp_no = b.emp_no
where b.title= 'Manager'

--16. Find the total number of employees in each department.
select b.title , count(a.emp_no) 
from company..Employees$ a
join company..employee_titles$ b on a.emp_no = b.emp_no
group by b.title

--17. Retrieve the department number and name where the most recently hired employee works.
--//need to recheck it //I have checked it 
SELECT c.dep_no AS department_number, c.dep_name AS department_name, a.hire_date
FROM company..Employees$ a
JOIN company..dept_emp$ b ON a.emp_no = b.emp_no
JOIN company..departments$ c ON b.dept_no = c.dep_no
WHERE a.hire_date = (
    SELECT min(hire_date)
    FROM company..Employees$
)


--18. Get the department number, name, and average salary for departments with more than 3 employees.
SELECT c.dep_no AS department_number, 
       c.dep_name AS department_name, 
       AVG(a.salary) AS average_salary
FROM company..salaries$ a
JOIN company..dept_emp$ b ON a.emp_no = b.emp_no
JOIN company..departments$ c ON b.dept_no = c.dep_no
GROUP BY c.dep_no, c.dep_name
HAVING COUNT(b.emp_no) > 3;

--19. Retrieve the employee number, first name, last name, and title of all employees hired in 2005.
select a.emp_no , a.first_name , a.last_name  , b.title
from company..Employees$ a
join company..employee_titles$ b on a.emp_no = b.emp_no
WHERE YEAR(a.hire_date) = 2005;

--20. Find the department with the highest average salary.
SELECT TOP 1
c.dep_no AS department_number, 
       c.dep_name AS department_name, 
       AVG(a.salary) AS avg_salary
FROM company..salaries$ a
JOIN company..dept_emp$ b ON a.emp_no = b.emp_no
JOIN company..departments$ c ON b.dept_no = c.dep_no
GROUP BY c.dep_no, c.dep_name
ORDER BY avg_salary DESC;

--21. Retrieve the employee number, first name, last name, and salary of employees hired before the year 2005.
select a.emp_no , a.first_name , a.last_name  , b.salary
from company..Employees$ a
join company..salaries$ b on a.emp_no = b.emp_no
WHERE YEAR(a.hire_date) < 2005;

--22. Get the department number, name, and total number of employees for departments with a female manager.
-- //need to recheck it [give empty value]
SELECT c.dept_no, d.dep_name, COUNT( a.emp_no) AS Total_number
FROM company..Employees$ a
JOIN company..employee_titles$ b ON a.emp_no = b.emp_no
JOIN company..dept_emp$ c ON a.emp_no = c.emp_no
JOIN company..departments$ d ON c.dept_no = d.dep_no
WHERE a.gender = 'F' and  b.title = 'Manager' 
GROUP BY c.dept_no, d.dep_name;

--23. Retrieve the employee number, first name, last name, and department name of employees who are currently working in the Finance department.
SELECT distinct(a.emp_no), a.first_name, a.last_name, d.dep_name
FROM company..Employees$ a
JOIN company..employee_titles$ b ON a.emp_no = b.emp_no
JOIN company..dept_emp$ c ON a.emp_no = c.emp_no
JOIN company..departments$ d ON c.dept_no = d.dep_no
WHERE d.dep_name='Finance'


--24. Find the employee with the highest salary in each department.
--this didn't work 
select top 1
       a.first_name,a.last_name
from company..Employees$ a
join company..salaries$ b on a.emp_no=b.emp_no
join company..dept_emp$ d  on b.emp_no=d.emp_no
join company..departments$ c on c.dep_no= d.dept_no
group by  a.first_name,a.last_name ,c.dep_name;
----------------------------------------------------------------
-----------------------------------------------------------------
--//this worked
WITH RankedSalaries AS (
    SELECT 
        a.emp_no,
        a.first_name,
        a.last_name,
        c.dep_no,
        c.dep_name,
        b.salary,
        ROW_NUMBER() OVER (PARTITION BY c.dep_no ORDER BY b.salary DESC) AS rn
    FROM company..Employees$ a
    JOIN company..salaries$ b ON a.emp_no = b.emp_no
    JOIN company..dept_emp$ d ON a.emp_no = d.emp_no
    JOIN company..departments$ c ON d.dept_no = c.dep_no
)
SELECT 
    emp_no,
    first_name,
    last_name,
    dep_no,
    dep_name,
    salary
FROM RankedSalaries
WHERE rn = 1;

-------------------------------------------------------------------------------------------------------
--25. Retrieve the employee number, first name, last name, and department name of employees who have held a managerial position.
SELECT DISTINCT a.emp_no, a.first_name, a.last_name, d.dep_name
FROM company..Employees$ a
JOIN company..employee_titles$ b ON a.emp_no = b.emp_no
JOIN company..dept_emp$ c ON a.emp_no = c.emp_no
JOIN company..departments$ d ON c.dept_no = d.dep_no
WHERE b.title LIKE '%Manager%';

--26. Get the total number of employees who have held the title "Senior Manager."
SELECT COUNT(emp_no) AS total_senior_managers
FROM company..employee_titles$
WHERE title = 'Senior Manager';

--27. Retrieve the department number, name, and the number of employees who have worked there for more than 5 years.
SELECT a.dept_no, b.dep_name, 
       DATEDIFF(year, a.from_date, GETDATE()) AS employment_period_in_years
FROM company..dept_emp$ a
JOIN company..departments$ b ON a.dept_no = b.dep_no
WHERE DATEDIFF(year, a.from_date, GETDATE()) > 5;

--28. Find the employee with the longest tenure in the company.
SELECT top 1
    emp_no,
    first_name,
    last_name,
    hire_date,
    DATEDIFF(year, hire_date, GETDATE()) AS tenure_in_years
FROM 
    company..Employees$;

--29. Retrieve the employee number, first name, last name, and title of employees whose hire date is between '2005-01-01' and '2006-01-01'.
SELECT a.emp_no, a.first_name, a.last_name, c.dep_name
FROM company..Employees$ a
join company..dept_emp$ b on a.emp_no=b.emp_no
JOIN company..departments$ c on b.dept_no=c.dep_no
WHERE a.hire_date between '2005-01-01' and '2006-01-01'

--30. Get the department number, name, and the oldest employee's birth date for each department.
SELECT d.dep_no, 
       d.dep_name, 
       MIN(e.birth_date) AS oldest_birth_date
FROM company..dept_emp$ de
JOIN company..Employees$ e ON de.emp_no = e.emp_no
JOIN company..departments$ d ON de.dept_no = d.dep_no
GROUP BY d.dep_no, d.dep_name;