
const io = @import("io.zig");


pub var img_home_bg                   : io.gui.Image = undefined;
pub var img_home_btn_newgame          : io.gui.Image = undefined;
pub var img_home_btn_newgame_hovered  : io.gui.Image = undefined;
pub var img_home_btn_minigames        : io.gui.Image = undefined;
pub var img_home_btn_minigames_hovered: io.gui.Image = undefined;
pub var img_home_btn_puzzles          : io.gui.Image = undefined;
pub var img_home_btn_puzzles_hovered  : io.gui.Image = undefined;
pub var img_home_btn_survival         : io.gui.Image = undefined;
pub var img_home_btn_survival_hovered : io.gui.Image = undefined;
pub var img_home_btn_credits          : io.gui.Image = undefined;
pub var img_home_btn_credits_hovered  : io.gui.Image = undefined;
pub var img_home_btn_quit             : io.gui.Image = undefined;
pub var img_home_btn_quit_hovered     : io.gui.Image = undefined;

pub var img_game_bg                     : io.gui.Image = undefined;
pub var img_game_seeds                  : io.gui.Image = undefined;
pub var img_game_seeds_hovered          : io.gui.Image = undefined;
pub var img_game_seeds_selected         : io.gui.Image = undefined;
pub var img_game_water_icon             : io.gui.Image = undefined;
pub var img_game_water                  : io.gui.Image = undefined;
pub var img_game_watering_can           : io.gui.Image = undefined;
pub var img_game_flower_rose            : io.gui.Image = undefined;
pub var img_game_flower_philodendron    : io.gui.Image = undefined;
pub var img_game_flower_stone           : io.gui.Image = undefined;
pub var img_game_flower_rose_white      : io.gui.Image = undefined;
pub var img_game_icon_rose              : io.gui.Image = undefined;
pub var img_game_icon_philodendron      : io.gui.Image = undefined;
pub var img_game_icon_stone             : io.gui.Image = undefined;
pub var img_game_icon_rose_white        : io.gui.Image = undefined;
pub var img_game_shot_thorn             : io.gui.Image = undefined;
pub var img_game_shot_thorn_frozen      : io.gui.Image = undefined;
pub var img_game_monster_skeleton       : io.gui.Image = undefined;
pub var img_game_monster_skeleton_helmet: io.gui.Image = undefined;
pub var img_game_monster_undead         : io.gui.Image = undefined;
pub var img_game_monster_undead_fast    : io.gui.Image = undefined;
pub var img_game_monster_bat_brown      : io.gui.Image = undefined;
pub var img_game_monster_bat_grey       : io.gui.Image = undefined;
pub var img_game_monster_ghost          : io.gui.Image = undefined;
pub var img_game_row_removed            : io.gui.Image = undefined;
pub var img_game_sign_stop              : io.gui.Image = undefined;
pub var img_game_sign_stop_hovered      : io.gui.Image = undefined;
pub var img_game_sign_retry             : io.gui.Image = undefined;
pub var img_game_sign_retry_hovered     : io.gui.Image = undefined;
pub var img_game_sign_next              : io.gui.Image = undefined;
pub var img_game_sign_next_hovered      : io.gui.Image = undefined;

pub const nb_game_monster_skeleton        = 3;
pub const nb_game_monster_skeleton_helmet = 3;
pub const nb_game_monster_undead          = 6;
pub const nb_game_monster_undead_fast     = 6;
pub const nb_game_monster_bat_brown       = 6;
pub const nb_game_monster_bat_grey        = 6;
pub const nb_game_monster_ghost           = 10;

pub var img_menu_bg            : io.gui.Image = undefined;
pub var img_menu_option        : io.gui.Image = undefined;
pub var img_menu_option_greyed : io.gui.Image = undefined;
pub var img_menu_option_hovered: io.gui.Image = undefined;
pub var img_menu_credits       : io.gui.Image = undefined;

pub var img_digits     : io.gui.Image = undefined;
pub var img_digits_tiny: io.gui.Image = undefined;

pub const nb_digits = 10;


