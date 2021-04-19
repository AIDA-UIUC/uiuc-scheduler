// Initial import of catalog data into Neo4j.
// Run these queries in order from top to bottom.

// -------- Nodes -------- //

// Colleges
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/nodes/colleges_nodes.csv" as collegeProperties
CREATE (college:College)
SET college += collegeProperties

// Subjects
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/nodes/subject_nodes.csv" as subjectProperties
CREATE (subject:Subject)
SET subject += subjectProperties

// Courses
:auto USING PERIODIC COMMIT 500
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/nodes/course_nodes.csv" as courseProperties
CREATE (course:Course)
SET course += courseProperties
SET course.number = toInteger(course.number)

// Gen Eds
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/nodes/gen_ed_nodes.csv" as genEdProperties
CREATE (genEd:GenEd)
SET genEd += genEdProperties

// Sections
:auto USING PERIODIC COMMIT 500
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/nodes/section_nodes.csv" as sectionProperties
CREATE (section:Section)
SET section += sectionProperties
SET section.crn = toInteger(section.crn)
SET section.year = toInteger(section.year)
SET section.gpa = toFloat(section.gpa)
SET section.`A+` = toInteger(section.`A+`)
SET section.`A` = toInteger(section.`A`)
SET section.`A-` = toInteger(section.`A-`)
SET section.`B+` = toInteger(section.`B+`)
SET section.`B` = toInteger(section.`B`)
SET section.`B-` = toInteger(section.`B-`)
SET section.`C+` = toInteger(section.`C+`)
SET section.`C` = toInteger(section.`C`)
SET section.`C-` = toInteger(section.`C-`)
SET section.`D+` = toInteger(section.`D+`)
SET section.`D` = toInteger(section.`D`)
SET section.`D-` = toInteger(section.`D-`)
SET section.`F` = toInteger(section.`F`)

// Create Indexes
CREATE INDEX FOR (college:College) ON (college.collegeId);
CREATE INDEX FOR (subject:Subject) ON (subject.subjectId);
CREATE INDEX FOR (course:Course) ON (course.courseId);
CREATE INDEX FOR (genEd:GenEd) ON (genEd.genEdId);
CREATE INDEX FOR (section:Section) ON (section.crn, section.year, section.term);

// Meetings/Instructors/Buildings
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/nodes/meeting_nodes.csv" as props
MATCH (section:Section {crn: toInteger(props.crn),
                        year: toInteger(props.year), 
                        term: props.term})
WITH props, section
CREATE (meeting:Meeting {startDate: props.startDate, 
                        endDate: props.endDate, 
                        startTime: props.startTime, 
                        endTime: props.endTime, 
                        typeId: props.typeId,
                        meeting: props.meeting,
                        name: props.name,
                        days: props.days})
CREATE (section)-[:HAS_MEETING]->(meeting)
WITH props, meeting
UNWIND split(props.instructor, ':') AS instructorName
MERGE (instructor:Instructor {name: instructorName})
CREATE (instructor)-[:TEACHES]->(meeting)
WITH props, meeting
WHERE props.building IS NOT NULL
MERGE (building:Building {name: props.building})
MERGE (meeting)-[located:LOCATED_IN]->(building)
ON CREATE
  SET located.room = props.room

// -------- Relationships -------- //

// College -> Subject
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/relationships/colleges_to_subjects.csv" as collegeSubjects
MATCH (college:College {collegeId: collegeSubjects.collegeId})
MATCH (subject:Subject {subjectId: collegeSubjects.subjectId})
CREATE (college)-[:HAS_SUBJECT]->(subject)

// Subject -> Course
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/relationships/subjects_to_courses.csv" as subjectCourses
MATCH (subject:Subject {subjectId: subjectCourses.subjectId}) 
MATCH (course:Course {courseId: subjectCourses.courseId})
CREATE (subject)-[:HAS_COURSE]->(course)

// Course -> Section
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/relationships/courses_to_sections.csv" as courseSections
MATCH (course:Course {courseId: courseSections.courseId})
MATCH (section:Section {crn: toInteger(courseSections.crn), year: toInteger(courseSections.year), term: courseSections.term})
CREATE (course)-[:HAS_SECTION]->(section)

// Course -> GenEd
:auto USING PERIODIC COMMIT 100
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/AIDA-UIUC/uiuc-scheduler/master/data/neo4j/relationships/gen_eds_to_courses.csv" as courseGenEds
MATCH (course:Course {courseId: courseGenEds.courseId})
MATCH (genEd:GenEd {genEdId: courseGenEds.genEdId})
CREATE (course)-[:SATISFIES]->(genEd)

