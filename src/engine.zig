
const std = @import("std");
const io = @import("io.zig");
const assets = @import("assets.zig");

// "universal constants":

pub const water_worth: u32 = 25;
pub const rain_speed_y: f32 = 0.5;
pub const monster_half_width: f32 = 0.25;
pub const monster_delay: f32 = 1.0;
pub const monster_damage: u32 = 100;

// All durations are measured in seconds.
// All distances are measured in "cell size".
// All speeds are measured in distance / duration.

//                                  \  /
//                                   \/
//      0       1       2       3    /\    \  /
//      |       |       |       |   /  \    \/
//      |  0.5  |  1.5  |  2.5  |           /
//      |   |   |   |   |   |   |          /
//
//       -------+-------+-------    ------- 0
//      |\      |       |       |
//      | (0,0) |       |       |   -- 0.5
//      |       |       |       |
//      +-------+-------+-------+   ------- 1
//      |       |\      |       |
//      |       | (1,1) |       |   -- 1.5
//      |       |       |       |
//      +-------+-------+-------+   ------- 2
//      |       |       |       |
//      |       |       |       |   -- 2.5
//      |       |       |       |
//       -------+-------+-------    ------- 3

pub const Coords = struct {
	x: f32,
	y: f32,

	pub fn are_inside_rect(coords: Coords, min: Coords, max: Coords) bool {
		return (min.x <= coords.x and coords.x <= max.x) and (min.y <= coords.y and coords.y <= max.y);
	}
};

pub const Cell = struct {
	state: enum {
		grass,
	//	water, //TODO: add (with aquatic plants)
	//	hole, //TODO: add (made by huge explosions)
	//	tomb, //TODO: add (spawns monsters occasionally)
	},
};

pub const FlowerKind = enum {
	rose,
	philodendron,
//	cactus_instant, //TODO: add (explodes instantly killing nearby monsters)
	stone,
//	cactus_small, //TODO: add (explodes when a monster walks on it)
	rose_white,
//	carnivorous, //TODO: add (eats monsters in front of it)
//	rose_double, //TODO: add (shots twice as fast as the rose)
//	...,

	pub fn get_cost(kind: FlowerKind) u32 {
		return switch (kind) {
			.rose           => 100,
			.philodendron   =>  50,
		//	.cactus_instant => 150,
			.stone          =>  50,
		//	.cactus_small   =>  25,
			.rose_white     => 175,
		//	.carnivorous    => 150,
		//	.rose_double    => 200,
		};
	}

	pub fn get_health_initial(kind: FlowerKind) ?u32 {
		return switch (kind) {
			.rose           => 300,
			.philodendron   => 300,
		//	.cactus_instant => null,
			.stone          => 4000,
		//	.cactus_small   => 300,
			.rose_white     => 300,
		//	.carnivorous    => 300,
		//	.rose_double    => 300,
		};
	}

	pub fn get_delay(kind: FlowerKind) ?f32 {
		return switch (kind) {
			.rose           =>  1.0,
			.philodendron   => 24.0,
		//	.cactus_instant => null,
			.stone          => null,
		//	.cactus_small   => null,
			.rose_white     =>  1.0,
		//	.carnivorous    => 42.0,
		//	.rose_double    =>  0.5,
		};
	}

	pub fn get_delay_initial(kind: FlowerKind) ?f32 {
		return switch (kind) {
			.rose           =>  0.0,
			.philodendron   => 12.0,
		//	.cactus_instant => null,
			.stone          => null,
		//	.cactus_small   => 16.0,
			.rose_white     =>  0.0,
		//	.carnivorous    =>  0.0,
		//	.rose_double    =>  0.0,
		};
	}

	pub fn get_refill_delay(_: FlowerKind) f32 {
	//TODO: add get_seed_delay
		return 1.0;
	}
};

pub const FlowerState = enum {
	dying,
	normal,
};

pub const Flower = struct {
	health: u32,
	kind  : FlowerKind,
//	state : FlowerState,

	age  : f32,
	delay: f32,

	pub fn init(kind: FlowerKind) Flower {
		return .{
			.health = kind.get_health_initial() orelse 0,
			.kind   = kind,
		//	.state  = .normal,
			.age    = 0.0,
			.delay  = kind.get_delay_initial() orelse 0.0,
		};
	}
};

