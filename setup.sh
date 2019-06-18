#!/bin/sh

###############################################################################
echo
echo Installing system libraries...
echo
###############################################################################

sudo apt-get install\
    python3\
    python3-tk\
    scons\
    libsdl2-dev\
    libsdl2-image-dev\
    libsdl2-ttf-dev\
    libsdl2-mixer-dev\
    libassimp-dev\
    liblua5.3-dev

###############################################################################
echo
echo Installing DMD compiler...
echo
###############################################################################

#DMD=2.067.1
#DMD=2.073.2
#DMD=2.080.0
#DMD=2.082.0
#DMD=2.085.1
DMD=2.086.0

DMDDEB=dmd_$DMD-0_amd64.deb
DMDDEBFILE=local/$DMDDEB

#------------------------------------------------------------------------------

echo -n "Checking: $DMDDEB... "

if [ -f $DMDDEBFILE ]; then
	echo "Already loaded."
else
	echo "Not loaded."
	echo "Fetching: " $DMDDEB
	wget http://downloads.dlang.org/releases/2.x/$DMD/$DMDDEB -O $DMDDEBFILE
	sudo dpkg -i $DMDDEBFILE
fi

###############################################################################

echo
echo Done.

