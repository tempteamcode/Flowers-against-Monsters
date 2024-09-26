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
	// Version functions be called even if SDL wasn't initialized.
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

// oups global variable for constructing images with the renderer.
var renderer: ?*c.SDL_Renderer = null;

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
		_texture: *c.SDL_Texture,
		_w : u31,
		_h : u31,

		pub fn alloc_from_file(path: [:0]const u8) LibraryError!Image {
			const surface = c.IMG_Load(path) orelse {
				printError("IMG_Load");
				return error.Library;
			};
			defer c.SDL_DestroySurface(surface);
			const texture = c.SDL_CreateTextureFromSurface(renderer.?, surface) orelse {
				printError("SDL_CreateTextureFromSurface");
				return error.Library;
			};
			const width: u31 = @intCast(surface.*.w);
			const height: u31 = @intCast(surface.*.h);
			return .{ ._texture = texture, ._w = width, ._h = height};
		}
		pub fn free(image: Image) void {
			c.SDL_DestroyTexture(image._texture);
		}

		pub fn get_width(image: Image) u31 {
			return image._w;
		}
		pub fn get_height(image: Image) u31 {
			return image._h;
		}
		pub fn get_pixel(image: Image, coords: Coords) Color {
			// const surface = image.surface;
			if (0 <= coords.x and coords.x < image._w) {
				if (0 <= coords.y and coords.y < image._h) {
					// var color: Color = undefined;
					// assert(c.SDL_ReadSurfacePixel(surface, @intCast(coords.x), @intCast(coords.y), &color.r, &color.g, &color.b, &color.a));
					// color.a = 255 - color.a; // SDL uses the opposite alpha convention
					// return color;

					// oups, how to read the pixel values on a texture, knowing it could cost intensive GPU/CPU ?
					return .{ .r = 0, .g = 0, .b = 0, .a = 0 };
				}
			}

			return .{ .r = 0, .g = 0, .b = 0, .a = 255 };
		}
	};

	pub const Window = struct {
		_window: *c.SDL_Window,
		_render: *c.SDL_Renderer,
		_logical_width: u31,
		_logical_height: u31,

		pub fn init(width: u31, height: u31, title: [:0]const u8) LibraryError!Window {
			if (!initialized) try gui.init();

			// flag c.SDL_WINDOW_RESIZABLE exists. But the program needs to be adapted.
			const win = c.SDL_CreateWindow(title, width, height, c.SDL_WINDOW_RESIZABLE) orelse {
				printError("SDL_CreateWindow");
				return error.Library;
			};
			errdefer c.SDL_DestroyWindow(win);

			const rdr = c.SDL_CreateRenderer(win, null) orelse {
				printError("SDL_CreateRenderer");
				return error.Library;
			};
			errdefer c.SDL_DestroyRenderer(rdr);
			std.debug.print("SDL chose renderer '{s}'.\n", .{c.SDL_GetRendererName(rdr)});

			const ok = c.SDL_SetRenderLogicalPresentation(rdr, 640, 480, c.SDL_LOGICAL_PRESENTATION_STRETCH, c.SDL_SCALEMODE_LINEAR); // this function ain't up-to-date.
			if (!ok) {
				printError("SDL_SetRenderLogicalPresentation");
				return error.Library;
			}

			renderer = rdr; // oups global variable for constructing images with the renderer.
			return .{ ._window = win, ._render = rdr, ._logical_width = 640, ._logical_height = 480 };
		}
		pub fn deinit(window: Window) void {
			c.SDL_DestroyRenderer(window._render);
			c.SDL_DestroyWindow(window._window);
			gui.deinit();
		}

		fn blit_image_impl(window: Window, image: Image, src_rect: c.SDL_FRect, dst_coords: Coords) void {
			const corner_x: f32 = @as(f32, @floatFromInt(dst_coords.x)) - src_rect.w / 2.0;
			const corner_y: f32 = @as(f32, @floatFromInt(dst_coords.y)) - src_rect.h / 2.0;
			const dst_rect: c.SDL_FRect = .{ .x = corner_x, .y = corner_y, .w = src_rect.w, .h = src_rect.h };

			const ret = c.SDL_RenderTexture(window._render, image._texture, &src_rect, &dst_rect);
			if (!ret) {
				printError("SDL_RenderTexture");
				std.process.abort();
			}
		}

		pub fn get_width(window: Window) u31 {
			return window._logical_width;
		}
		pub fn get_height(window: Window) u31 {
			return window._logical_height;
		}

		pub fn fill_color(window: Window, color: Color) void {
			var ret = c.SDL_SetRenderDrawColor(window._render, color.r, color.g, color.b, 255 - color.a);
			if (!ret) {
				printError("SDL_SetRenderDrawColor");
				std.process.abort();
			}
			ret = c.SDL_RenderClear(window._render);
			if (!ret) {
				printError("SDL_RenderClear");
				std.process.abort();
			}
		}
		pub fn fill_image(window: Window, image: Image) void {
			const ret = c.SDL_RenderTexture(window._render, image._texture, null, null);
			if (!ret) {
				printError("SDL_RenderTexture");
				std.process.abort();
			}
		}
		pub fn blit_image(window: Window, image: Image, coords: Coords) void {
			const src_rect: c.SDL_FRect = .{
				.x = 0.0,
				.y = 0.0,
				.w = @floatFromInt(image.get_width()),
				.h = @floatFromInt(image.get_height()),
			};
			window.blit_image_impl(image, src_rect, coords);
		}
		pub fn blit_image_part(window: Window, image: Image, coords: Coords, coords_min: Coords, coords_max: Coords) void {
			const src_rect: c.SDL_FRect = .{
				.x = @floatFromInt(coords_min.x),
				.y = @floatFromInt(coords_min.y),
				.w = @floatFromInt(coords_max.x - coords_min.x),
				.h = @floatFromInt(coords_max.y - coords_min.y),
			};
			window.blit_image_impl(image, src_rect, coords);
		}

		pub fn refresh(window: Window) void {
			assert(c.SDL_RenderPresent(window._render));
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
			if ( ! c.SDL_PollEvent(&sdl_event)) return null;
			if (event_from_SDL(&sdl_event)) |event| return event;
		}
	}

	pub const Event = io_interface.gui.Event;

};