pub const BulletKind = enum {
	thorn,
	thorn_frozen,

	pub fn get_speed(kind: BulletKind) Coords {
		return switch (kind) {
			.thorn,
			.thorn_frozen => .{ .x = 7.0, .y = 0 },
		};
	}

	pub fn get_damage(kind: BulletKind) u32 {
		return switch (kind) {
			.thorn        => 20,
			.thorn_frozen => 20,
		};
	}
};

pub const Bullet = struct {
	coords: Coords,
	speed: Coords,

	kind: BulletKind,

	pub fn init(kind: BulletKind, coords: Coords) Bullet {
		return .{
			.coords = coords,
			.speed = kind.get_speed(),
			.kind = kind,
		};
	}
};

pub const MonsterKind = enum {
	skeleton,
	ghost,
//	monster_jumper, //TODO: add (jumps over the first flower)
	skeleton_helmet,
	undead,
	undead_angry,
//	skeleton_shield, //TODO: add (his shield blocks thorns)
//	bat, //TODO: add (flies over flowers and their shots)
//	...,

	pub fn get_speed(monster_kind: MonsterKind) f32 {
		return switch (monster_kind) {
			.skeleton          => 2.0 / 10.0,
			.ghost             => 2.0 / 10.0,
			.skeleton_helmet   => 2.0 / 10.0,
			.undead            => 2.0 / 10.0,
			.undead_angry      => 1.0 /  2.0,
		};
	}

	pub fn get_health_initial(monster_kind: MonsterKind) u32 {
		return switch (monster_kind) {
			.skeleton          => 181,
			.ghost             => 551,
		//	.monster_jumper    => 335,
			.skeleton_helmet   => 1281,
			.undead            => 331,
			.undead_angry      => 181,
		//	.skeleton_shield   => 1281,
		};
	}

	pub fn get_weaker(monster_kind: MonsterKind) ?MonsterKind {
		return switch (monster_kind) {
			.skeleton        => null,
			.ghost           => null,
			.skeleton_helmet => .skeleton,
			.undead          => .undead_angry,
			.undead_angry    => null,
		//	.skeleton_shield => .skeleton,
		};
	}
};

pub const MonsterState = enum {
	dying,
	normal,
};

pub const Monster = struct {
	x  : f32,
	row: u8,

	health: u32,
	kind  : MonsterKind,
//	state : MonsterState,
//	frozen: bool, //TODO

	age  : f32,
	delay: f32,

	pub fn init(kind: MonsterKind, x: f32, row: u8) Monster {
		return .{
			.x = x,
			.row = row,

			.health = kind.get_health_initial(),
			.kind   = kind,
		//	.state  = .normal,
		//	.frozen = false,
			.age    = 0.0,
			.delay  = 0.0,
		};
	}

	pub fn take_hit(monster: *Monster, kind: BulletKind) bool {
		switch (kind) {
			.thorn        => {},
			.thorn_frozen => {}, //TODO: monster.frozen_delay = (some duration);
		}

		monster.health -|= kind.get_damage();

		if (monster.kind.get_weaker()) |weaker_monster_kind| {
			if (monster.health <= weaker_monster_kind.get_health_initial()) {
				monster.kind = weaker_monster_kind;
			}
		}

		return true;
	}
};

pub const CollectibleKind = enum {
	water,
};

pub const Collectible = struct {
	coords: Coords,
	speed: Coords,

	kind: CollectibleKind,

	pub fn init(kind: CollectibleKind, coords: Coords) Collectible {
		return .{
			.coords = coords,
			.speed = .{ .x = 0.0, .y = 0.0 },
			.kind = kind,
		};
	}
};

pub const Field = struct {
	row_beg     : u8,
	row_end     : u8,
	cells       : [rows_count][cols_count]Cell,
//	jars        : [rows_count][cols_count]Jar, //TODO: add
	flowers     : [rows_count][cols_count]?Flower,
	bullets     : std.ArrayList(Bullet),
	monsters    : std.ArrayList(Monster),
	collectibles: std.ArrayList(Collectible),
	visible_min : Coords,
	visible_max : Coords,

	pub const rows_count = 5;
	pub const cols_count = 9;
};

pub const Seed = struct {
	delay: f32 = 0,
	kind: FlowerKind,
};