// GenEdCategories -> GenEd
MATCH (ac:GenEd {genEdId: "1CLL"})
MATCH (nw:GenEd {genEdId: "1NW"})
MATCH (us:GenEd {genEdId: "1US"})
MATCH (wc:GenEd {genEdId: "1WCC"})
MATCH (hp:GenEd {genEdId: "1HP"})
MATCH (la:GenEd {genEdId: "1LA"})
MATCH (ls:GenEd {genEdId: "1LS"})
MATCH (ps:GenEd {genEdId: "1PS"})
MATCH (qr1:GenEd {genEdId: "1QR1"})
MATCH (qr2:GenEd {genEdId: "1QR2"})
MATCH (bs:GenEd {genEdId: "1BSC"})
MATCH (ss:GenEd {genEdId: "1SS"})
CREATE (acp:GenEdCategory {genEdCategoryId: "ACP", name: "Advanced Composition"})
CREATE (cs:GenEdCategory {genEdCategoryId: "CS", name: "Cultural Studies"})
CREATE (hum:GenEdCategory {genEdCategoryId: "HUM", name: "Humanities & the Arts"})
CREATE (nat:GenEdCategory {genEdCategoryId: "NAT", name: "Natural Sciences & Technology"})
CREATE (qr:GenEdCategory {genEdCategoryId: "QR", name: "Quantitative Reasoning"})
CREATE (sbs:GenEdCategory {genEdCategoryId: "SBS", name: "Social & Behavioral Sciences"})
CREATE (acp)-[:HAS_GENED]->(ac)
CREATE (cs)-[:HAS_GENED]->(nw)
CREATE (cs)-[:HAS_GENED]->(us)
CREATE (cs)-[:HAS_GENED]->(wc)
CREATE (hum)-[:HAS_GENED]->(hp)
CREATE (hum)-[:HAS_GENED]->(la)
CREATE (nat)-[:HAS_GENED]->(ls)
CREATE (nat)-[:HAS_GENED]->(ps)
CREATE (qr)-[:HAS_GENED]->(qr1)
CREATE (qr)-[:HAS_GENED]->(qr2)
CREATE (sbs)-[:HAS_GENED]->(bs)
CREATE (sbs)-[:HAS_GENED]->(ss)

// Turn section year and term properties into nodes
CALL apoc.periodic.iterate(
  "MATCH (section:Section) RETURN section",
  "MERGE (year:Year {name: section.year})
   MERGE (term:Term {name: section.term})
   MERGE (year)-[:HAS_TERM]->(term)
   CREATE (section)-[:DURING_YEAR]->(year)
   CREATE (section)-[:DURING_TERM]->(term)
   REMOVE section.year
   REMOVE section.term", {batchSize: 50})

// Turn section part of term node
CALL apoc.periodic.iterate(
  "MATCH (section:Section)-[:DURING_TERM]->(term:Term) WHERE section.partOfTerm IS NOT NULL RETURN section, term",
  "MERGE (partOfTerm:PartOfTerm {partOfTermId: section.partOfTerm})
   MERGE (term)-[:HAS_PARTOFTERM]->(partOfTerm)
   CREATE (section)-[:DURING_PARTOFTERM]->(partOfTerm)
   REMOVE section.partOfTerm", {batchSize: 50})

// Set Part of Term Names
MATCH (xm:PartOfTerm {partOfTermId: "XM"})
MATCH (_1:PartOfTerm {partOfTermId: "1"})
MATCH (a:PartOfTerm {partOfTermId: "A"})
MATCH (b:PartOfTerm {partOfTermId: "B"})
MATCH (sf:PartOfTerm {partOfTermId: "SF"})
MATCH (s1:PartOfTerm {partOfTermId: "S1"})
MATCH (s2:PartOfTerm {partOfTermId: "S2"})
MATCH (s2a:PartOfTerm {partOfTermId: "S2A"})
MATCH (s2b:PartOfTerm {partOfTermId: "S2B"})
SET xm.name = "Extramural"
SET _1.name = "Full Term"
SET a.name  = "First Half"
SET b.name  = "Second Half"
SET sf.name = "Full Term"
SET s1.name = "(S1) First 4 Weeks"
SET s2.name = "(S2) Last 8 Weeks"
SET s2a.name = "First Half of S2"
SET s2b.name = "Second Half of S2"

// Set better Gen Ed Names
MATCH (ac:GenEd {genEdId: "1CLL"})
MATCH (nw:GenEd {genEdId: "1NW"})
MATCH (us:GenEd {genEdId: "1US"})
MATCH (wc:GenEd {genEdId: "1WCC"})
MATCH (hp:GenEd {genEdId: "1HP"})
MATCH (la:GenEd {genEdId: "1LA"})
MATCH (ls:GenEd {genEdId: "1LS"})
MATCH (ps:GenEd {genEdId: "1PS"})
MATCH (qr1:GenEd {genEdId: "1QR1"})
MATCH (qr2:GenEd {genEdId: "1QR2"})
MATCH (bs:GenEd {genEdId: "1BSC"})
MATCH (ss:GenEd {genEdId: "1SS"})
SET ac.name = "Advanced Composition"
SET nw.name = "Non-Western Cultures"
SET us.name = "U.S. Minority Cultures"
SET wc.name = "Western/Comparative Cultures"
SET hp.name = "Historical & Philosophical Perspectives"
SET la.name = "Literature & the Arts"
SET ls.name = "Life Sciences"
SET ps.name = "Physical Sciences"
SET qr1.name = "Quantitative Reasoning I"
SET qr2.name = "Quantitative Reasoning II"
SET bs.name = "Behavorial Sceince"
SET ss.name = "Social Science"

// Changed my mind on separating year, term, and part of term from section
CALL apoc.periodic.iterate(
  "MATCH (section:Section)-[:DURING_YEAR]->(year:Year), (section)-[:DURING_TERM]->(term:Term), (section)-[:DURING_PARTOFTERM]->(partOfTerm:PartOfTerm) RETURN section, year, term, partOfTerm",
  "SET section.year = year.name
   SET section.term = term.name
   SET section.partOfTerm = partOfTerm.partOfTermId", {batchSize: 50})

// Create More Indexes
CREATE INDEX FOR (genEdCategory:GenEdCategory) ON (genEdCategory.genEdCategoryId);
CREATE INDEX FOR (instructor:Instructor) ON (instructor.name);
CREATE INDEX FOR (building:Building) ON (building.name);
CREATE INDEX FOR (year:Year) ON (year.name);
CREATE INDEX FOR (term:Term) ON (term.name);
CREATE INDEX FOR (partOfTerm:PartOfTerm) ON (partOfTerm.partOfTermId);