fn event_from_SDL(event: *c.SDL_Event) ?gui.Event {
	return switch (event.type) {
		c.SDL_EVENT_QUIT               => .quit,
		c.SDL_EVENT_USER               => .timer,

		c.SDL_EVENT_MOUSE_MOTION       => {
			const coords = convert_event_coordinates(event.button.x, event.button.y);
			return .{ .mousemove = coords };
		},
		c.SDL_EVENT_MOUSE_BUTTON_DOWN  =>  {
			const coords = convert_event_coordinates(event.button.x, event.button.y);
			return .{ .mousepress = coords };
		},
		c.SDL_EVENT_MOUSE_BUTTON_UP    =>  {
			const coords = convert_event_coordinates(event.button.x, event.button.y);
			return .{ .mouserelease = coords };
		},

		else                           => null, // the other events are ignored
	};
}

fn convert_event_coordinates(x: f32, y: f32) gui.Coords {
	// SDL_ConvertEventToRenderCoordinates() would be better but it doesn't work.
	var new_x: f32 = undefined;
	var new_y: f32 = undefined;
	const ret = c.SDL_RenderCoordinatesFromWindow(
		renderer,
		x,
		y,
		&new_x,
		&new_y,
	);
	if (!ret) {
		printError("SDL_RenderCoordinatesFromWindow");
		return gui.Coords {.x = @intFromFloat(x), .y = @intFromFloat(y)};
	}
	return gui.Coords {.x = @intFromFloat(new_x), .y = @intFromFloat(new_y)};
}
