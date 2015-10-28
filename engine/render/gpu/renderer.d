//*****************************************************************************
//
// Objects doing rendering...
//
//*****************************************************************************

//-----------------------------------------------------------------------------
/* Let's think. What I want, is that I can place skyboxes and other
 * postprocessing effects with node batches. Also, I'd like to put
 * instanced batches to same structure.
 *
 * Reason: drawing order.
 */
//-----------------------------------------------------------------------------

module engine.render.gpu.render;

interface Renderer
{
}

class RendererGroup
{
    Renderers[] renderers;

}
