#!/usr/bin/perl

use DBI;

## open ( STDERR, ">/dev/null" );
open ( STDERR, ">/var/log/unanet/jiraImport.err" );

open (TIPROJECTS, ">./csv/tiProjects.csv");
open (TITASKS, ">./csv/tiTasks.csv");
open (TIASSIGNMENTS, ">./csv/tiAssignments.csv");
open (TIADMIN, ">./csv/tiAdmin.csv");
open (PLATPROJECTS, ">./csv/platProjects.csv");
open (PLATTASKS, ">./csv/platTasks.csv");
open (PLATASSIGNMENTS, ">./csv/platAssignments.csv");
open (PROPROJECTS, ">./csv/proProjects.csv");
open (PROTASKS, ">./csv/proTasks.csv");
open (PROASSIGNMENTS, ">./csv/proAssignments.csv");
open (PROADMIN, ">./csv/proAdmin.csv");
open (CODES, "<./csv/specialCustomers.csv");

my $codelist = <CODES>;

## Connect to the Jira DB ##

my $dbh = DBI->connect('DBI:mysql:jiradb:localhost:3306', '###', '###');
die "Unable for connect to server $DBI::errstr" unless $dbh;

## Titanium Projects ##

my $query1 =
"SELECT
 IFNULL(IF(opt.customvalue = 'NONE','CR',RIGHT(opt.customvalue, 4)),'CR'),
 j.pkey,
 'DEV',
 'Open',
 'UWEJACOBS',
 LEFT(j.SUMMARY, 50) AS 'summary',
 opt2.customvalue
FROM
 jiraissue j
 LEFT JOIN customfieldvalue cust ON (j.ID = cust.ISSUE AND cust.customfield = 10071)
 LEFT JOIN customfieldoption opt ON (cust.stringvalue = opt.id  AND cust.customfield = opt.customfield)
 LEFT JOIN customfieldvalue doc ON j.id = doc.issue AND doc.customfield = 10160
 LEFT JOIN customfieldoption opt2 ON (doc.stringvalue = opt2.id AND doc.customfield = opt2.customfield) 
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 (j.pkey LIKE 'TITAN%' OR j.pkey LIKE 'TRPT%') AND
 (j.CREATED >= current_date()-7 OR j.UPDATED >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 RIGHT(opt.customvalue, 5) NOT IN ($codelist)
ORDER BY
 j.pkey ASC";

my $sth = $dbh->prepare($query1) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectID, $projType, $completed, $assignedTo, $synopsis, $doc);

$sth->bind_columns(undef, \$userCode, \$projectID, \$projType, \$completed, \$assignedTo, \$synopsis, \$doc);

while( $sth->fetch() ) {
  print TIPROJECTS "\"$userCode\",\"$projectID\",\"$projType\",\"$completed\",\"$assignedTo\",\"V\",\"Y\",\"C\",\"N\",\"N\",\"N\",\"N\",\"Y\",\"Y\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"$synopsis\",\"\",\"\",\"\",\"\",\"N\",\"100\",\"\",\"U\",\"P\",\"P\",\"O\",\"N\",\"N\",\"\",\"$doc\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"H\",\"green\",\"Y\",\"Y\",\"Y\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
}

$sth->finish();

close TIPROJECTS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import project --file ./csv/tiProjects.csv`;

open (LOG,">/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------TI PMR PROJECTS------------\n";
print LOG $output;
close LOG;

## Titanium Tasks ##

my $query2 =
"SELECT
 IFNULL(IF(opt.customvalue = 'NONE','CR',RIGHT(opt.customvalue, 4)),'CR'),
 j.pkey
FROM
 jiraissue j LEFT JOIN customfieldvalue cust ON j.ID = cust.ISSUE AND cust.customfield = 10071
 LEFT JOIN customfieldoption opt ON (cust.stringvalue = opt.id AND cust.customfield = opt.customfield)
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 j.pkey LIKE 'TITAN%' AND
 (j.created >= current_date()-7 OR j.updated >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 RIGHT(opt.customvalue, 5) NOT IN ($codelist)";

my $sth = $dbh->prepare($query2) or die "Unable to set value to \$sth";

$sth->execute();

my @tasks = (
        'Research',
        'Analysis',
        'Design',
        'Coding',
        'Code Review',
        'Build',
        'Testing',
        'Deployment',
        'Training',
        'Documentation',
        'Meetings',
        'Admin',
        'Requirements',
        'Re-Work' );

my ($userCode, $projectID);

$sth->bind_columns(undef, \$userCode, \$projectID);

while( $sth->fetch() ) {
   foreach my $task (@tasks) {
        print TITASKS "\"$userCode\",\"$projectID\",\"$task\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
    }
}

$sth->finish();

close TITASKS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import task --file ./csv/tiTasks.csv`;

