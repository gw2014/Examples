#!/usr/bin/perl

use DBI;

my @pmrlist;
my $pmrcount = 0;
my $pmrtotal = 0;

open (STDERR, ">/dev/null");
# open (STDERR, ">/home/greg/scripts/delta.err");

# open (FILE, ">/home/greg/scripts/delta.csv");

my $dbh = DBI->connect('DBI:mysql:jiradb:localhost:3306', '###', '###');
die "Unable for connect to server $DBI::errstr" unless $dbh;

my $query =
"SELECT
 pkey
FROM
 jiraissue
WHERE
 (pkey like 'PLAT-%' OR
 pkey like 'TITAN-%' OR
 pkey like 'PROSVC-%') AND
 issuetype <> '23'
ORDER BY
 pkey ASC";

my $sth = $dbh->prepare($query) or die "Unable to set value to \$sth";

if($sth->execute) {
  $pmrcount = 0;
  while(my @dat = $sth->fetchrow) {
    foreach (@dat) {
      $pmrlist[$pmrcount] = $_;
      $pmrcount++;
    }
  }
  $pmrtotal = $pmrcount;
}

$pmrcount = 0;

while ($pmrcount < $pmrtotal) {
  my $query2 =
  "SELECT
    distinct jiraissue.pkey,
    (SELECT
      customfieldvalue.numbervalue
     FROM
      customfieldvalue LEFT JOIN jiraissue ON (jiraissue.id = customfieldvalue.issue) AND customfieldvalue.customfield = 10060
     WHERE
      jiraissue.pkey = '$pmrlist[$pmrcount]') -
    (SELECT
      customfieldvalue.numbervalue
     FROM
      customfieldvalue LEFT JOIN jiraissue ON (jiraissue.id = customfieldvalue.issue) AND customfieldvalue.customfield = 10100
     WHERE
      jiraissue.pkey = '$pmrlist[$pmrcount]') AS 'delta'
   FROM
    jiraissue
    JOIN customfieldvalue ON (jiraissue.id = customfieldvalue.issue)
   WHERE
    jiraissue.pkey = '$pmrlist[$pmrcount]'";

  my $sth = $dbh->prepare($query2) or die "Unable to set value to \$sth";

  $sth->execute();

  my ($pkey, $delta);

  $sth->bind_columns(undef, \$pkey, \$delta);

  while( $sth->fetch() ) {
    if (($delta) && ($delta != 0)) {
      my $update = qq(
      UPDATE
       jiraissue,
       customfieldvalue
      SET
       customfieldvalue.numbervalue = '$delta'
      WHERE
       jiraissue.id = customfieldvalue.issue AND
       jiraissue.pkey = '$pkey' AND
       customfieldvalue.customfield = 10110);
      $dbh->do($update);
    }
  }
++$pmrcount;
}

$dbh->disconnect();
