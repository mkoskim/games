###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=empty

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

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/render/scene3d/glsl/
BLOBFILES += $(ENGINE)/render/postprocess/glsl/
BLOBFILES += $(ENGINE)/stock/system

include $(ENGINE)/build/Makegame.mak

