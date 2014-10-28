#!/usr/bin/env python

log = open('out','r')
log_0 = open('out_node0', 'w')
log_1 = open('out_node1', 'w')

line = log.readline()

while line != '':
    if(line.find('NODE:  0') > -1):
        log_0.write(line)
    else:
        log_1.write(line)

    line = log.readline()
   
log.close()
log_0.close() 
log_1.close()
