-- Bank SQL practice (SQLite)
-- Sample banking data and queries covering the SQL topics I practiced:
-- WHERE, JOIN, GROUP BY, HAVING, CASE WHEN, subqueries, window functions.
-- Run with: sqlite3 bank_practice.db < bank_practice.sql

------------------------------------------------------------
-- 1. Schema and sample data
------------------------------------------------------------
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    city        TEXT
);

CREATE TABLE accounts (
    account_id   INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
    account_type TEXT NOT NULL,
    balance      REAL NOT NULL
);

CREATE TABLE transactions (
    transaction_id INTEGER PRIMARY KEY,
    account_id     INTEGER NOT NULL REFERENCES accounts(account_id),
    amount         REAL NOT NULL,
    tx_type        TEXT NOT NULL,   -- 'deposit' or 'withdrawal'
    tx_date        TEXT NOT NULL
);

INSERT INTO customers VALUES
    (1, 'Anna Petrosyan', 'Yerevan'),
    (2, 'Ben Mueller',    'Munich'),
    (3, 'Clara Weiss',    'Berlin'),
    (4, 'David Smith',    'London'),
    (5, 'Eva Novak',      'Prague');

INSERT INTO accounts VALUES
    (101, 1, 'checking',  2500.00),
    (102, 1, 'savings',   8000.00),
    (103, 2, 'checking',  1200.00),
    (104, 3, 'checking',   300.00),
    (105, 4, 'savings',  15000.00),
    (106, 5, 'checking',    50.00);

INSERT INTO transactions VALUES
    (1,  101, 1500,  'deposit',    '2026-01-05'),
    (2,  101,  200,  'withdrawal', '2026-01-12'),
    (3,  101,  700,  'withdrawal', '2026-02-01'),
    (4,  102, 5000,  'deposit',    '2026-01-10'),
    (5,  102, 3000,  'deposit',    '2026-02-15'),
    (6,  103,  800,  'deposit',    '2026-01-20'),
    (7,  103,  450,  'withdrawal', '2026-02-03'),
    (8,  103,   60,  'withdrawal', '2026-02-20'),
    (9,  104,  300,  'deposit',    '2026-01-25'),
    (10, 105, 12000, 'deposit',    '2026-01-02'),
    (11, 105, 2500,  'withdrawal', '2026-02-10'),
    (12, 105,  900,  'deposit',    '2026-03-01'),
    (13, 106,   50,  'deposit',    '2026-02-18'),
    (14, 104,  120,  'withdrawal', '2026-03-05'),
    (15, 101,  300,  'deposit',    '2026-03-10');

------------------------------------------------------------
-- 2. Queries
------------------------------------------------------------

-- Q1. SELECT / WHERE: accounts with a balance above 1000
SELECT account_id, account_type, balance
FROM accounts
WHERE balance > 1000;

-- Q2. JOIN: each customer with their accounts
SELECT c.name, a.account_id, a.account_type, a.balance
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
ORDER BY c.name;

-- Q3. GROUP BY + aggregates: total and average balance per customer
SELECT c.name,
       COUNT(a.account_id) AS num_accounts,
       SUM(a.balance)      AS total_balance,
       AVG(a.balance)      AS avg_balance
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;

-- Q4. WHERE vs HAVING: accounts whose total deposits exceed 1000
-- WHERE filters rows before grouping, HAVING filters groups after.
SELECT account_id, SUM(amount) AS total_deposits
FROM transactions
WHERE tx_type = 'deposit'
GROUP BY account_id
HAVING SUM(amount) > 1000;

-- Q5. MAX / MIN / COUNT: transaction summary per account
SELECT account_id,
       COUNT(*)    AS num_transactions,
       MAX(amount) AS largest,
       MIN(amount) AS smallest
FROM transactions
GROUP BY account_id;

-- Q6. CASE WHEN: label accounts by balance size
SELECT account_id,
       balance,
       CASE
           WHEN balance >= 10000 THEN 'high'
           WHEN balance >= 1000  THEN 'medium'
           ELSE 'low'
       END AS balance_tier
FROM accounts;

-- Q7. Subquery: accounts with a balance above the average
SELECT account_id, balance
FROM accounts
WHERE balance > (SELECT AVG(balance) FROM accounts);

-- Q8. Multi-table JOIN: customers who made a withdrawal over 500
SELECT DISTINCT c.name
FROM customers c
JOIN accounts a     ON a.customer_id = c.customer_id
JOIN transactions t ON t.account_id  = a.account_id
WHERE t.tx_type = 'withdrawal'
  AND t.amount > 500;

-- Q9. Window function: largest and second-largest transaction per account,
-- ignoring small amounts (100 or less).
-- A wrapping query is needed because window results cannot be filtered
-- in the same SELECT where they are calculated.
SELECT account_id, transaction_id, amount, rank_in_account
FROM (
    SELECT account_id,
           transaction_id,
           amount,
           ROW_NUMBER() OVER (
               PARTITION BY account_id
               ORDER BY amount DESC
           ) AS rank_in_account
    FROM transactions
    WHERE amount > 100
) AS ranked
WHERE rank_in_account <= 2;
