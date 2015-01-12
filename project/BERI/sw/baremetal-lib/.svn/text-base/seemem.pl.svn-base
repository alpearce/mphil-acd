
my $response;
my @file;
while ($response !~ /accepted/) {
	`nios2-debug mem.elf > output.txt &`;
	sleep 2;
	open(IN, "output.txt"); 
	@file=<IN>;
	$response = join(/ /, @file); 
	if ($response !~ /accepted/) {
		`killall -r nios2*`;
	}
}
	
