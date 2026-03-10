-- banking_transactions_report.sql
-- Query for daily banking transaction report

WITH customer_accounts AS (
    SELECT
        c.customer_id,
        c.customer_name,
        a.account_id,
        a.account_type,
        a.branch_id,
        a.open_date,
        a.status
    FROM
        customers c
    JOIN accounts a
        ON c.customer_id = a.customer_id
    WHERE
        a.status = 'ACTIVE'
),

daily_transactions AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.transaction_date,
        t.transaction_type,
        t.amount,
        t.currency,
        t.channel,
        t.status
    FROM
        transactions t
    WHERE
        t.transaction_date >= CURRENT_DATE - INTERVAL '1 DAY'
),

account_balances AS (
    SELECT
        account_id,
        SUM(
            CASE
                WHEN transaction_type = 'CREDIT' THEN amount
                WHEN transaction_type = 'DEBIT' THEN -amount
                ELSE 0
            END
        ) AS net_balance
    FROM
        transactions
    GROUP BY
        account_id
),

large_transactions AS (
    SELECT
        transaction_id,
        account_id,
        amount,
        transaction_date
    FROM
        transactions
    WHERE
        amount > 10000
)

SELECT
    ca.customer_id,
    ca.customer_name,
    ca.account_id,
    ca.account_type,
    dt.transaction_id,
    dt.transaction_date,
    dt.transaction_type,
    dt.amount,
    ab.net_balance,
    CASE
        WHEN lt.transaction_id IS NOT NULL THEN 'FLAGGED'
        ELSE 'NORMAL'
    END AS transaction_flag
FROM
    customer_accounts ca
LEFT JOIN daily_transactions dt
    ON ca.account_id = dt.account_id
LEFT JOIN account_balances ab
    ON ca.account_id = ab.account_id
LEFT JOIN large_transactions lt
    ON dt.transaction_id = lt.transaction_id
ORDER BY
    dt.transaction_date DESC;