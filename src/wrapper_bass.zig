
const io_interface = @import("io_interface.zig");
const LibraryError = io_interface.LibraryError;

const c = @cImport({
	@cInclude("bass.h");
});

const builtin = @import("builtin");

var initialized_music = false;
var initialized_sound = false;
var playing: ?c.HMUSIC = null;

pub const music = struct {

	pub fn init() LibraryError!void {
		if (initialized_music) return;
		if (!initialized_sound) {
			if (c.BASS_GetVersion() & 0xFFFF0000 != 0x02040000) return error.Library;
			if (c.BASS_Init(-1, 44100, c.BASS_DEVICE_STEREO, if (builtin.os.tag == .windows) 0 else null, null) != c.TRUE) return error.Library;
		}
		initialized_music = true;
	}
	pub fn deinit() void {
		if (!initialized_music) return;
		if (!initialized_sound) _ = c.BASS_Free();
		initialized_music = false;
	}

	pub const Music = struct {
		_handle: c.HMUSIC,

		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Music {
			const flags: c.DWORD = c.BASS_MUSIC_RAMPS | c.BASS_MUSIC_SURROUND2;
			const handle = c.BASS_MusicLoad(c.FALSE, @constCast(path.ptr), 0, 0, flags, 1);
			if (handle == 0) return error.Library;
			return .{ ._handle = handle };
		}
		pub fn free(mus: Music) void {
			_ = c.BASS_MusicFree(mus._handle);
		}
	};

	pub const PlayRepetition = io_interface.music.PlayRepetition;
	pub fn play(mus: Music, repetition: PlayRepetition) LibraryError!void {
		music.stop();

		const flag_repetition: c.DWORD = switch (repetition) { .once => 0, .loop => c.BASS_SAMPLE_LOOP };
		const flags = c.BASS_ChannelFlags(mus._handle, flag_repetition, c.BASS_SAMPLE_LOOP);
		if (flags == -1 or (flags & c.BASS_SAMPLE_LOOP) != flag_repetition) return error.Library;

		if (c.BASS_ChannelPlay(mus._handle, c.TRUE) != c.TRUE) return error.Library;
		playing = mus._handle;
	}
	pub fn stop() void {
		if (playing) |mus_handle| {
			_ = c.BASS_ChannelStop(mus_handle);
			playing = null;
		}
	}

};

pub const sound = struct {

	pub fn init() LibraryError!void {
		if (initialized_sound) return;
		if (!initialized_music) {
			if (c.BASS_GetVersion() & 0xFFFF0000 != 0x02040000) return error.Library;
			if (c.BASS_Init(-1, 44100, c.BASS_DEVICE_STEREO, if (builtin.os.tag == .windows) 0 else null, null) != c.TRUE) return error.Library;
		}
		initialized_sound = true;
	}
	pub fn deinit() void {
		if (!initialized_sound) return;
		if (!initialized_music) _ = c.BASS_Free();
		initialized_sound = false;
	}

	pub const Sound = struct {
		_handle: c.HSAMPLE,

		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Sound {
			const handle = c.BASS_SampleLoad(c.FALSE, @constCast(path.ptr), 0, 0, 1, c.BASS_SAMPLE_OVER_VOL);
			if (handle == 0) return error.Library;
			return .{ ._handle = handle };
		}
		pub fn free(snd: Sound) void {
			_ = c.BASS_SampleFree(snd._handle);
		}
	};

	pub fn play(snd: Sound) LibraryError!void {
		const channel = c.BASS_SampleGetChannel(snd._handle, 0);
		if (channel == 0) return error.Library;
		if (c.BASS_ChannelPlay(channel, c.TRUE) != c.TRUE) return error.Library;
	}

};
