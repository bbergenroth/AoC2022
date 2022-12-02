--part one
create table key (them text, you text, score int);
insert into key values ('A','X',4), ('A','Y',8), ('A','Z',3), ('B','X',1), ('B','Y',5), ('B','Z',9), ('C','X',7), ('C','Y',2), ('C','Z',6);
create table input (them text, you text);
\copy input from input.txt (delimiter ' ')
select sum(score) from key join input on (key.them=input.them and key.you=input.you);

--part two
truncate table key;
insert into key values ('A','X',3), ('A','Y',4), ('A','Z',8), ('B','X',1), ('B','Y',5), ('B','Z',9), ('C','X',2), ('C','Y',6), ('C','Z',7);
select sum(score) from key join input on (key.them=input.them and key.you=input.you);
