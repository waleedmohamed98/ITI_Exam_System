--The function is used to get the stundets who study the course denpending on the name of the course 
create or alter function getStudentsincourse(@coursename varchar(20))
returns table
as 
return
(
select concat(upper(left(st_fname,1))+lower(substring(st_fname,2,len(st_fname)-1)),'  ',upper(left(St_Lname,1))+lower(substring(St_Lname,2,len(st_fname)-1))) as [Student's Fullname]
from Student s inner join [dbo].[Student_course] sc
on s.Student_ID = sc.[Student_ID] inner join [dbo].[Course] c
on c.Course_ID=sc.[course_ID]
where [Crs_Name]= @coursename
)
--Done BY ALY OMAR

select * from dbo.getStudentsincourse('python')



create or alter function getinstructorcourse(@coursename varchar(20))
returns table
as 
return
(
select concat(upper(left(ins_fname,1))+lower(substring(ins_fname,2,len(ins_fname)-1)),'  ',
upper(left(ins_Lname,1))+lower(substring(ins_Lname,2,len(ins_fname)-1))) as [Instructor's Fullname]
from instructor i inner join [dbo].[instructor_course] ic
on i.Instructor_ID = ic.Instructor_ID inner join [dbo].[Course] c
on c.Course_ID=ic.Instructor_ID
where [Crs_Name]= @coursename
)
--Done BY ALY OMAR


select * from dbo.getinstructorcourse('RTOS')

--The function is used to get the stundets who study the course denpending on the name of the students
create or alter function getcoursesstudents(@id int)
returns table
as 
return
(select [Crs_Name] ,[Crs_description],concat(upper(left(st_fname,1))+lower(substring(st_fname,2,len(st_fname)-1)),'  ',upper(left(St_Lname,1))+lower(substring(St_Lname,2,len(st_fname)-1))) as [Student's Fullname]
from [dbo].[Course] c inner join [dbo].[Student_course] sc
on c.Course_ID=sc.[course_ID] inner join Student s
on s.Student_ID = sc.[Student_ID]
where s.Student_ID= @id
)
--Done BY ALY OMAR

select * from getcoursesstudents(5)

create or alter function getcourseinstructor(@instructorid int)
returns table
as 
return
(
select [Crs_Name],[Crs_description],concat(upper(left(ins_fname,1))+lower(substring(ins_fname,2,len(ins_fname)-1)),'  ',
upper(left(ins_Lname,1))+lower(substring(ins_Lname,2,len(ins_fname)-1))) as [Instructor's Fullname]
from [dbo].[Course] c inner join [dbo].[instructor_course] ic
on c.Course_ID=ic.[course_ID] inner join instructor i
on ic.[instructor_ID] = i.[Instructor_ID]

where i.[Instructor_ID]= @instructorid
)


select * from dbo.getcourseinstructor(1)