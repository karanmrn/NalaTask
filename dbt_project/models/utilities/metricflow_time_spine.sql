select dateadd('day', row_number() over (order by seq4()) - 1, '2020-01-01'::date)::date as date_day
from table(generator(rowcount => 7305))
