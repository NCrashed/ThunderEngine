Thunder Engine
============
This project is an attemp to create flexible and unkillable engine like Warcraft III engine. It is not a game, it is a tool to
create your custom games. Thunder Engine is going to continue the idea of map scripting while eleminating some common restriction whose you can find in war3 engine (for instance, unable to simply track mouse cursor).

Engine will be able to load and use mdl/mdx model formats, blp textures, will be able to run jazz code. It can provoke some license
issues and when it does engine will be switched to use custom model/texture formats, custom scripting language (cjass or lua for instance).

Planning features
=================
* Offical mods support and repository (maybe XGM).
* Some backward compatibility with war3 engine and editor.
* Graphics update, modern shading and better hi-resolution model/texture support.
* Fully scripts controlled interface.
* Mods would be able to add new native functions for scripting language.

Compilation
===========

Project uses some open-source libraries as dependencies. They can be found at Dependencies folder. Project compilation
has dependency compilation ability. It requires MinGW, CMake for windows and GCC, CMAKE for linux. You can compile
dependency yourself as described bellow.

For automatic compilation go to script directory and call:
```
$ rdmd compile.d all [debug|release]
```

Under linux you should have at least following packages installed:
* gcc
* gcc-c++
* dmd v2.062
* cmake
* mesa-libgl
* mesa-libglu
* randr

Manual dependency compilation
=============================

**[Derelict3](https://github.com/aldacron/Derelict3)**

Dynamic bindings to OpenGL, GLFW3, FreeImage and others. Location: Dependencies/Derelict3.

**Compilation**
Go to build folder:
```
$ dmd build.d && ./build.exe
```

**[GLFW3](https://github.com/elmindreda/glfw)**

Crossplatform library for creating window and manipulating drawing context. Written in C and compiles with Cmake,GCC/MinGW.
Also you can manually compile it with VisualC. Location: Dependencies/GLFW3.

**Compilation**
GNU/Linux:
```
cmake
make
```
Finally copy src/libglfw.so into project bin derectory (if it doesn't exist, create).

Windows: 
MinGW:
```
cmake -G "MinGW Makefiles" .\
make
```
Finally copy src/glfw.dll into project bin derectory (if it doesn't exist, create).

VisualStudio:
Generate studio project with CMake gui, compile it with VisualStudio and copy 
glfw.dll into project Bin derectory (if it doesn't exist, create).

**[FreeImage](http://freeimage.sourceforge.net/)**

FreeImage is an Open Source library project for developers who would like to support popular 
graphics image formats like PNG, BMP, JPEG, TIFF and others as needed by today's multimedia applications.
Written in C/C++ and used to provide texture loading. Location: Dependencies/FreeImage.

**Compilation**

GNU/Linux:
```
make -f Makefile.fip
```
Finally copy libfreeimageplus-3.15.4.so into project Bin directory and rename to libfreeimage.so. Fostom uses
modified freeimage version, therefore offical version can fail.

Windows:

With MinGW:
```
make -fMakefile.mingw
```
Finally copy FreeImage.dll into project bin directory.

With Visual Studio:

FreeImage provide project for VisualStudio, compile it and
copy FreeImage.dll into project Bin directory. Compilation in debug 
mode adds 'd' suffix to dll name, remove it.

**[Goldie](http://www.semitwist.com/goldie/)**

Used to generate mdl parser from grammar. Will be used to parse jass sources
and other planning formats.

**Compilation**

In Goldie folder:
```
rdmd compile.d goldie debug
rdmd compile.d grmc release
rdmd compile.d staticlang release
```

**[SemiTwistDTools](https://bitbucket.org/Abscissa/semitwistdtools/wiki/Home)**

Used by Goldie. Misc collection of tools, such as a case-insensitive string type, 
enhanced unittest features, a build configuration tool (stbuild, a cmd-line front-end 
for rdmd), useful mixins, etc.

**Compilation**

In SemiTwistDTools folder:
```
rdmd compile.d all release
```

Milestones
===========
**v0.0.1**:
* MDL model parser and rendering.
* BLP textures support.
* Frustum culling.

**v0.0.2**: (public announcement on XGM)
* MDX model support.
* Skeletal animation.
* Creating more detail roadmap.

Screenshots
===========

