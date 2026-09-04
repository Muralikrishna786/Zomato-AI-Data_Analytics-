SELECT
customer_id,
customer_name,
email,
age,
CASE when age <25 then 'Gen Z'
     when age <40 then 'Millennials'
     when age <55 then 'Gen X'
     when age is null then 'Unknown'
     else 'Boomer' END as age_segment,
gender,
marital_status,
occupation,
income_band,
education,
family_size
from {{ ref('stg_users') }}
