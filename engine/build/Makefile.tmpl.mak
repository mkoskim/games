###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=

BLOBFILES=data/

#------------------------------------------------------------------------------

EXE=

#------------------------------------------------------------------------------

LIBDIRS=
LIBS=
LDFLAGS=

#------------------------------------------------------------------------------
# Add stock items to BLOB if you use them
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/stock/

include engine/build/Makegame.mak

