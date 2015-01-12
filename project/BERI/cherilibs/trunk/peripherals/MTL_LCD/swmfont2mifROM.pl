#!/usr/bin/perl
#-
# Copyright (c) 2012 Simon W. Moore
# All rights reserved.
#
# This software was previously released by the author to students at
# the University of Cambridge and made freely available on the web.  It
# has been included for this project under the following license.
# 
# This software was developed by SRI International and the University of
# Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-10-C-0237
# ("CTSRD"), as part of the DARPA CRASH research programme.
#
# @BERI_LICENSE_HEADER_START@
#
# Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  BERI licenses this
# file to you under the BERI Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.beri-open-systems.org/legal/license-1-0.txt
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @BERI_LICENSE_HEADER_END@
#
#*****************************************************************************
#
# This is a nasty hacked up script used once to convert an X11 font
# into a memory initialisation file (mif)
#
# Notes on usage:
# grabed a pcf font from:
#   /usr/share/fonts/X11/misc/8x13-ISO8859-10.pcf.gz
# created bdf font from pcf using fontforge (just used "SaveAs" in GUI)
#
#MIF file format example from Quartus help:
#
#    DEPTH = 32;                   -- The size of data in bits
#    WIDTH = 8;                    -- The size of memory in words
#    ADDRESS_RADIX = HEX;          -- The radix for address values
#    DATA_RADIX = BIN;             -- The radix for data values
#CONTENT                       -- start of (address : data pairs)
#BEGIN
#
#    00 : 00000000;                -- memory address : data
#    01 : 00000001;
#    02 : 00000010;

use strict;

# input file and its final dimensions:
# my $filein="8x13-ISO8859-10-13.bdf";
# my $maxnumchar=128;
my $filein="cp437-8x12.bdf";
my $maxnumchar=256;
my $capheight=9;
my $fontheight=13;
my $charheightrom=16; # 16 words per character in the ROM even for 12 line font

open(FIN,"<",$filein) or die "Failed to open ".$filein;

print "WIDTH = 8;\n";
printf("DEPTH = %d;\n",$maxnumchar*$charheightrom);
print "ADDRESS_RADIX = HEX;\n";
print "DATA_RADIX = BIN;\n";
print "CONTENT\nBEGIN\n";

my $state=0;
my @t;
my $nextchar="";
my $j=0;
my $h=0;
my $shape;
my $width=0;
my $height=0;
my $xoffset=0;
my $yoffset=0;
my $linenum=0;
my $addr=0;
my $binary="";

LINE: while(<FIN>) {
    chomp;
    @t = split(/ /,$_);
#    if($t[0] eq "STARTCHAR") {
#	print $_,"\n";
#    }
    if($state==0) {
	if($_ eq "BITMAP") {
	    $state=1;
	    $linenum=0;
#	        printf("                             // +--------+\n");
	    for($j=0; $j<($capheight-$height-$yoffset); $j++) {
#		printf("rom[12'h%03x] <= 8'b00000000; // |........|\n",$addr);
		printf("%03x : 00000000;\n",$addr);
		$addr++;
		$linenum++;
	    }

	} elsif($t[0] eq "BBX") {
#	    print "BBX: ",join(",",@t[1..4]),"\n";
	    $width=$t[1];
	    $height=$t[2];
	    $xoffset=$t[3];
	    $yoffset=$t[4];
	} else {
	    if($t[0] eq "ENCODING") {
		$nextchar=$t[1];
		if($nextchar>=$maxnumchar) {
		    last LINE;
		}
#		if($nextchar>=32) {
#		    print "/////////////////////////////// Charcter ",$nextchar," = ",chr($nextchar),"\n";
#		} else {
#		    print "/////////////////////////////// Charcter ",$nextchar," = ctrl-",chr($nextchar+64),"\n";
#		}
	    }
	}
    } elsif($state==1) {
	if($_ eq "ENDCHAR") {
	    $state=0;
	   # for($j=0; $j<($fontheight-$capheight+$yoffset); $j++) {
	    if($fontheight<16) { $fontheight=16; }
	    for(; $linenum<$fontheight; $linenum++) {
		printf("%03x : 00000000;\n",$addr);
#		printf("rom[12'h%03x] <= 8'b00000000; // |........|\n",$addr);
		$addr++;
	    }
#	        printf("                             // +--------+\n");
	} else {
	    $h=hex($_)>>$xoffset;
	    $shape="";
	    $binary="";
	    for($j=0; $j<8; $j++) {
		$shape=(($h & 0x1)==1 ? "*" : " ").$shape;
		$binary=(($h & 0x1)==1 ? "1" : "0").$binary;
		$h=$h>>1;
	    }
	    printf("%03x : %s;\n",$addr,$binary);
#	    printf("rom[12'h%03x] <= 8'b%s; // |%s|\n",$addr,$binary,$shape);
	    $addr++;
	    $linenum++;
	}
    }
}
for(; $addr<2048; $addr++) {
    printf("%03x : 00000000;\n",$addr);
#    printf("rom[12'h%03x] <= 8'b00000000;\n",$addr);
}
close(FIN);

printf("END;\n");

exit;
