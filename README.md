Game projects with common engine
================================

~~Reinventing~~ Reconstructing the wheel - it is a way to learn how
things work.

---

Cloning repository with submodules:

`git clone https://github.com/mkoskim/games.git --recursive`

---

**NOTE:** Currently I am working - when working - with (1) new asset loading
system based on assimp, (2) integrating lua for loading assets, and then
(3) restructure shader engine to match the changes. At the moment, 
most of the examples do not compile. The one that I am using to develop is:

tools/objectviewer

Feel free to try it, and browse the rest of the code.

---

**Description:** See:

[games wiki](https://github.com/mkoskim/games/wiki)

[Engine Architecture (googledocs)](https://drive.google.com/open?id=1naIU1XoFX2Qmj-EIo02rn3QQdQ-95cXKt9H4fcCajGo&authuser=0)

**TODO:** Things that need to be done, many of them affecting to architecture:

[TODO](https://github.com/mkoskim/games/blob/master/engine/doc/TODO)

**Installing:** See:

[INSTALL](https://github.com/mkoskim/games/blob/master/INSTALL)

---

*New:* This project now takes D libraries as git submodules, so dub is no
more needed. Hopefully I can keep up with versions...

