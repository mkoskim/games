###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=luademo.d

#------------------------------------------------------------------------------

EXE=

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

BLOBFILES=data/

#------------------------------------------------------------------------------

SRCPATH += ~/.dub/packages/luad-master/
OBJS    += engine/libs/linux64/liblua5.1.a

#------------------------------------------------------------------------------
# Add stock items to BLOB if you use them
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/render/postprocess/glsl/
BLOBFILES += engine/stock/

include engine/build/Makegame.mak

