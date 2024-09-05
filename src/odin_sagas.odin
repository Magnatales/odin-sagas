package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

import s "core:strings"
import tiled "utils"

main :: proc() 
{
//load TileMap data example:
    map_path := tiled.TILED_RESOURCES + "Overworld.tmx"
    fmt.println(map_path)
    tilemap := tiled.load_tilemap(map_path)
    fmt.println(tilemap)
//=========================


    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)

    defer 
    {
        if len(track.allocation_map) > 0 {
            fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
            for _, entry in track.allocation_map {
                fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
            }
        }
        if len(track.bad_free_array) > 0 {
            fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
            for entry in track.bad_free_array {
                fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
            }
        }
        mem.tracking_allocator_destroy(&track)
    }

    rl.InitWindow(1280, 720, "Odin Sagas")
    rl.SetWindowMonitor(1)
    defer rl.CloseWindow()

    icon := rl.LoadImage("resources/icon.png")
    texture := rl.LoadTexture("resources/icon.png")
    rl.SetWindowIcon(icon)
    defer rl.UnloadImage(icon)

    window_flags : rl.ConfigFlags : {.WINDOW_RESIZABLE}
    rl.SetWindowState(window_flags)
    rl.SetTargetFPS(144)

    for !rl.WindowShouldClose() 
    {
        rl.BeginDrawing()
            text := fmt.ctprint("Something")
            rl.DrawText(text, 20, 20, 10, rl.RAYWHITE)
            rl.ClearBackground(rl.RAYWHITE)
            rl.DrawTexture(texture, 0, 0, rl.RAYWHITE)
            rl.DrawFPS(10, 10)
        rl.EndDrawing()

        mem.free_all(context.temp_allocator)
    }
}