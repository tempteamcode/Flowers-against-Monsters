
const std = @import("std");

pub fn enumFromName(Enum: anytype, name: []const u8, err: anytype) !Enum {
	inline for (@typeInfo(Enum).Enum.fields) |field| {
		if (std.mem.eql(u8, field.name, name)) return @enumFromInt(field.value);
	}

	return err;
}

pub fn enumListNames(allocator: std.mem.Allocator, Enum: anytype, separator: []const u8) ![]const u8 {
	var list = std.ArrayList(u8).init(allocator);
	errdefer list.deinit();

	inline for (@typeInfo(Enum).Enum.fields) |field| {
		if (list.items.len > 0) try list.appendSlice(separator);
		try list.appendSlice(field.name);
	}

	return list.toOwnedSlice();
}

pub fn enumRestrict(value: anytype, values: anytype) @TypeOf(value) {
	for (values) |v| if (value == v) return value;

	return values[0];
}

pub fn compileLogFmt(comptime fmt: []const u8, values: anytype) void {
	const text = std.fmt.comptimePrint(fmt, values);
	@compileLog(text);
}

pub fn haveSameFields(lp: anytype, rp: anytype, lhs: anytype, rhs: anytype) bool {
	for (lhs) |l| {
		if (l.name.len > 0 and l.name[0] == '_') continue; // ignore "private" fields

		for (rhs) |r| {
			if (std.mem.eql(u8, l.name, r.name)) {
				if (@hasField(@TypeOf(l), "type")) {
					if (!haveSameInterface(l.type, r.type)) {
						compileLogFmt("in: {any}.{s} vs {any}.{s}", .{ lp, l.name, rp, r.name });
						return false;
					}
				} else {
					std.debug.assert(@hasDecl(lp, l.name) and @hasDecl(rp, r.name));
					if (!haveSameInterface(@TypeOf(@field(lp, l.name)), @TypeOf(@field(rp, r.name)))) {
						compileLogFmt("in: {any}.{s} vs {any}.{s}", .{ lp, l.name, rp, r.name });
						return false;
					}
				}
				break;
			}
		} else {
			compileLogFmt("extra field: '{s}'", .{ l.name });
			compileLogFmt("in: {any} vs {any}", .{ lp, rp });
			return false;
		}
	}

	for (rhs) |r| {
		for (lhs) |l| {
			if (std.mem.eql(u8, l.name, r.name)) break;
		} else {
			compileLogFmt("missing field: '{s}'", .{ r.name });
			compileLogFmt("in: {any} vs {any}", .{ lp, rp });
			return false;
		}
	}

	return true;
}

pub fn haveSameInterface(lhs: anytype, rhs: anytype) bool {
	const lti = @typeInfo(lhs);
	const rti = @typeInfo(rhs);

	const tags = @typeInfo(@TypeOf(lti)).Union;
	inline for (tags.fields) |tag| {
		if ((lti == @field(tags.tag_type.?, tag.name)) != (rti == @field(tags.tag_type.?, tag.name))) {
			compileLogFmt("different types: '{any}' vs '{any}'", .{ lhs, rhs });
			return false;
		}
	}

	switch (lti) {
		.Struct => {
			return
				haveSameFields(lhs, rhs, lti.Struct.fields, rti.Struct.fields) and
				haveSameFields(lhs, rhs, lti.Struct.decls, rti.Struct.decls);
		},
		.Union => {
			return
				haveSameFields(lhs, rhs, lti.Union.fields, rti.Union.fields) and
				haveSameFields(lhs, rhs, lti.Union.decls, rti.Union.decls);
		},
		else => {
			if (lhs != rhs) compileLogFmt("different types: '{any}' vs '{any}'", .{ lhs, rhs });
			return lhs == rhs;
		},
	}
}
