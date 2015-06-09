//*****************************************************************************
//
// Dungeon: class to load & play a dungeon. This might have lots to
// share with other dungeon-based games (e.g. guerrilla project).
//
//*****************************************************************************

module src.dungeon;

//-----------------------------------------------------------------------------
/*

Lets think about this a while...

    Dungeon has:
    - Dungeon itself
    - Mobs (models)
    - Player (model)
    - Shaders
    - In-game GUI

On the other hand, some resources might be shared within entire game,
for example, shaders... And maybe some rendering pipelines. Let's think...

    Character creation / selection    <-----------------+
                                                        |
    --> "Off-dungeon" dungeon + off-dungeon GUI  <------+
                                                        |
    --> Dungeon selection                               |
                                                        |
    --> Running dungeon (w/ in-dungeon GUI) ------------+

*/
//-----------------------------------------------------------------------------

