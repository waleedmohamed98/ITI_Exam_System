-----procedures---
----1-- assign students to exam

CREATE TYPE dbo.StudentIDTableType AS TABLE
(
    StudentID INT
);
go
create or alter proc assign_student_exam
@instructor_ID int,
@exam_ID int,
@course_ID int,
@start_time datetime,
@end_time datetime
as
begin
	if exists (select 1 from instructor_course 
	where instructor_ID = @instructor_ID and course_ID = @course_ID)
	
	begin
		if exists(select 1 from Exam
		where Exam_ID = @exam_ID and Course_ID = @course_ID)
		begin 
			declare @studentList dbo.StudentIDTableType;
			insert into @studentList (StudentID)
			select student_id
			from Student_course
			where Course_ID = @course_ID 

		insert into Student_exam(Student_ID,Exam_ID,Start_date,End_date)
		select StudentID,@exam_ID,@start_time,@end_time
		from @studentList

		print('students assigned successfully')
		
		end
	else
		begin
			RAISERROR('The exam does not exist or is not associated with the specified course.', 16, 1);
		end
	end
    ELSE
		BEGIN
			 RAISERROR('You are not authorized to assign students to this exam.', 16, 1);
		END
END;


end


go
-----2-----creating exam manually and randomized

create TYPE dbo.QuestionTableType AS TABLE
(
    QuestionID INT, Degree INT
);
go
create or alter proc createExam
@InstructorID INT,
@CourseID INT,
@ExamType VARCHAR(20), -- 'Exam' or 'Corrective'
    @Intake INT,
    @BranchID INT,
    @TrackID INT,
    @StartTime DATETIME,
    @EndTime DATETIME,
    @TotalTime INT,
    @AllowanceOptions NVARCHAR(MAX),
    @ManualSelection BIT, -- 1 for manual, 0 for random 
    @NumMCQ INT,
	@MCQDegree float,
    @NumTF INT,
	@TFDegree float,
	@TextDegree float,
    @NumText INT,
	@questions dbo.QuestionTableType READONLY
