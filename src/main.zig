const std = @import("std");
const rl = @import("raylib");
const cl = @import("zclay");

const renderer = @import("raylib_render_clay.zig");

const allocator = std.heap.page_allocator;

const white: cl.Color = .{ 250, 250, 255, 255 };
const light_grey: cl.Color = .{ 224, 215, 210, 255 };
const red: cl.Color = .{ 168, 66, 28, 255 };
const orange: cl.Color = .{ 225, 138, 50, 255 };
const transparent: cl.Color = .{ 0, 0, 0, 0 };

const height: i32 = 768;
const width: i32 = 1366;

pub fn main() !void {
    // Check display manager type x11/wayland
    const env_map = try std.process.getEnvMap(allocator);
    var iter = env_map.iterator();

    while (iter.next()) |entry| {
        const key = entry.key_ptr.*;
        const value = entry.value_ptr.*;

        if (std.mem.eql(u8, key, "XDG_SESSION_TYPE")) {
            if (std.mem.eql(u8, value, "wayland")) {
                std.debug.print("Wayland session detected\n", .{});
            }
        }
    }

    // Init Clay
    const min_memory_size: u32 = cl.minMemorySize();
    const memory = try allocator.alloc(u8, min_memory_size);
    defer allocator.free(memory);

    const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
    _ = cl.initialize(arena, .{ .h = height, .w = width }, .{});
    cl.setMeasureTextFunction(void, {}, renderer.measureText);

    initRayLib() catch |err| {
        std.debug.print("Failed to initialize raylib: {}\n", .{err});
        return err;
    };

    try loadFont(@embedFile("./resources/Roboto-Regular.ttf"), 0, 24);

    while (!rl.windowShouldClose()) {
        rl.clearBackground(rl.Color.blank);
        const mouse_pos = rl.getMousePosition();
        cl.setPointerState(.{
            .x = mouse_pos.x,
            .y = mouse_pos.y,
        }, rl.isMouseButtonDown(.left));

        cl.setLayoutDimensions(.{
            .h = @floatFromInt(rl.getScreenHeight()),
            .w = @floatFromInt(rl.getScreenWidth()),
        });

        const key = rl.getKeyPressed();

        switch (key) {
            .f1 => {
                std.debug.print("F1 pressed\n", .{});
            },
            .f2 => {
                std.debug.print("F2 pressed\n", .{});
            },
            .f3 => {
                std.debug.print("F3 pressed\n", .{});
            },
            .f4 => {
                std.debug.print("F4 pressed\n", .{});
            },
            else => {},
        }

        var render_commands = createLayout();
        // Update and draw the layout
        rl.beginDrawing();
        try renderer.clayRaylibRender(&render_commands, allocator);

        rl.endDrawing();
    }
}

fn initRayLib() !void {
    rl.setConfigFlags(.{
        .window_resizable = false,
        .window_transparent = true,
    });
    rl.initWindow(width, height, "Raylib zig Example");

    rl.setTargetFPS(120);
}

fn createLayout() cl.ClayArray(cl.RenderCommand) {
    cl.beginLayout();
    cl.UI()(.{
        .id = .ID("OuterContainer"),
        .layout = .{ .direction = .top_to_bottom, .sizing = .grow, .padding = .all(16), .child_gap = 16 },
        .background_color = transparent,
    })({
        cl.UI()(.{
            .id = .ID("Header"),
            .layout = .{ .direction = .left_to_right, .sizing = .{ .w = .grow, .h = .fixed(60) }, .child_alignment = .{ .x = .center, .y = .center } },
            .background_color = orange,
        })({
            cl.text("SillyCode Macros", .{ .font_size = 32, .color = white });
        });
        cl.UI()(.{
            .id = .ID("Container"),
            .layout = .{ .sizing = .grow, .direction = .left_to_right, .child_gap = 16 },
            .background_color = transparent,
        })({
            cl.UI()(.{
                .id = .ID("MainContent"),
                .layout = .{ .sizing = .grow },
                .background_color = transparent,
                .border = .{ .color = light_grey, .width = .all(2) },
            })({});

            cl.UI()(.{
                .id = .ID("SideBar"),
                .layout = .{
                    .direction = .top_to_bottom,
                    .sizing = .{ .h = .grow, .w = .fixed(300) },
                    .padding = .all(16),
                    .child_alignment = .{ .x = .center, .y = .top },
                    .child_gap = 16,
                },
                .background_color = red,
            })({
                cl.text("Name of the macro (Placeholder)", .{ .font_size = 24, .color = white });
                cl.UI()(.{
                    .id = .ID("Separator Blank Space"),
                    .layout = .{ .sizing = .{ .w = .grow, .h = .fixed(60) } },
                    .background_color = transparent,
                })({});
                cl.text("F1: Set Roblox Position", .{ .color = white });
                cl.text("F2: Start Macro", .{ .color = white });
                cl.text("F3: Stop Macro", .{ .color = white });
                cl.text("F4: Pause Macro", .{ .color = white });
            });
        });
    });

    return cl.endLayout();
}

fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) !void {
    renderer.raylib_fonts[font_id] = try rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}
