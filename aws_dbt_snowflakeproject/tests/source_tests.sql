{{
  config(
    severity = 'warn',
    )
}}
Select
    1
From
    {{ source('staging', 'bookings') }}
Where
    BOOKING_AMOUNT < 200