as
begin
	set NOCOUNT ON
	BEGIN TRANSACTION;

	DECLARE @examID int

	DECLARE @total_degree int

	DECLARE @max_degree int

	INSERT INTO Exam (Instructor_ID, Course_ID, Exam_Type, Intake_ID, Branch_ID, Track_ID, Start_time, End_time, total_time, allowance_options)
    VALUES (@InstructorID, @CourseID, @ExamType, @Intake, @BranchID, @TrackID, @StartTime, @EndTime, @TotalTime, @AllowanceOptions)

	set @examID = SCOPE_IDENTITY()
	
	
	if @ManualSelection = 1
	begin

		insert into Exam_question(Exam_ID,Question_ID,degree,question_type)
		select @examID,QuestionID,Degree,
			CASE 
                   WHEN q.QuestionID IN (SELECT question_ID FROM mcq_questions) THEN 'mcq'
                   WHEN q.QuestionID IN (SELECT question_ID FROM [text questions]) THEN 'text'
                   WHEN q.QuestionID IN (SELECT question_ID FROM [true or false questions]) THEN 'TRUE OR FALSE'
                   ELSE 'Unknown'
               END AS question_type
			   from @questions q
	end
	else
	begin
		insert into Exam_question(Exam_ID,Question_ID,Degree,question_type)
		select @examID,question_ID,@MCQDegree as degree,'mcq'

		from( select top(@NumMCQ) question_ID ,@MCQDegree AS Degree from mcq_questions
			where Course_ID=@CourseID order by NEWID()) as mcq_questions
			union all
			select @examID,question_ID,@TextDegree as degree,'text'
			from(
			select top(@NumText) question_ID ,@TextDegree as Degree from [text questions] 
			where CourseID=@CourseID order by NEWID()) as text_questions 
			union all
			select @examID,question_ID,@TFDegree as degree,'TRUE OR FALSE'
			from(
			select top (@NumTF) question_ID , @TFDegree As Degree from [true or false questions] 
			where CourseID=@CourseID order by NEWID()) as tf_questions
			
	end

	
	select @max_Degree = max_degree
	from Course
	where Course_ID = @CourseID;

	select @total_degree = SUM(degree)
	from   Exam_question
	where Exam_ID = @examID;

	if @total_degree > @max_Degree
	
	begin
		print('the total degree of the questions is greater than the max degree
			of the exam.')
			rollback transaction;
	end
	else
	begin
		commit transaction;
	end
end
go

---3----taking exam
go

create or alter proc take_Exam
@student_id int,
@exam_id int
AS
BEGIN
	SET NOCOUNT ON

	if exists( select 1 from Student_exam as se
	join Exam as e 
	on se.Exam_ID=  e.Exam_ID
	where se.Student_ID = @student_id 
	and se.Exam_ID = @exam_id
	and GETDATE() between Start_date  and End_date
	)
	begin
		select* 
		from StudentExam
		where Exam_ID = @exam_id
		and Student_ID = @student_id
	end
	ELSE
		BEGIN
			print('you cannot take this exam at the current time')
		end
end

go


----4 update student result with student answers
create TYPE dbo.QuestionanswerType AS TABLE
(
    QuestionID INT, answer nvarchar(max)
);

go
create or alter proc finish_exam
@studentID int,
@examID int,
@answer QuestionanswerType readonly
as
begin
	declare @questionID int,@correctanswer varchar(max),
	@questiontype varchar(55),@iscorrect bit,@student_answer varchar(max)

	declare student_answer cursor for
	select questionID, answer 
	from @answer
	
	open student_answer

	fetch next from student_answer into @questionID,@student_answer
	while @@FETCH_STATUS = 0
	
	begin
		select @questiontype = q.question_type
		from question as q
		where q.Question_ID = @questionID

		IF @questiontype = 'MCQ'
		begin
			select @correctanswer = correct_answer
			from mcq_questions
			where question_ID = @questionID 

			SET @iscorrect = CASE WHEN @student_answer = @correctanswer THEN 1 ELSE 0 END;

		end
		else
		if @questiontype = 'TRUE OR FALSE'
		begin
			select @correctanswer = correct_answer
			from [true or false questions]
			where question_ID = @questionID
			SET @iscorrect = CASE 
			WHEN LTRIM(RTRIM((@student_answer))) = LTRIM(RTRIM((@correctanswer))) THEN 1 ELSE 0 
			end
		end
		else
		if @questiontype = 'text' 
		
		begin 
		select @correctanswer = AcceptedTextAnswer 
		from [text questions]
		where question_ID = @questionID
			set @iscorrect = case when CHARINDEX(@correctanswer,@student_answer)>0 OR
			@Student_answer like '%'+@correctanswer+'%'
			then 1 else 0 
			end
		end
		insert into Student_answer(Student_ID,Exam_ID,question_ID,St_answer,Is_correct)
		values(@studentID,@examID,@questionID,@student_answer,@iscorrect)
		
		fetch next from student_answer into @questionID,@student_answer
	end
	close student_answer
	deallocate student_answer

declare @totalquestions int,@correctanswers int,@result decimal(5,2)

select @totalquestions = COUNT(*)
from Exam_question
where Exam_ID = @examID

select @correctanswers = COUNT(*)
from Student_answer
where Exam_ID = @examID
and Student_ID = @studentID
and Is_correct = 1

set @result = case 
	when @totalquestions > 0 then (@correctanswers*1 / @totalquestions)*100
	else 0
	end
update Student_exam
set result = @result
where Student_ID = @studentID 
and Exam_ID = @examID
end

-----stored procedures for validation of adding ,deleting,updating
---for instructor---
-----1 adding questions
go
create or alter proc SP_ADD_Q
@instructor_ID int,
@course_ID int,
@question_Type varchar(50),
@correct_answer nvarchar(max)=null,
@question_text nvarchar(max),
@question_ID int,
@true_OR_False_Q_ID int,
@mcqQuestionID int,
@TEXT_QUESTION_ID int,
@a varchar(50),
@b varchar(50),
@c varchar(50)



as 
begin 
	if exists(select 1 from  instructor_course where Course_ID = @course_ID 
	and instructor_ID = @instructor_ID)
	begin
		if not exists( SELECT 1
            FROM (
                SELECT question_text, Course_ID
				FROM mcq_questions WHERE question_text = @question_text AND Course_ID = @course_ID
                UNION ALL
                SELECT question_text, CourseID FROM [true or false questions] 
				WHERE question_text = @question_text AND CourseID = @course_ID
                UNION ALL
                SELECT question_text, CourseID FROM [text questions] 
				WHERE question_text = @question_text AND CourseID = @course_ID
            ) AS q
			)
			begin 
			insert into question(question_ID,question_type,Course_ID)
			values(@question_ID,@question_Type,@course_ID)
			

			

		IF @question_Type = 'MCQ'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM mcq_questions 
			WHERE Course_ID = @course_ID AND question_text = @question_text)
            BEGIN
                INSERT INTO mcq_questions(mcq_question_ID,question_ID, Course_ID, question_text, correct_answer,A,B,C)
                VALUES (@mcqQuestionID,@question_ID, @course_ID, @question_text, @correct_answer,@a,@b,@c);
                

               
				END
                ELSE
                BEGIN
                    RAISERROR('The question already exists in mcq_questions.', 16, 1);
                END
            END
            ELSE IF @question_Type = 'TRUE OR FALSE'
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM [true or false questions] 
				WHERE CourseID = @course_ID AND question_text = @question_text)
                BEGIN
                    INSERT INTO [true or false questions] 
					(true_OR_False_Q_ID,question_ID, CourseID, question_text, correct_answer)
                    VALUES (@true_OR_False_Q_ID,@question_ID, @course_ID, @question_text, @correct_answer);

                END
                ELSE
                BEGIN
                    RAISERROR('The question already exists in [true or false questions].', 16, 1);
                END
            END
            ELSE IF @question_Type = 'Text'
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM [text questions] 
				WHERE CourseID = @course_ID AND question_text = @question_text)
                BEGIN
                    INSERT INTO [text questions] (TEXT_QUESTION_ID,question_ID, CourseID, question_text)
                    VALUES (@TEXT_QUESTION_ID,@question_ID, @course_ID, @question_text);
                END
                ELSE
                BEGIN
                    RAISERROR('The question already exists in [text questions].', 16, 1);
                END
            END
        END
        ELSE
        BEGIN
            RAISERROR('The question already exists in the database.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to add questions to this course.', 16, 1);
    END
