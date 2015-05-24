#!/usr/bin/env python
###############################################################################
#
# Examine trace files: Extract only function call timings, and sort them
# by call tree time (and later maybe with other fields).
#
###############################################################################

import sys

if len(sys.argv) < 2:
    print "Usage: traceview {by_treetime | by_numcalls}"
    sys.exit(-1)

#------------------------------------------------------------------------------
# Extract info
#------------------------------------------------------------------------------

records = []

for line in open("trace.log").read().split("\n"):
    fields = line.split(None, 4)
    if len(fields) == 5:
        try:
            for i in range(0, 4): fields[i] = int(fields[i])
            records.append(fields)
        except ValueError: pass

#------------------------------------------------------------------------------
# Sort
#------------------------------------------------------------------------------

records = {
    "by_treetime": reversed(sorted(records, key = lambda r: r[1])),
    "by_numcalls": reversed(sorted(records, key = lambda r: r[0])),
}[sys.argv[1]]

#------------------------------------------------------------------------------
# Print back
#------------------------------------------------------------------------------

header = [
    ["Num Call", "Tree Time", "Func Time", "Per Call", ""],
    5 * [""],
]

for record in header + list(records):
    print "%12s %12s %12s %12s   %s" % tuple(record[i] for i in [1, 2, 3, 0, 4])


