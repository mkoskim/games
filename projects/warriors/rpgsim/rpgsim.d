//*****************************************************************************
//*****************************************************************************
//
//
//
//*****************************************************************************
//*****************************************************************************

import std.stdio;
import std.string;
import std.algorithm;
import std.range;

/******************************************************************************

BRAINSTORMING

See SKETCHING document also.

Actors have their personal vault for buffering food, raw materials and so
on.

DAILIES: For each day, actors:

    - Need to fulfil their daily nutrition (Meal item)
    - Receive 16 time points: rest is automatic
    - Decide, how to use those time points

If character has spare food in vault, or can get upkeep by free, s/he is of
course free to spend all the awakening time in her/his freetime activities.

Getting enough food is mandatory for NPC/PC. How to get that food, that's up to
choices. At poorest situation, you go begging for food, or gather/hunting them
from forest.

******************************************************************************/

//-----------------------------------------------------------------------------
// Resources... We might need "sources of resources", too... And there are
// items that wear out bit by bit. For example, apples will rotten in time.
//-----------------------------------------------------------------------------

struct Item
{
    ID id;
    
    //-------------------------------------------------------------------------
    // Item types: Do we need to classify items? To consumables, facilities,
    // and so on? How we handle "rotting", to prevent NPCs to store
    // infinite amounts of raw materials?
    //-------------------------------------------------------------------------
    
    enum ID {
        Meal,       // Daily nutriment
        Time,       // Time slot for actions

        Meat, Fish, Berries, Vegetables, Mushrooms, BirdEggs,

        Campfire,
        
        /* Actions */
        HuntGather,
        
        /* Facilities */
        Forest,
    }

    //-------------------------------------------------------------------------
    
    this(Item.ID id) { this.id = id; }
    
    Stack opMul(int count)   { return Stack(id, count); }
    Stack opMul_r(int count) { return Stack(id, count); }

    Bag opAdd(Item item) { return Bag(this, item); }

    //-------------------------------------------------------------------------
    // Stack of items
    //-------------------------------------------------------------------------
    
    struct Stack {
        ID id;
        int count;

        this(Item.ID id, int count = 1) {
            this.id = id;
            this.count = count;
        }
            
        this(Item item, int count = 1) { this(item.id, count); }

        Bag opAdd(Stack stack) { return Bag(this, stack); }
    }

    //-------------------------------------------------------------------------
    // Collection of items
    //-------------------------------------------------------------------------

    struct Bag {
        int[ID] items;

        //---------------------------------------------------------------------

        this(int[ID] items)     { this.items = items; }
        
        this(ID[] items...)     { foreach(item; items) add(item); }
        this(Item[] items...)   { foreach(item; items) add(item); }
        this(Stack[] stacks...) { foreach(stack; stacks) add(stack); }
        this(Bag[] bags...)     { foreach(bag; bags) add(bag); }
        
        //---------------------------------------------------------------------

        int opApply(int delegate(ref ID, ref int) dg) {
            foreach(id, count; items) {
                auto result = dg(id, count);
                if(result) return result;
            }
            return 0;
        }

        int  opIndex(ID id) { return items[id]; }
        void opIndexAssign(int count, ID id) { items[id] = count; }
                
        //---------------------------------------------------------------------

        Bag add(ID item, int count = 1)   { items[item] = count + (item in items ? items[item] : 0); return this; }
        Bag add(Item item, int count = 1) { return add(item.id, count); }
        Bag add(Stack stack)              { return add(stack.id, stack.count); }        
        Bag add(Bag bag)                  { foreach(item, count; bag.items) add(item, count); return this; }
        
        Bag sub(ID id, int count = 1)     { return add(id, -count); }
        Bag sub(Item item, int count = 1) { return add(item, -count); }
        Bag sub(Stack stack)              { return sub(stack.id, stack.count); }
        Bag sub(Bag bag)                  { foreach(id, count; bag.items) sub(id, count); return this; }
        
        //---------------------------------------------------------------------

        Bag opAdd(ID item)     { return Bag(this).add(item); }
        Bag opAdd(Item item)   { return Bag(this).add(item); }
        Bag opAdd(Stack stack) { return Bag(this).add(stack); }
        Bag opAdd(Bag bag)     { return Bag(this).add(bag); }

        Bag opSub(ID item)     { return Bag(this).sub(item); }
        Bag opSub(Item item)   { return Bag(this).sub(item); }
        Bag opSub(Stack stack) { return Bag(this).sub(stack); }
        Bag opSub(Bag bag)     { return Bag(this).sub(bag); }

        //---------------------------------------------------------------------

        bool has(ID id, int count = 1)     { return id in items && items[id] >= count; }
        bool has(Item item, int count = 1) { return has(item.id, count); }
        
        bool has(Bag bag) {
            foreach(id, count; bag) if(!has(id, count)) return false;
            return true;
        }
        
        //---------------------------------------------------------------------

        Bag wealth() {
            Bag result;
            foreach(id, count; items) if(count > 0) result.add(id, count);
            return result;
        }
        
        Bag debt() {
            Bag result;
            foreach(id, count; items) if(count < 0) result.add(id, count);
            return result;
        }

        //---------------------------------------------------------------------

