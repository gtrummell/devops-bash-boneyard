#!/bin/bash

sudo kill -9 `sudo ps -ef|grep line|grep -v grep|awk '{print $2}'`
