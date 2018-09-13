###############################################################################
#
#
#
###############################################################################

MAIN=wolfish.d

#------------------------------------------------------------------------------

EXE=
ENGINE = ../../engine/

LDFLAGS=
LIBDIRS=
LIBS=
OBJS=

BLOBFILES=data/

#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/stock/unsorted

#------------------------------------------------------------------------------
# Add items you use to BLOB.
#------------------------------------------------------------------------------

BLOBFILES += $(ENGINE)/render/scene3d/glsl/
BLOBFILES += $(ENGINE)/render/postprocess/glsl/
BLOBFILES += $(ENGINE)/stock/system

include $(ENGINE)/build/Makegame.mak

