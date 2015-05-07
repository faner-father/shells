#!/bin/bash

ifconfig|grep 'inet addr'|tr -s '\t' ' '|cut -d ' ' -f 3|cut -d ':' -f 2|grep \
    -v '127'
