###############################################################################
#
# Set up default things: shared by config & build scons
#
###############################################################################

Import("*")

#------------------------------------------------------------------------------

env["ENGINE"] = env.Dir("../../").abspath

#------------------------------------------------------------------------------

import platform

env["PLATFORM"] = platform.system()

#------------------------------------------------------------------------------
#
# Merge directories from system path: We assume, that user has modified
# system environment to has correct directories in the path, so we try to
# utilize it. But at the same time, we want to preserve everything added
# to path by top level scripts.
#
#------------------------------------------------------------------------------

import os

env["ENV"]["PATH"] = os.pathsep.join(
    set(env["ENV"]["PATH"].split(os.pathsep)) |
    set(os.environ["PATH"].split(os.pathsep))
)

#------------------------------------------------------------------------------
# Print out information
#------------------------------------------------------------------------------

print("Build platform:", env["PLATFORM"])
#print(env.subst("$PROGSUFFIX"))
