create table cal (id serial, cal int);

\copy cal (cal) from cal.txt with csv

select coalesce, sum(coalesce) over () from (
  select coalesce from (
    select id, sum, coalesce(sum - lag(sum) over(order by id), sum) from (
      select id, cal, sum(cal) over (order by id) as sum 
      from cal
    ) a where cal is null
  ) b order by coalesce desc limit 3
) c;
