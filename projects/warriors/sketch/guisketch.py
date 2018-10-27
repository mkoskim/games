#!/usr/bin/env python3
###############################################################################
#
# Sketching GUI (non-realtime part)
#
###############################################################################

import sys

print("Python version:",  ".".join(map(str, sys.version_info[:3])))
if sys.version_info.major < 3:
    print("Need Python 3")
    exit(-1)
    
#------------------------------------------------------------------------------
# How it works?
#
# Build window: In build window, you can (1) select a character or create new
# one, (2) select a class, and (3) tailor your build.
#
# Character Window: Choose achievements to enable apparel, choose apparel to
# certain dungeon blocks.
#
#------------------------------------------------------------------------------

from tkinter import *
import tkinter.ttk as ttk

###############################################################################
#
###############################################################################

#------------------------------------------------------------------------------
# Build is what player plays. It has specializations (including class) and
# visual representation (toon).
#------------------------------------------------------------------------------

class Build:

    def __init__(self, toon, spec):
        self.spec = spec
        self.toon = toon

#------------------------------------------------------------------------------
# Specializations / specification is the spec of the build: class, traits,
# etc etc
#------------------------------------------------------------------------------

class Spec:

    def __init__(self, cls):
        self.cls = cls

#------------------------------------------------------------------------------
# Toon is a visual representation of player / build. Toons have "diary":
# it is list of chosen achievements, which then decide the options the player
# has for outlook. Achievements come in two level: account-wide, and toon-
# specific.
#------------------------------------------------------------------------------

class Toon:

    def __init__(self, name, race):
        self.name = name
        self.race = race

#------------------------------------------------------------------------------
# Account ties all together (builds, toons and such)
#------------------------------------------------------------------------------

class Account:

    def __init__(self):
        self.toons = [
            Toon("Toon A", "Nord"),
            Toon("Toon B", "Human"),
            Toon("Toon C", "Human"),
        ]

        self.builds = [
            Build(self.toons[0], "Warrior"),
            Build(self.toons[0], "Hunter"),
        ]

account = Account()

###############################################################################
#
###############################################################################

class MainWindow(Frame):

    def quit(self, event):
        self.master.destroy()
        
    #--------------------------------------------------------------------------

    def __init__(self, master=None):
        super(MainWindow, self).__init__(master, pady = 5, padx = 5)

        #----------------------------------------------------------------------

        self.master = master
        self.master.title("Warriors")
        self.master.bind("<Escape>", self.quit)
        self.pack(fill=BOTH, expand=1)

        #----------------------------------------------------------------------
        # Main selections
        #----------------------------------------------------------------------

        self.mainmenu = Listbox(self)
        self.mainmenu.pack(anchor = NW, side = LEFT)
        
        for choice in ["Dungeons", "Builds", "Toons", "Account"]:
            self.mainmenu.insert(END, choice)

        #----------------------------------------------------------------------
        # Player's builds
        #----------------------------------------------------------------------

        self.buildlist = Listbox(self)
        self.buildlist.pack(anchor = NW, side = LEFT)

        for build in account.builds:
            self.buildlist.insert(END, "%s: %s" % (build.toon.name, build.spec))
        self.buildlist.insert(END, "<New build>")

        #----------------------------------------------------------------------
        # Player's toons
        #----------------------------------------------------------------------

        self.toonlist = Listbox(self)
        self.toonlist.pack(anchor = NW, side = LEFT)

        for toon in account.toons:
            self.toonlist.insert(END, toon.name)
        self.toonlist.insert(END, "<New toon>")

    #--------------------------------------------------------------------------


###############################################################################
#
###############################################################################

root = Tk()
root.geometry("1200x800")
app = MainWindow(root)
root.mainloop()

