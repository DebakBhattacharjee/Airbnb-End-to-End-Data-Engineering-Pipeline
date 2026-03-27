{{
  config(
    materialized = 'incremental',
    unique_key = 'LISTING_ID',
    )
}}

Select
LISTING_ID,
HOST_ID,
PROPERTY_TYPE,
ROOM_TYPE,
CITY,
COUNTRY,
ACCOMMODATES,
BEDROOMS,
BATHROOMS,
PRICE_PER_NIGHT,
{{tag('price_per_night')}} as PRICE_PER_NIGHT_TAG,
CREATED_AT
FROM
    {{ ref('bronze_listings') }}