pub const SeedsKind = union(enum) {
	fixed: []const FlowerKind,
	player_choice: void, //TODO: add
//	conveyor: []const SeedsWave, // TODO: add
};

pub const Wave = struct {
	timestamp_beg: f32,
	timestamp_end: f32,
	monsters     : []const MonsterKind,
	monsters_freq: []const f32,
};

pub const Progress = struct {
	state: enum {
		fighting,
		victory,
		defeat,
	} = .fighting,
	water: ?u32,
	rain_delay: f32,
	rain_freq : f32,
	kind : SeedsKind,
	seeds: [seeds_max_count]?Seed,
	waves: []const Wave,
	duration: f32 = 0.0,
	rand: std.Random,

	pub fn rand_float(progress: *Progress, min: f32, max: f32) f32 {
		std.debug.assert(min <= max);
		return (progress.rand.float(f32) - min) * (max - min) + min;
	}
	pub fn rand_byte(progress: *Progress, min: u8, max: u8) u8 {
		std.debug.assert(min <= max);
		return progress.rand.intRangeAtMost(u8, min, max);
	}

	pub const seeds_max_count = 8;
};

const PutSeedsOutcome = enum { put, not_refilled_yet, not_enough_water, out_of_field, not_available_cell };
pub fn put_seeds(seed: *Seed, coords: Coords, field: *Field, progress: *Progress) PutSeedsOutcome {
	if (seed.delay > 0) return .not_refilled_yet;

	if (coords.x < 0 or coords.y < 0) return .out_of_field;
	const col: u8 = @intFromFloat(coords.x); // truncating
	const row: u8 = @intFromFloat(coords.y); // truncating
	if (!(field.row_beg <= row and row < field.row_end)) return .out_of_field;
	if (!(0 <= col and col < Field.cols_count)) return .out_of_field;

	const cell = &field.cells[row][col];
	if (cell.state != .grass) return .not_available_cell;
	if (field.flowers[row][col]) |_| return .not_available_cell;

	if (progress.water) |water| {
		const cost = seed.kind.get_cost();
		if (cost > water) return .not_enough_water;

		progress.water = water - cost;
	}

	field.flowers[row][col] = Flower.init(seed.kind);

	seed.delay = seed.kind.get_refill_delay();

	return .put;
}

