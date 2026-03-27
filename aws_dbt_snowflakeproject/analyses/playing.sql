{% set flag  = 2 %}


Select * from {{ ref('bronze_bookings')}}
{% if flag == 1 %}
    where NIGHTS_BOOKED > 1
{% else %}
    Where NIGHTS_BOOKED = 1
{% endif %}