
const std = @import("std");
const io = @import("io.zig");
const assets = @import("assets.zig");
const screens = @import("screens.zig");
const screen_home = @import("screen_home.zig");

pub fn main() !void {

	// initialize the libraries

	try io.gui.init();
	defer io.gui.deinit();

	try io.music.init();
	defer io.music.deinit();

	try io.sound.init();
	defer io.sound.deinit();


	// create the window and start the game

	const window = try io.gui.Window.init(640, 480, "Flowers against Monsters");
	defer window.deinit();

	try assets.musics_init();
	defer assets.musics_deinit();

	try io.music.play(assets.mus_DaisyCrave, .loop);
	defer io.music.stop();

	if (try screen_intro(window) == .quit) return;

	const title_screen_outcome = try screen_title(window);
	defer assets.sounds_deinit(); // the title screen inits the sounds
	defer assets.images_deinit(); // the title screen inits the images
	if (title_screen_outcome == .quit) return;

	try screen_home.screen_home(window);
}

fn screen_intro(window: io.gui.Window) !screens.ScreenOutcome {
	try io.gui.timer_set(1.0, .once);

	const img_info = try io.gui.Image.alloc_from_file("images/disclaimer.png");
	defer img_info.free();

	const img_info_coords = io.gui.Coords {
		.x = @divFloor(window.get_width(), 2),
		.y = @divFloor(window.get_height(), 2),
	};

	window.fill_color(.{ .r = 0, .g = 0, .b = 0, .a = 0 });
	window.blit_image(img_info, img_info_coords);
	window.refresh();

	while (true) {
		const event = io.gui.get_event_blocking();
		switch (event) {
			.quit => return .quit,
			.timer => return .done,

			.mousemove,
			.mousepress,
			.mouserelease => {},
		}
	}
}

fn screen_title(window: io.gui.Window) !screens.ScreenOutcome {
	const bg_load = try io.gui.Image.alloc_from_file("images/title/screen.png");
	defer bg_load.free();

	window.fill_image(bg_load);
	window.refresh();

	const btn_default = try io.gui.Image.alloc_from_file("images/title/button start.png");
	defer btn_default.free();
	const btn_hovered = try io.gui.Image.alloc_from_file("images/title/button start hovered.png");
	defer btn_hovered.free();

	// the title screen is also the assets loading screen
	// (except for the musics which are loaded even before)
	try assets.sounds_init();
	errdefer assets.sounds_deinit();
	try assets.images_init();
	errdefer assets.images_deinit();

	const btn_coords = io.gui.Coords {
		.x = @divFloor(window.get_width(), 2),
		.y = window.get_height() - @divFloor(btn_default.get_height(), 2) - 20,
	};

	var was_hovered = false;
	window.blit_image(btn_default, btn_coords);
	window.refresh();

	while (true) {
		const event = io.gui.get_event_blocking();
		switch (event) {
			.quit => return .quit,
			.timer => unreachable,

			.mousemove,
			.mousepress,
			.mouserelease => |mouse_coords| {
				const is_hovering = screens.are_coords_on_image(mouse_coords, btn_default, btn_coords);

				if (is_hovering != was_hovered) {
					window.fill_image(bg_load);
					window.blit_image(if (is_hovering) btn_hovered else btn_default, btn_coords);
					window.refresh();
					was_hovered = is_hovering;
				}

				if (is_hovering and event == .mousepress) {
					try io.sound.play(assets.snd_button);
					return .done;
				}
			},
		}
	}
}
