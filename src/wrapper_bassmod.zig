
const io_interface = @import("io_interface.zig");
const LibraryError = io_interface.LibraryError;

const c = @cImport({
	@cInclude("bassmod.h");
});

var initialized = false;

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

	pub const PlayRepetition = io_interface.music.PlayRepetition;

	pub fn play_file(path: [:0]const u8, repetition: PlayRepetition) LibraryError!void {
		const flag_repetition: c_ulong = switch (repetition) { .once => 0, .loop => c.BASS_MUSIC_LOOP };
		const flags: c_ulong = flag_repetition | c.BASS_MUSIC_RAMPS | c.BASS_MUSIC_SURROUND2;

		if (c.BASSMOD_MusicLoad(c.FALSE, @constCast(path.ptr), 0, 0, flags) != c.TRUE) return error.Library;
		errdefer c.BASSMOD_MusicFree();

		if (c.BASSMOD_MusicPlay() != c.TRUE) return error.Library;
	}

	pub fn stop() void {
		c.BASSMOD_MusicFree();
	}

};
