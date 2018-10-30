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
# 
#
###############################################################################

#------------------------------------------------------------------------------
# Specializations: Just listing some common MMORPG classes as example
#------------------------------------------------------------------------------

specs = [
    "Warrior", "Barbarian", "Knight",
    "Hunter", "Archer",
    "Druid", "Sorcerer", "Mage",
    "Thief", "Nightblade", "Assassin",
]

#------------------------------------------------------------------------------
# Races: Races limit the class options you have. Just some example listing.
#------------------------------------------------------------------------------

races = [
    "Nord", "Human",
    "Elf", "Dwarf",
]

#------------------------------------------------------------------------------
# Can we have something similar to Oblivion Birthsign / Skyrim Standing Stone
# for toons? Something similar to GW2 Norn spirit guides (Raven, Bear, Wolf,
# Snow Leopard)?
#------------------------------------------------------------------------------


###############################################################################
#
###############################################################################

#------------------------------------------------------------------------------
# Achievements data structure. When account is rewarded, check if that
# completes some achievements.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# Dungeon reward structure: what trophies are given when dungeon is
# completed. Rewards probably need to be divided to two parts: (1) rewards
# tracked per class (for account and toon), and (2) generic rewards (like
# gold coins, vendor currencies) which are tracked by account only.
#
# Let try this way: (1) rewards are account-wide items, (2) trophies are
# class specific items for account & toon. Account tracks total number of
# trophies received.
#
# TODO: How to implement mentor chest? This is given to other accounts, if
# someone in the group gets the first achievement.
# TODO: How to implement challenge quests? Challenges are optional objectives
# for dungeons.
#
#------------------------------------------------------------------------------

class Dungeon:

	def __init__(self, name, trophies, rewards):
		self.name = name
		self.trophies = trophies
		self.rewards  = rewards

	def completed(self, account):
		account.reward(self.trophies, self.rewards)

dungeons = [
	Dungeon("Dungeon A T1", ["Dungeon A T1"], [ "T1 chest" ]),
	Dungeon("Dungeon A T2", ["Dungeon A T2"], [ "T1 chest", "T2 chest" ]),
	Dungeon("Dungeon A T3", ["Dungeon A T3"], [ "T1 chest", "T2 chest", "T3 chest" ]),
]

#------------------------------------------------------------------------------
# Vendors are entities, which translate items to another. These items are
# trophies in account / toon wallet.
#------------------------------------------------------------------------------

class Vendor:

	def __init__(self):
		pass

#------------------------------------------------------------------------------
# Toon is a visual representation of player / build. Toons have "diary":
# it is list of chosen achievements, which then decide the options the player
# has for outlook. Achievements come in two level: account-wide, and toon-
# specific.
#------------------------------------------------------------------------------

class Toon:

    #--------------------------------------------------------------------------

	def __init__(self, name, race):
		self.name = name
		self.race = race
		
		self.trophies = { }		# Trophies collected by this toon (per class)
		self.diary = [ ]		# Chosen achievements (per story block)

    #--------------------------------------------------------------------------

	def reward(self, cls, trophies):
		print("%s @ %s: %s" % (self.name, cls, trophies))
		# self.trophies[cls][trophy] += 1
		# Check if some achivement was completed
		
	#--------------------------------------------------------------------------

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
# Account ties all together (builds, toons and such)
#------------------------------------------------------------------------------

class Account:

    #--------------------------------------------------------------------------

    def __init__(self):

        #----------------------------------------------------------------------

        self.toons = [
            Toon("Toon A", "Nord"),
            Toon("Toon B", "Human"),
            Toon("Toon C", "Human"),
        ]

        #----------------------------------------------------------------------

        self.builds = [
            Build(self.toons[0], "Warrior"),
            Build(self.toons[0], "Hunter"),
        ]
        
        self.current = self.builds[0]

        #----------------------------------------------------------------------
		
        self.wallet   = { }		# Account wide items
        self.trophies = { }		# Account wide trophies (by class)
		
    #--------------------------------------------------------------------------
	# Rewarding player: update account & toon trophy tables
    #--------------------------------------------------------------------------

    def reward(self, trophies, rewards):
    	# Update account wide trophies
    	# Update character specific trophies
		# Trophies are permanent: they can't be traded, lost or destroyed.
        print("Trophy: %s" % (trophies))
        self.current.toon.reward(self.current.spec, trophies)

		# Rewards are account wide "currencies"
		# Account wide currencies can be exchanged to other items, and for
		# (certain) trophies.
        print("Reward: %s" % (rewards))

