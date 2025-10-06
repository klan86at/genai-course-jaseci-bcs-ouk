# creating class management system with nodes and edges
# nodes: course, student, teacher, assignment, grade
# edges: enrolled_in, teaches, assigned_to, submitted_assignment, belongs_to
# properties: course(name, code), student(name, id), teacher(name, id), assignment(title, due_date), grade(score)
# import from byllm { Model }
# glob llm = Model(model_name="groq/llama-3.1-8b-instant");
# def generate_course_description(course_name: str) -> str by llm();
# def generate_assignment_prompt(assignment_title: str) -> str by llm();
# def generate_feedback(assignment_title: str, score: int) -> str by llm();
# def generate_study_tip(topic: str) -> str by llm();
# def generate_teacher_intro(teacher_name: str) -> str by llm();
# def generate_student_intro(student_name: str) -> str by llm();
# def generate_grade_comment(score: int) -> str by llm();
# def generate_course_outline(course_name: str) -> str by llm();
# def generate_assignment_instructions(assignment_title: str) -> str by llm();
# def generate_enrollment_confirmation(student_name: str, course_name: str) -> str by llm();
# def generate_teacher_feedback(teacher_name: str, course_name: str) -> str by llm();
# def generate_student_feedback(student_name: str, course_name: str) -> str by llm();
# def generate_course_summary(course_name: str) -> str by llm();
# def generate_assignment_summary(assignment_title: str) -> str by llm();
# def generate_grade_summary(score: int) -> str by llm();
# def generate_study_plan(topic: str) -> str by llm();
# def generate_course_recommendation(student_name: str) -> str by llm();
# def generate_teacher_recommendation(course_name: str) -> str by llm();
# def generate_student_recommendation(course_name: str) -> str by llm();
# def generate_assignment_recommendation(course_name: str) -> str by llm();
# def generate_grade_recommendation(score: int) -> str by llm();
# def generate_course_update(course_name: str) -> str by llm();
# def generate_assignment_update(assignment_title: str) -> str by llm();
# def generate_grade_update(score: int) -> str by llm();
# def generate_student_update(student_name: str) -> str by llm();
# def generate_teacher_update(teacher_name: str) -> str by llm();
# def generate_system_summary() -> str by llm();
# def generate_system_report() -> str by llm();
# def generate_system_analysis() -> str by llm();
# def generate_system_insights() -> str by llm();
# def generate_system_recommendations() -> str by llm();
# def generate_system_overview() -> str by llm();
# def generate_system_details() -> str by llm();
# def generate_system_statistics() -> str by llm();
# def generate_system_metrics() -> str by llm();
# def generate_system_performance() -> str by llm();
# def generate_system_trends() -> str by llm();
# def generate_system_forecast() -> str by llm();
# def generate_system_evaluation() -> str by llm();
# def generate_system_improvements() -> str by llm();
# def generate_system_changes() -> str by llm();
# def generate_system_history() -> str by llm();
# def generate_system_future() -> str by llm();
# def generate_system_goals() -> str by llm();
# def generate_system_objectives() -> str by llm();
# def generate_system_strategies() -> str by llm();
# def generate_system_tactics() -> str by llm();
# def generate_system_plans() -> str by llm();
# def generate_system_actions() -> str by llm();
# def generate_system_tasks() -> str by llm();
# def generate_system_projects() -> str by llm();
# def generate_system_initiatives() -> str by llm();
# def generate_system_programs() -> str by llm();
# def generate_system_policies() -> str by llm();
# def generate_system_procedures() -> str by llm();
# def generate_system_guidelines() -> str by llm();
# def generate_system_standards() -> str by llm();
# def generate_system_best_practices() -> str by llm();
# def generate_system_lessons_learned() -> str by llm();
# def generate_system_case_studies() -> str by llm();
# def generate_system_examples() -> str by llm();

# creating class management system with nodes and edges
# Classroom Management System in Jac
# This system manages students, teachers, courses, assignments, and grades

# Node types for our classroom system
node person {
    has name: str;
    has email: str;
    has created_at: str;
}

node student(person) {
    has student_id: str;
    has grade_level: str;
    has gpa: float = 0.0;
}

