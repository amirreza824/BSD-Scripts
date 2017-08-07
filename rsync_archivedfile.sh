#!/bin/sh

for i in /usr/home/amir/*
do
    if ! `fstat ${i} | grep -q " w "`; then
        scp ${i} 10.10.10.1:/root/OLD_LOGGER/amir/
    fi
done