open (LOG,">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------TI PMR TASKS------------\n";
print LOG $output;
close LOG;

## Titanium Assignments ##

my $query3 =
"SELECT
 IFNULL(IF(opt.customvalue = 'NONE','CR',RIGHT(opt.customvalue, 4)),'CR'),
 j.pkey,
 (SELECT CASE
  WHEN j.ASSIGNEE = 'jhershey' THEN 'john'
  WHEN j.ASSIGNEE = 'jewelvu' THEN 'jvu'
  WHEN j.ASSIGNEE = 'jeff' THEN 'jbriscoe'
  WHEN j.ASSIGNEE = 'richardr' THEN 'dick'
  WHEN j.ASSIGNEE = 'george' THEN 'georgev'
  WHEN j.ASSIGNEE = 'gwilson' THEN 'greg'
  WHEN j.ASSIGNEE = 'hphibbs' THEN 'howard'
  WHEN j.ASSIGNEE = 'jmilligan' THEN 'joe'
  WHEN j.ASSIGNEE = 'rholczman' THEN 'rob'
  ELSE j.ASSIGNEE END) AS 'assignee',
 (SELECT ADDDATE(curdate(), 4))
FROM
 jiraissue j LEFT JOIN customfieldvalue cust ON j.ID = cust.ISSUE AND cust.customfield = 10071
 LEFT JOIN customfieldoption opt ON (cust.stringvalue = opt.id AND cust.customfield = opt.customfield)
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 j.pkey LIKE 'TITAN%' AND
 (j.created >= current_date()-7 OR j.updated >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 RIGHT(opt.customvalue, 5) NOT IN ($codelist)
ORDER BY j.pkey ASC";

my $sth = $dbh->prepare($query3) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectID, $name, $date);

$sth->bind_columns(undef, \$userCode, \$projectID, \$name, \$date);

while( $sth->fetch() ) {
   print TIASSIGNMENTS "\"$userCode\",\"$projectID\",\"\",\"$name\",\"\",\"$date\",\"\",\"\",\"N\",\"L\",\"P\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
}

$sth->finish();

close TIASSIGNMENTS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import assignment --file ./csv/tiAssignments.csv`;

open (LOG, ">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------TI PMR ASSIGNMENTS------------\n";
print LOG $output;
close LOG;

## Titanium Project Administrators ##

my $query4 =
"SELECT
 IFNULL(IF(opt.customvalue = 'NONE','CR',RIGHT(opt.customvalue, 4)),'CR'),
 j.pkey,
 'JBRISCOE',
 'resourceManager',
 'N'
FROM
 jiraissue j LEFT JOIN customfieldvalue cust ON j.ID = cust.ISSUE AND cust.customfield = 10071
 LEFT JOIN customfieldoption opt ON (cust.stringvalue = opt.id AND cust.customfield = opt.customfield)
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 j.pkey LIKE 'TITAN%' AND
 (j.created >= current_date()-7 OR j.updated >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 RIGHT(opt.customvalue, 5) NOT IN ($codelist)";

my $sth = $dbh->prepare($query4) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectID, $projAdmin, $projRole, $primary);

$sth->bind_columns(undef, \$userCode, \$projectID, \$projAdmin, \$projRole, \$primary);

while( $sth->fetch() ) {
  print TIADMIN "\"$userCode\",\"$projectID\",\"$projAdmin\",\"$projRole\",\"$primary\",\"\"\r\n";
}

$sth->finish();

close TIADMIN;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import project_administrator --file ./csv/tiAdmin.csv`;

open (LOG, ">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------TI PMR ADMIN------------\n";
print LOG $output;
close LOG;

## Platinum Projects ##

my $query5 =
"SELECT
 'CR',
 j.pkey,
 'DEV',
 'Open',
 'UWEJACOBS',
 LEFT(j.SUMMARY, 50)
FROM
 jiraissue j JOIN customfieldvalue c ON (j.id = c.issue)
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 (j.pkey like 'PLAT%') AND
 ((c.customfield = 10085 OR c.customfield = 10182) AND (c.stringvalue = '0')) AND
 (j.CREATED >= current_date()-7 OR j.UPDATED >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0')";

my $sth = $dbh->prepare($query5) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectID, $projType, $completed, $assignedTo, $synopsis);

$sth->bind_columns(undef, \$userCode, \$projectID, \$projType, \$completed, \$assignedTo, \$synopsis);

while( $sth->fetch() ) {
  print PLATPROJECTS "\"$userCode\",\"$projectID\",\"$projType\",\"$completed\",\"$assignedTo\",\"V\",\"N\",\"C\",\"N\",\"N\",\"N\",\"N\",\"Y\",\"Y\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"$synopsis\",\"\",\"\",\"\",\"\",\"N\",\"100\",\"\",\"U\",\"P\",\"P\",\"O\",\"N\",\"N\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"H\",\"green\",\"Y\",\"Y\",\"Y\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
}

$sth->finish();

close PLATPROJECTS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import project --file ./csv/platProjects.csv`;

open (LOG,">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PLAT PMR PROJECTS------------\n";
print LOG $output;
close LOG;

## Platinum Tasks ##

my $query6 =
"SELECT
 'CR',
 j.pkey
FROM
 jiraissue j JOIN customfieldvalue c ON (j.id = c.issue)
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 (j.pkey like 'PLAT%') AND
 ((c.customfield = 10085 OR c.customfield = 10182) AND (c.stringvalue = '0')) AND
 (j.CREATED >= current_date()-7 OR j.UPDATED >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0')";

my $sth = $dbh->prepare($query6) or die "Unable to set value to \$sth";

$sth->execute();

my @tasks = (
        'Research',
        'Analysis',
        'Design',
        'Coding',
        'Build',
        'Testing',
        'Deployment',
        'Training',
        'Documentation',
        'Meetings',
        'Admin',
        'Re-Work' );

my ($userCode, $projectID);

$sth->bind_columns(undef, \$userCode, \$projectID);

while( $sth->fetch() ) {
   foreach my $task (@tasks) {
        print PLATTASKS "\"$userCode\",\"$projectID\",\"$task\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
    }
}

$sth->finish();

close PLATTASKS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import task --file ./csv/platTasks.csv`;

open (LOG,">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PLAT PMR TASKS------------\n";
print LOG $output;
close LOG;

## Platinum Assignments ##

my $query7 =
"SELECT
 'CR',
 j.pkey,
 (SELECT CASE
  WHEN j.assignee = 'cnaganoor' then 'chaya'
  ELSE j.assignee END),
 (SELECT ADDDATE(curdate(), 4))
FROM
 jiraissue j JOIN customfieldvalue c ON (j.id = c.issue)
 LEFT JOIN customfieldvalue proj ON (j.id = proj.issue AND proj.customfield = '10085')
WHERE
 j.ASSIGNEE NOT IN ('z-closed','z-automationcandidate','z-closedautomation','z-deferred','z-platdocumentation','z-productmanagement','z-documentation') AND
 (j.pkey like 'PLAT%') AND
 ((c.customfield = 10085 OR c.customfield = 10182) AND (c.stringvalue = '0')) AND
 (j.CREATED >= current_date()-7 OR j.UPDATED >= current_date()-7) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0')";

my $sth = $dbh->prepare($query7) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectID, $name, $date);

$sth->bind_columns(undef, \$userCode, \$projectID, \$name, \$date);

while( $sth->fetch() ) {
  print PLATASSIGNMENTS "\"$userCode\",\"$projectID\",\"\",\"$name\",\"\",\"$date\",\"\",\"\",\"N\",\"L\",\"P\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
}

$sth->finish();

close PLATASSIGNMENTS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import assignment --file ./csv/platAssignments.csv`;

open (LOG, ">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PLAT PMR ASSIGNMENTS------------\n";
print LOG $output;
close LOG;

## Pro Services Projects ##

my $proServicesProjectsQuery =
"SELECT
 LEFT(RIGHT(code.textvalue, char_length(code.textvalue) - 19), char_length(RIGHT(code.textvalue, char_length(code.textvalue) - 19)) - 19) AS 'userCode',
 issue.pkey AS 'pmrNumber',
 'BILL' AS 'pmrType',
 LEFT(RIGHT(contact.textvalue, char_length(contact.textvalue) - 19), char_length(RIGHT(contact.textvalue, char_length(contact.textvalue) - 19)) - 19) AS 'contactName',
 IF(status.pname = 'Ready to Bill','Ready to Bill','Open') AS 'pmrStatus',
 'UWE' AS 'pmrAdmin',
 LEFT(issue.SUMMARY, 50) AS 'pmrSummary',
 requirements.customvalue AS 'pmrReqDoc'
FROM
 jiraissue issue
 LEFT JOIN customfieldvalue code ON (issue.id = code.issue AND code.customfield = '11350')
 LEFT JOIN customfieldvalue contact ON (issue.id = contact.issue AND contact.customfield = '11355')
 LEFT JOIN customfieldvalue doc ON (issue.id = doc.issue AND doc.customfield = '10160')
 LEFT JOIN customfieldvalue proj ON (issue.id = proj.issue AND proj.customfield = '10085')
 LEFT JOIN customfieldoption requirements ON (doc.stringvalue = requirements.id AND doc.customfield = requirements.customfield)
 JOIN issuestatus status ON (issue.issuestatus = status.id)
WHERE
 status.pname NOT IN ('Done','Closed') AND
 CONVERT(SUBSTRING_INDEX(issue.pkey,'-',-1),UNSIGNED INTEGER) NOT BETWEEN '3000' AND '13200' AND
 (issue.pkey LIKE 'PROSVC%') AND
 (issue.created >= current_date()-10 OR issue.updated >= current_date()-10) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 issue.issuetype <> '23'
ORDER BY
 issue.pkey ASC";

my $sth = $dbh->prepare($proServicesProjectsQuery) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectNumber, $projectType, $contactName, $projectStatus, $projectAdmin, $projectSummary, $requirementsDocument);

$sth->bind_columns(undef, \$userCode, \$projectNumber, \$projectType, \$contactName, \$projectStatus, \$projectAdmin, \$projectSummary, \$requirementsDocument);

while( $sth->fetch() ) {
  print PROPROJECTS "\"$userCode\",\"$projectNumber\",\"$projectType\",\"$projectStatus\",\"$projectAdmin\",\"V\",\"Y\",\"C\",\"N\",\"N\",\"N\",\"N\",\"Y\",\"Y\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"$projectSummary\",\"\",\"\",\"\",\"\",\"N\",\"100\",\"\",\"U\",\"P\",\"P\",\"O\",\"N\",\"N\",\"\",\"$requirementsDocument\",\"$contactName\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"H\",\"green\",\"Y\",\"Y\",\"Y\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
}

$sth->finish();

close PROPROJECTS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import project --file ./csv/proProjects.csv`;

open (LOG,">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PRO SERVICES PROJECTS------------\n";
print LOG $output;
close LOG;

## Pro Services Tasks ##

my $proServicesTasksQuery =
"SELECT
 LEFT(RIGHT(code.textvalue, char_length(code.textvalue) - 19), char_length(RIGHT(code.textvalue, char_length(code.textvalue) - 19)) - 19) AS 'userCode',
 issue.pkey
FROM
 jiraissue issue
 LEFT JOIN customfieldvalue code ON (issue.id = code.issue AND code.customfield = '11350')
 LEFT JOIN customfieldvalue proj ON (issue.id = proj.issue AND proj.customfield = '10085')
 JOIN issuestatus status ON (issue.issuestatus = status.id)
WHERE
 status.pname NOT IN ('Done','Closed') AND
 CONVERT(SUBSTRING_INDEX(issue.pkey,'-',-1),UNSIGNED INTEGER) NOT BETWEEN '3000' AND '13200' AND
 issue.pkey LIKE 'PROSVC%' AND
 (issue.created >= current_date()-10 OR issue.updated >= current_date()-10) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 issue.issuetype <> '23'
ORDER BY
 issue.pkey ASC";

my $sth = $dbh->prepare($proServicesTasksQuery) or die "Unable to set value to \$sth";

$sth->execute();

my @projectTasks = (
        'Research',
        'Analysis',
        'Design',
        'Coding',
        'Code Review',
        'Build',
        'Testing',
        'Deployment',
        'Training',
        'Documentation',
        'Meetings',
        'Admin',
        'Requirements',
        'Re-Work' );

my ($userCode, $projectNumber);

$sth->bind_columns(undef, \$userCode, \$projectNumber);

while( $sth->fetch() ) {
   foreach my $projectTask (@projectTasks) {
        print PROTASKS "\"$userCode\",\"$projectNumber\",\"$projectTask\",\"Y\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
    }
}

$sth->finish();

close PROTASKS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import task --file ./csv/proTasks.csv`;

open (LOG,">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PRO SERVICES TASKS------------\n";
print LOG $output;
close LOG;

## Pro Services Assignments ##

my $proServicesAssignmentsQuery =
"SELECT
 LEFT(RIGHT(code.textvalue, char_length(code.textvalue) - 19), char_length(RIGHT(code.textvalue, char_length(code.textvalue) - 19)) - 19) AS 'userCode',
 issue.pkey,
 issue.assignee,
 (SELECT ADDDATE(curdate(), 4))
FROM
 jiraissue issue
 LEFT JOIN customfieldvalue code ON (issue.id = code.issue AND code.customfield = '11350')
 LEFT JOIN customfieldvalue proj ON (issue.id = proj.issue AND proj.customfield = '10085')
 JOIN issuestatus status ON (issue.issuestatus = status.id)
WHERE
 status.pname NOT IN ('Done','Closed') AND
 CONVERT(SUBSTRING_INDEX(issue.pkey,'-',-1),UNSIGNED INTEGER) NOT BETWEEN '3000' AND '13200' AND
 issue.pkey LIKE 'PROSVC%' AND
 (issue.created >= current_date()-10 OR issue.updated >= current_date()-10) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 issue.issuetype <> '23'
ORDER BY
 issue.pkey ASC";

my $sth = $dbh->prepare($proServicesAssignmentsQuery) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectNumber, $assigneeName, $assignmentEndDate);

$sth->bind_columns(undef, \$userCode, \$projectNumber, \$assigneeName, \$assignmentEndDate);

while( $sth->fetch() ) {
   print PROASSIGNMENTS "\"$userCode\",\"$projectNumber\",\"\",\"$assigneeName\",\"\",\"$assignmentEndDate\",\"\",\"\",\"N\",\"L\",\"P\",\"\",\"\",\"\",\"\",\"\",\"\",\"\",\"\"\r\n";
}

$sth->finish();

close PROASSIGNMENTS;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import assignment --file ./csv/proAssignments.csv`;

open (LOG, ">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PRO SERVICES ASSIGNMENTS------------\n";
print LOG $output;
close LOG;

## Pro Services Administrators ##

my $proServicesAdminQuery =
"SELECT
 LEFT(RIGHT(code.textvalue, char_length(code.textvalue) - 19), char_length(RIGHT(code.textvalue, char_length(code.textvalue) - 19)) - 19) AS 'userCode',
 issue.pkey,
 'GABBY',
 'resourceManager',
 'N'
FROM
 jiraissue issue
 LEFT JOIN customfieldvalue code ON (issue.id = code.issue AND code.customfield = '11350')
 LEFT JOIN customfieldvalue proj ON (issue.id = proj.issue AND proj.customfield = '10085')
 JOIN issuestatus status ON (issue.issuestatus = status.id)
WHERE
 status.pname NOT IN ('Done','Closed') AND
 CONVERT(SUBSTRING_INDEX(issue.pkey,'-',-1),UNSIGNED INTEGER) NOT BETWEEN '3000' AND '13200' AND
 issue.pkey LIKE 'PROSVC%' AND
 (issue.created >= current_date()-10 OR issue.updated >= current_date()-10) AND
 (proj.stringvalue IS NULL OR proj.stringvalue = '0') AND
 issue.issuetype <> '23'
ORDER BY
 issue.pkey ASC";

my $sth = $dbh->prepare($proServicesAdminQuery) or die "Unable to set value to \$sth";

$sth->execute();

my ($userCode, $projectNumber, $projectAdmin, $projectRole, $primaryAdmin);

$sth->bind_columns(undef, \$userCode, \$projectNumber, \$projectAdmin, \$projectRole, \$primaryAdmin);

while( $sth->fetch() ) {
  print PROADMIN "\"$userCode\",\"$projectNumber\",\"$projectAdmin\",\"$projectRole\",\"$primaryAdmin\",\"\"\r\n";
}

$sth->finish();
$dbh->disconnect();

close PROADMIN;

my $output = `/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.0.x86_64/jre/bin/java -jar Import.jar --url http://### --username ### --password ### --import project_administrator --file ./csv/proAdmin.csv`;

open (LOG, ">>/var/log/unanet/jiraImportLog");
flock LOG,2;
print LOG "------------PRO SERVICES ADMIN------------\n";
print LOG $output;
close LOG;