account = Account()

dungeons[0].completed(account)

###############################################################################
#
# GUI structure
#
###############################################################################

#------------------------------------------------------------------------------
#
# How GW2 does it:
#
# - Main level menu: game menu (options), contacts + LFG, Hero, inventory,
#   mail, shop, guild, WvW, PvP
# - Hero: equipment, build, training (hero points), story journal, crafting,
#   achievements, masteris
# - Hero/equipment: equipment, wardrobe (transmutations), dyes, outfits,
#   miniatures, finishers, mail carriers, glider skins, mounts, novelties
#
# How we do it:
#
# 1) We put all the builds in one menu. You can choose & edit the build, or
#    create a new one.
# 2) All cosmetic options go to toon menu. Here you can (1) choose the
#    "storyline" (achievements) for this toon, and then (2) choose from
#    available options the outlook, including dyes, gliders, mounts and such.
# 3) Dungeons menu contains all the dungeons / game modes: offline solo PvE,
#    online PvE, PvP and such.
# 4) Account wide achievements? Should they put in the toons menu as one
#    option?
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Build Window to edit builds: choose toon, choose class, choose traits.
#------------------------------------------------------------------------------

class BuildWindow(Frame):

    #--------------------------------------------------------------------------

    def __init__(self, master=None):
        super(BuildWindow, self).__init__(master, pady = 5, padx = 5)

        self.buildlist = Listbox(self)
        self.buildlist.pack(anchor = NW, side = LEFT)

        for build in account.builds:
            self.buildlist.insert(END, "%s: %s" % (build.toon.name, build.spec))
        self.buildlist.insert(END, "<New build>")

    #--------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Toon Window: Edit toons, create diaries, choose outfit.
#------------------------------------------------------------------------------

class ToonWindow(Frame):

    #--------------------------------------------------------------------------

    def __init__(self, master=None):
        super(ToonWindow, self).__init__(master, pady = 5, padx = 5)

        self.toonlist = Listbox(self)
        self.toonlist.pack(anchor = NW, side = LEFT)

        for toon in account.toons:
            self.toonlist.insert(END, toon.name)
        self.toonlist.insert(END, "<New toon>")

#------------------------------------------------------------------------------
# Dungeon Window to simulate completions.
#------------------------------------------------------------------------------

class DungeonWindow(Frame):

    #--------------------------------------------------------------------------

    def __init__(self, master=None):
        super(DungeonWindow, self).__init__(master, pady = 5, padx = 5)

#------------------------------------------------------------------------------
# Vendor Window to simulate vendors (exchanging items to other items/trophies).
#------------------------------------------------------------------------------

class VendorWindow(Frame):

    #--------------------------------------------------------------------------

    def __init__(self, master=None):
        super(VendorWindow, self).__init__(master, pady = 5, padx = 5)

###############################################################################
#
###############################################################################

class MainWindow(Frame):

    #--------------------------------------------------------------------------

    def __init__(self, master=None):
        super(MainWindow, self).__init__(master, pady = 5, padx = 5)

        #----------------------------------------------------------------------

        self.master = master
        self.master.title("Warriors")
        self.master.bind("<Escape>", self.quit)
        self.pack(fill=BOTH, expand=1)

        #----------------------------------------------------------------------
        # Show current build
        #----------------------------------------------------------------------

        self.selected = Label(self)
        self.selected.config(text = "%s: %s" % (
            account.current.toon.name,
            account.current.spec,
        ))
        self.selected.pack(anchor = W)

        #----------------------------------------------------------------------
        # Menu
        #----------------------------------------------------------------------

        self.mainbook = ttk.Notebook(self)
        self.mainbook.add(BuildWindow(),   text = "Builds")
        self.mainbook.add(ToonWindow(),    text = "Toons")
        self.mainbook.add(DungeonWindow(), text = "Dungeons")
        self.mainbook.add(VendorWindow(), text = "Vendors")
        self.mainbook.pack(fill = BOTH, expand = 1)
        
    #--------------------------------------------------------------------------

    def quit(self, event):
        self.master.destroy()
        

###############################################################################
#
###############################################################################

root = Tk()
root.geometry("900x600")
app = MainWindow(root)
root.mainloop()

