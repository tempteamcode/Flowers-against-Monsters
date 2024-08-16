
const std = @import("std");
const io = @import("io.zig");
const assets = @import("assets.zig");
const screens = @import("screens.zig");
const screen_game = @import("screen_game.zig");

fn screen_home_callback(btn_index: usize, window: io.gui.Window) !?screens.ScreenOutcome {
	// TODO: play button sound

	return switch (btn_index) {
		0 => try screen_game.screen_level_select(window),    // new game
		1 => null, //TODO: implement this button             // mini games
		2 => null, //TODO: implement this button             // puzzles
		3 => null, //TODO: implement this button             // survival
		4 => try screen_credits(window),                     // credits
		5 => .quit,                                          // quit

		else => unreachable,
	};
}

pub fn screen_home(window: io.gui.Window) !void {
	const screen = screens.ScreenOfButtons {
		.background_image      = assets.img_home_bg,
		.buttons_center_coords = &.{ .{ .x = 404, .y = 264 }            , .{ .x = 321, .y = 351 }               , .{ .x = 385, .y = 425 }              , .{ .x = 575, .y = 366 }               , .{ .x = 200, .y = 375 }             , .{ .x = 68, .y = 408 }             },
		.buttons_default_image = &.{ assets.img_home_btn_newgame        , assets.img_home_btn_minigames         , assets.img_home_btn_puzzles          , assets.img_home_btn_survival          , assets.img_home_btn_credits         , assets.img_home_btn_quit           },
		.buttons_hovered_image = &.{ assets.img_home_btn_newgame_hovered, assets.img_home_btn_minigames_hovered , assets.img_home_btn_puzzles_hovered  , assets.img_home_btn_survival_hovered  , assets.img_home_btn_credits_hovered , assets.img_home_btn_quit_hovered   },
		.button_callback_click = &screen_home_callback,
	};

	while (true) {
		switch (try screen.show(window)) {
			.done => {
				io.music.stop();
				try io.music.play_file("musics/Daisy Crave.it", .loop);

				continue;
			},
			.quit => break,
		}
	}
}

fn screen_credits(window: io.gui.Window) !screens.ScreenOutcome {
	io.music.stop();

	const center = io.gui.Coords {
		.x = @divFloor(window.get_width(), 2),
		.y = @divFloor(window.get_height(), 2),
	};

	window.fill_image(assets.img_menu_bg);
	window.blit_image(assets.img_menu_credits, center);
	window.refresh();


	try io.music.play_file("musics/Grainiac Maniac.it", .loop);

	while (true) {
		const event = io.gui.get_event_blocking();
		switch (event) {
			.quit => return .quit,
			.timer => unreachable,
			.mousemove => {},
			.mousepress => return .done,
			.mouserelease => {},
		}
	}
}