END;


go 

------2- updating questions

create or alter proc update_question
@instructor_ID int,
@course_ID int,
@question_Type varchar(50),
@correct_answer nvarchar(max)=null,
@question_text nvarchar(max),
@accepted_answer nvarchar(max)=null,
@question_ID int
as
begin
	if exists(select 1 from  instructor_course where Course_ID = @course_ID 
	and instructor_ID = @instructor_ID)

	begin 
	if @question_type = 'mcq'
	
	begin
		update mcq_questions
		set question_text = @question_text, correct_answer = @correct_answer
		where question_ID = @question_ID and course_ID =@course_ID
	end
	else  if @question_type = 'TRUE OR FALSE'
	begin
		update [true or false questions]
		set question_text = @question_text ,correct_answer = @correct_answer
		where question_ID = @question_ID and  [CourseID]=@course_ID
	end
	else if @question_type = 'Text'

	begin
		update [text questions]
		set question_text = @question_text , acceptedTextAnswer = @accepted_answer
		where question_ID = @question_ID and [CourseID] =@course_ID
	end
	else 
		begin 
			RAISERROR('Invalid question type specified.', 16, 1)
		end
	end
	else
		begin
			 RAISERROR('You are not authorized to update questions in this course.', 16, 1)
		end
end

go
----3----deleting question

CREATE or alter proc sp_delete_question
@instructor_ID int,
@course_Id int,
@qusetion_ID int,
@question_Type varchar(50)
as
begin
	
	if exists(select 1 from  instructor_course where Course_ID = @course_ID 
	and instructor_ID = @instructor_ID)

	begin 
	if @question_type = 'mcq'
		begin
			delete  from mcq_questions
			where question_ID =@qusetion_ID and Course_ID = @course_Id
			delete  from  [dbo].[question]
			where question_ID =@qusetion_ID and [Course_ID] = @course_Id
		end
	
	else  if @question_type = 'TRUE OR FALSE'

		begin 
			delete  from [true or false questions] 
			where question_ID =@qusetion_ID and CourseID = @course_Id
			delete  from  [dbo].[question]
			where question_ID =@qusetion_ID and [Course_ID] = @course_Id
		end
	else if @question_type = 'Text'
	begin
		delete  from [text questions]
		where question_ID =@qusetion_ID and CourseID = @course_Id
		delete  from  [dbo].[question]
		where question_ID =@qusetion_ID and [Course_ID] = @course_Id
	end
	end

	else
		begin
			RAISERROR('You are not authorized to delete questions from this course.', 16, 1);
		end
