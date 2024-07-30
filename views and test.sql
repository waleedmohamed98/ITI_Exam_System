---1-view for showing the exam to student

create or alter  view StudentExam
as
select 
	e.Exam_ID,
	e.Course_ID,
	e.Branch_ID,
	e.Intake_ID,
	e.Track_ID,
	e.allowance_options,
	e.Exam_Type,
	se.Start_date,
	se.End_date,
	se.Student_ID,
	q.Question_ID,
	q.Degree,
		case
			when q.question_type = 'MCQ' then (select question_text from mcq_questions 
			where q.Question_ID =question_ID)
			
			when q.question_type = 'TF' then (select question_text from [true or false questions] 
			where q.Question_ID =question_ID)

			when q.question_type = 'Text' then (select question_text from  [text questions]
			where q.Question_ID =question_ID )
		End as question_TEXT,
	mc.A,
	mc.B,
	mc.C
	
	from Exam as e

	join Student_exam as se on e.Exam_ID= se.Exam_ID
	join Exam_question as q on e.Exam_ID = q.Exam_ID
	LEFT JOIN mcq_questions AS mc ON q.Question_ID = mc.question_ID AND q.question_type = 'MCQ'
	

	select * from StudentExam

go
----2- view to show the student result ---
create or alter view student_result
as
select 
SE.Exam_ID,
se.Student_ID,
s.St_Fname,s.St_Lname,
c.Crs_Name,
se.result,
e.Exam_Type,
e.Start_time,
e.End_time,
e.Intake_ID,
e.Branch_ID,
t.Track_ID,
t.Track_Name

from Student_exam as se
join Student as s 
on se.Student_ID = s.Student_ID
join Exam as e
on e.Exam_ID = se.Exam_ID
join Course as c
on e.Course_ID =  c.Course_ID
join Track as t
on e.Track_ID = t.Track_ID

select * from student_result
go
----3- view to show the course_info
create or alter view course_info
as 
select c.Course_ID,c.Crs_Name,
c.Max_degree,c.Min_degree
,ic.instructor_ID, i.Ins_Fname,i.ins_Lname,
t.Track_ID,t.Track_Name


from Course as c
join instructor_course as ic
on c.Course_ID = ic.course_ID
join instructor as i
on ic.instructor_ID = i.Instructor_ID
join Exam as e
on c.Course_ID = e.Course_ID
join Track as t
on e.Track_ID = t.Track_ID

go
---4- student schedule exams
create or alter view student_exam_schedule
as
select e.Exam_ID,e.Exam_Type,
e.allowance_options,b.Branch_Name,
e.Start_time,e.End_time,
E.total_time as exam_duration,
c.Crs_Name,se.Student_ID,
CASE
        WHEN GETDATE() < e.Start_time THEN 'Upcoming'
        WHEN GETDATE() BETWEEN e.Start_time AND e.End_time THEN 'Ongoing'
        ELSE 'Completed'
    END AS ExamStatus


from Exam as e
join Student_exam as se
on e.Exam_ID = se.Exam_ID
join Course as c
on c.Course_ID= e.Course_ID
join Branch as b
on e.Branch_ID = b.Branch_ID

select* from student_exam_schedule
go
----5--- creating a questionpool
create or alter view question_pool
as
select 
q.Question_ID,
q.question_type,
c.Course_ID,
c.Crs_Name,
mcq.question_text,
mcq.A,
mcq.B,
mcq.C,
mcq.correct_answer,
NULL AS TrueFalseAnswer,
NULL AS AcceptedTextAnswer


from mcq_questions as mcq
join question as q
on mcq.question_ID= q.Question_ID
join Course as c
on c.Course_ID = mcq.Course_ID
where q.question_type= 'mcq'

union all

select 
q.Question_ID,
q.question_type,
c.Course_ID,
c.Crs_Name,
tf.question_text,
null as A,
null as B,
null as c,
null as correct_answer,
tf.correct_answer AS TrueFalseAnswer,
NULL AS AcceptedTextAnswer


from [dbo].[true or false questions] as tf
join question as q
on tf.question_ID= q.Question_ID
join Course as c
on c.Course_ID = tf.CourseID
where q.question_type= 'TRUE OR FALSE'

union all

select 
q.Question_ID,
q.question_type,
c.Course_ID,
c.Crs_Name,
t.question_text,
null as A,
null as B,
null as c,
null as correct_answer,
null AS TrueFalseAnswer,
t.AcceptedTextAnswer AS AcceptedTextAnswer


from [dbo].[text questions] as t
join question as q
on t.question_ID= q.Question_ID
join Course as c
on c.Course_ID = t.CourseID
where q.question_type= 'Text'

select * from question_pool

go
----6---view for showing text answers that instructor will add the degree for manually
create or alter view text_answer_for_evaluation
as
select 
sa.Exam_ID,
sa.Student_ID,
sa.question_ID,
t.question_text,
t.AcceptedTextAnswer,
sa.St_answer,
sa.Is_correct




from student_answer as sa
join [text questions] as t
on sa.question_ID = t.question_ID
where sa.Is_correct = null

go
-------7 create view to show instructor information ---
create or alter view instructor_info
as 
select 
i.Instructor_ID,
i.Ins_Fname,i.ins_Lname,i.Email,
ic.course_ID,c.Crs_Name,c.Crs_description,
ic.year



from instructor as i 
join instructor_course as ic 
on i.Instructor_ID = ic.instructor_ID
join Course as c 
on ic.course_ID = c.Course_ID

select * from instructor_info

go
-------8 create view to show student information ---

create or alter view student_info
as
select s.Student_ID,s.St_Fname,s.St_Lname,s.Email,b.Branch_Name,
t.Track_Name,i.Intake_ID,i.Intake_Name,
sc.Course_ID ,sc.year,
c.Crs_Name,c.Crs_description

from Student as s 
join Student_course as sc
on s.Student_ID = sc.Student_ID
join Course as c 
on c.Course_ID = sc.Course_ID
join Branch as b
on s.Branch_ID= b.Branch_ID
join Intake as i 
on s.Intake_ID = i.Intake_ID
join Track as t 
on s.Track_ID = t.Track_ID

select * from student_info

go
-------9 create view to show intake_branch_track_details------
create or alter view intake_branch_track_details
as
select i.Intake_ID,i.Intake_Name,b.Branch_ID,b.Branch_Name,
t.Track_ID,t.Track_Name



from  Intake as i 
join Student as s 
on i.Intake_ID =  s.Branch_ID
join Track as t 
on t.Track_ID =  s.Track_ID
join Branch as b 
on b.Branch_ID = s.Branch_ID

select* from intake_branch_track_details
go

