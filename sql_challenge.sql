show databases;
create database Date28092026;
use Date28092026;
show schemas;


/*--------TABLE Employees -------*/
CREATE TABLE Employees (
  emp_id INTEGER PRIMARY KEY, name TEXT, dept TEXT,
  salary INTEGER, hire_date TEXT, mgr_id INTEGER
);

INSERT INTO Employees VALUES
(1,'Arjun','Sales',120000,'2020-01-15',NULL),
(2,'Priya','Sales',95000,'2020-06-01',1),
(3,'Rahul','Sales',95000,'2021-03-10',1),
(4,'Kiran','Sales',72000,'2022-08-20',2),
(5,'Divya','Sales',68000,'2023-01-05',2),
(6,'Sneha','Tech',150000,'2019-05-11',NULL),
(7,'Vikram','Tech',135000,'2020-02-17',6),
(8,'Meera','Tech',135000,'2021-07-30',6),
(9,'Ravi','Tech',110000,'2022-11-14',7),
(10,'Tara','Tech',88000,'2023-04-22',7),
(11,'Aman','HR',90000,'2021-09-09',NULL),
(12,'Zoya','HR',75000,'2022-02-28',11);

select * from Employees;

/*--------TABLE Sales -------*/
CREATE TABLE Sales (
  sale_id INTEGER PRIMARY KEY, emp_id INTEGER,
  sale_date TEXT, region TEXT, amount REAL
);

INSERT INTO Sales VALUES
(1,2,'2024-01-05','North',12000),(2,2,'2024-01-20','North',8000),
(3,3,'2024-01-11','South',15000),(4,3,'2024-02-14','South',9000),
(5,4,'2024-02-03','North',5000),(6,4,'2024-03-18','East',7000),
(7,5,'2024-03-02','South',11000),(8,2,'2024-03-25','North',14000),
(9,3,'2024-04-08','South',6000),(10,5,'2024-04-19','East',18000),
(11,2,'2024-05-06','North',9500),(12,4,'2024-05-21','North',4500),
(13,3,'2024-06-02','South',22000),(14,5,'2024-06-27','East',13000),
(15,2,'2024-07-14','North',16000);

select * from Sales;

/*--------TABLE Sales -------*/
CREATE TABLE Products (product_id INTEGER, category TEXT, price REAL, launch_date TEXT);

INSERT INTO Products VALUES
(1,'Laptop',85000,'2023-01-10'),(2,'Laptop',65000,'2023-06-15'),
(3,'Phone',45000,'2023-02-20'),(4,'Phone',32000,'2024-01-08'),
(5,'Phone',28000,'2024-03-12'),(6,'Tablet',38000,'2023-09-01'),
(7,'Tablet',22000,'2024-02-14'),(8,'Monitor',18000,'2023-11-05');

select * from Products;

/*Q1 — Salary Ranking With Ties
For every employee, return their department, name, salary, their salary rank within the department, 
and how far below the department's top earner they sit. 
Employees on identical salaries must share the same rank without skipping the next number.*/
SELECT
    dept,
    name,
    salary,

    DENSE_RANK() OVER (
        PARTITION BY dept
        ORDER BY salary DESC
    ) AS salary_rank,

    MAX(salary) OVER (
        PARTITION BY dept
    ) - salary AS below_top_salary

FROM Employees
ORDER BY dept, salary_rank, name;

/*Q2 — Month-Over-Month Growth
Return total sales for each month, alongside the previous month's total and the percentage change between them. 
The first month has no prior month — handle that sensibly rather than letting it error or show a misleading zero.*/
WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m') AS month,
        SUM(amount) AS total_sales
    FROM Sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),

sales_with_previous AS
(
    SELECT
        month,
        total_sales,

        LAG(total_sales) OVER (
            ORDER BY month
        ) AS previous_month_sales

    FROM monthly_sales
)

SELECT
    month,
    total_sales,
    previous_month_sales,

    CASE
        WHEN previous_month_sales IS NULL THEN NULL
        ELSE ROUND(
            (total_sales - previous_month_sales)
            * 100.0 / previous_month_sales,
            2
        )
    END AS percentage_change

FROM sales_with_previous

ORDER BY month;


