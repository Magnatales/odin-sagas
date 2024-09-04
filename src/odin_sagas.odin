package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"

main :: proc() 
{
    default_allocator := context.allocator
    tracking_allocator : mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, default_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer reset_tracking_allocator(&tracking_allocator)

    reset_tracking_allocator :: proc(a: ^mem.Tracking_Allocator) -> bool {
        err := false

        fmt.printfln("=============================================")
        for _, value in a.allocation_map{
            fmt.printfln("%v: Leaked %v bytes\n", value.location, value.size)
            err = true
        }

        if len(a.bad_free_array) > 0 {
            fmt.printfln("=============================================")
            for b in a.bad_free_array {
                fmt.printfln("%v: Bad free\n", b.location)
                err = true
            }
        }
        mem.tracking_allocator_clear(a)
        return err
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

    reset_tracking_allocator(&tracking_allocator)
    
}