const images_paths = [_] struct { *io.gui.Image, [:0]const u8 } {
	.{ &img_home_bg                   , "images/home/background.png"                        },
	.{ &img_home_btn_newgame          , "images/home/buttons/new game.png"                  },
	.{ &img_home_btn_newgame_hovered  , "images/home/buttons/new game hovered.png"          },
	.{ &img_home_btn_minigames        , "images/home/buttons/mini games greyed.png"         },
	.{ &img_home_btn_minigames_hovered, "images/home/buttons/mini games greyed hovered.png" },
	.{ &img_home_btn_puzzles          , "images/home/buttons/puzzles greyed.png"            },
	.{ &img_home_btn_puzzles_hovered  , "images/home/buttons/puzzles greyed hovered.png"    },
	.{ &img_home_btn_survival         , "images/home/buttons/survival greyed.png"           },
	.{ &img_home_btn_survival_hovered , "images/home/buttons/survival greyed hovered.png"   },
	.{ &img_home_btn_credits          , "images/home/buttons/credits.png"                   },
	.{ &img_home_btn_credits_hovered  , "images/home/buttons/credits hovered.png"           },
	.{ &img_home_btn_quit             , "images/home/buttons/quit.png"                      },
	.{ &img_home_btn_quit_hovered     , "images/home/buttons/quit hovered.png"              },

	.{ &img_game_bg                     , "images/field/background.png"                            },
	.{ &img_game_seeds                  , "images/field/seeds.png"                                 },
	.{ &img_game_seeds_hovered          , "images/field/seeds hovered.png"                         },
	.{ &img_game_seeds_selected         , "images/field/seeds selected.png"                        },
	.{ &img_game_water_icon             , "images/field/water tiny.png"                            },
	.{ &img_game_water                  , "images/field/water.png"                                 },
	.{ &img_game_watering_can           , "images/field/watering can.png"                          },
	.{ &img_game_flower_rose            , "images/field/flowers/64x/Red_Rose.png"                  },
	.{ &img_game_flower_philodendron    , "images/field/flowers/64x/Light_Green_Chrysanthemum.png" },
	.{ &img_game_flower_stone           , "images/field/flowers/64x/stone.png"                     },
	.{ &img_game_flower_rose_white      , "images/field/flowers/64x/White_Rose.png"                },
	.{ &img_game_icon_rose              , "images/field/flowers/32x/Red_Rose.png"                  },
	.{ &img_game_icon_philodendron      , "images/field/flowers/32x/Light_Green_Chrysanthemum.png" },
	.{ &img_game_icon_stone             , "images/field/flowers/32x/stone.png"                     },
	.{ &img_game_icon_rose_white        , "images/field/flowers/32x/White_Rose.png"                },
	.{ &img_game_shot_thorn             , "images/field/shots/64x/thorn.png"                       },
	.{ &img_game_shot_thorn_frozen      , "images/field/shots/64x/thorn frozen.png"                },
	.{ &img_game_monster_skeleton       , "images/field/monsters/64x/skeleton.png"                 },
	.{ &img_game_monster_skeleton_helmet, "images/field/monsters/64x/skeleton shield.png"          },
	.{ &img_game_monster_undead         , "images/field/monsters/64x/undead.png"                   },
	.{ &img_game_monster_undead_fast    , "images/field/monsters/64x/undead fast.png"              },
	.{ &img_game_monster_bat_brown      , "images/field/monsters/64x/bat brown.png"                },
	.{ &img_game_monster_bat_grey       , "images/field/monsters/64x/bat grey.png"                 },
	.{ &img_game_monster_ghost          , "images/field/monsters/64x/ghost.png"                    },
	.{ &img_game_row_removed            , "images/field/row removed.png"                           },
	.{ &img_game_sign_stop              , "images/field/sign stop.png"                             },
	.{ &img_game_sign_stop_hovered      , "images/field/sign stop hovered.png"                     },
	.{ &img_game_sign_retry             , "images/field/sign retry.png"                            },
	.{ &img_game_sign_retry_hovered     , "images/field/sign retry hovered.png"                    },
	.{ &img_game_sign_next              , "images/field/sign next.png"                             },
	.{ &img_game_sign_next_hovered      , "images/field/sign next hovered.png"                     },

	.{ &img_menu_bg            , "images/menu/background.png"     },
	.{ &img_menu_option        , "images/menu/option.png"         },
	.{ &img_menu_option_greyed , "images/menu/option greyed.png"  },
	.{ &img_menu_option_hovered, "images/menu/option hovered.png" },
	.{ &img_menu_credits       , "images/menu/credits.png"        },

	.{ &img_digits     , "images/digits.png"      },
	.{ &img_digits_tiny, "images/digits tiny.png" },
};


pub fn init() !void {
	for (images_paths, 0..) |image_path, i| {
		errdefer deinit_until(i);

		const img_ptr, const path = image_path;
		img_ptr.* = try io.gui.Image.alloc_from_file(path);
	}
}

fn deinit_until(end: usize) void {
	for (images_paths, 0..) |image_path, i| {
		if (i == end) break;

		const img_ptr, _ = image_path;
		img_ptr.*.free();
	}
}

pub fn deinit() void {
	@call(.always_inline, &deinit_until, .{ images_paths.len });
}
