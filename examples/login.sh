#!/bin/bash

FLY=${FLYBIN:-fly}

$FLY -t test_main login -c http://localhost
