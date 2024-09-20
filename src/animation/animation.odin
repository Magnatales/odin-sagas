package animation

import sprites "../sprites"
import rl "vendor:raylib"
import "core:fmt"

Animation :: struct 
{
    id: string,
    sheet: sprites.SpriteSheet,
    frame_sequence: []i32,
    frame_time: f32,
}

AnimatedEntity :: struct
{
    animations: map[string]Animation,
    current_animation: ^Animation,
    current_frame: i32,
    elapsed_time: f32,
    position: rl.Vector2,
    scale: f32,
    rotation: f32,
    color: rl.Color,
}

get_frame :: proc(animation: Animation, current_frame: i32) -> rl.Rectangle
{
    return sprites.get_frame_rect(animation.sheet, animation.frame_sequence[current_frame])
}

set_animation :: proc (entity: ^AnimatedEntity, animation_name: string)
{
    animation := entity.animations[animation_name]
    if entity.current_animation != nil && entity.current_animation.id == animation.id
    {
        return
    }

    entity.current_animation = &entity.animations[animation_name]
    entity.current_frame = 0
    entity.elapsed_time = 0.0
}

update :: proc(entity: ^AnimatedEntity, delta_time: f32)
{
    entity.elapsed_time += delta_time

    if entity.elapsed_time >= entity.current_animation.frame_time 
    {
        entity.elapsed_time = 0.0
        entity.current_frame += 1

        if entity.current_frame >= i32(len(entity.current_animation.frame_sequence)) 
        {
            entity.current_frame = 0
        }
    }
}

draw :: proc(entity: AnimatedEntity) 
{
    animation := entity.current_animation
    frame_rect := get_frame(animation^, entity.current_frame)

    dest_rect := rl.Rectangle{
        x = entity.position.x, 
        y = entity.position.y, 
        width = frame_rect.width * entity.scale, 
        height = frame_rect.height * entity.scale,
    }

    origin := rl.Vector2{frame_rect.width / 2, frame_rect.height / 2}
    rl.DrawTexturePro(animation.sheet.texture, frame_rect, dest_rect, origin, entity.rotation, entity.color)
}