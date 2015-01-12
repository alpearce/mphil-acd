#-
# Copyright (c) 2013 Colin Rothwell
# All rights reserved.
#
# This software was developed by Colin Rothwell as part of his final year
# undergraduate project.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
#!/usr/bin/env python

import sys
import re

def extract_results(result_string):
    pattern = r"(?P<count>\d+): (?P<tag>\w+) Result (?P<value>[0-9a-f]{8})\n"
    return re.findall(pattern, result_string)

def extract_results_from_file(filename):
    with open(filename) as fil:
        return extract_results(fil.read())

def main():
    if len(sys.argv) != 3:
        print 'Usage: compare_transcripts.py <transcript file> <transcript file>'
        return 1

    first_results = extract_results_from_file(sys.argv[1])
    second_results = extract_results_from_file(sys.argv[2])

    if first_results == second_results:
        print "Match!"
    else:
        print "Mismatch :("
        for i in range(len(first_results)):
            first = first_results[i]
            second = second_results[i]
            diff = abs(int(first[2], 16) - int(second[2], 16))
            if first != second:
                print first, second, 'Difference:', diff


if __name__ == '__main__':
    main()
