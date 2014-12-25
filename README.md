Game projects with common engine
================================

-------------------------------------------------------------------------------

Quick history
-------------

Programming has always been one of my hobbies, and programming
games has always had a place in my heart. At Sep 2014, I started
to make a game, and it was clear at the beginning that I put
reusable parts to separate directory tree to ease making other
games.

I started with Python and SDL (CPU side rendering). It came soon
clear that it is too slow for my purposes, so I switched to
Python + OpenGL. I tried some game engines, but professional
ones were too complex, and I didn't like the lightweight ones
I tried.

I switched to C++ using OpenGL and glm, but I quickly remembered
why I haven't used C++ on my freetime projects to anything larger
than a single file.

I evaluated two different languages to continue my work: D and Go.
I was already somewhat familiar to D, as I made virtual machine part
of my MSc with that. I have no exact reasons to prefer D over Go,
but as I got it up and running OpenGL and SDL quite easily, I decided
to go with that.


-------------------------------------------------------------------------------

Current situation
-----------------

I have mainly worked with engine internals, especially thinking,
designing and experimenting architecture. That work is far from
done, you can read my TODO file to get some idea about the
work to be done:

   engine/doc/TODO

You can also take a look to engine/doc/CHANGELOG to see things that
have been worked with and somewhat solved.

If you look to projects/ directory, you will see that many directories
are quite empty at the moment. My game projects act as drivers for
engine development. In many ways, they act as unit tests for the
engine.

Currently there are three projects that I use to evaluate my engine:

   * projects/pacman: this is plain old pacman. When I make larger
     changes to engine architecture, I first try to make pacman
     working again.
     
   * projects/wolfish: Wolfenstein-like FPS pseudo 3D game project.
     In a way, this is just small step from pacman-like pure 2D
     maze game to 3D world. I have used this game project to examine
     various basic 3D rendering issues (like normal mapping).

   * projects/cylinderium: Cylinderium is the first more originel
     game idea. It is aimed to be Uridium-like shoot'em up with
     rolling platform. Currently, it is used to as a test bench
     to sketch architecture for (CPU-side) animations.

   * projects/sketch: This is common 'sketching table' when
     changes are too large or complex to be done with pacman, or
     if none of the projects use the feature.

There are some game projects waiting the engine to grow. The most
important at the moment are:

   * projects/platform: My intention is to use simple 2D platform
     game as test bench when starting to work with physics engine.
     My intention is to bind bullet physics engine to the engine.
     
   * 'Doomish', 'Quakish' - at some point, there is a need to
     extend wolfish to have mazes in truely three dimensions, and
     at that point Doom/Quake-like FPS project can be a good
     intermediate step forward.

   * projects/guerrilla: This is intended to be third person
     shooter with modern weapons (assault riffle).

   * projects/space: This is a placeholder for some kind of space
     ship shooter.
     
   * projects/rtstrategy: This is a placeholder for some kind of real
     time stragety game. I have thought to use such game to study
     game AI.

Some very special projects are:     

   * moe3d: I have text editor called 'moe', aimed for story writers.
     This is a placeholder to make it utilize 3D graphics.

   * yofrankie (and/or some other Blender game): Games are collaborative
     efforts of programmers and artists. As modeling tools like Blender
     is used by artists, my intention is to have at least limited
     integration to file formats they use. Blender files can contain
     even an entire game, which makes it very interesting format for
     game developer.
     
     My intention is to reuse Blender game graphics, sounds, animations
     and such, and rewrite the game logic with my engine.

-------------------------------------------------------------------------------

Some design principles and future directions
--------------------------------------------

Simplicity: The engine is mainly meant for me to implement game projects I
find interesting. It is not meant to be the best, fastest or most feature-rich
game engine in the world. No, it is mostly targeted for game prototyping
and demonstrations, and the intention is that you change to better
engine when your game grows and exceeds the limitations of a simple engine.

"Portability": Simplicity may be one driver for architecture, but at the same
time, I feel it also important that the engine works with somewhat similar
principles as better game engines like Ogre3D and alike, so that moving to other
engine would not cause huge architectural changes for your game prototype.

To achieve that, I have tried to implement some common techniques used by
other engines.

Small code base: As long as my architecture is evolving, I try to keep my
source base (both engine and projects) small. The smaller the code base,
the easier it is to make architectural changes.

Error reporting: My principle has been that any error the engine catches
will crash the game. Catching errors can greatly decrease the time you
waste for debugging. For the same reason, I try not to expose unstable
interfaces outside - I know it is too tempting for me to use shortcuts,
and then debug several days only to find a 'stupid user error' - and
if I do that, I try to keep it as temporal solution.

