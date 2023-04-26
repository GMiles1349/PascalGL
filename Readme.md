# PGL - the Pascal Game Library.


### PGL is a 2D game framework, which also offers some limited 3D functionality, written in Delphi. 
In it's current form, PGL includes functoinality for
- Windowing
- OpenGL context creation
- Mouse, keyboard and controller input
- Clocks and timers
- Drawing graphics on the GPU and CPU
- Audio loading, playback and manipulation
- Vector and matrix math
- Color manipulation
- Simple collision between 2D and 3D objects

### The idea behind PGL:

PGL aims to provide an *Object Oriented* interface for the user to create and handle a window, 
user input, manipulate graphical image data on the GPU and CPU, process audio, and tie it all together
with similar functionality that uses the classes and structs defined in the **PGLTypes** unit.

An Object Oriented approached was chosen purely to make it easier to think about how the user handles
their data. The user **owns** their objects and has direct access to them, as opposed to the way
many C libraries give the user handles or pointers to objects which are passed into functions. Instead of 
doing something like

-`glfwDestroyWindow(window)`
or
-`glNamedBufferData(coolbuffer, sizeof(int) * somecoolnumber, &myarrayofdata[0], GL_STREAM_DRAW)`,
we call the object's member functions directly like
`TPGLWindow.Close()`.

There are perfomance costs associated with going this route, but for the purposes of what PGL is
intended to do, I consider these costs neglibible. Further, going with an OO approach aids in
development by allowing for the intellisense and similar to show you what your objects are 
capable of without having to refer to documentation. Typing `TPGLSprite.` will supply you with all of the
user-accessible fields, properties and functions that belong to that object.

It's a very simple concept, nothing at all that most anyone wouldn't assume or take for granted, but was
a conscious choice so as to simplify the user's experience.

There is also an effor to make the individual source units and independant as possible, so that you can
use **PGLClock.pas** for clock and timer functionality in projects where you want it, or **PGLAudio.pas**
in another project, and not have to incure the bloat of also including the windowing, drawing and math
units if you don't need them. Though, **PGLTypes.pas** is currently a requirement to use all other units.

### Why am I doing this?

**The short answer:** because I like to make top-down shooters and Zelda-like games, and I don't like SFML 
or GLFW.

**The longer answer:** because I wanted to learn OpenGL to aid in writing engines for my games, and I found 
myself feeling restricted by things like SFML and GLFW and writing a lot of boilerplate code to implement
functionality that I personally thought would have been a given, e.g. manipulating image data on the
CPU side, handling a wider range of window properties, overriding window behaviors, basic "camera"
prototypes, etc...

I wanted to learn how to have performant 2D rendering done on the GPU for an existing game protype that was
using Win32 GDI for drawing, so I checked out SFML. I found it cumbersome and lacking in performance (that 
may be a different story had I been using it with C++ vice pascal), so I decided "I'll just write my own SFML". 
I jumped right into learning OpenGL, and chose GLFW as my tool for handling windowing and context creation. I 
found GLFW limiting for some certain things I wanted to do, so then decided "I'll just write my own GLFW".

Over a year later, and I've made no progress on the game, but I've had a great time figuring out how to write
a framework that I could then use to build and engine and development tools with. The game will never be done.

