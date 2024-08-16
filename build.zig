
const std = @import("std");
const util = @import("src/util.zig");

const libraries = struct {
	pub const supported = struct {
		pub const gui = enum {
			SDL_with_LodePNG,
		};
		pub const music = enum {
			none,
			BASSMOD,
		};
		pub const sound = enum {
			none,
			SDL,
		};
	};

	pub const default = struct {
		pub const gui   = libraries.supported.gui.SDL_with_LodePNG;
		pub const music = libraries.supported.music.BASSMOD;
		pub const sound = libraries.supported.sound.SDL;
	};
};

pub fn build(b: *std.Build) !void {
	const target_std = b.standardTargetOptions(.{});
	const optimize = .ReleaseSafe; //b.standardOptimizeOption(.{});


	// figure out which libraries to use

	const libs_gui   = try util.enumListNames(b.allocator, libraries.supported.gui  , " or ");
	const libs_music = try util.enumListNames(b.allocator, libraries.supported.music, " or ");
	const libs_sound = try util.enumListNames(b.allocator, libraries.supported.sound, " or ");

	const lib_gui   = if (b.option([]const u8, "libgui"  , libs_gui  )) |name| try util.enumFromName(libraries.supported.gui  , name, error.UnknownGuiLibrary  ) else libraries.default.gui  ;
	const lib_music = if (b.option([]const u8, "libmusic", libs_music)) |name| try util.enumFromName(libraries.supported.music, name, error.UnknownMusicLibrary) else libraries.default.music;
	const lib_sound = if (b.option([]const u8, "libsound", libs_sound)) |name| try util.enumFromName(libraries.supported.sound, name, error.UnknownSoundLibrary) else libraries.default.sound;

	var use_lib_sdl = false;
	var use_lib_lodepng = false;
	var use_lib_bassmod = false;
	switch (lib_gui) {
		.SDL_with_LodePNG => { use_lib_sdl = true; use_lib_lodepng = true; },
	}
	switch (lib_music) {
		.none             => {},
		.BASSMOD          => use_lib_bassmod = true,
	}
	switch (lib_sound) {
		.none             => {},
		.SDL              => use_lib_sdl = true,
	}

	const use_libc = use_lib_sdl or use_lib_lodepng or use_lib_bassmod;


	// restrict the target to targets supported by the libraries used

	const target = t: {
		var os = target_std.result.os.tag;
		var arch = target_std.result.cpu.arch;

		if (use_lib_sdl) {
			os   = util.enumRestrict(os  , [_]@TypeOf(os  ) { .windows, .linux });
			arch = util.enumRestrict(arch, [_]@TypeOf(arch) { .x86, .x86_64 });
		}
		if (use_lib_bassmod) {
			os   = util.enumRestrict(os  , [_]@TypeOf(os  ) { .windows, .linux });
			arch = util.enumRestrict(arch, [_]@TypeOf(arch) { .x86 });
		}

		if (os == target_std.result.os.tag and arch == target_std.result.cpu.arch)
			break :t target_std
		else
			break :t b.resolveTargetQuery(.{ .os_tag = os, .cpu_arch = arch });
	};


	// clean the output directory //TODO: does not always work

	const clean_step = b.step("clean", "Clean up");
	clean_step.dependOn(&b.addRemoveDirTree(b.install_path).step);


	// compile the project, giving it information about its configuration

	const exe = b.addExecutable(.{
		.name = "FaM",
		.root_source_file = b.path("src/main.zig"),
		.target = target,
		.optimize = optimize,
	});
	exe.addIncludePath(b.path("src"));

	const build_config = b.addOptions();
	build_config.addOption(@TypeOf(lib_gui  ), "lib_gui"  , lib_gui  );
	build_config.addOption(@TypeOf(lib_music), "lib_music", lib_music);
	build_config.addOption(@TypeOf(lib_sound), "lib_sound", lib_sound);
	exe.root_module.addOptions("build_config", build_config);


	// link the libraries used, and copy the dynamic ones in the output directory

	const target_os = target.result.os.tag;
	const target_arch = target.result.cpu.arch;

	if (use_libc) {
		exe.linkLibC();
	}
	if (use_lib_sdl) {
		exe.linkSystemLibrary("SDL"); // dynamically linked
		switch (target_arch) {
			.x86 => switch (target_os) {
				.windows => {
					exe.addLibraryPath(b.path("libraries/SDL-devel-1.2.15-VC/SDL-1.2.15/lib/x86"));
					exe.addIncludePath(b.path("libraries/SDL-devel-1.2.15-VC/SDL-1.2.15/include"));
					b.installFile("libraries/SDL-1.2.15-win32/SDL.dll", "bin/SDL.dll");
				},
				.linux => {
					exe.addCSourceFile(.{ .file = b.path("libraries/SDL-devel-linux-requirements.c") });
					exe.addLibraryPath(b.path("libraries/SDL-devel-1.2.15-1.i386/lib"));
					exe.addIncludePath(b.path("libraries/SDL-devel-1.2.15-1.i386/include/SDL"));
					b.installFile("libraries/SDL-1.2.15-1.i386/lib/libSDL-1.2.so.0", "bin/libSDL-1.2.so.0");
				},
				else => return error.UnsupportedOsForLibrarySDL,
			},
			.x86_64 => switch (target_os) {
				.windows => {
					exe.addLibraryPath(b.path("libraries/SDL-devel-1.2.15-VC/SDL-1.2.15/lib/x64"));
					exe.addIncludePath(b.path("libraries/SDL-devel-1.2.15-VC/SDL-1.2.15/include"));
					b.installFile("libraries/SDL-1.2.15-win32-x64/SDL.dll", "bin/SDL.dll");
				},
				.linux => {
					exe.addCSourceFile(.{ .file = b.path("libraries/SDL-devel-linux-requirements.c") });
					exe.addLibraryPath(b.path("libraries/SDL-devel-1.2.15-1.x86_64/lib64"));
					exe.addIncludePath(b.path("libraries/SDL-devel-1.2.15-1.x86_64/include/SDL"));
					b.installFile("libraries/SDL-1.2.15-1.x86_64/lib64/libSDL-1.2.so.0", "bin/libSDL-1.2.so.0");
				},
				else => return error.UnsupportedOsForLibrarySDL,
			},
			else => return error.UnsupportedCpuArchitectureForLibrarySDL,
		}
	}
	if (use_lib_lodepng) {
		exe.addCSourceFile(.{ .file = b.path("libraries/lodepng-87032dd/lodepng-87032dd9c379892e08bba71c647bdaca793aee3c/lodepng.c") }); // statically linked
		exe.addIncludePath(b.path("libraries/lodepng-87032dd/lodepng-87032dd9c379892e08bba71c647bdaca793aee3c"));
	}
	if (use_lib_bassmod) {
		exe.linkSystemLibrary("BASSMOD"); // dynamically linked
		if (target_arch != .x86) return error.UnsupportedCpuArchitectureForLibraryBASSMOD;
		switch (target_os) {
			.windows => {
				exe.addLibraryPath(b.path("libraries/bassmod20/c"));
				exe.addIncludePath(b.path("libraries/bassmod20/c"));
				exe.addLibraryPath(b.path("libraries/bassmod20"));
				b.installFile("libraries/bassmod20/BASSMOD.dll", "bin/BASSMOD.dll");
			},
			.linux => {
				exe.addLibraryPath(b.path("libraries/bassmod20-linux"));
				exe.addIncludePath(b.path("libraries/bassmod20-linux"));
				b.installFile("libraries/bassmod20-linux/libbassmod.so", "bin/libbassmod.so");
			},
			else => return error.UnsupportedOsForLibraryBASSMOD,
		}
	}


	// copy the assets in the output directory

	b.installDirectory(.{ .source_dir = b.path("images"), .install_dir = .bin, .install_subdir = "images" });
	b.installDirectory(.{ .source_dir = b.path("musics"), .install_dir = .bin, .install_subdir = "musics" });
	b.installDirectory(.{ .source_dir = b.path("sounds"), .install_dir = .bin, .install_subdir = "sounds" });


	// add the binary in the output directory

	b.installArtifact(exe);
}
