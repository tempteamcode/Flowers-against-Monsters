
pub const LibraryError = error { Library, Invalid };

pub const gui = struct {
	pub fn init() LibraryError!void {}
	pub fn deinit() void {}

	pub const Coords = struct { x: i32, y: i32 };
	pub const Direction = enum { up, down, left, right };
	pub const Color = struct { r: u8, g: u8, b: u8, a: u8 }; // alpha: 0 = opaque, 255 = transparent

	pub const Image = struct {
		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Image { _ = path; return .{}; }
		pub fn free(image: Image) void { _ = image; }

		pub fn get_width(image: Image) u31 { _ = image; comptime unreachable; }
		pub fn get_height(image: Image) u31 { _ = image; comptime unreachable; }
		pub fn get_pixel(image: Image, coords: Coords) Color { _ = image; _ = coords; comptime unreachable; }
	};

	pub const Window = struct {
		pub fn init(width: u31, height: u31, title: [:0]const u8) LibraryError!Window { _ = width; _ = height; _ = title; return .{}; }
		pub fn deinit(window: Window) void { _ = window; }

		pub fn get_width(window: Window) u31 { _ = window; comptime unreachable; }
		pub fn get_height(window: Window) u31 { _ = window; comptime unreachable; }

		pub fn fill_color(window: Window, color: Color) void { _ = window; _ = color; }
		pub fn fill_image(window: Window, image: Image) void { _ = window; _ = image; }
		pub fn blit_image(window: Window, image: Image, coords: Coords) void { _ = window; _ = image; _ = coords; }
		pub fn blit_image_part(window: Window, image: Image, coords: Coords, coords_min: Coords, coords_max: Coords) void { _ = window; _ = image; _ = coords; _ = coords_min; _ = coords_max; }

		pub fn refresh(window: Window) void { _ = window; }
	};

	pub const TimerRepetition = enum { once, loop };
	pub fn timer_set(delay_seconds: f32, repetition: TimerRepetition) LibraryError!void { _ = delay_seconds; _ = repetition; comptime unreachable; }
	pub fn timer_stop() void {}
	pub fn timer_clear_events() void { comptime unreachable; }
	pub fn get_time_elapsed() f32 { comptime unreachable; }

	pub fn get_event_blocking() Event { comptime unreachable; }
	pub fn get_event_or_null() ?Event { comptime unreachable; }

	pub const Event = union(enum) {
		quit: void,
		timer: void,
	//	keypress: Key,
	//	keyrelease: Key,
		mousemove: Coords,
		mousepress: Coords,
		mouserelease: Coords,
	};

	//pub const Key = union(enum) { ... }; // unused
};

pub const music = struct {
	pub fn init() LibraryError!void {}
	pub fn deinit() void {}

	pub const PlayRepetition = enum { once, loop };
	pub fn play_file(path: [:0]const u8, repetition: PlayRepetition) LibraryError!void { _ = path; _ = repetition; }
	pub fn stop() void {}
};

pub const sound = struct {
	pub fn init() LibraryError!void {}
	pub fn deinit() void {}

	pub const Sound = struct {
		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Sound { _ = path; return .{}; }
		pub fn free(snd: Sound) void { _ = snd; }

		pub fn play(snd: Sound) void { _ = snd; }
	};
};
