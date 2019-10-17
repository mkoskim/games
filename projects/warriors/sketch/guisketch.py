#!/usr/bin/env python3
###############################################################################
#
# Sketching GUI (non-realtime parts): Builds, achievements and so on.
#
###############################################################################

import sys

print("Python version:",  ".".join(map(str, sys.version_info[:3])))
if sys.version_info.major < 3:
    print("Need Python 3")
    exit(-1)
    
from tkinter import *
import tkinter.ttk as ttk

###############################################################################
#
# How it works?
#
# - Player has account.
# - Account has list of toons and builds.
# - A build combines toon to "spec" (class, specialization, "gears", ...)
# - Dungeon completition gives rewards
# - These rewards include "tokens"/"badges" for achievements
#
#------------------------------------------------------------------------------
#
# Let's try to create an example case. Let's go with LoTR lore.
#
# Let's say that your character wants to be a Mirkwood soldier. Let's say
# s/he is human, so that s/he does not have birth rights for Mirkwood basics.
#
# To be able to wear Mirkwood/Lothlorien hunter armor, what the character
# should do? S/he should be respected enough by Mirkwood elves for this. S/he
# should have gathered enough renown amongst the elves and their leaders
# (Thranduil; Galadriel and Celeborn). This would be done by fighting against
# Dol Guldur, and protecting the woods against all sorts of corruptions.
#
# You'd need to show your braveness and dedication for the community, and
# you'd need to have some great victories in that process.
#
# OK, you have done it, you have earned the trust and respect. To get the armor,
# you'd need someone to craft it for you, from "materials". Basically, you'd
# need those materials - either gathered or bought - as well as some reward for
# the one crafting it for you.
#
# Something like this:
#
# T1: No badges from tutorials
# T2: No badges from tutorials
# T3: Soldier badge  <- Mirkwood T3 completion (complete certain dungeons at T1)
# T4: Sergeant badge <- Mirkwood T4 completion
#     Mentor badge   <- Mirkwood T4 mentor completion
# T5: Something special from T5
#
# Badges are achievement completion trophies, not dungeon rewards.
#
# Soldier badge + rep + mats + gold -> Soldier armor
# Sergeant badge + rep + mats + gold -> Sergeant armor
# Sergeant armor + Mentor badge + rep & mats & gold -> Veteran armor
#
# There is a need for:
#
# (1) some sort of generic currency / currencies, lets call it gold: these can
#     be acquired from any content, these tell the "generic" play time of the
#     player.
# (2) Cluster specific currencies: These are gathered from dungeon cluster.
#
# TODO: How to implement mentor chest? This is given to other accounts, if
# someone in the group gets the first achievement. In addition to account &
# char specific trophies and achievement checking, there should be also a
# group wide achievements.
#
# TODO: How to implement challenge quests? Challenges are optional objectives
# for dungeons.
#
# TODO: Loot lists. I am not a big fan for random rewards, but they might
# have their place. For example, distributing material gains (lots of
# different materials, not that many loot slots to use), and giving some
# randomness for more rare gains (e.g. we could have achievement giving
# reward at 10 completions, or the same item as loot with 10% chance).
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# Dungeons give rewards to account.
#
# Let try this way: (1) rewards are account-wide items, (2) trophies are
# class specific items for account & toon. Account tracks total number of
# trophies received.
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
	Dungeon("Mirkwood/A/T1", ["Mirkwood/A/T1"], None),
	Dungeon("Mirkwood/A/T2", ["Mirkwood/A/T2"], None),
	Dungeon("Mirkwood/A/T3", ["Mirkwood/A/T3"], None),
]

#------------------------------------------------------------------------------
# Achievements data structure. When account is rewarded from dungeon (or
# vendor, from exchanging items!), check if that completes some achievements.
#------------------------------------------------------------------------------

class Achievement:

	def __init__(self, reward, requirements):
		self.reward = reward
		self.requirements = requirements

	def check(self):
		# Check if this is already completed (reward in account)
		# Check, if account trophies meets the requirements.
		pass

achievements = [
	# "Mirkwood" achievements (sketching)
	Achievement("Mirkwood/Recruit", None),		# Join the elven army to protect region
	Achievement("Mirkwood/Soldier", None),		# Complete T3 dungeons
	Achievement("Mirkwood/Sergeant", None),		# Complete T4 dungeons (autocomplete T3)
	Achievement("Mirkwood/Mentor", None),		# Complete T4 mentor (autocomplete T4)
]

#------------------------------------------------------------------------------
# Vendors are entities, which translate items to another. These items are
# trophies in account / toon wallet. BTW, maybe not all armors are available
# to all races - races too different can't wear those.
#------------------------------------------------------------------------------

