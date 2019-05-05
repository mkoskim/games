Game projects with common engine
================================

~~Reinventing~~ Reconstructing the wheel - it is a way to learn how
things work.

---

**Linux Mint 18 (64-bit):** Installing:

```
$ git clone https://github.com/mkoskim/games.git --recursive
$ cd games
games$ ./setup.sh
```

For more info: [INSTALL](https://github.com/mkoskim/games/blob/master/INSTALL)

---

**Building:** To get debugging logs from running executables, I wrote a script (engine/build/logger.py) which can be used to view and filter them. Consult also engine/utils/logger.d to see, how log lines are sent from executable to the tool. As I want this tool to be persistent, it can also be used to compile & run projects. The easiest way to use logger.py for any project is to use scons to launch it:

```
games$ cd tools/objectview
objectview$ scons logger
```

Now you can press "Build & Run" button to build and run the project, and catch the log lines to the tool. The tool itself is of course anything but complete, but it will already help you by separating so called "log lines" (sort of oneshot info from execution) from "watch values" (sort of frequently updated values for certain tag) to separate tabs.

---

**NEW:** I have made some preliminary 32-bit **Windows** build. Some information can be found here: [WINDOWS.txt](https://github.com/mkoskim/games/blob/master/WINDOWS.txt)

At the moment, I can get few running versions of projects when using preliminary scons build script:

```
testbench/empty$ scons run
tools/objectview$ scons run
```

Getting objectview working is generally good news, as it opens OpenGL window, loads assets with ASSIMP, and shows them on the screen.

---

**NOTE:** Currently I am working - when working - with (1) new asset loading system based on assimp, (2) integrating lua for loading assets, and then (3) restructure shader engine to match the changes. At the moment, most of the examples do not compile. The one that I am using to develop is `tools/objectviewer`. Feel free to try it, and browse the rest of the code.

---

**Description:** See:

[games wiki](https://github.com/mkoskim/games/wiki)

[Engine Architecture (googledocs)](https://drive.google.com/open?id=1naIU1XoFX2Qmj-EIo02rn3QQdQ-95cXKt9H4fcCajGo&authuser=0)

**TODO:** Things that need to be done, many of them affecting to architecture:

[TODO](https://github.com/mkoskim/games/blob/master/engine/doc/TODO)

---

**Other similar projects:**

* [Dash](https://github.com/Circular-Studios/Dash)

* [Dagon](https://github.com/gecko0307/dagon)

* [GFM](https://github.com/d-gamedev-team/gfm)

* [DAllegro](https://github.com/SiegeLord/DAllegro5)

* [unecht](https://github.com/Extrawurst/unecht)