pub fn forward(duration: f32, field: *Field, progress: *Progress) !void {
	if (duration > 0.2) {
		const steps_count: usize = @intFromFloat(duration / 0.1);
		const step_size = duration / @as(f32, @floatFromInt(steps_count));
		for (0..steps_count) |_| try forward(step_size, field, progress);
		return;
	}

	for (&field.flowers, 0..) |*flowers, y| {
		for (flowers, 0..) |*flower_or_null, x| if (flower_or_null.*) |*flower| {
			flower.age += duration;
			if (flower.delay >= 0.0) {
				flower.delay -= duration;
				if (flower.delay <= 0.0) {
					const coords: Coords = .{
						.x = @as(f32, @floatFromInt(x)) + 0.5,
						.y = @as(f32, @floatFromInt(y)) + 0.5,
					};
					switch (flower.kind) {
						.rose,
					//	.rose_double,
						.rose_white => {
							//TODO: if (no monster in sight) continue;

							io.sound.play(assets.snd_shot_emitted) catch {};

							//TODO: insert it in the appropriate position (L-to-R order)

							const bullet_kind: BulletKind = if (flower.kind == .rose_white) .thorn_frozen else .thorn;
							try field.bullets.append(Bullet.init(bullet_kind, coords));
						},
						.philodendron => {
							try field.collectibles.append(Collectible.init(.water, coords));
						},
						.stone => continue,
					}
					flower.delay += flower.kind.get_delay().?;
				}
			}
		};
	}

	//TODO: ensure monsters are sorted from leftmost to rightmost

	// iterate on bullets from rightmost to leftmost
	var bullet_index = field.bullets.items.len;
	while (bullet_index > 0) { bullet_index -= 1;
		const bullet = &field.bullets.items[bullet_index];

		bullet.coords.x += bullet.speed.x * duration;
		bullet.coords.y += bullet.speed.y * duration;

		var bullet_hit = false;
		for (field.monsters.items, 0..) |*monster, monster_index| {
			if (
				(bullet.coords.x >= monster.x - monster_half_width) and
				(bullet.coords.x <= monster.x + monster_half_width) and
				(@as(i32, @intFromFloat(bullet.coords.y)) == monster.row) and
				(monster.health > 0)
			) {
				if (monster.take_hit(bullet.kind)) {
					io.sound.play(assets.snd_shot_hit) catch {};
					bullet_hit = true;

					if (monster.health <= 0) {
						io.sound.play(assets.snd_monster_dead) catch {};
						_ = field.monsters.orderedRemove(monster_index);
					}

					break;
				}
			}
		}

		if (bullet_hit or !bullet.coords.are_inside_rect(field.visible_min, field.visible_max)) {
			_ = field.bullets.orderedRemove(bullet_index);
		}
	}

	// iterate on monsters from leftmost to rightmost
	for (field.monsters.items) |*monster| {
		var flower_hit = false;
		const col = @as(i32, @intFromFloat(monster.x));
		if (0 <= col and col < Field.cols_count) {
			if (field.flowers[monster.row][@intCast(col)]) |*flower| {
				flower_hit = true;
				if (monster.delay >= 0.0) {
					monster.delay -= duration;
					if (monster.delay <= 0.0) {
						io.sound.play(assets.snd_flower_attacked) catch {};

						flower.health -|= monster_damage;
						if (flower.health <= 0) {
							io.sound.play(assets.snd_monster_ate) catch {};

							field.flowers[monster.row][@intCast(col)] = null;
						}

						monster.delay += monster_delay;
					}
				}
			}
		}

		if (!flower_hit) {
			monster.x -= monster.kind.get_speed() * duration;
			if (monster.x < 0.0) {
				io.sound.play(assets.snd_game_defeat) catch {};
				progress.state = .defeat;
			}
		}

		monster.age += duration;
	}

	const collectibles_count = field.collectibles.items.len;
	for (0..collectibles_count) |iteration| {
		const collectible_index = collectibles_count-1-iteration;
		const collectible = &field.collectibles.items[collectible_index];

		//collectible.coords.x += collectible.speed.x * duration;
		collectible.coords.y += collectible.speed.y * duration;

		if (!collectible.coords.are_inside_rect(field.visible_min, field.visible_max)) {
			_ = field.collectibles.orderedRemove(collectible_index);
		}
	}

	if (progress.rain_freq > 0.0) {
		progress.rain_delay -= duration;
		if (progress.rain_delay <= 0.0) {
			const water = Collectible {
				.coords = .{ .x = progress.rand_float(field.visible_min.x, field.visible_max.x), .y = 0 },
				.speed = .{ .x = 0, .y = rain_speed_y },
				.kind = .water,
			};
			try field.collectibles.append(water);
			progress.rain_delay += progress.rain_freq;
		}
	}

	const duration_prev = progress.duration;
	progress.duration += duration;

	var waves_end: f32 = 0.0;
	for (progress.waves) |wave| {
		if (wave.timestamp_end > waves_end) waves_end = wave.timestamp_end;
		if (wave.timestamp_beg < progress.duration and duration_prev < wave.timestamp_end) {
			const duration_beg = @max(wave.timestamp_beg, duration_prev);
			const duration_end = @min(progress.duration, wave.timestamp_end);
			for (wave.monsters, wave.monsters_freq) |monster_kind, monster_freq| {
				const count_beg = (duration_beg - wave.timestamp_beg) / monster_freq;
				const count_end = (duration_end - wave.timestamp_beg) / monster_freq;
				for (@intFromFloat(count_beg)..@intFromFloat(count_end)) |_| {
					io.sound.play(assets.snd_monster_spawned) catch {};
					const row = progress.rand_byte(field.row_beg, field.row_end - 1);
					try field.monsters.append(Monster.init(monster_kind, field.visible_max.x, row));
				}
			}
		}
	}

	if (field.monsters.items.len == 0 and progress.duration > waves_end) {
		switch (progress.state) {
			.fighting => {
				io.sound.play(assets.snd_game_victory) catch {};
				progress.state = .victory;
			},
			.victory => {},
			.defeat => {},
		}
	}

	for (0..progress.seeds.len) |i| {
		if (progress.seeds[i]) |_| {
			if (progress.seeds[i].?.delay > 0.0) {
				progress.seeds[i].?.delay -= duration;
			}
		}
	}
}
