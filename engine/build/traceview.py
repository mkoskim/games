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
    if len(fields) != 5: continue
    try:
        for i in range(0, 4): fields[i] = int(fields[i])
        records.append(fields)
    except ValueError: pass
    except IndexError: pass

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

print "%12s %12s %12s %12s" % ("Tree Time", "Func Time", "Per Call", "Num Call")
print

for record in records:
    print "%12d %12d %12d %12d   %s" % (record[1], record[2], record[3], record[0], record[4])

