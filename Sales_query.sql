-- USE EntryTest;

-- QUESTION 1:
/* How can you write a SQL query to calculate the total sales of furniture products,
grouped by each quarter of the year, and order the results chronologically? */

SELECT 
    CONCAT('Q', QUARTER(ORDER_DATE), '-', YEAR(ORDER_DATE)) AS QUARTER_YEAR,
    ROUND(SUM(SALES), 2) AS TOTAL_SALES
FROM ORDERS WHERE PRODUCT_ID LIKE 'FUR%' GROUP BY QUARTER_YEAR
ORDER BY SUBSTRING(QUARTER_YEAR, 4, 4) ASC, SUBSTRING(QUARTER_YEAR, 2, 1) ASC;

-- QUESTION 2:
/* How can you analyze the impact of different discount levels on sales performance across product categories, 
specifically looking at the number of orders and total profit generated for each discount classification?

Discount level condition:
No Discount = 0
0 < Low Discount < 0.2
0.2 < Medium Discount < 0.5
High Discount > 0.5 */

SELECT 
    PRODUCT.CATEGORY,
    CASE
		WHEN ORDERS.DISCOUNT =0 THEN 'No Discount'
        WHEN ORDERS.DISCOUNT > 0 AND ORDERS.DISCOUNT < 0.2 THEN 'Low Discount'
        WHEN ORDERS.DISCOUNT >= 0.2 AND ORDERS.DISCOUNT < 0.5 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS DISCOUNT_LEVEL,
    COUNT(ORDERS.ORDER_ID) AS TOTAL_ORDERS, ROUND(SUM(ORDERS.PROFIT), 2) AS TOTAL_PROFIT
FROM ORDERS
JOIN PRODUCT ON PRODUCT.ID = ORDERS.PRODUCT_ID
GROUP BY PRODUCT.CATEGORY, DISCOUNT_LEVEL
ORDER BY PRODUCT.CATEGORY ASC, DISCOUNT_LEVEL ASC;

-- QUESTION 3:
/* How can you determine the top-performing product categories within each customer segment based on sales and profit, 
focusing specifically on those categories that rank within the top two for profitability? */

WITH ranked_products AS (
    SELECT 
        CUSTOMER.SEGMENT,
        PRODUCT.CATEGORY,
        RANK() OVER (PARTITION BY CUSTOMER.SEGMENT ORDER BY SUM(ORDERS.SALES) DESC) AS SALE_RANK,
        RANK() OVER (PARTITION BY CUSTOMER.SEGMENT ORDER BY SUM(ORDERS.PROFIT) DESC) AS PROFIT_RANK,
        SUM(ORDERS.SALES) AS TOTAL_SALES,
        SUM(ORDERS.PROFIT) AS TOTAL_PROFIT
    FROM ORDERS 
    JOIN CUSTOMER ON CUSTOMER.ID = ORDERS.CUSTOMER_ID
	JOIN PRODUCT ON PRODUCT.ID = ORDERS.PRODUCT_ID
    GROUP BY CUSTOMER.SEGMENT, PRODUCT.CATEGORY
)
SELECT SEGMENT, CATEGORY, SALE_RANK, PROFIT_RANK
FROM ranked_products WHERE PROFIT_RANK <=2
ORDER BY SEGMENT, PROFIT_RANK;

-- QUESTION 4
/*
How can you create a report that displays each employee's performance across different product categories, 
showing not only the total profit per category but also what percentage of 
their total profit each category represents, with the results ordered by the 
percentage in descending order for each employee?
*/
WITH EMPLOYEE_TOTAL_PROFIT AS (
    SELECT ID_EMPLOYEE, SUM(PROFIT) AS TOTAL_PROFIT
    FROM ORDERS GROUP BY ID_EMPLOYEE
),
CATEGORY_PROFIT AS (
    SELECT ORDERS.ID_EMPLOYEE, PRODUCT.CATEGORY, SUM(ORDERS.PROFIT) AS CATEGORY_PROFIT
    FROM ORDERS JOIN PRODUCT ON PRODUCT.ID = ORDERS.PRODUCT_ID
    GROUP BY ORDERS.ID_EMPLOYEE, PRODUCT.CATEGORY
)
SELECT 
    c.ID_EMPLOYEE, c.CATEGORY,
    ROUND(c.CATEGORY_PROFIT, 2) AS ROUNDED_TOTAL_PROFIT,
    ROUND((c.CATEGORY_PROFIT / e.TOTAL_PROFIT) * 100, 2) AS PROFIT_PERCENTAGE
FROM CATEGORY_PROFIT c
JOIN EMPLOYEE_TOTAL_PROFIT e ON c.ID_EMPLOYEE = e.ID_EMPLOYEE
ORDER BY c.ID_EMPLOYEE ASC, PROFIT_PERCENTAGE DESC;


-- QUESTION 5:
/*
How can you develop a user-defined function in SQL Server 
to calculate the profitability ratio for each product category an employee has sold, 
and then apply this function to generate a report that 
ranks each employee's product categories by their profitability ratio?
*/
DELIMITER //

CREATE FUNCTION CALC_PROFITABILITY_RATIO(TOTAL_SALES DECIMAL(16,2), TOTAL_PROFIT DECIMAL(16,2))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE PROFITABILITY_RATIO DECIMAL(10,2);
    IF TOTAL_SALES = 0 THEN
        SET PROFITABILITY_RATIO = 0;
    ELSE
        SET PROFITABILITY_RATIO = ROUND(TOTAL_PROFIT / TOTAL_SALES, 2);
    END IF;
    RETURN PROFITABILITY_RATIO;
END
//
DELIMITER ;

SELECT 
    O.ID_EMPLOYEE, 
    P.CATEGORY, 
    ROUND(SUM(O.SALES), 2) AS TOTAL_SALES, 
    ROUND(SUM(O.PROFIT), 2) AS TOTAL_PROFIT,
    CALC_PROFITABILITY_RATIO(ROUND(SUM(O.SALES), 2), ROUND(SUM(O.PROFIT), 2)) AS PROFITABILITY_RATIO
FROM ORDERS O
JOIN PRODUCT P ON P.ID = O.PRODUCT_ID
GROUP BY O.ID_EMPLOYEE, P.CATEGORY 
ORDER BY O.ID_EMPLOYEE ASC,PROFITABILITY_RATIO DESC;
