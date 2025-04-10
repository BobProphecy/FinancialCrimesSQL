{{
  config({    
    "materialized": "table",
    "alias": "financial_crimes_scored",
    "schema": "financialcrimes"
  })
}}

WITH WIRE_TRANSFERS AS (

  {#Accesses wire transfer data for financial crime analysis.#}
  SELECT * 
  
  FROM {{ source('BOBW.FINANCIALCRIMES', 'WIRE_TRANSFERS') }}

),

wire_transfer_details AS (

  {#Compiles detailed information on wire transfer transactions for better tracking and analysis.#}
  SELECT 
    TRANSACTION_ID AS TRANSACTION_ID,
    CONCAT(FIRST_NAME, ' ', LAST_NAME) AS full_name,
    FROM_BANK AS FROM_BANK,
    FROM_ACCOUNT_NUMBER AS FROM_ACCOUNT_NUMBER,
    TO_BANK AS TO_BANK,
    TO_ACCOUNT_NUMBER AS TO_ACCOUNT_NUMBER,
    ORIGINATING_COUNTRY AS ORIGINATING_COUNTRY,
    DESTINATION_COUNTRY AS DESTINATION_COUNTRY,
    ROUND(TRANSACTION_AMOUNT, 2) AS transaction_amount
  
  FROM WIRE_TRANSFERS

),

ORIG_COUNTRY AS (

  {#Extracts data from the financial crimes country watchlist for compliance and risk assessment.#}
  SELECT * 
  
  FROM {{ source('BOBW.FINANCIALCRIMES', 'COUNTRY_WATCHLIST') }}

),

INDIVIDUAL_WATCHLIST AS (

  {#Accesses the individual watchlist for monitoring financial crimes.#}
  SELECT * 
  
  FROM {{ source('BOBW.FINANCIALCRIMES', 'INDIVIDUAL_WATCHLIST') }}

),

DEST_COUNTRY AS (

  {#Accesses a list of countries flagged for financial crimes.#}
  SELECT * 
  
  FROM {{ source('BOBW.FINANCIALCRIMES', 'COUNTRY_WATCHLIST') }}

),

wire_transfer_joins AS (

  {#Compiles detailed information on wire transfers, including origin and destination country issues and individual watchlist reasons.#}
  SELECT 
    in0.TRANSACTION_ID AS TRANSACTION_ID,
    in0.FULL_NAME AS FULL_NAME,
    in0.FROM_BANK AS FROM_BANK,
    in0.FROM_ACCOUNT_NUMBER AS FROM_ACCOUNT_NUMBER,
    in0.TO_BANK AS TO_BANK,
    in0.TO_ACCOUNT_NUMBER AS TO_ACCOUNT_NUMBER,
    in0.ORIGINATING_COUNTRY AS ORIGINATING_COUNTRY,
    in1.ISSUE AS ORIG_ISSUE,
    in0.DESTINATION_COUNTRY AS DESTINATION_COUNTRY,
    in2.ISSUE AS DEST_ISSUE,
    in0.TRANSACTION_AMOUNT AS TRANSACTION_AMOUNT,
    in3.REASON AS INDIVIDUAL_REASON
  
  FROM wire_transfer_details AS in0
  LEFT JOIN ORIG_COUNTRY AS in1
     ON in0.ORIGINATING_COUNTRY = in1.COUNTRY
  LEFT JOIN DEST_COUNTRY AS in2
     ON in0.DESTINATION_COUNTRY = in2.COUNTRY
  LEFT JOIN INDIVIDUAL_WATCHLIST AS in3
     ON in0.FULL_NAME = in3.FULL_NAME

),

score_trans AS (

  {#Evaluates wire transfer transactions, flagging those with specified reasons and transaction amounts between $5000 and $10000 for further review.#}
  SELECT 
    TRANSACTION_ID AS TRANSACTION_ID,
    FULL_NAME AS FULL_NAME,
    INDIVIDUAL_REASON AS INDIVIDUAL_REASON,
    FROM_BANK AS FROM_BANK,
    FROM_ACCOUNT_NUMBER AS FROM_ACCOUNT_NUMBER,
    TO_BANK AS TO_BANK,
    TO_ACCOUNT_NUMBER AS TO_ACCOUNT_NUMBER,
    ORIGINATING_COUNTRY AS ORIGINATING_COUNTRY,
    ORIG_ISSUE AS ORIG_ISSUE,
    DESTINATION_COUNTRY AS DESTINATION_COUNTRY,
    DEST_ISSUE AS DEST_ISSUE,
    TRANSACTION_AMOUNT AS TRANSACTION_AMOUNT,
    CASE
      WHEN INDIVIDUAL_REASON IS NOT NULL AND INDIVIDUAL_REASON <> ''
        THEN 1
      ELSE 0
    END AS flag_individual_reason,
    CASE
      WHEN ORIG_ISSUE IS NOT NULL AND ORIG_ISSUE <> ''
        THEN 1
      ELSE 0
    END AS flag_orig_country,
    CASE
      WHEN DEST_ISSUE IS NOT NULL AND DEST_ISSUE <> ''
        THEN 1
      ELSE 0
    END AS flag_dest_country,
    CASE
      WHEN TRANSACTION_AMOUNT >= 5000 AND TRANSACTION_AMOUNT < 10000
        THEN 1
      ELSE 0
    END AS flag_trans_amount
  
  FROM wire_transfer_joins

),

compile_score AS (

  {#Evaluates transaction risk by analyzing various factors associated with wire transfers.#}
  SELECT 
    TRANSACTION_ID AS TRANSACTION_ID,
    FULL_NAME AS FULL_NAME,
    INDIVIDUAL_REASON AS INDIVIDUAL_REASON,
    FROM_BANK AS FROM_BANK,
    FROM_ACCOUNT_NUMBER AS FROM_ACCOUNT_NUMBER,
    TO_BANK AS TO_BANK,
    TO_ACCOUNT_NUMBER AS TO_ACCOUNT_NUMBER,
    ORIGINATING_COUNTRY AS ORIGINATING_COUNTRY,
    ORIG_ISSUE AS ORIG_ISSUE,
    DESTINATION_COUNTRY AS DESTINATION_COUNTRY,
    DEST_ISSUE AS DEST_ISSUE,
    TRANSACTION_AMOUNT AS TRANSACTION_AMOUNT,
    FLAG_INDIVIDUAL_REASON AS FLAG_INDIVIDUAL_REASON,
    FLAG_ORIG_COUNTRY AS FLAG_ORIG_COUNTRY,
    FLAG_DEST_COUNTRY AS FLAG_DEST_COUNTRY,
    FLAG_TRANS_AMOUNT AS FLAG_TRANS_AMOUNT,
    (FLAG_INDIVIDUAL_REASON + FLAG_ORIG_COUNTRY + FLAG_DEST_COUNTRY + FLAG_TRANS_AMOUNT) AS risk_score
  
  FROM score_trans AS wire_transfer_details_1

),

sorted_compile_score AS (

  {#Ranks compile scores by risk level, prioritizing higher risks for attention.#}
  SELECT * 
  
  FROM compile_score
  
  ORDER BY RISK_SCORE DESC NULLS LAST

)

SELECT *

FROM sorted_compile_score
