
const std = @import("std");
const util = @import("util.zig");
const interface = @import("io_interface.zig");
const build_config = @import("build_config");


pub const gui = switch (build_config.lib_gui) {
//	.none             => interface.gui,
	.SDL_with_LodePNG => @import("wrapper_sdl.zig").gui,
};

pub const music = switch (build_config.lib_music) {
	.none             => interface.music,
	.BASSMOD          => @import("wrapper_bassmod.zig").music,
};

pub const sound = switch (build_config.lib_sound) {
	.none             => interface.sound,
	.SDL              => @import("wrapper_sdl.zig").sound,
};


comptime {
	if (!util.haveSameInterface(gui  , interface.gui  )) @compileError(  "gui is not conforming to its interface");
	if (!util.haveSameInterface(music, interface.music)) @compileError("music is not conforming to its interface");
	if (!util.haveSameInterface(sound, interface.sound)) @compileError("sound is not conforming to its interface");
}
