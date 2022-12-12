create table input (move serial, direction text, distance int);
create table knots (id int, x int, y int);
create table moves (move serial, id int, x int, y int);
\copy input (direction, distance) from input.txt delimiter ' ';

--part 1
--keep track of knot position
insert into knots values (0,0,0),(1,0,0);

--recursive function moves appropriate direction until moves exhausted
--could just use another for loop but recursion is fun
--I did not use this to actually solve the first part but
--generalized my part two solution to work for part 1 as well (the knots parameter)
--it isn't very fast due to all the lookups and updates
create or replace function travel(direction text, distance integer, knots integer) returns int
language plpgsql as
$$
declare
    hx int;
    hy int;
    tx int;
    ty int;
    dx int := 0;
    dy int := 0;
begin
    if distance > 0 then
        select x, y into hx, hy from knots where id = 0;
        if direction = 'R' then
            dx = 1;
        elsif direction = 'L' then
            dx = -1;
        elsif direction = 'U' then
            dy = -1;
        elsif direction = 'D' then
            dy = 1;
        end if;
        update knots set x = hx + dx, y = hy + dy where id = 0;
        for i in 1..knots - 1 loop
            select x, y into hx, hy from knots where id = i - 1;
            select x, y into tx, ty from knots where id = i;
            --Chebyshev distance formula
            if greatest(abs(hx - tx), abs(hy - ty)) > 1 then
                dx = (hx - tx)::numeric / 2::numeric;
                dy = (hy - ty)::numeric / 2::numeric;
                update knots set x = tx + dx, y = ty + dy where id = i;
                insert into moves (id, x, y) values (i, tx, ty);
            end if;
        end loop;
        perform travel(direction, distance - 1, knots);
    end if;
    return 0;
end;
$$;

select travel(direction, distance, 2) from input order by move;
select count(*) + 1 --moves plus starting position
from (
    select distinct x, y from moves where id = 1) a;

--part 2
--reset and add the extra knots to keep track of
truncate table moves;
update knots set x = 0, y = 0;
insert into knots values (2,0,0),(3,0,0),(4,0,0),(5,0,0),(6,0,0),(7,0,0),(8,0,0),(9,0,0);

select travel(direction, distance, 10) from input order by move;
select count(*) + 1 --moves plus starting position
from (
    select distinct x, y from moves where id = 9) a;

