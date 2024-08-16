
const std = @import("std");
const io = @import("io.zig");

pub const Alignment = enum { left, center, right };

pub const ScreenOutcome = enum {
	done, // done with this screen
	quit, // quit the whole program
};

pub const ScreenOfButtons = struct {
	background_image       : io.gui.Image,
	buttons_center_coords  : []const io.gui.Coords,
	buttons_default_image  : []const io.gui.Image,
	buttons_hovered_image  : []const io.gui.Image,
	button_callback_click  : *const fn (button_index: usize, window: io.gui.Window) anyerror!?ScreenOutcome,

	pub fn refresh(screen: *const ScreenOfButtons, window: io.gui.Window, button_index_hovered: ?usize) void {
		window.fill_image(screen.background_image);

		// iterate on reverse order, to draw from background to foreground
		var i = screen.buttons_center_coords.len; while (i > 0) { i -= 1; window.blit_image(if (i != button_index_hovered) screen.buttons_default_image[i] else screen.buttons_hovered_image[i], screen.buttons_center_coords[i]); }

		window.refresh();
	}

	pub fn show(screen: *const ScreenOfButtons, window: io.gui.Window) anyerror!ScreenOutcome {
		var button_index_hovered: ?usize = null;
		screen.refresh(window, button_index_hovered);

		while (true) {
			const event = io.gui.get_event_blocking();
			switch (event) {
				.quit => return .quit,
				.timer => unreachable,

				.mousemove,
				.mousepress,
				.mouserelease => |mouse_coords| {
					const button_index_hovering = are_coords_on_images(mouse_coords, screen.buttons_default_image, screen.buttons_center_coords);

					if (button_index_hovering != button_index_hovered) {
						screen.refresh(window, button_index_hovering);
						button_index_hovered = button_index_hovering;
					}

					if (event == .mousepress) {
						if (button_index_hovering) |button_index| {
							if (try screen.button_callback_click(button_index, window)) |outcome| {
								return outcome;
							} else {
								screen.refresh(window, button_index_hovering);
							}
						}
					}
				},
			}
		}

	}
};

pub fn are_coords_on_image(coords: io.gui.Coords, image: io.gui.Image, image_coords: io.gui.Coords) bool {
	// if the coordinates are outside of the image's bounding box, get_pixel returns transparent
	const color = image.get_pixel(.{ .x = coords.x - image_coords.x + @divFloor(image.get_width(), 2), .y = coords.y - image_coords.y + @divFloor(image.get_height(), 2) });
	return color.a != 255; // transparent pixels aren't considered part of the image
}

pub fn are_coords_on_images(coords: io.gui.Coords, images: []const io.gui.Image, images_coords: []const io.gui.Coords) ?usize {
	for (images, images_coords, 0..) |image, image_coords, image_index| {
		if (are_coords_on_image(coords, image, image_coords)) return image_index;
	}

	return null;
}

pub fn blit_sprite(window: io.gui.Window, image: io.gui.Image, coords: io.gui.Coords, index: usize, count: usize) void {
	const sprite_width = @divExact(image.get_width(), count);
	window.blit_image_part(image, coords, .{ .x = @intCast(sprite_width * index), .y = 0 }, .{ .x = @intCast(sprite_width * (index + 1)), .y = image.get_height() });
}

pub fn blit_string(window: io.gui.Window, str: []const u8, coords: io.gui.Coords, alignment: Alignment, font_img: io.gui.Image, font_len: usize, font_base: u8) void {
	const char_width: i32 = @intCast(@divExact(font_img.get_width(), font_len));
	const str_width: i32 = @as(i32, @intCast(str.len)) * char_width;

	const left_x: i32 = switch (alignment) {
		.left => coords.x + @divFloor(char_width, 2),
		.center => coords.x - @divFloor(str_width - char_width, 2),
		.right => coords.x - str_width - @divFloor(char_width, 2),
	};

	for (str, 0..) |char, i| {
		const char_coords = io.gui.Coords { .x = left_x + char_width * @as(i32, @intCast(i)), .y = coords.y };
		blit_sprite(window, font_img, char_coords, char - font_base, font_len);
	}
}

pub fn blit_integer(allocator: std.mem.Allocator, window: io.gui.Window, coords: io.gui.Coords, value: u32, alignment: Alignment, digits_img: io.gui.Image, digits_count: u8) !void {
	const str = try std.fmt.allocPrint(allocator, "{d}", .{ value });
	defer allocator.free(str);

	blit_string(window, str, coords, alignment, digits_img, digits_count, '0');
}