        Bag missing(Bag bag) { return (this + bag).debt(); }

        //---------------------------------------------------------------------

        bool doable(Action action) {
            return has(action.requires);
        }

        void perform(Action action) {
            add(action.netresult);
        }
    }    
}

//-----------------------------------------------------------------------------
// Facility / catalyst: To convert items to other types, NPCs need facilities.
// There 
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// Actions: we do something, and we get something as result. Basic plan is
// that actors check what actions they can do, and choose the ones they want
// to fulfil.
//
// TODO: There is a need for telling the amount of items needed / produced.
// Well, but is there? We can always list the item several times, can't we?
//
//-----------------------------------------------------------------------------

class Action
{
    Item.Bag netresult;

    this() { }

    this(Item.Bag consumes, Item.Bag results) {
        netresult = results - consumes;
    }

    this(Action action) {
        this.netresult = action.netresult;
    }
    
    //-------------------------------------------------------------------------

    Item.Bag requires() { return netresult.debt(); }
    Item.Bag produces() { return netresult.wealth(); }

    //-------------------------------------------------------------------------

    void combine(Action action) {
        netresult.add(action.netresult);
    }
}

Action[] actions;

static this()
{
    with(Item) {
        actions = [
            
            new Action(Stack(ID.Forest) + Stack(ID.Time, 12), Bag(Stack(ID.HuntGather, 12))),
            
            new Action(Bag(ID.HuntGather), Bag(ID.Vegetables)),
            new Action(Bag(ID.HuntGather), Bag(ID.Berries)),
            new Action(Bag(ID.HuntGather), Bag(ID.Meat)),
            new Action(Bag(ID.HuntGather), Bag(ID.Fish)),
            new Action(Bag(ID.HuntGather), Bag(ID.BirdEggs)),
            new Action(Bag(ID.HuntGather), Bag(ID.Mushrooms)),
            
            new Action(Bag(ID.HuntGather), Bag(ID.Campfire)),

            new Action(
                Bag(ID.Campfire, ID.Vegetables, ID.Berries, ID.Meat),
                Bag(ID.Meal)
            ),
        ];
    }
}

//-----------------------------------------------------------------------------

class Actor
{
    Item.Bag vault;

    this() { }
    this(Item.Bag[] owns...) { foreach(bag; owns) vault.add(bag); }
    this(Item.Stack[] owns...) { foreach(stack; owns) vault.add(stack); }

    //-------------------------------------------------------------------------
    // wakeup() prepares Actor for new round
    //-------------------------------------------------------------------------
    
    void wakeup() {
        vault[Item.ID.Forest] = 1;
        vault[Item.ID.Time]   = 16;
    }

    //-------------------------------------------------------------------------

    void perform(Action action) {
        vault.perform(action);
    }

    //-------------------------------------------------------------------------

    Action[] possible() {
        Action[] result;
        foreach(action; actions) if(vault.doable(action)) result ~= action;
        return result;
    }

    //-------------------------------------------------------------------------

    struct Potential {
        Action action;
        Item.Bag missing;
        
        this(Action action, Item.Bag missing) {
            this.action = action;
            this.missing = missing;
        }
    }

    Potential[] actionsfor(Item.ID id) {
        Potential[] result;
        foreach(action; actions) if(action.netresult.has(id))
        {
            result ~= Potential(action, vault.missing(action.requires));
        }
        return result;
    }

    //-------------------------------------------------------------------------

    void show(string prefix, Action[] actions)
    {
        writeln(prefix);
        foreach(action; actions) {
            writeln("    ", action.requires, " => ", action.produces);
        }        
    }

    void show(string prefix, Potential[] actions)
    {
        writeln(prefix);
        foreach(action; actions) {
            writeln("    ", action.action.produces, ": ", action.missing);
        }        
    }
}

//-----------------------------------------------------------------------------

void main()
{
    Actor hunter = new Actor();
    
    hunter.wakeup();

    hunter.show("Actions for meal:", hunter.actionsfor(Item.ID.Meal));

    Action[] possible = hunter.possible();

    hunter.show("Possible actions:", possible);
    
    writeln("Performing: ", possible[0].netresult);
    writeln(hunter.vault);
    hunter.perform(possible[0]);
    writeln(hunter.vault);    
}

//-----------------------------------------------------------------------------
// We need "companys": there is a shared storage to use. For example, one
// NPC makes vegetables, and another makes meals from them.
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
//
// Market: NPCs trade things. If possible, I don't implement fixed prices for
// things, but a mechanism to let supply & demand to give the price for
// things. We might compute a "market analysis" at each round to see, what
// items are asked, and what are offered.
//
// There needs to be some sort of negotiation process, or something: maybe
// there can be alternative ways to pay the product. 
//
//-----------------------------------------------------------------------------
//
// Selling Time items means an offer to work. Buying Time means employing.
// This needs to be so that employer provides also her/his skills to be used.
//
// There might be need to make contracts - two NPCs make a contract, similar
// to market entry, but sort of "guaranteed" market entry.
//
//-----------------------------------------------------------------------------

/*
struct Auction
{
    Item[] buying;      // Items not in NPC possession
    Item[] offering;    // Items in NPC possession
}
*/

