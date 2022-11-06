PascalGL is a work in progress 2D framework that includes custom written windowing and OpenGL context creation, rendering via "pgl" classes and the provided shaders, handling of mouse, keyboard and controller input, audio capabilities through OpenAL, text shaping and rendering with FreeType 2, and basic "clock" functionality.

Currently, PGL is only supported with Delphi on Windows, 32 and 64 bit builds.
The current state has known bugs. Functionality from the user's perspective is inconsistent (pglRenderTexture.SetColorValues() vs. pglSprite.SetColors() and similar).

In order to use PGL in a project, add the provided directories to your compiler search path:
/Source
/TextShaping4Delphi
/Delphi-XInput/Source
/Delphi-STBI/Stb

Documentation and examples are soon to come, but in the meantime, you can follow the below instruction to start using PGL in a project after including the required search paths.

In your Unit interface Uses clause, add glDrawMain to use the windowing, context creation, and 2D rendering capabilites, then
-declare a "window" variable of type pglWindow
-call PGLInit(window,width,height,title,flags);
--flags is an array of enums, but can be left empty with [].

-create a "main" loop and call pglWindowUpdate() at the top of it.
--pglWindowUpdate() will swap the window buffers and handle window messages.
--PGL has a global pglRunning variable that tells whether or not PGL is currently initialized and running and can be used as a loop condition, e.g.
	while pglRunning do begin
	    pglWindowUpdate();
	end;

-a call to window.close() will destroy the window and rendering context, clean up any PGL objects that had been created, and set pglRunning to false.

The primary classes you will be using beyond pglWindow are

pglRenderTarget/pglRenderTexture
-only pglRenderTexture is able to have instances created by the user. pglRenderTexture and pglWindow are descendants or pglRenderTarget. A pglRenderTexture is a wrapper around an OpenGL Framebuffer Object, and acts as an offscreen "drawing surface". Functionality is provided to "blit" their contents to other pglRenderTextures and the pglWindow.

pglImage
-used hold image data in ram. Provides functions for basic image data access and manipulation and upload to the GPU.

pglTexture
-warpper around OpenGL's Texture2D.

pglSprite
-assign it a pglTexture through SetTexture() in order to draw to a pglRenderTarget with pglRenderTarget.DrawSprite().
	

 
