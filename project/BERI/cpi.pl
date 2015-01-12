use strict;

open FILE, "<", $ARGV[0] or die $!;
my $cycles=0;
my $instructions=0;
my $lines=0;
my @delays;
my $totalDelay;
my $clusterCycles;
my $clusterInstructions;
my $percent;
my $i;
my $line;
my $cpi;
my $totbranchhits;
my $totbranchmisses;
my $totjumphits;
my $totjumpmisses;
my $totjumpreghits;
my $totjumpregmisses;
my $branchhits;
my $branchmisses;
my $jumphits;
my $jumpmisses;
my $jumpreghits;
my $jumpregmisses;
my $il1hits;
my $il1misses;
my $l1Rhits;
my $l1Rmisses;
my $l1Whits;
my $l1Wmisses;
my $l2Rhits;
my $l2Rmisses;
my $l2Whits;
my $l2Wmisses;
my $flushes;
my $quanta;
my $count;

print "Simulation Performance Report\n Each Quanta is 25k instructions.\n Format is Category : Hit Rate ( Total in Thousands )\n";
print "Quanta\tBranch Rate\tJump Rate\tJump Reg Rate\tIssued/Retired\tCycles Per Instruction\n";

while (<FILE>) {
  $line = $_;
  if ($line =~ /(\d+) dead cycles/) {
  	$cycles += $1;
	  $clusterCycles += $1;
  	$delays[$1] += $1;
  	$totalDelay += $1;
  }
  if ($line =~ /inst +\d+/) {
  	$cycles += 1;
	  $clusterCycles += 1;
  	$instructions += 1;
	  $clusterInstructions += 1;
  }
  if ($line =~ /\[\>BH/) {
  	$branchhits += 1;
  }
  if ($line =~ /\[\>BM/) {
  	$branchmisses += 1;
  }
  if ($line =~ /\[\>JH/) {
  	$jumphits += 1;
  }
  if ($line =~ /\[\>JM/) {
  	$jumpmisses += 1;
  }
  if ($line =~ /\[\>RH/) {
  	$jumpreghits += 1;
  }
  if ($line =~ /\[\>RM/) {
  	$jumpregmisses += 1;
  }
  if ($line =~ /Flush/) {
  	$flushes += 1;
  }
  if ($line =~ /\[\$IL1H/) {
  	$il1hits += 1;
  }
  if ($line =~ /\[\$IL1M/) {
  	$il1misses += 1;
  }
  if ($instructions%25000 == 0 && $instructions != 0) {
    $quanta += 1;
    print $quanta;
    if ($branchhits + $branchmisses != 0) {
      $cpi = sprintf("%2.3f", 100*$branchhits/($branchhits + $branchmisses));
      $count = sprintf("%3.2f", ($branchhits + $branchmisses)/1000);
      print "\t".$cpi."(".$count."k)";
    }
    if ($jumphits + $jumpmisses != 0) {
      $cpi = sprintf("%2.3f", 100*$jumphits/($jumphits + $jumpmisses));
      $count = sprintf("%3.2f", ($jumphits + $jumpmisses)/1000);
      print "\t".$cpi."(".$count."k)";
    }
    if ($jumpreghits + $jumpregmisses != 0) {
      $cpi = sprintf("%2.3f", 100*$jumpreghits/($jumpreghits + $jumpregmisses));
      $count = sprintf("%3.2f", ($jumpreghits + $jumpregmisses)/1000);
      print "\t".$cpi."(".$count."k)";
    }
    if ($il1hits + $il1misses != 0) {
      $cpi = sprintf("%2.3f", ($il1hits + $il1misses)/25000);
      print "\t".$cpi;
    }
    if ($clusterCycles != 0) {$cpi = sprintf("%2.3f", $clusterCycles/$clusterInstructions);}
    print "\t\tcpi:".$cpi."\n";
    $totbranchhits += $branchhits;
    $totbranchmisses += $branchmisses;
    $totjumphits += $jumphits;
    $totjumpmisses += $jumpmisses;
    $totjumpreghits += $jumpreghits;
    $totjumpregmisses += $jumpregmisses;
    $branchhits = $branchmisses = $jumphits = $jumpmisses = $jumpreghits = $jumpregmisses = 0;
    $il1hits = $il1misses = $l1Rhits = $l1Rmisses = $l1Whits = $l1Wmisses = $l2Rhits = $l2Rmisses = $l2Whits = $l2Wmisses = 0;
    $flushes = 0;
    $totalDelay = 0;
    $clusterCycles = 0;
    $clusterInstructions = 0;
    $instructions += 1;
  }
}

$cpi = $cycles/$instructions;
print "CPI = ".$cpi."\tBranch Rate:".$totbranchhits/($totbranchhits+$totbranchmisses)."\tJump Rate:".$totjumphits/($totjumphits+$totjumpmisses)."\tJump Register Rate:".$totjumpreghits/($totjumpreghits+$totjumpregmisses)."\n";
#$cpi = $misses/$branches;
#print "Branch miss rate = ".$cpi."\n";
