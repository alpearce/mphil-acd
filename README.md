# mphil-acd
Final project for Advanced Computer Design at Cambridge

I implemented a basic hardware compression module for use with streaming traces from the BERI processor to the software debugging unit. Compression was based on the VPC compression algorithms (http://www.computer.org/csdl/trans/tc/2005/11/t1329-abs.html). Some compression was achieved, but I found that overall, the VPC software algorithms are not the best model for implementing hardware compression for stream tracing. 
