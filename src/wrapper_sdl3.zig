//! Provides a zig interface for the SDL 3 graphic library.

const std = @import("std");

const io_interface = @import("io_interface.zig");
const LibraryError = io_interface.LibraryError;

// SDL3 defines the type SDL_bool, which zig assimilates to its own boolean type
// but the macros SDL_TRUE and SDL_FALSE are assimilated to c_int. So there's not
// compatible with the type SDL_bool returned by many functions.

const c = @cImport({
	@cDefine("SDL_MAIN_HANDLED", "1");
	@cInclude("SDL3/SDL_main.h");
	@cInclude("SDL3/SDL.h");
	@cInclude("SDL3_image/SDL_image.h");
});

var initialized = false;
var set_main_ready = false;

fn assert(expected: bool) void {
	if (!expected) @panic("SDL3 does not work.");
}

fn printError(funcName: []const u8) void {
	const message = c.SDL_GetError();
	std.debug.print("{s}(): {s}.\n", .{funcName, message});
}

fn printDevInfo() void {
	// Can be called even if SDL wasn't initialized.
	const version = c.SDL_GetVersion();
	const major = c.SDL_VERSIONNUM_MAJOR(version);
	const minor = c.SDL_VERSIONNUM_MINOR(version);
	const micro = c.SDL_VERSIONNUM_MICRO(version);
	const revision = c.SDL_GetRevision();
	const img_version = c.IMG_Version();
	const img_major = c.SDL_VERSIONNUM_MAJOR(img_version);
	const img_minor = c.SDL_VERSIONNUM_MINOR(img_version);
	const img_micro = c.SDL_VERSIONNUM_MICRO(img_version);
	std.debug.print("Using SDL {}.{}.{} ({s}).\nUsing SDL_image {}.{}.{}.\n",
		.{major, minor, micro, revision, img_major, img_minor, img_micro});

	const platform = c.SDL_GetPlatform();
	const cpu_count = c.SDL_GetCPUCount();
	const cache_line_size = c.SDL_GetCPUCacheLineSize();
	const simd_align = c.SDL_GetSIMDAlignment();
	const ram = c.SDL_GetSystemRAM();
	std.debug.print(
		"Platform: {s}\nCPU: {} avalaible\nL1 cache line: {}b\nSMID alignement: {}b\nRAM: {}MiB\n",
		.{platform, cpu_count, cache_line_size, simd_align, ram}
	);
}

export fn io_gui_timer_callback_once(_: ?*anyopaque, _: c.SDL_TimerID, interval: u32) u32 {
	_ = interval;
	var sdl_event: c.SDL_Event = .{ .type = c.SDL_EVENT_USER };
	assert(c.SDL_PushEvent(&sdl_event));
	return 0;
}

export fn io_gui_timer_callback_loop(_: ?*anyopaque, _: c.SDL_TimerID, interval: u32) u32 {
	var sdl_event: c.SDL_Event = .{ .type = c.SDL_EVENT_USER };
	assert(c.SDL_PushEvent(&sdl_event));
	return interval;
}

