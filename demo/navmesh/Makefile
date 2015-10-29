###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=navmesh.d

#------------------------------------------------------------------------------

EXE=

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

BLOBFILES = data/

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES += engine/stock/unsorted

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/render/postprocess/glsl/
BLOBFILES += engine/stock/system

include engine/build/Makegame.mak