node teacher(person) {
    has teacher_id: str;
    has department: str;
    has office_number: str;
}

node course {
    has course_code: str;
    has course_name: str;
    has schedule: str;
    has credits: int = 3;
    has room_number: str;
}

node assignment {
    has title: str;
    has description: str;
    has due_date: str;
    has max_score: int = 100;
}

node grade {
    has points_earned: int = 0;
    has submitted: bool = false;
    has submission_date: str;
}

# Edges types to define relationships
edge enrolled;
edge teaches;
edge assigned_to;
edge submitted_assignment;
edge belongs_to;

# Creating the main system(Graph)
can classroom_system;
graph classroom_system {
    has anchor students;
    has anchor teachers;
    has anchor courses;
    has anchor assignments;

    walker init {
        here.students = [];
        here.teachers = [];
        here.courses = [];
        here.assignments = [];

        # Create teachers
        teacher1 = spawn node::teacher(
            name="Alice Johnson",
            email="alice@university.edu",
            teacher_id="T1001",
            department="Computer Science",
            office_number="CS101"
        );
        teacher2 = spawn node::teacher(
            name="Bob Smith",
            email="smith@university.edu",
            teacher_id="T1002",
            department="Mathematics",
            office_number="MATH201"
        );
        here.teachers += [teacher1, teacher2];

        # Create students
        student1 = spawn node::student(
            name="Kennedy langat",
            email="langat@student.edu",
            student_id="S001",
            grade_level="junior",
            gpa=3.5
        );
        student2 = spawn node::student(
            name="Alice Wanjiku",
            email="wanjiku@student.edu",
            student_id="S002",
            grade_level="senior",
            gpa=3.8
        );
        student3 = spawn node::student(
            name="John Doe",
            email="doe@student.edu",
            student_id="S003",
            grade_level="freshman",
            gpa=3.2
        );

        here.students += [student1, student2, student3];

        # Create courses
        course1 = spawn node::course(
            course_code="CS101",
            course_name="Introduction to Computer Science",
            schedule="Mon-Wed-Fri 10:00-11:00",
            credits=3,
            room_number="Room 101"
        );
        course2 = spawn node::course(
            course_code="MATH201",
            course_name="Calculus I",
            schedule="Tue-Thu 09:00-10:30",
            credits=4,
            room_number="Room 202"
        );

        here.courses += [course1, course2];

        # Create relationships
        spawn edge::teaches from teacher1 to course1;
        spawn edge::enrolled from student2 to course2;

        # Students enroll in courses
        spawn edge::enrolled from student1 to course1;
        spawn edge::enrolled from student1 to course2;
        spawn edge::enrolled from student2 to course1;
        spawn edge::enrolled from student3 to course2;

        print "Classroom system initialized with sample data";
    }

    # Walker to enroll a student in a course
    walker enroll_student {
        has student_id: str;
        has course_code: str;

        student_node = std.graph_nodes(here, node::student)[0] where node::student.student_id == student_id;
        course_node = std.graph_nodes(here, node::course)[0] where node::course.course_code == course_code;

        if (student_node and course_node) {
            spawn edge::enrolled from student_node to course_node;
            print "Student " + student_id + " enrolled in " + course_code;
        } else {
            print "Error: Student or Course not found";
        }
    }

    # Walker to assign a teacher to a course
    walker assign_teacher {
        has teacher_id: str;
        has course_code: str;

        teacher_node = std.graph_nodes(here, node::teacher)[0] where node::teacher.teacher_id == teacher_id;
        course_node = std.graph_nodes(here, node::course)[0] where node::course.course_code == course_code;

        if (teacher_node and course_node) {
            spawn edge::teaches from teacher_node to course_node;
            print "Teacher " + teacher_id + " assigned to " + course_code;
        } else {
            print "Error: Teacher or Course not found";
        }
    }

    # Walker to create an assignment for a course
    walker create_assignment {
        has course_code: str;
        has assignment_title: str;
        has due_date: str;
        has max_score: int = 100;
        has description: str;

        course_node = std.graph_nodes(here, node::course)[0] where node::course.course_code == course_code;

        if (course_node) {
            assignment_node = spawn node::assignment(
                title=assignment_title,
                due_date=due_date,
                max_score=max_score,
                description=description
            );
            spawn edge::assigned_to from assignment_node to course_node;
            here.assignments += [assignment_node];
            print "Assignment " + assignment_title + " created for course " + course_code;
        } else {
            print "Error: Course not found";
        }
    }

    # Walker to submit an assignment
    walker submit_assignment {
        has student_id: str;
        has assignment_title: str;
        has submission_date: str;
        has points_earned: int;

        student_node = std.graph_nodes(here, node::student)[0] where node::student.student_id == student_id;
        assignment_node = std.graph_nodes(here, node::assignment)[0] where node::assignment.title == assignment_title;

        if (student_node and assignment_node) {
            grade_node = spawn node::grade(
                points_earned=points_earned,
                submitted=true,
                submission_date=submission_date
            );
            spawn edge::submitted_assignment from student_node to grade_node;
            spawn edge::belongs_to from grade_node to assignment_node;
            print "Assignment submitted by " + student_id + " with score: " + std.to_str(points_earned);
        } else {
            print "Error: Student or Assignment not found";
        }
    }

    # Walker to get student's courses
    walker get_student_courses {
        has student_id: str;

        student_node = std.graph_nodes(here, node::student)[0] where node::student.student_id == student_id;

        if (student_node) {
            courses = student_node --> node::course;
            print "Courses for student " + student_id + ":";
            for course in courses {
                print "- " + course.course_code + ": " + course.course_name;
            }
        } else {
            print "Error: Student not found";
        }
    }

    # Walker to get course roster
    walker get_course_roster {
        has course_code: str;

        course_node = std.graph_nodes(here, node::course)[0] where node::course.course_code == course_code;

        if (course_node) {
            students = course_node <-- node::student;
            teacher = course_node <-- node::teacher;
            
            # Pre-process complex logic
            teacher_name = "Not Assigned";
            if (teacher) {
                teacher_name = teacher[0].name;
            }
            
            print "Roster for course " + course_code + ":";
            print "Teacher: " + teacher_name;
            print "Students:";
            for student in students {
                print "- " + student.student_id + ": " + student.name;
            }
        } else {
            print "Error: Course not found";
        }
    }

    # Walker to calculate student GPA
    walker calculate_gpa {
        has student_id: str;
        
        student_node = std.graph_nodes(here, node::student)[0] where node::student.student_id == student_id;
        
        if (student_node) {
            # Get all grades for this student
            grades = student_node --> node::grade;
            
            if (grades.length > 0) {
                total_points = 0;
                max_total = 0;
                
                for grade in grades {
                    assignment = grade <-- node::assignment;
                    if (assignment.length > 0) {
                        total_points += grade.points_earned;
                        max_total += assignment[0].max_score;
                    }
                }
                
                if (max_total > 0) {
                # Calculate and format GPA - break down the calculation
                percentage = total_points / max_total;
                gpa_value = percentage * 4.0;
                formatted_gpa = std.round(gpa_value, 2);
                print "GPA calculated for " + student_id + ": " + std.to_str(formatted_gpa);
                }
            } else {
                print "No grades found for student " + student_id;
            }
        } else {
            print "Student not found";
        }
    }

    # Main execution walker
    walker main {
        # Create the classroom system
        classroom = spawn graph::classroom_system;

        # Initialize with sample data
        walker_init() spawn classroom;

        # Example operations
        walker_get_course_roster(course_code="CS101") spawn classroom;
        walker_get_student_courses(student_id="S001") spawn classroom;

        # Create a new assignment
        walker_create_assignment(
            course_code="CS101",
            assignment_title="Programming Project 1",
            due_date="2024-10-01",
            max_score=100,
            description="Build a simple application using Python"
        ) spawn classroom;

        # Student submit the assignment
        walker_submit_assignment(
            student_id="S001",
            assignment_title="Programming Project 1",
            submission_date="2024-09-30",
            points_earned=95
        ) spawn classroom;

        # Calculate GPA for a student
        walker_calculate_gpa(student_id="S001") spawn classroom;
    }
}
