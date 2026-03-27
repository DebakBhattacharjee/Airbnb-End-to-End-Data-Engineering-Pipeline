{{
  config(
    materialized = 'ephemeral',
    )
}}

WITH bookings as
(
    Select
        BOOKING_ID,
        BOOKING_DATE,
        BOOKING_STATUS,
        CREATED_AT
    FROM
        {{ ref('OBT') }}
)
Select * from bookings