class Vendor:

	def __init__(self, item, price):
		self.item  = item
		self.price = price

vendors = [
	# "Mirkwood" cosmetics (sketching)
	Vendor("Mirkwood/Recruit/Armor",  [ "Mirkwood/Recruit",  "gold + mats" ]),
	Vendor("Mirkwood/Soldier/Armor",  [ "Mirkwood/Soldier",  "gold + mats", "rep" ]),
	Vendor("Mirkwood/Sergeant/Armor", [ "Mirkwood/Sergeant", "gold + mats", "rep" ]),
	Vendor("Mirkwood/Veteran/Armor",  [ "Mirkwood/Mentor",   "gold + mats", "rep" ]),
]

#------------------------------------------------------------------------------
# Toon is a visual representation of player / build. Toons have "diary":
# it is list of chosen achievements, which then decide the options the player
# has for outlook. Achievements come in two level: account-wide, and toon-
# specific.
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# Can we have something similar to Oblivion Birthsign / Skyrim Standing Stone
# for toons? Something similar to GW2 Norn spirit guides (Raven, Bear, Wolf,
# Snow Leopard)?
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

    races = [
        "Nord", "Human",
        "Elf", "Dwarf",
    ]

#------------------------------------------------------------------------------
# Specializations / specification is the spec of the build: class, traits,
# etc etc
#------------------------------------------------------------------------------

class Spec:

    def __init__(self, cls):
        self.cls = cls

    specs = [
        "Warrior", "Barbarian", "Knight",
        "Hunter", "Archer",
        "Druid", "Sorcerer", "Mage",
        "Thief", "Nightblade", "Assassin",
    ]

#------------------------------------------------------------------------------
# Build is what player plays. It has specializations (including class) and
# visual representation (toon).
#------------------------------------------------------------------------------

class Build:

    def __init__(self, toon, spec):
        self.toon = toon
        self.spec = spec

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
        self.current  = 0       # Current build, if any
        
        self.location = None    # Location is account wide

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
        build = self.builds[self.current]
        build.toon.reward(build.spec, trophies)

		# Rewards are account wide "currencies"
		# Account wide currencies can be exchanged to other items, and for
		# (certain) trophies.
        print("Reward: %s" % (rewards))

account = Account()

#------------------------------------------------------------------------------
# Test runs
#------------------------------------------------------------------------------

dungeons[0].completed(account)

#exit(0)

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
# 1) We put all the builds (for all characters) in one menu. You can
#    choose & edit the build, or create a new one.
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
        self.buildlist.bind('<<ListboxSelect>>', self.onselect)
        self.buildlist.pack(anchor = NW, side = LEFT)

        for build in account.builds:
            self.buildlist.insert(END, "%s: %s" % (build.toon.name, build.spec))
        self.buildlist.insert(END, "<New build>")

        self.toonname = Label(self, text = "Character:")
        self.toonname.pack(anchor = NW)
        
        self.clsname = Label(self, text = "Class:")
        self.clsname.pack(anchor = NW)

        self.onBuildSwitch()

    #--------------------------------------------------------------------------

    def onselect(self, event):
        print(event.widget.curselection())
        account.current = int(event.widget.curselection()[0])
        if account.current >= len(account.builds):
            account.current = None
        self.onBuildSwitch()

    def onBuildSwitch(self):
        index = account.current
        if index is None:
            self.toonname["text"] = "Character: <Choose>"
            self.clsname["text"]  = "Class: <Choose>"
        else:
            build = account.builds[index]
            self.toonname["text"] = "Character: " + build.toon.name
            self.clsname["text"]  = "Class: " + build.spec

        self.master.onBuildSwitch()

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
        self.selected.pack(anchor = W)
        #self.onBuildSwitch()

        #----------------------------------------------------------------------
        # Menu
        #----------------------------------------------------------------------

        self.mainbook = ttk.Notebook(self)
        self.mainbook.add(BuildWindow(self),   text = "Builds")
        self.mainbook.add(ToonWindow(self),    text = "Toons")
        self.mainbook.add(DungeonWindow(self), text = "Dungeons")
        self.mainbook.add(VendorWindow(self),  text = "Vendors")
        self.mainbook.pack(fill = BOTH, expand = 1)
        
    #--------------------------------------------------------------------------

    def onBuildSwitch(self):
        if account.current is None:
            name, spec = "<None>", "<None>"
        else:
            build = account.builds[account.current]
            name, spec = build.toon.name, build.spec
            
        self.selected.config(text = "%s: %s" % (name, spec))

    #--------------------------------------------------------------------------

    def quit(self, event):
        self.master.destroy()
        

root = Tk()
root.geometry("900x600")
app = MainWindow(root)
root.mainloop()

