#!/bin/sh
###############################################################################
#
# Install system libraries
#
###############################################################################

#------------------------------------------------------------------------------

apt install libsdl2-dev				# SDL2
apt install libsdl2-image-dev		# SDL2 image formats
apt install libsdl2-ttf-dev			# SDL2 TTF fonts
apt install libassimp-dev			# ASSIMP
apt install liblua5.2-dev			# Lua

###############################################################################
#
# Get DMD compiler
#
###############################################################################

#DMD=2.067.1
DMD=2.073.2

#------------------------------------------------------------------------------

DMDDEB=dmd_$DMD-0_amd64.deb
DMDDEBFILE=../local/$DMDDEB

echo -n "Checking: " $DMDDEB "... "
if [ -f $DMDDEBFILE ]; then
	echo "Already loaded."
else
	echo "Not loaded."
	echo "Fetching: " $DMDDEB
	wget http://downloads.dlang.org/releases/2.x/$DMD/$DMDDEB -O $DMDDEBFILE
	sudo dpkg -i $DMDDEBFILE
fi

#------------------------------------------------------------------------------

