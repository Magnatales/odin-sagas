package sprites

import rl "vendor:raylib"

SpriteSheet :: struct
{
    texture: rl.Texture2D,
    rows: i32,
    cols: i32,
}

Sprite :: struct
{
    sheet: SpriteSheet,
    frame: i32,
}

get_frame_rect :: proc(sheet : SpriteSheet, frame: i32) -> rl.Rectangle
{
    tile_size := rl.Vector2{f32(sheet.texture.width / sheet.cols), f32(sheet.texture.height / sheet.rows)}

    frame_x := (frame % sheet.cols) * i32(tile_size.x)
    frame_y := (frame / sheet.cols) * i32(tile_size.y)
    result := rl.Rectangle{
        x = f32(frame_x), y = f32(frame_y), 
        width = tile_size.x, height = tile_size.y,
    }
    return result
}