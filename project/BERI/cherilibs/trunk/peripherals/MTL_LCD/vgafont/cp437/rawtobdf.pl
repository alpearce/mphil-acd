#!/usr/bin/perl
# convert <W>x<H>.raw to cp437-<W>x<H>.bdf
# raw is an image of all chars on one line
use strict;

my ($width,$height) = $ARGV[0] =~ /^(\d+)x(\d+)\.raw$/;
if (!defined($width) || !defined($height) || scalar @ARGV != 1)
{
	print "usage: $0 <w>x<h>.raw\n";
	exit;
}

open INFILE,"<$ARGV[0]" or die "can't open $ARGV[0]: $!";
my $raw;
read INFILE,$raw,$width*$height*256;
close INFILE;

sub getpix
{
	my ($char,$x,$y) = @_;
	die if $x < 0 || $x >= $width ||
		$char < 0 || $char >= 256;
	my $pos = $char*$width + $y*256*$width + $x;
	my $cell = substr $raw,$pos,1;
	return 0 if $cell eq ".";
	return 1 if $cell eq "@";
	die "error - found '$cell' in .raw file";
}

sub getline
{
	my ($char,$y) = @_;
	die if $y < 0 || $y >= $height;
	my $sum = 0;
	die if $width > 8; # not going into this
	my $x;
	for ($x=0; $x<$width; $x++)
	{
		$sum += getpix($char,$x,$y) << (7-$x);
	}
	return $sum;
}

open OUTFILE,">cp437-${width}x${height}.bdf" or die "$!";
print OUTFILE <<HEADER;
STARTFONT 2.1
FONT cp437-${width}x$height
SIZE $height 100 100
FONTBOUNDINGBOX $width $height 0 0
STARTPROPERTIES 9
PIXEL_SIZE $height
POINT_SIZE 1
RESOLUTION_X 100
RESOLUTION_Y 100
FONT_ASCENT $height
FONT_DESCENT 0
AVERAGE_WIDTH 80
SPACING "C"
DEFAULT_CHAR 32
ENDPROPERTIES
CHARS 256
HEADER

my $swidth = $width*90;
my ($char,$y);
for ($char=0; $char<256; $char++)
{
	print OUTFILE "STARTCHAR $char\n";
	print OUTFILE "ENCODING $char\n";
	print OUTFILE "SWIDTH $swidth 0\n";
	print OUTFILE "DWIDTH $width 0\n";
	print OUTFILE "BBX $width $height 0 0\n";
	print OUTFILE "BITMAP\n";

	for ($y=0; $y<$height; $y++)
	{
		printf OUTFILE "%02x\n", getline($char,$y);
	}

	print OUTFILE "ENDCHAR\n";
}

print OUTFILE "ENDFONT\n";
close OUTFILE;

