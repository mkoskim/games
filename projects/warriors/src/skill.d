//*****************************************************************************
//*****************************************************************************

module src.skill;

import engine;

//*****************************************************************************
//
// SKILLS:
//
// When skill is triggered:
// - Cooldown starts
// - Animation starts: animation prevents triggering other skills
//
// Note:
//
//	- Skills share cooldown timer
//
//*****************************************************************************

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class CooldownTimer
{
    uint end;
    uint duration;

    this() {
        duration = 0;
        end = 0;
    }

    void fire(uint t)   { end = game.ticks + t; duration = t; }
    bool running()      { return game.ticks < end; }
    uint left()         { return running() ? end - game.ticks : 0; }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

class Skill {
    string name;

    CooldownTimer* cooldown;

    uint animtime;      // How long (ms) it takes to perform this?
    uint hotspot;       // At which point (ms) effect is applied?

    this(string name_, CooldownTimer *cooldown_) {
        name = name_;
        cooldown = cooldown_;
    }

    this(string name_, Skill *skill) {
        this(name_, skill.cooldown);
    }
}


