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

BLOBFILES=data/

#------------------------------------------------------------------------------

BLOBFILES += local/

#------------------------------------------------------------------------------
# Add stock items to BLOB if you use them
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/render/postprocess/glsl/
BLOBFILES += engine/stock/

include engine/build/Makegame.mak

