
This game is currently in an early alpha version.
It lacks lots of contents and isn't very polished.


Play
====

Start the executable located inside "zig-out/bin/", and enjoy the game!


Build
=====

To build this project:
- Zig 0.13.0 is needed
- inside "libraries/", extract each archive into its own subdirectory
- delete "zig-out/"
- run the "zig build" command

The following optional parameters can be appended to the build command:
- "-Dtarget=..." to request a specific target, such as "x86_64-windows"
  (if the specified target is not supported, an other one will be used)
- "-Dlibgui=..." to specify which supported GUI library should be used
- "-Dlibmusic=..." to specify which supported music library to use
- "-Dlibsound=..." to specify which supported sound library to use
  (see the top of "build.zig" for lists of the supported libraries)


Structure
=========

This project defines *A CUSTOM INTERFACE* for all its io operations:
- "src/io_interface.zig" is this interface, which all the code uses
- "src/io.zig" gets its implementation from the libraries' wrappers
  and uses "src/util.zig" to guarantee that it matches the interface
(The game never uses a library directly, it only uses this interface.)

Multiple *LIBRARIES* are supported as implementations of this interface:
- "src/wrapper_....zig" wraps the supported libraries in this interface
- "libraries/" stores the library files needed to build and run the game
- "build.zig" lists the supported libraries and contains the build logic
(It should be straightforward to add support for new other io libraries.)

The game has several *SCREENS* (the title screen, the home screen, etc.):
- "src/main.zig" implements both the loading screen and the title screen
- "src/screens.zig" contains utility code to build more complex screens
- "src/screen_home.zig" implements the home screen (with its buttons)
- "src/screen_game.zig" implements the game's display and interactions
- "src/engine.zig" defines and implements the game's "physics" engine

The game relies on *DATA* from the following source files:
- "src/levels.zig" defines the different levels of the game
- "src/assets.zig" lists the assets (images, musics, sounds)

The *ASSETS* are stored in:
- "images/" for the images
- "musics/" for the musics
- "sounds/" for the sounds

The *BUILD OUTPUTS* are stored in:
- ".zig-cache/" for cached temporary object files
- "zig-out/" for the game's binary and its assets


Contribute
==========

The goal is to make this game as professional and as complete as a similar one!
(We may not reach this ambitious goal, but we should be heading towards that!)
Extra content is also welcome: more characters, game modes, mini games, etc.

Rules:
- Only commit stuff you have made, or have the rights to use with a link to the source (in credits.txt).
- The last commit of master must always compile and only have clean code, consistent and without "hacks".
- Try to only put on master meaningful commits, ideally with a single purpose (ex.: "added new ennemies").
- You can rewrite history (even if shared/pushed), as long as it doesn't rehash commits made by others.
