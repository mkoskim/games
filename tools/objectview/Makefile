###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=objectview.d

#------------------------------------------------------------------------------

EXE=
ENGINE = ../../engine/

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES = data/
BLOBFILES += engine/stock/generic
#BLOBFILES += local/

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/render/scene3d/glsl/
BLOBFILES += $(ENGINE)/render/postprocess/glsl/
BLOBFILES += $(ENGINE)/stock/system

include $(ENGINE)/build/Makegame.mak