end

go

----validation for training manager procedures 

-----1 validation for adding ,deleting ,updating instructor

create or alter proc sp_add_instructor
@manager_id int,
@ins_fname varchar(100),
@ins_Lname varchar(100),
@email varchar(255),
@Instructor_ID int

as
begin
	if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
		    IF NOT EXISTS (SELECT 1 FROM instructor WHERE Email = @Email)
	begin
		insert into instructor(Instructor_ID,Ins_Fname,ins_Lname,Email,Training_manager_ID)
		values(@Instructor_ID,@ins_fname,@ins_Lname,@email,@manager_id)
	end
	else
		begin
			RAISERROR('the instructor is already there',16,1)
		end
	end
	else
		begin
			RAISERROR('you are not authorized to add instructor.',16,1);
		end
end
go

create or alter  proc sp_update_instructor 
@manager_id int,
@instructor_id int,
@ins_fname varchar(100),
@ins_Lname varchar(100),
@email varchar(255)

as 
begin 
	if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
	 IF EXISTS (SELECT 1 FROM instructor WHERE Instructor_ID = @instructor_id)
	begin
		update instructor
		set ins_fname=@ins_fname , ins_Lname = @ins_Lname ,email = @email
		where Instructor_ID = @instructor_id
	end
	else
		begin 
			RAISERROR('The instructor does not exist.', 16, 1);
		end
		end
	else 
		begin
			RAISERROR('You are not authorized to update the instructor.', 16, 1);
		end
end
go
---------- delete instructor---
create proc sp_delete_instructor
@manager_id INT,
@instructor_id INT
as
begin
	if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
	 IF EXISTS (SELECT 1 FROM instructor WHERE Instructor_ID = @instructor_id)
	begin
	delete from instructor
	where Instructor_ID = @instructor_id
	end
	ELSE
        BEGIN
            RAISERROR('The instructor does not exist.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to delete the instructor.', 16, 1);
    END
END;

go
create or alter proc sp_add_instructor_course
 @manager_id INT,
    @instructor_id INT,
    @course_id INT,
	@year int,
	@IC_ID int

as
begin
if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
	IF EXISTS (SELECT 1 FROM instructor WHERE Instructor_ID = @instructor_id)
	and exists (select 1 from Course where Course_ID = @course_id)
	begin
		insert into instructor_course (IC_ID,instructor_ID,course_ID,year)
		values(@IC_ID,@instructor_id,@course_id,@year)
	end
	else
	     BEGIN
            RAISERROR('Either the instructor or the course does not exist.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to add the instructor to the course.', 16, 1);
    END
END;
-----validation for update,deleting ,adding instructor for course
go
create or alter proc sp_update_instructor_course
	@manager_id INT,
    @instructor_course_id INT,
    @instructor_id INT,
    @course_id INT,
	@year int
as
begin
	if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
	if exists (select 1 from instructor_course where IC_ID= @instructor_course_id)

	begin
	update instructor_course
	set instructor_ID = @instructor_id
	, course_ID = @course_id
	where IC_ID = @instructor_course_id
	end
	ELSE
        BEGIN
            RAISERROR('The instructor-course assignment does not exist.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to update the instructor-course assignment.', 16, 1);
    END
END;

go
----- delete instructor_course--
create or alter  proc sp_delete_instructor_course
 @manager_id INT,
 @instructor_course_id INT
 as
 begin
	
	if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
	if exists (select 1 from instructor_course where IC_ID= @instructor_course_id)

	begin
	delete from instructor_course
	where IC_ID = @instructor_course_id
	end
	ELSE
        BEGIN
            RAISERROR('The instructor-course assignment does not exist.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to delete the instructor-course assignment.', 16, 1);
    END
