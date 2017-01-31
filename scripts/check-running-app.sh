#!/bin/bash

if pgrep -x "java" > /dev/null
then
  exit 0
else
  exit 1
fi
