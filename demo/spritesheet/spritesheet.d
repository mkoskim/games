//*****************************************************************************
//
// Simple spritesheet demo. Sprite sheet handling was changed so that
// instead of splitting sheet to separate textures, the sheet is loaded
// as is. The new function generates separate rectangular meshes with
// correct UV coordinates to use individual sprites from sheet.
//
//*****************************************************************************

import engine;

//-----------------------------------------------------------------------------

import std.random;

//-----------------------------------------------------------------------------

void main()
{
    //-------------------------------------------------------------------------
    // Initialize screen
    //-------------------------------------------------------------------------
    
    game.init();

    //-------------------------------------------------------------------------
    // Create layer, using default 2D shader and "pixel" camera (camera coords
    // are window coords).
    //-------------------------------------------------------------------------

    auto scene = new render.DirectRender(
        render.Camera.topleft2D(),
        new render.RenderState2D()
    );

    auto batch = scene.addbatch();
    
    //-------------------------------------------------------------------------
    // Create shape sheet from sprite sheet. As second spritesheet used
    // contains some duplicate images, we post-process the result a bit.
    //-------------------------------------------------------------------------
    
    auto empty = batch.upload();
    
    auto explosions = [

        render.Model.sheet(
            batch,
            new render.Texture("engine/stock/spritesheets/explosion2.png"),
            40, 40,         // Dimensions of single sprite in sheet (in pixles)
            40.0, 40.0      // Dimensions for created rectangular mesh
        )[0],

        function render.Model[](render.Batch batch)
        {
            auto grid = render.Model.sheet(
                batch,
                new render.Texture("engine/stock/spritesheets/explosion1.png"),
                128, 128,
                100.0, 100.0
            )[0];
            
            return [
                grid[0], grid[1], grid[2], grid[3],
                grid[5], grid[6], grid[7], grid[8]
            ];
        }(batch),
    ];

    //-------------------------------------------------------------------------
    // Explosion animation: after random waiting (to prevent all explosions
    // to be in the same phase), pick random animation and position, and
    // run it. Rinse and repeat.
    //-------------------------------------------------------------------------
    
    class Explosion : game.Fiber
    {
        this() { super(&run); }

        override void run()
        {
            // ----------------------------------------------------------------
            // Wait random time before starting
            // ----------------------------------------------------------------

            foreach(_; 0 .. std.random.uniform(0, 10)) nextframe();

            // ----------------------------------------------------------------

            auto sprite = scene.add(vec3(0, 0, 0), empty);

            for(;;) {
            
                // (1) Random placement
                sprite.grip.pos = vec3(
                    std.random.uniform(0, game.screen.width),
                    std.random.uniform(0, game.screen.height),
                    0
                );
                
                // (2) Random shape
                render.Model[] animation = explosions[std.random.uniform(0, 2)];
                //render.Shape[] animation = explosions[1];
                
                // (3) Run the sequence
                foreach(phase; 0 .. animation.length) {
                    sprite.model = animation[phase];
                    nextframe();
                }
            }
        }
    }

    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();

    foreach(_;0 .. 10) actors.add(new Explosion());

    //-------------------------------------------------------------------------

    actors.reportperf();

    simple.gameloop(25, &scene.draw, actors, null);
}

