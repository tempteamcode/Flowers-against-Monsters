
const std = @import("std");
const io = @import("io.zig");
const assets = @import("assets.zig");
const engine = @import("engine.zig");
const levels = @import("levels.zig");
const screens = @import("screens.zig");

const Status = struct {
	field: engine.Field,
	progress: engine.Progress,
	mouse: struct {
		seeds_selected: ?usize = null,
		seeds_hovered : ?usize = null,
		sign_hovered  : bool = false,
	},

	const coords_watering_can: io.gui.Coords = .{ .x = 48, .y = 420 };
	const coords_water       : io.gui.Coords = .{ .x = 48, .y = 466 };

	const coords_seeds: [engine.Progress.seeds_max_count]io.gui.Coords = .{
		.{ .x = 65 * 2, .y = 430 },
		.{ .x = 65 * 3, .y = 430 },
		.{ .x = 65 * 4, .y = 430 },
		.{ .x = 65 * 5, .y = 430 },
		.{ .x = 65 * 6, .y = 430 },
		.{ .x = 65 * 7, .y = 430 },
		.{ .x = 65 * 8, .y = 430 },
		.{ .x = 65 * 9, .y = 430 },
	};

	const monster_cell_offset_y = 0.8;
	const flower_cell_offset_y = -0.1;

	const image_sign_coords: io.gui.Coords = .{ .x = 600, .y = 440 };
	fn image_sign(status: *const Status, hovered: bool) io.gui.Image {
		return switch (status.progress.state) {
			.fighting => if (hovered) assets.img_game_sign_stop_hovered else assets.img_game_sign_stop,
			.victory => if (hovered) assets.img_game_sign_next_hovered else assets.img_game_sign_next,
			.defeat => if (hovered) assets.img_game_sign_retry_hovered else assets.img_game_sign_retry,
		};
	}
};


const field_top_left_corner: io.gui.Coords = .{ .x =  20, .y =  80 };
const field_width_height   : io.gui.Coords = .{ .x = 576, .y = 320 };

fn screen_to_field(coords: io.gui.Coords) engine.Coords {
	return .{
		.x = @as(f32, @floatFromInt(coords.x - field_top_left_corner.x)) / field_width_height.x * engine.Field.cols_count,
		.y = @as(f32, @floatFromInt(coords.y - field_top_left_corner.y)) / field_width_height.y * engine.Field.rows_count,
	};
}
fn field_to_screen(coords: engine.Coords) io.gui.Coords {
	return .{
		.x = @as(i32, @intFromFloat(coords.x / engine.Field.cols_count * field_width_height.x)) + field_top_left_corner.x,
		.y = @as(i32, @intFromFloat(coords.y / engine.Field.rows_count * field_width_height.y)) + field_top_left_corner.y,
	};
}


pub fn screen_level_select(window: io.gui.Window) !screens.ScreenOutcome {
	var buttons_center_coords: [50]io.gui.Coords = undefined;
	var buttons_default_image: [50]io.gui.Image  = .{ assets.img_menu_option_greyed } ** 50;
	var buttons_hovered_image: [50]io.gui.Image  = .{ assets.img_menu_option_greyed } ** 50;
	if (levels.levels.len > 50) @compileError("too many levels for the selection screen");

	for (&buttons_center_coords, 0..) |*coords, i| {
		coords.x = (@as(u31, @intCast(i)) % 10) * 56 + @divFloor(window.get_width() - 9*56, 2);
		coords.y = (@as(u31, @intCast(i)) / 10) * 56 + @divFloor(window.get_height() - 4*56, 2);
	}


	for (0..levels.levels.len) |i| {
		buttons_default_image[i] = assets.img_menu_option;
		buttons_hovered_image[i] = assets.img_menu_option_hovered;
	}

	const screen = screens.ScreenOfButtons {
		.background_image        = assets.img_menu_bg,
		.buttons_center_coords   = &buttons_center_coords,
		.buttons_default_image   = &buttons_default_image,
		.buttons_hovered_image   = &buttons_hovered_image,
		.button_callback_click   = &screen_level_select_callback,
	};

	return try screen.show(window);
}

fn screen_level_select_callback(button_index: usize, window: io.gui.Window) anyerror!?screens.ScreenOutcome {
	var level_index = button_index;
	if (level_index >= levels.levels.len) return null;

	while (true) {
		switch (try screen_game(window, level_index)) {
			.quit => return .quit,
			.stop => return .done,
			.next => if (level_index + 1 < levels.levels.len) { level_index += 1; } else { return .done; },
			.retry => continue,
		}
	}
}

