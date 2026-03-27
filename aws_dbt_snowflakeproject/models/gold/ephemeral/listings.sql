{{
  config(
    materialized = 'ephemeral',
    )
}}

WITH listings as
(
    Select
        LISTING_ID,
        PROPERTY_TYPE,
        ROOM_TYPE,
        CITY,
        COUNTRY,
        PRICE_PER_NIGHT_TAG,
        LISTINGS_CREATED_AT
    FROM
        {{ ref('OBT') }}
)
Select * from listings