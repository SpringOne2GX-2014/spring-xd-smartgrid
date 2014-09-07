#!/bin/bash
/home/ubuntu/apache-jmeter-2.11/bin/jmeter -n -p user.properties -t SmartGrid.jmx -l generate-results.jtl

