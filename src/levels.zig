
const engine = @import("engine.zig");
const Field       = engine.Field;
const Wave        = engine.Wave;
const SeedsKind   = engine.SeedsKind;
const MonsterKind = engine.MonsterKind;

const sec = 1.0;
const min = 60*sec;

pub const Level = struct {
	row_beg   : u8           = 0,
	row_end   : u8           = Field.rows_count,
	seeds_kind: SeedsKind    = .player_choice,
	water     : ?u32         = 50,
	water_freq: f32          = 6*sec,
	waves     : []const Wave,
};

pub const levels = [_]Level {
	.{ // 1
		.row_beg = 2,
		.row_end = 3,
		.seeds_kind = .{ .fixed = &.{ .rose } },
		.water = 150,
		.waves = &.{
			.{ .timestamp_beg =  5.0*sec, .timestamp_end = 40.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 10.0*sec } },
			.{ .timestamp_beg = 41.5*sec, .timestamp_end = 42.8*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{  0.5*sec } },
		},
	},
	.{ // 2
		.row_beg = 1,
		.row_end = 4,
		.seeds_kind = .{ .fixed = &.{ .rose, .philodendron } },
		.waves = &.{
			.{ .timestamp_beg =        0.0*sec, .timestamp_end = 2*min+50.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 20.0*sec } },
			.{ .timestamp_beg =       39.0*sec, .timestamp_end = 2*min+50.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 40.0*sec } },
			.{ .timestamp_beg = 1*min+10.0*sec, .timestamp_end = 2*min+50.0*sec, .monsters = &.{ .ghost    }, .monsters_freq = &.{ 30.0*sec } },
			.{ .timestamp_beg = 1*min+39.0*sec, .timestamp_end = 2*min+50.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 30.0*sec } },
			.{ .timestamp_beg = 2*min+39.0*sec, .timestamp_end = 2*min+40.2*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{  0.5*sec } },
		},
	},
	.{ // 3
		.seeds_kind = .{ .fixed = &.{ .rose, .philodendron, .stone } }, //TODO: add .cactus_instant
		.waves = &.{
			.{ .timestamp_beg =       -4.0*sec, .timestamp_end = 2*min         , .monsters = &.{ .skeleton }, .monsters_freq = &.{ 24.0*sec } },
			.{ .timestamp_beg = 1*min+20.1*sec, .timestamp_end = 2*min+32.5*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 12.0*sec } },
			.{ .timestamp_beg = 1*min+32.0*sec, .timestamp_end = 2*min         , .monsters = &.{ .skeleton }, .monsters_freq = &.{ 12.0*sec } },
			.{ .timestamp_beg = 1*min+56.1*sec, .timestamp_end = 2*min+32.5*sec, .monsters = &.{ .ghost    }, .monsters_freq = &.{ 12.0*sec } },

			.{ .timestamp_beg = 3*min         , .timestamp_end = 3*min+0.65*sec, .monsters = &.{ .skeleton, .ghost }, .monsters_freq = &.{ 0.1*sec, 0.3*sec } },
		},
	},
	.{ // 4
		.seeds_kind = .{ .fixed = &.{ .rose, .philodendron, .stone } }, //TODO: add .cactus_instant, .cactus_small
		.waves = &.{
			.{ .timestamp_beg =        0.0*sec, .timestamp_end = 1*min+40.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 24.0*sec } },
			.{ .timestamp_beg = 1*min+20.0*sec, .timestamp_end = 3*min         , .monsters = &.{ .skeleton }, .monsters_freq = &.{ 14.0*sec } },
			.{ .timestamp_beg = 1*min+32.0*sec, .timestamp_end = 3*min         , .monsters = &.{ .undead   }, .monsters_freq = &.{ 29.0*sec } },
			.{ .timestamp_beg = 1*min+20.0*sec, .timestamp_end = 3*min         , .monsters = &.{ .ghost    }, .monsters_freq = &.{ 28.0*sec } },

			.{ .timestamp_beg = 3*min         , .timestamp_end = 3*min+0.55*sec, .monsters = &.{ .skeleton, .ghost }, .monsters_freq = &.{ 0.1*sec, 0.5*sec } },
		},
	},
	.{ // 5
		.seeds_kind = .{ .fixed = &.{ .rose, .philodendron, .stone, .rose_white } }, //TODO: add .cactus_instant, .cactus_small
		.waves = &.{
			.{ .timestamp_beg =       16.0*sec - 16.0*sec, .timestamp_end = 5*min+25.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 16.0*sec } },
			.{ .timestamp_beg = 1*min+4.00*sec - 48.0*sec, .timestamp_end = 5*min+25.0*sec, .monsters = &.{ .ghost    }, .monsters_freq = &.{ 48.0*sec } },
			.{ .timestamp_beg = 1*min+20.0*sec - 48.0*sec, .timestamp_end = 5*min+25.0*sec, .monsters = &.{ .undead   }, .monsters_freq = &.{ 48.0*sec } },
			.{ .timestamp_beg = 1*min+36.0*sec - 48.0*sec, .timestamp_end = 5*min+25.0*sec, .monsters = &.{ .undead   }, .monsters_freq = &.{ 48.0*sec } },
			.{ .timestamp_beg = 1*min+52.0*sec - 32.0*sec, .timestamp_end = 5*min+25.0*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{ 32.0*sec } },
			.{ .timestamp_beg = 2*min+24.0*sec           , .timestamp_end = 2*min+24.6*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{  0.1*sec } },
			.{ .timestamp_beg = 3*min+12.0*sec - 32.0*sec, .timestamp_end = 1*min+36.6*sec, .monsters = &.{ .ghost    }, .monsters_freq = &.{ 32.0*sec } },
			.{ .timestamp_beg = 3*min+28.0*sec           , .timestamp_end = 3*min+28.4*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{  0.1*sec } },
			.{ .timestamp_beg = 4*min+0.00*sec - 32.0*sec, .timestamp_end = 5*min+25.0*sec, .monsters = &.{ .undead   }, .monsters_freq = &.{ 32.0*sec } },
			.{ .timestamp_beg = 4*min+16.0*sec           , .timestamp_end = 4*min+16.2*sec, .monsters = &.{ .skeleton }, .monsters_freq = &.{  0.1*sec } },
			.{ .timestamp_beg = 4*min+48.0*sec           , .timestamp_end = 4*min+48.3*sec, .monsters = &.{ .undead   }, .monsters_freq = &.{  0.1*sec } },

			.{ .timestamp_beg = 5*min+30.0*sec           , .timestamp_end = 5*min+30.75*sec, .monsters = &.{ .skeleton, .ghost, .undead }, .monsters_freq = &.{ 0.1*sec, 0.2*sec, 0.4*sec } },
		},
	},
	.{ // 6
		.seeds_kind = .{ .fixed = &.{ .rose, .stone } },
		.water = null,
		.water_freq = 0.0,
		.waves = &.{
			.{ .timestamp_beg =  -2*sec, .timestamp_end = 48.0*sec, .monsters = &.{ .skeleton            }, .monsters_freq = &.{ 3.2*sec          } },
			.{ .timestamp_beg = 4.1*sec, .timestamp_end = 48.0*sec, .monsters = &.{ .skeleton, .ghost    }, .monsters_freq = &.{ 1.6*sec, 1.6*sec } },
			.{ .timestamp_beg = 8.2*sec, .timestamp_end = 48.0*sec, .monsters = &.{ .undead              }, .monsters_freq = &.{ 0.8*sec          } },
		},
	}
};
