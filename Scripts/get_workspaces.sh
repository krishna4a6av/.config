#!/bin/bash

niri msg workspaces | awk '
BEGIN {
    print "["
    first = 1
}
NR > 1 {
    if ($0 ~ /^[ ]*\* /) {
        if (!first) {
            print ","
        }
        name = $0
        sub(/^[ ]*\* /, "", name)
        print "    {\"name\": \"" name "\", \"is_active\": true}"
        first = 0
    } else if ($0 ~ /^[ ]*[0-9]+$/) {
        if (!first) {
            print ","
        }
        name = $0
        sub(/^[ ]*/, "", name)
        print "    {\"name\": \"" name "\", \"is_active\": false}"
        first = 0
    }
}
END {
    print "]"
}'
