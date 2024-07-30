----Triggers----
----1- Max degree of questions---
create or alter trigger Ensure_MAX_Degree
on [dbo].[Exam_question]
after insert,update
as
begin 
	Declare @examID int,@total_degree int,@course_ID int,@max_Degree int;

	select @examID = Exam_ID from inserted;
	
	select @course_ID = Course_ID 
	from Exam
	where Exam_ID= @examID;

	select @max_Degree = max_degree
	from Course
	where Course_ID = @course_ID;

	select @total_degree = SUM(degree)
	from   Exam_question
	where Exam_ID = @examID;

	if @total_degree > @max_Degree
		begin 
			 
			print('the total degree of the questions is greater than the max degree
			of the exam')
			rollback transaction;
		end
end;

----2--cannot sumbit the exam outside of time
create trigger student_sumbission
on student_answer
for insert,update
as 
begin
	declare @examID int, @student_ID int, @sumbissiontime datetime

	select @examID = i.Exam_ID, @student_ID = i.Student_ID, @sumbissiontime = GETDATE()
	from inserted as i

	if not exists(select 1 from Exam as e join StudentExam as se
	on se.Exam_ID = e.Exam_ID
	where se.Student_ID = @student_ID 
	and se.Exam_ID = @examID 
	and @sumbissiontime between se.Start_date and se.End_date)

	begin
		print('you cannot sumbit your answers outside specified time')
		rollback transaction
	end
end

go

----3---updating student result

create trigger updateresult
on student_answer
for insert, update
as
begin 
	declare @examID int,@student_ID int ,@result decimal(5,2),
	@correctanswers int,
	@totalQuestions int

	select @examID = exam_id, @student_ID = Student_ID
	from inserted

	select @correctanswers = COUNT(*)
	from Student_answer
	where Exam_ID = @examID 
	and Student_ID = @student_ID 
	and Is_correct = 1

	select @totalQuestions = COUNT(*)
	from Exam_question
	where Exam_ID = @examID

	if @totalQuestions > 0 
	begin
		set @result = (@correctanswers*1/ @totalQuestions)*100
	end
	else
	begin
		set @result = 0
	end
	update Student_exam
		set result= @result
		where Student_ID =@student_ID
		and Exam_ID = @examID
end

