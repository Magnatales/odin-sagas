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

    character_texture := rl.LoadTexture("resources/character.png")
    defer rl.UnloadTexture(character_texture)

    movement_sheet := sprites.SpriteSheet{texture = character_texture, rows = 4, cols = 4}

    RUN_DOWN :: "run_down"
    RUN_UP :: "run_up"
    RUN_LEFT :: "run_left"
    RUN_RIGHT :: "run_right"

    run_down := animation.Animation{id = RUN_DOWN, sheet = movement_sheet, frame_sequence = []i32{0, 1, 2, 3}, frame_time = 0.2}
    run_up := animation.Animation{id = RUN_UP, sheet = movement_sheet, frame_sequence = []i32{4, 5, 6, 7}, frame_time = 0.2}
    run_left := animation.Animation{id = RUN_LEFT, sheet = movement_sheet, frame_sequence = []i32{8, 9, 10, 11}, frame_time = 0.2}
    run_right := animation.Animation{id = RUN_RIGHT, sheet = movement_sheet, frame_sequence = []i32{12, 13, 14, 15}, frame_time = 0.2}

    character := animation.AnimatedEntity{
        animations = map[string]animation.Animation{"run_down" = run_down, "run_right" = run_right, "run_left" = run_left, "run_up" = run_up},
        current_animation = nil,
        position = rl.Vector2{640, 360},
        scale = 1.0,
        rotation = 0.0,
        color = rl.WHITE,
    }

    animation.set_animation(&character, "run_down")

    character.position = rl.Vector2{500, 400}
    character_speed :f32= 150.0


    window_flags : rl.ConfigFlags : {.WINDOW_RESIZABLE}
    rl.SetWindowState(window_flags)
    rl.SetTargetFPS(144)
    
    worldmap := tilemap.Load(tilemap.TILED_RESOURCES + "RiverWorld.tmx",2)

    camera := rl.Camera2D{}
    camera.target = rl.Vector2{character.position.x, character.position.y}
    camera.offset = rl.Vector2{1280/2, 720/2}
    camera.rotation = 0.0
    camera.zoom = 2

    for !rl.WindowShouldClose() 
    {
        dt := rl.GetFrameTime()

        input := rl.Vector2{0, 0}
        if rl.IsKeyDown(rl.KeyboardKey.D) 
        {
            input.x = 1
        } 
        
        if rl.IsKeyDown(rl.KeyboardKey.A) 
        {
            input.x = -1
        } 
        
        if rl.IsKeyDown(rl.KeyboardKey.W) 
        {
            input.y = -1
        } 
        
        if rl.IsKeyDown(rl.KeyboardKey.S) 
        {
            input.y = 1
        }

        if input.x == 1 
        {
            animation.set_animation(&character, "run_right")
        }
        else if input.x == -1 
        {
            animation.set_animation(&character, "run_left")
        }
        else if input.y == 1 
        {
            animation.set_animation(&character, "run_down")
        }
        else if input.y == -1 
        {
            animation.set_animation(&character, "run_up")
        }

        input = rl.Vector2Normalize(input)
        
        character.position.x += input.x * character_speed * dt
        character.position.y += input.y * character_speed * dt

        start_pos := [2]f32{camera.target.x, camera.target.y}
        end_pos := [2]f32{character.position.x,  character.position.y}

        p := math.lerp(start_pos, end_pos, dt * 5)
        camera.target = p
        

        width := rl.GetScreenWidth()
        height := rl.GetScreenHeight()

        camera.offset = rl.Vector2{f32(width/2), f32(height/2)}

        rl.BeginDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            rl.BeginMode2D(camera)
                tilemap.Render(&worldmap)
                animation.update(&character, dt)
                animation.draw(character)
            rl.EndMode2D()
            rl.DrawFPS(10, 10)
        rl.EndDrawing()

        mem.free_all(context.temp_allocator)
    }
}