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

#USECOMPILER = gdc

#------------------------------------------------------------------------------

SRCPATH += ~/.dub/packages/luad-master/
OBJS    += $(wildcard ~/.dub/packages/luad-master/extlib/x86_64-linux-gnu/liblua.a)

#------------------------------------------------------------------------------
# Add stock items to BLOB if you use them
#------------------------------------------------------------------------------

BLOBFILES += engine/render/scene3d/glsl/
BLOBFILES += engine/render/postprocess/glsl/
BLOBFILES += engine/stock/

include engine/build/Makegame.mak

