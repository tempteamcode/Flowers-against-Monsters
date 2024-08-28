
const io_interface = @import("io_interface.zig");
const LibraryError = io_interface.LibraryError;

const c = @cImport({
	@cInclude("bassmod.h");
});

const std = @import("std");

var initialized = false;
var playing: bool = false;

pub const music = struct {

	pub fn init() LibraryError!void {
		if (initialized) return;
		if (c.BASSMOD_GetVersion() != 2) return error.Library;
		if (c.BASSMOD_Init(-1, 44100, c.BASS_DEVICE_NOSYNC) != c.TRUE) return error.Library;
		initialized = true;
	}
	pub fn deinit() void {
		if (!initialized) return;
		c.BASSMOD_Free();
		initialized = false;
	}

	pub const Music = struct {
		_bytes: []u8,

		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Music {
			return .{ ._bytes = std.fs.cwd().readFileAlloc(std.heap.c_allocator, path, std.math.maxInt(c.DWORD)) catch return error.Library };
		}
		pub fn free(mus: Music) void {
			std.heap.c_allocator.free(mus._bytes);
		}
	};

	pub const PlayRepetition = io_interface.music.PlayRepetition;
	pub fn play(mus: Music, repetition: PlayRepetition) LibraryError!void {
		music.stop();

		const flag_repetition: c.DWORD = switch (repetition) { .once => 0, .loop => c.BASS_MUSIC_LOOP };
		const flags: c.DWORD = flag_repetition | c.BASS_MUSIC_RAMPS | c.BASS_MUSIC_SURROUND2;
		if (c.BASSMOD_MusicLoad(c.TRUE, mus._bytes.ptr, 0, @intCast(mus._bytes.len), flags) != c.TRUE) return error.Library;
		errdefer c.BASSMOD_MusicFree();

		if (c.BASSMOD_MusicPlay() != c.TRUE) return error.Library;
		playing = true;
	}
	pub fn stop() void {
		if (playing) {
			_ = c.BASSMOD_MusicStop();
			c.BASSMOD_MusicFree();
		}
		playing = false;
	}

};
