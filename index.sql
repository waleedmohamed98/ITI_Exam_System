---1 index for student
create index student_Index_Fn
on student (st_Fname)
go
create index student_Index_LN
on student (st_Lname)
go
create index student_Index_Branch
on student (branch_ID)
----2 index for instructor
go
create index instructor_index_FN
on instructor (ins_Fname)
go
create index instructor_index_LN
on instructor (ins_Lname)
go

----3 index for instructor_course
create index instructor_courseID_index
on [dbo].[instructor_course] (course_ID)

go
create index instructor_course_instructorID_index
on [dbo].[instructor_course] (instructor_ID)

go
-----4 index for course---
create index course_index_crs_name
on course (crs_name)

go
create index course_index_crs_description
on course (crs_description)
go

-----5-index for exam
create index exam_index_course_ID
on exam (course_ID)
go
create index exam_index_instructor_ID
on exam (instructor_ID)
go
create index exam_index_track_ID
on exam (track_ID)
go

------5 - index for exam question
create index exam_question_question_type
on exam_question([question_type])
go
create index exam_question_degree
on exam_question([Degree])
go
create index exam_question_exam_ID
on exam_question([Exam_ID])
go
create index exam_question_question_ID
on exam_question([Question_ID])
go
----6-- index for mcq question
create index mcq_quesiton_ID
on [dbo].[mcq_questions] ([question_ID])
go
create index mcq_quesiton_course_ID
on [dbo].[mcq_questions] ([Course_ID])
go

-----7---index for question
create  index  question_index_course_id
on question ([Course_ID])
go
create  index  question_index_question_type
on question ([question_type])
go
-----8--- index for student answer
create index student_answer_index_st_ID
on [dbo].[Student_answer] (student_ID)
go
create index student_answer_index_q_ID
on [dbo].[Student_answer] ([question_ID])
go
create index student_answer_index_e_ID
on [dbo].[Student_answer] ([Exam_ID])
go

---- 9--index for  student exam
create index student_Exam_st_id
on [dbo].[Student_exam] ([Student_ID])
go
create index student_Exam_e_id
on [dbo].[Student_exam] ([Exam_ID])
go
create index student_Exam_date
on [dbo].[Student_exam] ([Start_date],[End_date])
go
create index student_result
on [dbo].[Student_exam] ([result])

go
----10--true of false 
create index TF_index_q_ID
on[dbo].[true or false questions] ([question_ID])
go
create index TF_index_crs_ID
on[dbo].[true or false questions] ([CourseID])
go

----11 text questions

create index text_index_q_ID
on[dbo].[text questions] ([question_ID])

go

create index text_index_crs_ID
on[dbo].[text questions] ([CourseID])
go
----12--student_course
create index st_crs_st_ID
on [dbo].[Student_course] ([Student_ID])
go
create index st_crs_crs_ID
on [dbo].[Student_course] ([Course_ID])

go
