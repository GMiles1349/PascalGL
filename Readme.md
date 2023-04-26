# PGL - the Pascal Game Library.


### PGL is a 2D game framework, which also offers some limited 3D functionality, written in Delphi. 
In it's current form, PGL includes functoinality for
- Windowing
- OpenGL context creation
- Mouse, keyboard and controller input
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