/*Q3 — Top Performer Per Region
Identify the highest-selling employee in each region, by total sales value. 
If two people tie for first in a region, both must appear. */
WITH employee_region_sales AS
(
    SELECT
        s.region,
        e.emp_id,
        e.name,
        SUM(s.amount) AS total_sales

    FROM Sales s

    INNER JOIN Employees e
        ON s.emp_id = e.emp_id

    GROUP BY
        s.region,
        e.emp_id,
        e.name
),

ranked_sales AS
(
    SELECT
        region,
        emp_id,
        name,
        total_sales,

        DENSE_RANK() OVER (
            PARTITION BY region
            ORDER BY total_sales DESC
        ) AS sales_rank

    FROM employee_region_sales
)

SELECT
    region,
    emp_id,
    name,
    total_sales

FROM ranked_sales

WHERE sales_rank = 1

ORDER BY region, name;

/*Q4 — Employees With No Sales
List every employee who has never recorded a sale, including their department. 
Your query must not drop anyone simply because they belong to a department that does no selling */
SELECT
    e.emp_id,
    e.name,
    e.dept

FROM Employees e

LEFT JOIN Sales s
    ON e.emp_id = s.emp_id

WHERE s.emp_id IS NULL

ORDER BY e.emp_id;

/*Q5 — Management Hierarchy Depth
Using a recursive query, determine how many levels deep the reporting structure goes. 
For each level, return the level number, how many employees sit at it, and their names. */
WITH RECURSIVE hierarchy AS
(
    -- Starting level: employees who have no manager
    SELECT
        emp_id,
        name,
        mgr_id,
        0 AS level

    FROM Employees

    WHERE mgr_id IS NULL

    UNION ALL

    -- Find employees reporting to the previous level
    SELECT
        e.emp_id,
        e.name,
        e.mgr_id,
        h.level + 1

    FROM Employees e

    INNER JOIN hierarchy h
        ON e.mgr_id = h.emp_id
)

SELECT
    level,
    COUNT(*) AS employee_count,
    GROUP_CONCAT(
        name
        ORDER BY name
        SEPARATOR ', '
    ) AS names

FROM hierarchy

GROUP BY level

ORDER BY level;

/*Q6 — Products Against Category Average
For every product, return its category, price, the average price of its category, 
and how far above or below that average it sits as a percentage. Do not use a correlated subquery */
SELECT
    product_id,
    category,
    price,

    ROUND(
        AVG(price) OVER (
            PARTITION BY category
        ),
        2
    ) AS category_average,

    ROUND(
        (
            price
            - AVG(price) OVER (
                PARTITION BY category
            )
        )
        * 100.0
        /
        AVG(price) OVER (
            PARTITION BY category
        ),
        2
    ) AS percentage_vs_average

FROM Products

ORDER BY product_id;

/*Q7 — Running Total and Moving Average
For a single named employee, list each of their sales in date order with a running cumulative total and 
a 3-sale moving average. State in a comment what the moving average shows that the running total does not. */
SELECT
    s.sale_id,
    e.name,
    s.sale_date,
    s.amount,

    SUM(s.amount) OVER (
        ORDER BY s.sale_date, s.sale_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,

    ROUND(
        AVG(s.amount) OVER (
            ORDER BY s.sale_date, s.sale_id
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_average_3

FROM Sales s

INNER JOIN Employees e
    ON s.emp_id = e.emp_id

WHERE e.name = 'Priya'

ORDER BY s.sale_date, s.sale_id;

/*Q8 — Tenure Bands
Group employees into three tenure bands based on hire date — before 2021, 2021 to 2022, and 2023 onward. 
For each band return the headcount and average salary, sorted from highest average salary down. */
WITH tenure_bands AS
(
    SELECT
        emp_id,
        name,
        salary,
        hire_date,

        CASE
            WHEN hire_date < '2021-01-01'
                THEN 'Before 2021'

            WHEN hire_date < '2023-01-01'
                THEN '2021 to 2022'

            ELSE '2023 onward'
        END AS tenure_band

    FROM Employees
)

SELECT
    tenure_band,
    COUNT(*) AS headcount,
    ROUND(AVG(salary), 2) AS average_salary

FROM tenure_bands

GROUP BY tenure_band

ORDER BY average_salary DESC;