#! /usr/bin/env python

import sys
import os.path as path

TEST_DIRECTORY = "/home/cr437/ctsrd/cheritest/trunk/tests/"
TEST_PREFIX = TEST_DIRECTORY + "fpu_synth/test_raw_fpu_synth_"
TEST_SUFFIX = ".s"

def extract_test_lines(file):
    extracting_lines = False
    lines = []
    for line in file:
        stripped_line = line.strip()
        if extracting_lines and stripped_line != "":
            if stripped_line == "# END TEST":
                break
            else:
                lines.append(stripped_line)
        elif stripped_line == "# START TEST":
            extracting_lines = True
    return lines

def convert_to_c_line(line):
    wrapper = 'asm("{0}");'
    comment = '// {0}'
    parts = [part.strip() for part in line.split("#")]
    if len(parts) == 1: # No comment
        ins = parts[0]
        if ins.startswith('dmfc1'):
            ins = 'dmfc1 $t0, {0}'.format(ins.split(',')[1]).strip()
            ins = wrapper.format(ins)
            ins += '\nerr=CoProFPTestEval(0x,out(),t_num++,err);'
            return ins
        else:
            return wrapper.format(ins)
    else:
        ins_result = wrapper.format(parts[0])
        cmt_result = comment.format(parts[1])
        if parts[0] == '':
            return cmt_result
        else:
            return ' '.join((ins_result, cmt_result))

def main():
    if not 0 < len(sys.argv) < 3:
        print "Usage port_test.py <test file or name>"
        print
        print "If the file is not found, the test name will be consulted."
        return 1

    if len(sys.argv) == 1:
        statements = sys.stdin.readlines()
    else:
        file_name = sys.argv[1]
        if not path.exists(file_name):
            file_name = TEST_PREFIX + file_name + TEST_SUFFIX

        with open(file_name) as file:
            statements = extract_test_lines(file)

    print '\n'.join(map(convert_to_c_line, statements))

if __name__ == '__main__':
    sys.exit(main())
