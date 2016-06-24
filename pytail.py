#!/usr/bin/env python 
# coding: utf-8

# Author: jacky fang#
import os
import time
import signal
import sys
import thread

_stop_interrupt = False
_stopped = False

_debug = False

def log(msg):
    if not _debug:
        return
    with open('tail.log', 'a+') as l:
        l.write(msg)


def watch(filepath, last_size=-1):
    if os.path.isfile(filepath):
        st = os.stat(filepath)
        log("size=" + str(st.st_size))
        if last_size == -1:
            return st.st_size
        if st.st_size > last_size:
            with open(filepath, 'r') as f:
                f.seek(last_size)
                sys.stdout.write(f.read()); sys.stdout.flush()  
                last_size = st.st_size
    return last_size


def start(filepath):
    last_size = -1
    while not _stop_interrupt:
        last_size = watch(filepath, last_size)
        time.sleep(0.5)
    else:
        global _stopped
        print "received SIGINT, exit!"
        _stopped = True


stop_times = 3


def wait_signal():
    def interrupt(sig, frame):
        global _stop_interrupt, stop_times
        _stop_interrupt = True
        time.sleep(0.3)
        if _stopped:
            pass
        elif stop_times <= 0:
            print "warn stop failed, force stop!"
            sys.exit(-1)
        else:
            stop_times -= 1
            interrupt(sig, frame)
        
    signal.signal(signal.SIGINT, interrupt)
    if sys.platform.startswith('win'):
        while 1:
            try:
                time.sleep(1)
            except IOError:
                break
    else:
        signal.pause()


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise TypeError('lack args! the usage: ptail <filepath>')
    thread.start_new(start, (sys.argv[1], ))
    wait_signal()
    
