exec createExam
@InstructorID = 1,
    @CourseID = 1,
    @ExamType = 'corrective',
    @Intake = 1,
    @BranchID = 1,
    @TrackID = 1,
    @StartTime = '2024-07-25 00:20:00',
    @EndTime = '2024-07-25 2:00:00',
    @TotalTime = 120,
    @AllowanceOptions = N'None',
    @ManualSelection = 0, -- Set to 0 for random selection
    @NumMCQ = 5,
    @MCQDegree = 10.0,
    @NumTF = 4,
    @TFDegree = 5.0,
    @TextDegree = 15.0,
    @NumText = 2;

 go
 exec assign_student_exam
    @instructor_ID = 1,
    @exam_ID = 6,
    @course_ID = 1,
    @start_time = '2024-07-25 00:00:00',
    @end_time = '2024-07-23 02:00:00';

	go 

exec take_Exam
@student_id = 1,
@exam_ID = 6,
@examtype ='corrective'

declare @answers  as dbo.QuestionanswerType

insert into @answers(QuestionID,answer)
values(6,'A'),(9,'B'),(10,'C'),(7,'B'),(8,'C'),(202,'Use parameterized queries (prepared statements) with bound parameters.
Use stored procedures instead of dynamically constructed queries.
Validate and sanitize user inputs before using them in SQL queries.
Use least privilege principle for database access, restricting permissions based on need.'),(201,'INNER JOIN: Returns records that have matching values in both tables.
LEFT JOIN: Returns all records from the left table (table1), and the matched records from the right table (table2). The result is NULL from the right side, if there is no match.
RIGHT JOIN: Returns all records from the right table (table2), and the matched records from the left table (table1). The result is NULL from the left side, when there is no match'),(4,'True'),(5,'False')
,(2,'True'),(1,'False')

execute finish_exam
@studentID =2,
@examID =6,
@answer = @answers ;
go

execute SP_ADD_Q
@instructor_ID =1,
@course_ID =1,
@question_Type ='MCQ',
@correct_answer ='True',
@question_text = 'sql stands for structured query language? ',
@question_ID = 605,
@true_OR_False_Q_ID = 603,
@mcqQuestionID = 601,
@TEXT_QUESTION_ID =603,
@a='true',
@b='false',
@c='may be'


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


execute update_question
@instructor_ID =1,
@course_ID =1,
@question_Type ='mcq',
@correct_answer ='false',
@question_text ='sql stands for structured query languagee',
@accepted_answer ='010',
@question_ID =605

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


execute sp_delete_question
@instructor_ID =1,
@course_Id =1,
@qusetion_ID =605,
@question_Type = 'mcq'

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

execute sp_add_instructor
@manager_id =1,
@ins_fname ='mazen',
@ins_Lname ='magdy',
@email ='mazenmagdy@gmail.com',
@Instructor_ID=605

create proc sp_update_instructor 
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

exec sp_update_instructor
@manager_id =1,
@instructor_id =605,
@ins_fname ='mazennnnn',
@ins_Lname ='magdyyyyyy',
@email ='mazennnnnmagdyyyyy@yahoo.com'

create or alter  proc sp_delete_instructor
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

exec sp_delete_instructor
@manager_id =1,
@instructor_id =605


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

exec sp_add_instructor_course
@manager_id =1,
    @instructor_id =605,
    @course_id =1,
	@year = '2024',
	@IC_ID=605


create proc sp_update_instructor_course
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

exec sp_update_instructor_course
	@manager_id =1,
    @instructor_course_id =605,
    @instructor_id =1,
    @course_id =6,
	@year ='2024'


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

exec sp_delete_instructor_course
 @manager_id =3,
 @instructor_course_id =30



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

exec sp_add_course
@manager_Id =1,
@course_name ='maths',
@crs_description= 'calculations',
@max_degree =100,
@min_degree =50.5,
@Course_ID =605


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

exec sp_update_course
@manager_Id =1,
@course_ID =605,
@course_name ='mathsssss',
@crs_description='calculationsssss',
@max_degree =100,
@min_degree =60
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
exec sp_delete_crs
@manager_id =1,
   @course_id =605

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
 exec sp_add_branch
 @ManagerID =1,
@BranchName ='bahera',
@Branch_ID =605

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
 
exec sp_update_branch
@ManagerID =1,
@branchID =605,
@BranchName ='baheraaaaaaa'


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
 
exec sp_delete_branch
@ManagerID =1,
@branchID =605

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

exec sp_AddTrack
@ManagerID =1,
@TrackName ='backend',
@Track_ID=605


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

exec sp_UpdateTrack
@ManagerID =1,
@TrackID =605,
@TrackName ='back enddddddddddddd'

create or alter  proc sp_deleteTrack
@ManagerID INT,
@TrackID INT
as
begin
IF EXISTS (SELECT 1 FROM Instructor 
	WHERE Training_manager_ID = @ManagerID )
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

exec sp_deleteTrack
@ManagerID =1,
@TrackID =605

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


exec sp_AddIntake
@ManagerID =1,
@intake_name ='tenth',
@Intake_ID =605

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

exec sp_udate_intake
@ManagerID =1,
@intake_name ='tenthhhhhh',
@intake_id =605

------- if i changed the manager id------
exec sp_udate_intake
@ManagerID =6,
@intake_name ='tenthhhhhh',
@intake_id =605
-------- will not update because that is not the manager ----

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

exec sp_delete_intake
@ManagerID =1,
@intake_id =605

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

exec sp_AddStudent
@ManagerID =1,
@St_fname ='mazen',
@st_lname ='magdy',
@Email ='mazenmagdy@yahoo.com',
@IntakeID =1,
@BranchID =1,
@TrackID =1,
@Student_ID =605

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

exec sp_update_student
@ManagerID =1,
@studentID =605,
@St_fname='mazennnn',
@st_lname ='magdyyyy',
@Email ='mazennnnnmagdy@gmail.com',
@IntakeID =2,
@BranchID =2,
@TrackID =2

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

exec sp_delete_student
@ManagerID =1,
@studentID =605