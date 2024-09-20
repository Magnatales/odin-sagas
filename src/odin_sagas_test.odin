package main

import "core:fmt"
import "core:mem"
import "core:math"
import s "core:strings"

import rl "vendor:raylib"
import mem_tracking "mem_tracking"
import animation "animation"
import sprites "sprites"
import tilemap "tilemap"
import bunny "bunny"

main :: proc() 
{
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    defer mem_tracking.track(&track)

    rl.InitWindow(1280, 720, "Odin Sagas")
    rl.SetWindowMonitor(1)
    defer rl.CloseWindow()

    icon := rl.LoadImage("resources/icon.png")
    texture := rl.LoadTexture("resources/icon.png")
    rl.SetWindowIcon(icon)
    defer rl.UnloadImage(icon)

    bunny_character := bunny.init_bunny("resources/character.png", rl.Vector2{500, 400}, 150.0)

    window_flags : rl.ConfigFlags : {.WINDOW_RESIZABLE}
    rl.SetWindowState(window_flags)
    rl.SetTargetFPS(144)
    
    worldmap := tilemap.Load(tilemap.TILED_RESOURCES + "RiverWorld.tmx", 1)

    camera := rl.Camera2D{}
    camera.target = rl.Vector2{bunny_character.entity.position.x, bunny_character.entity.position.y}
    camera.offset = rl.Vector2{1280/2, 720/2}
    camera.rotation = 0.0
    camera.zoom = 2

    for !rl.WindowShouldClose() 
    {
        dt := rl.GetFrameTime()

        input := rl.Vector2{0, 0}
        
        bunny.update(&bunny_character, dt)

        start_pos := [2]f32{camera.target.x, camera.target.y}
        end_pos := [2]f32{bunny_character.entity.position.x,  bunny_character.entity.position.y}

        p := math.lerp(start_pos, end_pos, dt * 5)
        camera.target = p
        

        width := rl.GetScreenWidth()
        height := rl.GetScreenHeight()

        camera.offset = rl.Vector2{f32(width/2), f32(height/2)}

        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            rl.BeginMode2D(camera)
                tilemap.Render(&worldmap)
                bunny.draw(&bunny_character)
            rl.EndMode2D()
            rl.DrawFPS(10, 10)
        rl.EndDrawing()

        mem.free_all(context.temp_allocator)
    }
}