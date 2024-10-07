package input

import rl "vendor:raylib"
import "core:fmt"
import s "core:strings"

IsKeyDown :: rl.IsKeyDown
KeyboardKey :: rl.KeyboardKey

MoveInput :: enum{
    Up    = 1 << 0,
    Down  = 1 << 1,
    Left  = 1 << 2,
    Right = 1 << 3,
}

//Run this in Update:
GetPlayerInput::proc() -> bit_set[MoveInput]{

    output : bit_set[MoveInput]

    if(IsKeyDown(KeyboardKey.W)) {
        output += {MoveInput.Up}
    }
    
    if(IsKeyDown(KeyboardKey.A)) {
        output += {MoveInput.Left}
    }
    
    if(IsKeyDown(KeyboardKey.S)) {
        output += {MoveInput.Down}
    }
    
    if(IsKeyDown(KeyboardKey.D)) {
        output += {MoveInput.Right}
    }

    return output
}

ReadSetContains::proc(set:^bit_set[MoveInput], read:MoveInput) -> bool {
    return read in set
}

NormalizedMovementVector :: proc(set:^bit_set[MoveInput]) -> rl.Vector2 {

    x : f32 = 0
    x += MoveInput.Left in set ? -1 : 0
    x += MoveInput.Right in set ? 1 : 0

    y : f32 = 0
    y += MoveInput.Down in set ? 1 : 0
    y += MoveInput.Up in set ? -1 : 0

    return rl.Vector2Normalize({x,y})
}