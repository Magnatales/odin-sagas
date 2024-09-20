package bunny

import rl "vendor:raylib"
import sprites "../sprites"
import animation "../animation"

Bunny :: struct {
    controller: Controller,
    entity: animation.AnimatedEntity,
}

Controller :: struct {
    speed: f32,
}

init_bunny :: proc(texture_path: cstring, start_position: rl.Vector2, speed : f32) -> Bunny {
    character_texture := rl.LoadTexture(texture_path)

    movement_sheet := sprites.SpriteSheet{
        texture = character_texture,
        rows = 4,
        cols = 4,
    }

    run_down := animation.Animation{
        id = "run_down",
        sheet = movement_sheet,
        frame_sequence = []i32{0, 1, 2, 3},
        frame_time = 0.2,
    }
    run_up := animation.Animation{
        id = "run_up",
        sheet = movement_sheet,
        frame_sequence = []i32{4, 5, 6, 7},
        frame_time = 0.2,
    }
    run_left := animation.Animation{
        id = "run_left",
        sheet = movement_sheet,
        frame_sequence = []i32{8, 9, 10, 11},
        frame_time = 0.2,
    }
    run_right := animation.Animation{
        id = "run_right",
        sheet = movement_sheet,
        frame_sequence = []i32{12, 13, 14, 15},
        frame_time = 0.2,
    }

    entity := new(animation.AnimatedEntity)

    entity.animations = map[string]animation.Animation{
            "run_down" = run_down,
            "run_right" = run_right,
            "run_left" = run_left,
            "run_up" = run_up,
        }
    entity.current_animation = nil
    entity.position = start_position
    entity.scale = 1.0
    entity.rotation = 0.0
    entity.color = rl.WHITE
    

    animation.set_animation(&entity^, "run_down")

    return Bunny{
        controller = Controller{speed = speed},
        entity = entity^,
    }
}

update_movement :: proc(bunny: ^Bunny, delta_time: f32) {
    input := rl.Vector2{0, 0}

    if rl.IsKeyDown(rl.KeyboardKey.D) {
        input.x = 1
        animation.set_animation(&bunny.entity, "run_right")
    } else if rl.IsKeyDown(rl.KeyboardKey.A) {
        input.x = -1
        animation.set_animation(&bunny.entity, "run_left")
    }

    if rl.IsKeyDown(rl.KeyboardKey.W) {
        input.y = -1
        animation.set_animation(&bunny.entity, "run_up")
    } else if rl.IsKeyDown(rl.KeyboardKey.S) {
        input.y = 1
        animation.set_animation(&bunny.entity, "run_down")
    }

    input = rl.Vector2Normalize(input)

    bunny.entity.position.x += input.x * bunny.controller.speed * delta_time
    bunny.entity.position.y += input.y * bunny.controller.speed * delta_time
}

update :: proc(bunny: ^Bunny, delta_time: f32) {
    update_movement(bunny, delta_time)
    animation.update(&bunny.entity, delta_time)
}

draw :: proc(bunny: ^Bunny) {
    animation.draw(bunny.entity)
}