pub const gui = struct {

	var timer_id: ?c.SDL_TimerID = null;

	pub fn init() LibraryError!void {
		if (initialized) return;
		if (!set_main_ready) {
			c.SDL_SetMainReady();
			set_main_ready = true;
		}
		if ( ! c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER)) return error.Library;
		const img_flags = c.IMG_INIT_PNG;
		if (c.IMG_Init(img_flags) != img_flags) {
			printError("IMG_Init");
			return error.Library;
		}
		initialized = true;
		printDevInfo();
	}
	pub fn deinit() void {
		if (!initialized) return;
		c.IMG_Quit();
		c.SDL_Quit();
		initialized = false;
	}

	pub const Color = io_interface.gui.Color;
	pub const Direction = io_interface.gui.Direction;
	pub const Coords = io_interface.gui.Coords;

	pub const Image = struct {
		surface: *c.SDL_Surface,

		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Image {
			const surface = c.IMG_Load(path);
			if (surface) |ptr| {
				return .{ .surface = ptr };
			} else {
				printError("IMG_Load");
				return error.Library;
			}
		}
		pub fn free(image: Image) void {
			c.SDL_DestroySurface(image.surface);
		}

		pub fn get_width(image: Image) u31 {
			return @intCast(image.surface.*.w);
		}
		pub fn get_height(image: Image) u31 {
			return @intCast(image.surface.*.h);
		}
		pub fn get_pixel(image: Image, coords: Coords) Color {
			const surface = image.surface;
			if (0 <= coords.x and coords.x < surface.w) {
				if (0 <= coords.y and coords.y < surface.h) {
					var color: Color = undefined;
					assert(c.SDL_ReadSurfacePixel(surface, @intCast(coords.x), @intCast(coords.y), &color.r, &color.g, &color.b, &color.a));
					color.a = 255 - color.a; // SDL uses the opposite alpha convention
					return color;
				}
			}

			return .{ .r = 0, .g = 0, .b = 0, .a = 255 };
		}
	};

	pub const Window = struct {
		_window: *c.SDL_Window,
		// _render: ?*c.SDL_Renderer = null,

		pub fn init(width: u31, height: u31, title: [:0]const u8) LibraryError!Window {
			if (!initialized) try gui.init();

			// flag c.SDL_WINDOW_RESIZABLE exists. But the program needs to be adapted.
			const win = c.SDL_CreateWindow(title, width, height, 0) orelse {
				printError("SDL_CreateWindow");
				return error.Library;
			};
			errdefer c.SDL_DestroyWindow(win);

			// const rdr = c.SDL_CreateRenderer(win, null);
			// errdefer c.SDL_DestroyRenderer(rdr);
			// if (win == null) {
			// 	printError("SDL_CreateRenderer");
			// 	return error.Library;
			// }

			return .{ ._window = win } ; // , ._render = rdr };
		}
		pub fn deinit(window: Window) void {
			// c.SDL_DestroyRenderer(window._render);
			c.SDL_DestroyWindow(window._window);
			gui.deinit();
		}

		fn getSurfaceOrPanic(window: Window) *c.SDL_Surface {
			const surface = c.SDL_GetWindowSurface(window._window);
			assert(surface != null);
			return surface;
		}

		pub fn get_width(window: Window) u31 {
			return @intCast(c.SDL_GetWindowSurface(window._window).*.w);
		}
		pub fn get_height(window: Window) u31 {
			return @intCast(c.SDL_GetWindowSurface(window._window).*.h);
		}

		pub fn fill_color(window: Window, color: Color) void {
			const surface = window.getSurfaceOrPanic();
			const format_detail = c.SDL_GetPixelFormatDetails(surface.format);
			assert(format_detail != null);
			const pixel_value = c.SDL_MapRGBA(format_detail, null, color.r, color.g, color.b, 255 - color.a);
			assert(c.SDL_FillSurfaceRect(surface, null, pixel_value));
		}
		pub fn fill_image(window: Window, image: Image) void {
			std.debug.assert(window.get_width() == image.get_width());
			std.debug.assert(window.get_height() == image.get_height());
			const window_surface = window.getSurfaceOrPanic();
			assert(c.SDL_BlitSurface(image.surface, null, window_surface, null));
		}
		pub fn blit_image(window: Window, image: Image, coords: Coords) void {
			const corner_x = coords.x - @divFloor(image.get_width(), 2);
			const corner_y = coords.y - @divFloor(image.get_height(), 2);
			var dst_rect: c.SDL_Rect = .{ .x = @truncate(corner_x), .y = @truncate(corner_y), .w = undefined, .h = undefined };
			if (dst_rect.x != corner_x or dst_rect.y != corner_y) return; // the coordinates didn't fit, so it's outside the window
			const window_surface = window.getSurfaceOrPanic();
			assert(c.SDL_BlitSurface(image.surface, null, window_surface, &dst_rect));
		}
		pub fn blit_image_part(window: Window, image: Image, coords: Coords, coords_min: Coords, coords_max: Coords) void {
			var src_rect: c.SDL_Rect = .{ .x = @intCast(coords_min.x), .y = @intCast(coords_min.y), .w = @intCast(coords_max.x - coords_min.x), .h = @intCast(coords_max.y - coords_min.y) };
			const corner_x = coords.x - @divFloor(src_rect.w, 2);
			const corner_y = coords.y - @divFloor(src_rect.h, 2);
			var dst_rect: c.SDL_Rect = .{ .x = @truncate(corner_x), .y = @truncate(corner_y), .w = undefined, .h = undefined };
			if (dst_rect.x != corner_x or dst_rect.y != corner_y) return; // the coordinates didn't fit, so it's outside the window
			const window_surface = window.getSurfaceOrPanic();
			assert(c.SDL_BlitSurface(image.surface, &src_rect, window_surface, &dst_rect));
		}

		pub fn refresh(window: Window) void {
			assert(c.SDL_UpdateWindowSurface(window._window));
		}
	};

	pub const TimerRepetition = io_interface.gui.TimerRepetition;
	pub fn timer_set(delay_seconds: f32, repetition: TimerRepetition) LibraryError!void {
		timer_stop();

		const delay_ms: u32 = @intFromFloat(delay_seconds * 1000.0);
		if (delay_ms <= 0) return error.Invalid;

		const callback = switch (repetition) {
			.once => &io_gui_timer_callback_once,
			.loop => &io_gui_timer_callback_loop,
		};

		const ret = c.SDL_AddTimer(delay_ms, callback, null);
		if (ret == 0) {
			printError("SDL_AddTimer");
			return error.Library;
		}
		if (repetition == .loop) {
			timer_id = ret;
		}
	}
	pub fn timer_stop() void {
		if (timer_id) |id| {
			const ret = c.SDL_RemoveTimer(id);
			if (!ret) {
				printError("SDL_RemoveTimer");
			}
			timer_id = null;
		}
	}
	pub fn timer_clear_events() void {
		var ignored: [10]c.SDL_Event = undefined;
		c.SDL_PumpEvents(); // https://wiki.libsdl.org/SDL3/SDL_PeepEvents#remarks
		while (true) {
			const count = c.SDL_PeepEvents(
				&ignored,
				ignored.len,
				c.SDL_GETEVENT,
				c.SDL_EVENT_USER,
				c.SDL_EVENT_USER,
			);
			assert(count != -1);
			if (count == 0) break;
		}
	}
	pub fn get_time_elapsed() f32 {
		const static = struct { var ticks_last: u64 = 0.0; };
		const ticks_now = c.SDL_GetTicks();
		const ticks_elapsed = ticks_now -% static.ticks_last;
		static.ticks_last = ticks_now;
		return @as(f32, @floatFromInt(ticks_elapsed)) / 1000.0;
	}

	pub fn get_event_blocking() Event {
		var sdl_event: c.SDL_Event = undefined;
		while (true) {
			assert(c.SDL_WaitEvent(&sdl_event));
			if (event_from_SDL(&sdl_event)) |event| return event;
		}
	}
	pub fn get_event_or_null() ?Event {
		var sdl_event: c.SDL_Event = undefined;
		while (true) {
			if (c.SDL_PollEvent(&sdl_event)) return null;
			if (event_from_SDL(&sdl_event)) |event| return event;
		}
	}

	pub const Event = io_interface.gui.Event;

};

fn event_from_SDL(event: *c.SDL_Event) ?gui.Event {
	return switch (event.type) {
		c.SDL_EVENT_QUIT               => .quit,
		c.SDL_EVENT_USER               => .timer,

		c.SDL_EVENT_MOUSE_MOTION       => .{ .mousemove    = .{ .x = @intFromFloat(event.motion.x), .y = @intFromFloat(event.motion.y) } },
		c.SDL_EVENT_MOUSE_BUTTON_DOWN  => .{ .mousepress   = .{ .x = @intFromFloat(event.button.x), .y = @intFromFloat(event.button.y) } },
		c.SDL_EVENT_MOUSE_BUTTON_UP    => .{ .mouserelease = .{ .x = @intFromFloat(event.button.x), .y = @intFromFloat(event.button.y) } },

		else                           => null, // the other events are ignored
	};
}
