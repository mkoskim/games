###############################################################################
#
# Game Makefile template
#
###############################################################################

MAIN=portal.d

BLOBFILES=data/

#------------------------------------------------------------------------------

EXE=
ENGINE = ../../engine/

LIBDIRS=
LIBS=
LDFLAGS=

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)engine/stock/unsorted

#------------------------------------------------------------------------------
# Directories containing files used by the engine itself.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/render/scene3d/glsl/
BLOBFILES += $(ENGINE)/render/postprocess/glsl/
BLOBFILES += $(ENGINE)/stock/system

include $(ENGINE)/build/Makegame.mak

