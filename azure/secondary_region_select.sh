#!/bin/bash
region=$1
file=./azure_primary_to_secondary_region_map.yaml
grep "^${region}:" $file |awk -F: '{print $NF}'|sed 's/^ *//g'
echo $secondary_region
