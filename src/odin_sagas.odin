package main

import rl "vendor:raylib"
import "core:fmt"

main :: proc() {

    rl.InitWindow(1280, 720, "Odin Sagas")
    defer rl.CloseWindow()

    icon := rl.LoadImage("resources/icon.png")
    rl.SetWindowIcon(icon)
    defer rl.UnloadImage(icon)

    window_flags : rl.ConfigFlags : {.WINDOW_RESIZABLE}
    rl.SetWindowState(window_flags)
     rl.SetTargetFPS(144)

    for !rl.WindowShouldClose() 
    {
        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)

            rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }
}