#!/usr/bin/env python

import sys
import array
import subprocess

def extract_name_and_data(line):
    image_name = line.split(' ', 1)[0][len('START'):]
    start = 'START' + image_name + ' '
    return image_name, line.strip()[len(start):-len('END')]

def get_data(text_data):
    result = []
    for i in range(0, len(text_data), 2):
        byte_hex = text_data[i:i+1]
        result.append(int(byte_hex, 16))
    return result

def main():
    for line in [l.rstrip() for l in sys.stdin.readlines()]:
        if line.startswith('START'):
            image_name, image_data = extract_name_and_data(line)
            with open(image_name.lower() + '_data', 'wb') as mandelbrot_file:
                mandelbrot_file.write(image_data)
        else:
            print line
            
if __name__ == '__main__':
    main()
