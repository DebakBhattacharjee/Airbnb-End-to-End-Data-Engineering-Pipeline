{{  config(materialized = 'incremental')  }}

Select * from {{ source ('staging', 'hosts') }}

{% if is_incremental() %}
    where CREATED_AT > (Select COALESCE(Max(CREATED_AT), '1900-01-01') From {{  this }})
{% endif %}