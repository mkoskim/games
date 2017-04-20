###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=objectview.d

#------------------------------------------------------------------------------

EXE=

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES = data/
BLOBFILES += engine/stock/unsorted
#BLOBFILES += local/

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/render/postprocess/glsl/
BLOBFILES += engine/stock/system

include engine/build/Makegame.mak

