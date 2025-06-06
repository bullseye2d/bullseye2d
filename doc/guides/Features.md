# 🎯 Bullseye2D

## A rapid 2D game prototyping library for Dart

*   **Quickly** prototype and build web games
*   **2D Library** witihout wrestling huge frameworks
*   **Code-centric approach** to game dvelopment, valuing direct control and understanding of the engine's components. 

### Features:

*   **Graphics** 
    *   Fast 2D rendering with **WebGL2**.
    *   Automatic **Sprite batching**.
    *   Texture loading & management (sprite sheets, filtering, mipmapping, wrapping).
    *   Blend modes (alpha, additive, multiply, etc.).
    *   Draw primitives (points, lines, rects, ovals, polys).
    *   **Bitmap fonts** (with on the fly .ttf/.otf auto-atlas generation).

*   **Input Handling:**
    *   **Keyboard** (down, up, hit, char queue).
    *   **Mouse** (position, buttons, wheel) – plays nice with touch.
    *   **Gamepad** (multiple controllers, buttons, axes, triggers).
    *   **Accelerometer** for motion stuff.

*   **Audio Engine:**
    *   Play sounds and music.
    *   **Multi-channel audio** (control volume, pan, playback rate per channel).
    *   Sound retrigger delay control.

*   **Resource Loading:**
    *   Easy loading for textures, sounds, fonts, and generic data files.
    *   Built-in progress loader.
    *   Texture & font caching. 

*   **Game Loop & Structure:**
    *   Clear app lifecycle (`onCreate`, `onUpdate`, `onRender`).
    *   Auto-handles browser focus (pauses/resumes your game).
    *   Default loading screen included.

*   **Utils:**
    *   **Matrix stack** for easy 2D transformations (translate, rotate, scale).
    *   Color & vector math utilities.
    *   A flexible **debugging logger** with tagging and filtering capabilities.



<details>
<summary>Why build <em>another</em> engine?</summary>
<content>

-  **Dart:** It's a solid, performant path for Dart devs who want to make 2D web games.
-  **Control & Understanding:** Working with a more foundational library means you *get* what's happening.
-  **No Engine Bloat:** Most indie games don't need *every* feature from a behemoth engine. Often, you end up *fighting* those engines. Bullseye aims to give you just what you need.
-  **The Joy of Crafting (and Learning):** For many devs, building stuff from closer to the ground up is satisfying. It’s a great way to learn and experiment without a million layers of abstraction.
-  **Lightweight & Focused:** If your game is 2D, a specialized lib can be leaner and faster.
-  **Hackable:** Being a library makes it easier to plug in other tools or your own custom solutions without stepping on toes.

Basically, Bullseye is for Dart devs who want to make cool 2D web games with a good mix of control, performance, and a straightforward approach. It's about embracing Dart and modern web tech.

</content>
</details>

# Roadmap

Here are some ideas and plans what I want to add next to `Bullseye2D`: 

*   Compile to native desktop apps (Windows/Mac/Linux/maybe even Consoles)
*   Export/Bindings to VanillaJS and Typescript
*   Support for custom shaders
*   Add RenderTargets for rendering directly into framebuffers
*   Add Support for Tracker-Music-Formats (Protracker, Fasttracker ...)
*   Support for Tilemaps
*   Support for prebaked bitmap fonts
*   A simple themeable, immediate mode gui module
*   Improve Documentation
*   Official Website
*   More online resources (youtube videos, tutorial, educational material)
*   An example creating / manipulating texture by data
    - Maybe a per frame renderbuffer :)
*   Games as showcase and examples to learn from
