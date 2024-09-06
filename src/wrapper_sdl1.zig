
const io_interface = @import("io_interface.zig");
const LibraryError = io_interface.LibraryError;

const c = @cImport({
	@cInclude("SDL.h");
});

const c_png = @cImport({
	@cInclude("lodepng.h");
});

var initialized = false;

fn assert(expected: bool) void {
	if (!expected) @panic("SDL does not work.");
	//_ = expected;
}

export fn io_gui_timer_callback_once(interval: u32) u32 {
	var sdl_event: c.SDL_Event = .{ .type = c.SDL_USEREVENT };
	assert(c.SDL_PushEvent(&sdl_event) == 0);
	_ = interval;
	return 0;
}

export fn io_gui_timer_callback_loop(interval: u32) u32 {
	var sdl_event: c.SDL_Event = .{ .type = c.SDL_USEREVENT };
	assert(c.SDL_PushEvent(&sdl_event) == 0);
	return interval;
}

pub const gui = struct {

	pub fn init() LibraryError!void {
		if (initialized) return;
		if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER) != 0) return error.Library;
		initialized = true;
	}
	pub fn deinit() void {
		if (!initialized) return;
		c.SDL_Quit();
		initialized = false;
	}

	pub const Color = io_interface.gui.Color;
	pub const Direction = io_interface.gui.Direction;
	pub const Coords = io_interface.gui.Coords;

	pub const Image = struct {
		_surface: *c.SDL_Surface,

		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Image {
			var buffer_c: [*c]u8 = undefined;
			var width: c_uint = undefined;
			var height: c_uint = undefined;

			const depth = 32;
			const channels = 4;
			const maskR = 0x000000FF;
			const maskG = 0x0000FF00;
			const maskB = 0x00FF0000;
			const maskA = 0xFF000000;

			if (c_png.lodepng_decode32_file(&buffer_c, &width, &height, path.ptr) != 0) return error.Library;
			assert(buffer_c != null);
			defer c.free(buffer_c.?);

			const pitch = width*channels;
			const buffer: []u8 = buffer_c[0..height*pitch];

			const w: c_int = @bitCast(width);
			const h: c_int = @bitCast(height);
			const p: c_int = @bitCast(pitch);
			if (w != width or h != height or p != pitch) return error.Library;

			const surface_raw = c.SDL_CreateRGBSurfaceFrom(buffer.ptr, w, h, depth, p, maskR, maskG, maskB, maskA) orelse return error.Library;
			defer c.SDL_FreeSurface(surface_raw);

			const surface = c.SDL_DisplayFormatAlpha(surface_raw) orelse return error.Library;
			errdefer comptime unreachable; //c.SDL_FreeSurface(surface);

			return .{ ._surface = surface };
		}
		pub fn free(image: Image) void {
			c.SDL_FreeSurface(image._surface);
		}

		pub fn get_width(image: Image) u31 {
			return @intCast(image._surface.w);
		}
		pub fn get_height(image: Image) u31 {
			return @intCast(image._surface.h);
		}
		pub fn get_pixel(image: Image, coords: Coords) Color {
			const surface = image._surface;
			if (0 <= coords.x and coords.x < surface.w) {
				if (0 <= coords.y and coords.y < surface.h) {
					assert(c.SDL_LockSurface(surface) == 0);
					defer c.SDL_UnlockSurface(surface);

					const x: usize = @intCast(coords.x);
					const y: usize = @intCast(coords.y);

					const bpp = surface.format[0].BytesPerPixel;
					const buffer: [*]u8 = @ptrCast(surface.pixels);
					const p: [*]u8 = buffer[y * surface.pitch + x * bpp ..];

					const value = switch (bpp) {
						1 => p[0],
						2 => @as(*u16, @alignCast(@ptrCast(p))).*,
						3 =>
							if (c.SDL_BYTEORDER == c.SDL_BIG_ENDIAN)
								(@as(u24, p[0]) << 16) | (@as(u24, p[1]) << 8) | @as(u24, p[2])
							else
								@as(u24, p[0]) | (@as(u24, p[1]) << 8) | (@as(u24, p[2]) << 16),
						4 => @as(*u32, @alignCast(@ptrCast(p))).*,
						else => unreachable,
					};

					var color: Color = undefined;
					c.SDL_GetRGBA(value, surface.format, &color.r, &color.g, &color.b, &color.a);
					color.a = 255 - color.a; // SDL uses the opposite alpha convention
					return color;
				}
			}

			return .{ .r = 0, .g = 0, .b = 0, .a = 255 };
		}
	};

	pub const Window = struct {
		_screen: *c.SDL_Surface,

		pub fn init(width: u31, height: u31, title: [:0]const u8) LibraryError!Window {
			if (!initialized) try gui.init();

			const no_icon = 0;
			c.SDL_WM_SetCaption(title, no_icon);

			const any_bpp = 0;
			const flags = c.SDL_ANYFORMAT | c.SDL_DOUBLEBUF | c.SDL_HWSURFACE;
			const screen = c.SDL_SetVideoMode(width, height, any_bpp, flags) orelse return error.Library;

			return .{ ._screen = screen };
		}
		pub fn deinit(window: Window) void {
			_ = window;
			gui.deinit();
		}

		pub fn get_width(window: Window) u31 {
			return @intCast(window._screen.w);
		}
		pub fn get_height(window: Window) u31 {
			return @intCast(window._screen.h);
		}

		pub fn fill_color(window: Window, color: Color) void {
			const color_value = c.SDL_MapRGBA(window._screen.format, color.r, color.g, color.b, 255 - color.a);
			assert(c.SDL_FillRect(window._screen, null, color_value) == 0);
		}
		pub fn fill_image(window: Window, image: Image) void {
			const std = @import("std"); // to assert the precondition:
			std.debug.assert(window.get_width() == image.get_width());
			std.debug.assert(window.get_height() == image.get_height());
			assert(c.SDL_BlitSurface(image._surface, null, window._screen, null) == 0);
		}
		pub fn blit_image(window: Window, image: Image, coords: Coords) void {
			const corner_x = coords.x - @divFloor(image.get_width(), 2);
			const corner_y = coords.y - @divFloor(image.get_height(), 2);
			var dst_rect: c.SDL_Rect = .{ .x = @truncate(corner_x), .y = @truncate(corner_y), .w = undefined, .h = undefined };
			if (dst_rect.x != corner_x or dst_rect.y != corner_y) return; // the coordinates didn't fit, so it's outside the window
			assert(c.SDL_BlitSurface(image._surface, null, window._screen, &dst_rect) == 0);
		}
		pub fn blit_image_part(window: Window, image: Image, coords: Coords, coords_min: Coords, coords_max: Coords) void {
			var src_rect: c.SDL_Rect = .{ .x = @intCast(coords_min.x), .y = @intCast(coords_min.y), .w = @intCast(coords_max.x - coords_min.x), .h = @intCast(coords_max.y - coords_min.y) };
			const corner_x = coords.x - @divFloor(src_rect.w, 2);
			const corner_y = coords.y - @divFloor(src_rect.h, 2);
			var dst_rect: c.SDL_Rect = .{ .x = @truncate(corner_x), .y = @truncate(corner_y), .w = undefined, .h = undefined };
			if (dst_rect.x != corner_x or dst_rect.y != corner_y) return; // the coordinates didn't fit, so it's outside the window
			assert(c.SDL_BlitSurface(image._surface, &src_rect, window._screen, &dst_rect) == 0);
		}

		pub fn refresh(window: Window) void {
			assert(c.SDL_Flip(window._screen) == 0);
		}
	};

	pub const TimerRepetition = io_interface.gui.TimerRepetition;
	pub fn timer_set(delay_seconds: f32, repetition: TimerRepetition) LibraryError!void {
		const delay_ms: u32 = @intFromFloat(delay_seconds * 1000);
		if (delay_ms <= 0) return error.Invalid;

		const callback = switch (repetition) {
			.once => &io_gui_timer_callback_once,
			.loop => &io_gui_timer_callback_loop,
		};

		if (c.SDL_SetTimer(delay_ms, callback) != 0) return error.Library;
	}
	pub fn timer_stop() void {
		assert(c.SDL_SetTimer(0, null) == 0);
	}
	pub fn timer_clear_events() void {
		var ignored: [10]c.SDL_Event = undefined;
		c.SDL_PumpEvents();
		while (true) {
			const count = c.SDL_PeepEvents(&ignored, ignored.len, c.SDL_GETEVENT, c.SDL_USEREVENT);
			assert(count != -1);
			if (count == 0) break;
		}
	}
	pub fn get_time_elapsed() f32 {
		const static = struct { var ticks_last: u32 = 0.0; };
		const ticks_now = c.SDL_GetTicks();
		const ticks_elapsed = ticks_now -% static.ticks_last;
		static.ticks_last = ticks_now;
		return @as(f32, @floatFromInt(ticks_elapsed)) / 1000.0;
	}

	pub fn get_event_blocking() Event {
		var sdl_event: c.SDL_Event = undefined;
		while (true) {
			assert(c.SDL_WaitEvent(&sdl_event) == 1);
			if (event_from_SDL(&sdl_event)) |event| return event;
		}
	}
	pub fn get_event_or_null() ?Event {
		var sdl_event: c.SDL_Event = undefined;
		while (true) {
			if (c.SDL_PollEvent(&sdl_event) == 0) return null;
			if (event_from_SDL(&sdl_event)) |event| return event;
		}
	}

	pub const Event = io_interface.gui.Event;

};

fn event_from_SDL(event: *c.SDL_Event) ?gui.Event {
	return switch (event.type) {
		c.SDL_QUIT            => .quit,
		c.SDL_USEREVENT       => .timer,

	//	c.SDL_KEYDOWN         => .{ .keyrelease   = key_from_SDL(event.key.keysym.sym) orelse return null },
	//	c.SDL_KEYUP           => .{ .keypress     = key_from_SDL(event.key.keysym.sym) orelse return null },

		c.SDL_MOUSEMOTION     => .{ .mousemove    = .{ .x = event.motion.x, .y = event.motion.y } },
		c.SDL_MOUSEBUTTONDOWN => .{ .mousepress   = .{ .x = event.button.x, .y = event.button.y } },
		c.SDL_MOUSEBUTTONUP   => .{ .mouserelease = .{ .x = event.button.x, .y = event.button.y } },

		else                  => null, // the other events are ignored
	};
}

//fn key_from_SDL(key: c.SDLKey) ?gui.Key {
//	return switch (key) {
//		...
//
//		else                  => null, // the other keys are ignored
//	};
//}