END;


go
----validation for course add ,update ,delete
create or alter  proc sp_add_course
@manager_Id int,
@course_name varchar(100),
@crs_description varchar(255),
@max_degree float,
@min_degree float,
@Course_ID int
as
begin
if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	
	begin
		insert into Course(Course_ID,Crs_Name,Crs_description,Max_degree,Min_degree)
		values (@Course_ID,@course_name,@crs_description,@max_degree,@min_degree)
	end
	 ELSE
    BEGIN
        RAISERROR('You are not authorized to add a course.', 16, 1);
    END
END;
GO
create or alter proc sp_update_course
@manager_Id int,
@course_ID int,
@course_name varchar(100),
@crs_description varchar(255),
@max_degree float,
@min_degree float
as 
begin 
	if exists( select 1 from instructor where Training_manager_ID = @manager_id
	)
	begin
	IF EXISTS (SELECT 1 FROM Course WHERE Course_ID = @course_id)
	begin
		update Course 
		set Crs_Name = @course_name , Crs_description = @crs_description,
		Max_degree = @max_degree , Min_degree = @min_degree
		where Course_ID = @course_ID
	end
	ELSE
        BEGIN
            RAISERROR('The course does not exist.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to update the course.', 16, 1);
    END
END;

go

create or alter  proc sp_delete_crs
 @manager_id INT,
   @course_id INT
as 
begin
	if exists( select 1 from instructor where Training_manager_ID = @manager_id)
	begin
	IF EXISTS (SELECT 1 FROM Course WHERE Course_ID = @course_id)
	begin
		delete from Course
		where Course_ID = @course_id
		end
	 ELSE
        BEGIN
            RAISERROR('The course does not exist.', 16, 1);
        END
    END
    ELSE
    BEGIN
        RAISERROR('You are not authorized to delete the course.', 16, 1);
    END
END;
GO
create or alter  proc sp_add_branch
@ManagerID INT,
@BranchName NVARCHAR(100),
@Branch_ID int 
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )

	BEGIN
		INSERT INTO Branch(Branch_ID,Branch_Name)
		VALUES (@Branch_ID,@BranchName);
	END
	ELSE
	BEGIN
		RAISERROR('You are not authorized to add branches.', 16, 1);
	END
END;

go

create or alter proc sp_update_branch
@ManagerID INT,
@branchID int,
@BranchName NVARCHAR(100)
AS 
BEGIN 
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	begin
	if exists (select 1 from Branch where Branch_ID = @branchID)
	BEGIN 
		UPDATE Branch
		set Branch_Name = @BranchName
		where Branch_ID = @branchID
	end
	ELSE
        BEGIN
            RAISERROR('The branch does not exist.', 16, 1);
        END
	end
	else 
	begin
		RAISERROR('You are not authorized to UPDATE branches.', 16, 1);
	END
END;

go

create or alter  proc sp_delete_branch
@ManagerID INT,
@branchID int
as
begin
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	begin
	if exists (select 1 from Branch where Branch_ID = @branchID)
	BEGIN 
		delete from Branch 
		where Branch_ID = @branchID
	end
	ELSE
        BEGIN
            RAISERROR('The branch does not exist.', 16, 1);
        END
	end
	else 
	begin
		RAISERROR('You are not authorized to delete branches.', 16, 1);
	END
END;

go

CREATE or alter  PROCEDURE sp_AddTrack
@ManagerID INT,
@TrackName NVARCHAR(100),
@Track_ID int

AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	BEGIN
		INSERT INTO Track (Track_ID,Track_Name)
		VALUES (@Track_ID,@TrackName)
	END
	ELSE
	BEGIN
		RAISERROR('You are not authorized to add tracks.', 16, 1);
	END
END;
	
go

CREATE or alter  proc sp_UpdateTrack
@ManagerID INT,
@TrackID INT,
@TrackName NVARCHAR(100)
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	begin
	
	if exists(select 1 from Track where Track_ID = @TrackID)
	BEGIN
		UPDATE Track
		SET Track_Name = @TrackName
		WHERE Track_ID= @TrackID;
	END
	ELSE
        BEGIN
            RAISERROR('The track does not exist.', 16, 1);
        END
	end
	ELSE
	BEGIN
		RAISERROR('You are not authorized to update tracks.', 16, 1);
	END
