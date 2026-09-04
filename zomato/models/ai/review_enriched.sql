{{ config(
    materialized='table',
    tags=['ai']
) }}

select
    review_id,
    comment,
    
    case
        when lower(comment) like '%food%'
          or lower(comment) like '%taste%'
          or lower(comment) like '%flavour%'
          or lower(comment) like '%flavor%'
        then 'Food'

        when lower(comment) like '%delivery%'
          or lower(comment) like '%deliver%'
          or lower(comment) like '%late%'
        then 'Delivery'

        when lower(comment) like '%service%'
          or lower(comment) like '%staff%'
          or lower(comment) like '%waiter%'
        then 'Service'

        when lower(comment) like '%price%'
          or lower(comment) like '%expensive%'
          or lower(comment) like '%cost%'
        then 'Price'

        when lower(comment) like '%ambience%'
          or lower(comment) like '%atmosphere%'
          or lower(comment) like '%environment%'
        then 'Ambience'

        else 'Other'
    end as topic,

    case
        when lower(comment) like '%excellent%'
          or lower(comment) like '%amazing%'
          or lower(comment) like '%great%'
          or lower(comment) like '%good%'
          or lower(comment) like '%love%'
          or lower(comment) like '%delicious%'
        then 'Positive'

        when lower(comment) like '%bad%'
          or lower(comment) like '%worst%'
          or lower(comment) like '%terrible%'
          or lower(comment) like '%poor%'
          or lower(comment) like '%hate%'
          or lower(comment) like '%awful%'
        then 'Negative'

        else 'Neutral'
    end as sentiment_label,

    case
        when lower(comment) like '%excellent%'
          or lower(comment) like '%amazing%'
          or lower(comment) like '%great%'
          or lower(comment) like '%delicious%'
        then 0.9

        when lower(comment) like '%good%'
          or lower(comment) like '%love%'
        then 0.7

        when lower(comment) like '%bad%'
          or lower(comment) like '%worst%'
          or lower(comment) like '%terrible%'
          or lower(comment) like '%awful%'
        then -0.9

        when lower(comment) like '%poor%'
          or lower(comment) like '%hate%'
        then -0.7

        else 0.0
    end as sentiment_score,

    case
        when lower(comment) like '%late%'
          or lower(comment) like '%delay%'
          or lower(comment) like '%cold%'
          or lower(comment) like '%wrong%'
          or lower(comment) like '%bad%'
          or lower(comment) like '%poor%'
        then comment
        else null
    end as key_issue

from {{ ref('stg_reviews') }}
where comment is not null

