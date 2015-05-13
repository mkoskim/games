//*****************************************************************************
//
// General 'sketching' project to develop new features.
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
    
    auto layer = new render.Layer(
        render.shaders.Default2D.create(),
        render.Camera.topleft2D()
    );

    //-------------------------------------------------------------------------
    // Create shape sheet from sprite sheet. As second spritesheet used
    // contains some duplicate images, we post-process the result a bit.
    //-------------------------------------------------------------------------
    
    auto explosions = [

        render.Shape.sheet(
            layer.shader,
            new render.Texture("engine/stock/spritesheets/explosion2.png"),
            40, 40,
            40.0, 40.0
        )[0],

        function render.Shape[](render.Shader shader)
        {
            auto grid = render.Shape.sheet(
                shader,
                new render.Texture("engine/stock/spritesheets/explosion1.png"),
                128, 128,
                100.0, 100.0
            )[0];
            
            return [
                grid[0], grid[1], grid[2], grid[3],
                grid[5], grid[6], grid[7], grid[8]
            ];
        }(layer.shader),
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
            foreach(_; 0 .. std.random.uniform(0, 10)) nextframe();

            auto sprite = layer.add(0, 0);

            for(;;) {
            
                sprite.grip.pos = vec3(
                    std.random.uniform(0, game.screen.width),
                    std.random.uniform(0, game.screen.height),
                    0
                );
                
                render.Shape[] animation = explosions[std.random.uniform(0, 2)];
                //render.Shape[] animation = explosions[1];
                
                foreach(phase; 0 .. animation.length) {
                    sprite.shape = animation[phase];
                    nextframe();
                }
            }
        }
    }

    auto actors = new game.FiberQueue();

    foreach(_;0 .. 10) actors.add(new Explosion());

    //-------------------------------------------------------------------------

    simple.gameloop(25, &layer.draw, actors, null);
}