END;

go 

create or alter  proc sp_deleteTrack
@ManagerID INT,
@TrackID INT
as
begin
IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID= @ManagerID )
	begin
	
	if exists(select 1 from Track where Track_ID = @TrackID)
	BEGIN
		delete from Track
		where Track_ID = @TrackID
	END
	ELSE
        BEGIN
            RAISERROR('The track does not exist.', 16, 1);
        END
	end
	ELSE
	BEGIN
		RAISERROR('You are not authorized to delete tracks.', 16, 1);
	END
END;

go
CREATE or alter proc sp_AddIntake
@ManagerID INT,
@intake_name varchar(50),
@Intake_ID int
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	BEGIN
		INSERT INTO Intake (Intake_ID,Intake_Name)
		VALUES (@Intake_ID,@intake_name);
	END
	ELSE
	BEGIN
		RAISERROR('You are not authorized to add intakes.', 16, 1);
	END
END;

go
create or alter  proc sp_udate_intake
@ManagerID INT,
@intake_name varchar(50),
@intake_id int
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	begin
	if exists (select 1 from Intake where Intake_ID =@intake_id)
	BEGIN
		update Intake
		set Intake_Name = @intake_name
		where Intake_ID = @intake_id
	END
	ELSE
        BEGIN
            RAISERROR('The intake does not exist.', 16, 1);
        END
	end
	ELSE
	BEGIN
		RAISERROR('You are not authorized to update intakes.', 16, 1);
	END
END;

go
create or alter  proc sp_delete_intake
@ManagerID INT,
@intake_id int
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
	begin
	if exists (select 1 from Intake where Intake_ID =@intake_id)
	BEGIN
		delete from Intake
		where Intake_ID = @intake_id
	END
	ELSE
        BEGIN
            RAISERROR('The intake does not exist.', 16, 1);
        END
	end
	ELSE
	BEGIN
		RAISERROR('You are not authorized to delete intakes.', 16, 1);
	END
END;

go

CREATE or alter PROC sp_AddStudent
@ManagerID INT,
@St_fname VARCHAR(100),
@st_lname VARCHAR(100),
@Email NVARCHAR(100),
@IntakeID INT,
@BranchID INT,
@TrackID INT,
@Student_ID int 
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID)
	BEGIN
		INSERT INTO Student (Student_ID,St_Fname,St_Lname, Email, Intake_ID, Branch_ID, Track_ID)
		VALUES (@Student_ID,@St_fname,@st_lname, @Email, @IntakeID, @BranchID, @TrackID);
	END
	ELSE
	BEGIN
		RAISERROR('You are not authorized to add students.', 16, 1);
	END
END;

go

CREATE or alter PROC sp_update_student
@ManagerID INT,
@studentID int,
@St_fname VARCHAR(100),
@st_lname VARCHAR(100),
@Email NVARCHAR(100),
@IntakeID INT,
@BranchID INT,
@TrackID INT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID)
	begin
		if exists (select 1 from Student where Student_ID = @studentID)
	BEGIN
		update Student
		set St_Fname =@St_fname , St_Lname = @st_lname,
		email = @Email, Intake_ID = @IntakeID,Branch_ID = @BranchID,
		Track_ID = @TrackID
		where Student_ID = @studentID
	END
	ELSE
        BEGIN
            RAISERROR('The student does not exist.', 16, 1);
        END
	end
	ELSE
	BEGIN
		RAISERROR('You are not authorized to update students.', 16, 1);
	END
END;

go
CREATE or alter PROC sp_delete_student
@ManagerID INT,
@studentID int

AS
BEGIN
	IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID)
	begin
		if exists (select 1 from Student where Student_ID = @studentID)
	BEGIN
		delete from Student
		where Student_ID = @studentID
	END
	ELSE
        BEGIN
            RAISERROR('The student does not exist.', 16, 1);
        END
	end
	ELSE
	BEGIN
		RAISERROR('You are not authorized to delete students.', 16, 1);
	END
END;







		