fn screen_game_refresh(allocator: std.mem.Allocator, window: io.gui.Window, status: *const Status) !void {
	window.fill_image(assets.img_game_bg);

	if (0 < status.field.row_beg or status.field.row_end < engine.Field.rows_count) {
		for (0..engine.Field.rows_count + 1) |row_coverable_index| {
			const row_removable_index = @min(row_coverable_index, engine.Field.rows_count - 1);
			if (!(status.field.row_beg <= row_removable_index and row_removable_index < status.field.row_end)) {
				var row_center = field_to_screen(.{ .x = 0, .y = @as(f32, @floatFromInt(row_coverable_index)) + 0.5 });
				row_center.x = @divFloor(window.get_width(), 2);
				window.blit_image(assets.img_game_row_removed, row_center);
			}
		}
	}

	for (status.field.monsters.items) |monster| {
		var coords = field_to_screen(.{
			.x = monster.x,
			.y = @as(f32, @floatFromInt(monster.row)) + Status.monster_cell_offset_y,
		});
		const image = switch (monster.kind) {
			.skeleton        => assets.img_game_monster_skeleton       ,
			.ghost           => assets.img_game_monster_ghost          ,
			.skeleton_helmet => assets.img_game_monster_skeleton_helmet,
			.undead          => assets.img_game_monster_undead         ,
			.undead_angry    => assets.img_game_monster_undead_fast    ,
		};
		coords.y -= @divFloor(image.get_height(), 2);
		const image_sprites_count: usize = switch (monster.kind) {
			.skeleton        => assets.nb_game_monster_skeleton       ,
			.ghost           => assets.nb_game_monster_ghost          ,
			.skeleton_helmet => assets.nb_game_monster_skeleton_helmet,
			.undead          => assets.nb_game_monster_undead         ,
			.undead_angry    => assets.nb_game_monster_undead_fast    ,
		};
		const image_sprite_index = @as(usize, @intFromFloat(monster.age * @as(f32, @floatFromInt(image_sprites_count)))) % image_sprites_count;
		screens.blit_sprite(window, image, coords, image_sprite_index, image_sprites_count);
	}

	for (status.field.flowers, 0..) |flowers, row| for (flowers, 0..) |flower_or_null, col| {
		if (flower_or_null) |flower| {
			const coords = field_to_screen(.{
				.x = @as(f32, @floatFromInt(col)) + 0.5,
				.y = @as(f32, @floatFromInt(row)) + 0.5 + Status.flower_cell_offset_y,
			});
			const image = switch (flower.kind) {
				.rose           => assets.img_game_flower_rose        ,
				.philodendron   => assets.img_game_flower_philodendron,
				.stone          => assets.img_game_flower_stone       ,
				.rose_double    => assets.img_game_flower_rose_double ,
				.rose_white     => assets.img_game_flower_rose_white  ,
			};
			window.blit_image(image, coords);
		}
	};

	for (status.field.bullets.items) |bullet| {
		const coords = field_to_screen(bullet.coords);
		const image = switch (bullet.kind) {
			.thorn        => assets.img_game_shot_thorn       ,
			.thorn_frozen => assets.img_game_shot_thorn_frozen,
		};
		window.blit_image(image, coords);
	}

	for (status.progress.seeds, Status.coords_seeds, 0..) |seed_or_null, coords_center, i| {
		if (seed_or_null) |seed| {
			const image = switch (seed.kind) {
				.rose           => assets.img_game_icon_rose        ,
				.philodendron   => assets.img_game_icon_philodendron,
				.stone          => assets.img_game_icon_stone       ,
				.rose_double    => assets.img_game_icon_rose_double ,
				.rose_white     => assets.img_game_icon_rose_white  ,
			};
			window.blit_image(
				     if (i == status.mouse.seeds_selected) assets.img_game_seeds_selected
				else if (i == status.mouse.seeds_hovered ) assets.img_game_seeds_hovered
				else                                       assets.img_game_seeds, coords_center
			);
			window.blit_image(image, coords_center);
			if (status.progress.water != null) {
				var coords_water = coords_center; coords_water.x += 10; coords_water.y += 18;
				window.blit_image(assets.img_game_water_icon, coords_water); coords_water.y += 2;
				try screens.blit_integer(allocator, window, coords_water, seed.kind.get_cost(), .right, assets.img_digits_tiny, assets.nb_digits);
			}
		}
	}

	for (status.field.collectibles.items) |collectible| {
		const image = switch (collectible.kind) { .water => assets.img_game_water };
		window.blit_image(image, field_to_screen(collectible.coords));
	}

	if (status.progress.water) |water| {
		window.blit_image(assets.img_game_watering_can, Status.coords_watering_can);
		try screens.blit_integer(allocator, window, Status.coords_water, water, .center, assets.img_digits, assets.nb_digits);
	}

	window.blit_image(status.image_sign(status.mouse.sign_hovered), Status.image_sign_coords);

	window.refresh();
}

