//*****************************************************************************
//
// Simple spritesheet demo.
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
    // are window coords). Create single render batch.
    //-------------------------------------------------------------------------

    auto scene = new render.UnbufferedRender(
        render.Camera.topleft2D(),
        render.State.Default2D()
    );

    auto batch = scene.addbatch();

    //-------------------------------------------------------------------------
    // What we do: from splitted bitmaps, we create render models - a
    // combination of geometry (mesh) and material (in this case, having
    // just color map).
    //
    // This approach is not necessarily that suitable for texture animations,
    // it is meant for models with more or less static materials (most 3D
    // objects, as well as non-animated icons and such).
    //
    //-------------------------------------------------------------------------
    
    //-------------------------------------------------------------------------
    // Load first sprite sheet image, split it to separate bitmaps, and upload
    // them to GPU.
    //-------------------------------------------------------------------------

    render.Model[][] explosions;

    explosions ~= batch.upload(
        geom.rect(40, 40),
        Bitmap.splitSheet(
            "engine/stock/spritesheets/explosion2.png",     // File
            vec2i(40, 40),                                  // Source size
            vec2i(40, 40),                                  // Dest. size
            vec2i(0, 0),                                    // topleft padding
            vec2i(0, 0)                                     // bottomright padding
        )[0]
    );

    //-------------------------------------------------------------------------
    // Second spritesheet needs some postprocessing: we use anon function
    // for that.
    //-------------------------------------------------------------------------
    
    explosions ~= batch.upload(
        geom.rect(100, 100), 
        function Bitmap[]()
        {
            auto grid = Bitmap.splitSheet(
                "engine/stock/spritesheets/explosion1.png",
                vec2i(128, 128),
                vec2i(128, 128)
            )[0];
            
            return [
                grid[0], grid[1], grid[2], grid[3],
                grid[5], grid[6], grid[7], grid[8]
            ];
        }()
    );

    //-------------------------------------------------------------------------
    // "Batch marker"
    //-------------------------------------------------------------------------
    
    auto empty = batch.upload();
    
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

            auto sprite = scene.add(render.Grip.movable, empty);

            for(;;) {
                
                // (1) Random placement
                sprite.grip.pos = vec3(
                    std.random.uniform(0, game.screen.width),
                    std.random.uniform(0, game.screen.height),
                    0
                );
                
                // (2) Random sequence
                int row = std.random.uniform(0, 2);

                // (3) Run the sequence
                foreach(phase; explosions[row]) {
                    sprite.model = phase;
                    nextframe();
                }
            }
        }
    }

    //-------------------------------------------------------------------------

    auto actors = new game.FiberQueue();

    foreach(_;0 .. 20) actors.add(new Explosion());

    //-------------------------------------------------------------------------

    actors.reportperf();

    game.Track.rungc();

    simple.gameloop(20, &scene.draw, actors, null);
}

