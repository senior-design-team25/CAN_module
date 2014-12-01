#!/usr/bin/env python

log = open('out','r')
log_0 = open('out_node0', 'w')
log_1 = open('out_node1', 'w')
log_2 = open('out_node2', 'w')
log_3 = open('out_node3', 'w')

line = log.readline()

while line != '':
    if(line.find('NODE:  0') > -1):
        log_0.write(line)
    elif(line.find('NODE:  1') > -1):
        log_1.write(line)
    elif(line.find('NODE:  2') > -1):
        log_2.write(line)
    elif(line.find('NODE:  3') > -1):
        log_3.write(line)

    line = log.readline()
   
log.close()
log_0.close() 
log_1.close()
log_2.close()
log_3.close()