pub const ScreenGameOutcome = enum { quit, stop, retry, next };
pub fn screen_game(window: io.gui.Window, level_index: usize) !ScreenGameOutcome {
	io.music.stop();

	const prng_seed = 0;
	var prng = std.rand.DefaultPrng.init(prng_seed);

	var gpa = std.heap.GeneralPurposeAllocator(.{}){};
	defer std.debug.assert(gpa.deinit() == .ok);
	const allocator = gpa.allocator();

	const level = levels.levels[level_index];

	var status = Status {
		.field = .{
			.row_beg      = level.row_beg,
			.row_end      = level.row_end,
			.cells        = .{ .{ engine.Cell{ .state = .grass } } ** engine.Field.cols_count } ** engine.Field.rows_count,
			.flowers      = .{ .{                        null    } ** engine.Field.cols_count } ** engine.Field.rows_count,
			.bullets      = std.ArrayList(engine.Bullet     ).init(allocator),
			.monsters     = std.ArrayList(engine.Monster    ).init(allocator),
			.collectibles = std.ArrayList(engine.Collectible).init(allocator),
			.visible_min  = screen_to_field(.{ .x =                  0, .y =                   0 }),
			.visible_max  = screen_to_field(.{ .x = window.get_width(), .y = window.get_height() }),
		},
		.progress = .{
			.water = level.water,
			.rain_delay = level.water_freq,
			.rain_freq  = level.water_freq,
			.kind  = level.seeds_kind,
			.seeds = .{ null } ** engine.Progress.seeds_max_count,
			.waves = level.waves,
			.rand = prng.random(),
		},
		.mouse = .{},
	};
	defer {
		status.field.bullets     .deinit();
		status.field.monsters    .deinit();
		status.field.collectibles.deinit();
	}

	const all_seeds: []const engine.FlowerKind = &.{ .rose, .philodendron, .stone, .rose_white, .rose_double };
	const level_seeds = switch (level.seeds_kind) { 
		.fixed => |seeds| seeds,
		.player_choice => all_seeds, //TODO: add a seed selection screen instead
	};
	for (level_seeds, 0..) |seed, i| {
		status.progress.seeds[i] = .{ .kind = seed };
	}

	try screen_game_refresh(allocator, window, &status);

	try io.music.play_file("musics/Raze the Groof.it", .loop);
	defer io.music.stop();

	try io.gui.timer_set(0.05, .loop);
	defer io.gui.timer_stop();

	_ = io.gui.get_time_elapsed(); // t0

	while (true) {
		const event = io.gui.get_event_blocking();
		switch (event) {
			.quit => return .quit,
			.mousemove, .mousepress, .mouserelease => |mouse_coords| {
				status.mouse.seeds_hovered = null;
				for (Status.coords_seeds, 0..) |seeds_coords, seeds_index| {
					if (status.progress.seeds[seeds_index] == null) continue;
					if (screens.are_coords_on_image(mouse_coords, assets.img_game_seeds, seeds_coords)) {
						status.mouse.seeds_hovered = seeds_index;
						break;
					}
				}

				status.mouse.sign_hovered = screens.are_coords_on_image(mouse_coords, status.image_sign(false), Status.image_sign_coords);

				if (event == .mousepress) {
					var collectible_pressed: ?usize = null;
					var collectible_index = status.field.collectibles.items.len;
					while (collectible_index > 0) { collectible_index -= 1; // iteration from back to front
						const collectible = status.field.collectibles.items[collectible_index];
						const image = switch (collectible.kind) { .water => assets.img_game_water };
						const coords = field_to_screen(collectible.coords);
						if (screens.are_coords_on_image(mouse_coords, image, coords)) {
							collectible_pressed = collectible_index;
							break;
						}
					}

					if (collectible_pressed) |i| {
						const collectible = status.field.collectibles.orderedRemove(i);
						switch (collectible.kind) {
							.water => {
								//TODO: sound play water collected

								if (status.progress.water) |*water| water.* += engine.water_worth;
							},
						}
					} else if (status.mouse.seeds_hovered) |seeds_hovered| {
						//TODO: sound play seeds clicked

						status.mouse.seeds_selected = if (status.mouse.seeds_selected == seeds_hovered) null else seeds_hovered;
					} else if (status.mouse.seeds_selected) |seeds_selected| {
						if (status.progress.seeds[seeds_selected]) |*seeds| {
							const field_coords = screen_to_field(mouse_coords);
							if (engine.put_seeds(seeds, field_coords, &status.field, &status.progress) == .put) {
								//TODO: sound play flower planted

								status.mouse.seeds_selected = null;
							}
						}
					} else if (status.mouse.sign_hovered) {
						return switch (status.progress.state) {
							.fighting => .stop,
							.victory => .next,
							.defeat => .retry,
						};
					}
				}

				continue;
			},
			.timer => io.gui.timer_clear_events(),
		}

		const delay: f32 = io.gui.get_time_elapsed();
		try engine.forward(delay, &status.field, &status.progress);
		try screen_game_refresh(allocator, window, &status);
	}
}
