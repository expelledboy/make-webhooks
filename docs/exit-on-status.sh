#!/bin/bash

if [ "$1" == "run-webhook" ]; then
  exit $(curl -s http://localhost/crash | jq '.status')
fi
