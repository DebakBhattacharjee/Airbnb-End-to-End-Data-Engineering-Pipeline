{{
  config(
    materialized = 'ephemeral',
    )
}}

WITH hosts as
(
    Select
        HOST_ID,
        HOST_NAME,
        HOST_SINCE,
        IS_SUPERHOST,
        RESPONSE_RATE_QUALITY,
        HOST_CREATED_AT
    FROM
        {{ ref('OBT') }}
)
Select * from hosts