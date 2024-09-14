package tilemap

import "core:os"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:fmt"
import x "core:encoding/xml"
import fp "core:path/filepath"
import "core:slice"
import rl "vendor:raylib"

TILED_RESOURCES::"resources\\tiled\\"

Document :: x.Document
Attribute :: x.Attribute

Image :: rl.Image
Texture2D :: rl.Texture2D
Vector2 :: rl.Vector2
Rect :: rl.Rectangle

print :: fmt.println
printf :: fmt.printfln

TileSet :: struct {
    tex : Texture2D,
    name: string,
    tiled_version : string,
    cellW, cellH : int,
    rects : []Rect
}

TileMapLayer :: struct {
    name:string,
    data: []int,
    width, height : int
}

TileMap :: struct {
    width, height : int,
    cellW, cellH :int,
    firstgids : []int,
    gid_to_set : map[int]TileSet,
    sets : []TileSet,
    layers: []TileMapLayer,

    renderTex : rl.RenderTexture2D,
    source : Rect,
    dest : Rect,
    origin : Vector2
}

//Parses Tiled TileMap file to in-game representation, creates textures, draws tilemap on texture.
Load::proc(filepath: string,  drawScale : f32 = 1) -> TileMap{
    
    tilemap := load_tilemap(filepath)
    tilemap.renderTex = rl.LoadRenderTexture(i32(tilemap.cellW * tilemap.width), i32(tilemap.cellH * tilemap.height))

    tilemap.source = { 0, 0, f32(tilemap.renderTex.texture.width), f32(-tilemap.renderTex.texture.height) }
    
    tilemap.dest = {
        x = f32(rl.GetRenderWidth()/2), y = f32(rl.GetRenderHeight()/2), 
        width = f32(tilemap.renderTex.texture.width) * drawScale,  height = (f32(tilemap.renderTex.texture.height) * drawScale)
    }

    tilemap.origin = {tilemap.dest.width/2, tilemap.dest.height/2}

    generate_map_texture(&tilemap.renderTex, tilemap)

    return tilemap
}

Render::proc(tilemap: ^TileMap, rotation: f32 = 0, tint: rl.Color = rl.WHITE){
    rl.DrawTexturePro(tilemap.renderTex.texture, tilemap.source, tilemap.dest, tilemap.origin, rotation, tint)
}

//De-allocates tilemap?
Unload::proc(tilemap:^TileMap, allocator:= context.allocator){
    free(tilemap, context.allocator)
}


@(private)
get_render_texture::proc(tilemap: ^TileMap) -> rl.RenderTexture2D{
    return rl.LoadRenderTexture(i32(tilemap.cellW * tilemap.width), i32(tilemap.cellH * tilemap.height))
}
 
@(private)
to_Int :: proc(val: string, warning_if_fail: string) -> int{
    num, ok := strconv.parse_int(val)

    assert(ok, warning_if_fail)
    return num
}

//Use to load TileMap from a .tmx file.
@(private)
load_tilemap :: proc(filepath:string) -> TileMap {

    assert(os.exists(filepath), "Path to tilemap does not exist")
    assert(fp.ext(filepath) == ".tmx", "file provided is not Tiled tilemap (.tmx)")

    doc, err := x.load_from_file(filepath)
    
    if(err != nil){
        fmt.println(err)
    }

    dir := fp.dir(filepath)
    
    tilemap : TileMap
    sets : [dynamic]TileSet
    layers:[dynamic]TileMapLayer
    firstgids:[dynamic]int
    tilemap.gid_to_set = make(map[int]TileSet)

    layerCount := 0
    for e, i in doc.elements{
        switch e.ident{
            case "map": 
                for a in e.attribs{
                    switch a.key{
                        case "width": tilemap.width = to_Int(a.val, "Error processing map width value")
                        case "height": tilemap.height = to_Int(a.val, "Error processing map height value")
                        case "tilewidth": tilemap.cellW = to_Int(a.val, "Error processing tilemap cell width")
                        case "tileheight": tilemap.cellH = to_Int(a.val, "Error processing tilemap cell height")
                    }
                }

            case "tileset":
                p, err := strings.concatenate({dir, "\\", e.attribs[1].val}) //e.attribs[1].val = tileset file (.tsx) name.
                
                if(err != nil) {print("While concatenating tileset path", err)}
                
                tileset := load_tileset(p)
                firstgid:= to_Int(e.attribs[0].val, "Error processing firstgid attribute.")
                
                append(&sets, tileset)
                append(&firstgids, firstgid)

                tilemap.gid_to_set[firstgid] = tileset

            case "data":
                parent := doc.elements[e.parent]
                w:= to_Int(parent.attribs[2].val, "Error processing data w value")
                h:= to_Int(parent.attribs[3].val, "Error processing data h value")
                
                layer_data := e.value[0]
                map_layer := load_map_layer(e,w,h)
                
                append(&layers, map_layer)
        }
    }

    tilemap.sets = sets[:]
    tilemap.layers = layers[:]

    //Sort firstgids slice so numbers will always be in ascending order.
    s := firstgids[:]
    slice.sort(s)
    tilemap.firstgids = s

    return tilemap
}

//Use to load a Tileset (called automatically by load_tilemap())
@(private)
load_tileset :: proc(filepath:string) -> TileSet {

    assert(os.exists(filepath), "load_tileset: filepath does not exist")
    assert(fp.ext(filepath) == ".tsx", "load_tileset: provided filepath does not point to .tsx (tileset) file.")
    doc := load_xml(filepath)

    file_name := fp.base(filepath)

    set : TileSet
    for attr in doc.elements[0].attribs{
        switch attr.key{
            case "name":
                set.name = attr.val
            case "version":
                set.tiled_version = attr.val
            case "tilewidth":
                cellW := to_Int(attr.val, "Something went wrong when trying to parse tileWidth")
                set.cellW = cellW
            case "tileheight":
                cellH:= to_Int(attr.val, "Something went wrong when trying to parse tileHeight")
                set.cellH = cellH
        }
    }

    dir := fp.dir(filepath)
    for attr in doc.elements[1].attribs{
        if attr.key == "source"{
            imgPath := strings.clone_to_cstring(strings.concatenate({dir,"\\",attr.val}))
            set.tex = rl.LoadTexture(imgPath)
        }
    }

    assert(set.cellW > 0 && set.cellH > 0, "Cell width and Height superior to 0")
    set.rects = calculate_tileSet_rects(set.tex.width, set.tex.height, i32(set.cellW), i32(set.cellH))
    return set
}

//Loads a tilemap layer
@(private)
load_map_layer::proc(data:x.Element, width,height:int) -> TileMapLayer{    
    layout : [dynamic]int

    switch v in data.value[0] {
        case string:
            clean, has_alloc := strings.remove_all(v, "\r\n") //todo: remove allocated memory.
            
            split, err := strings.split(clean, ",")
            if(err != nil){print(err)}

            for s in split{
                num:= to_Int(s, "Error parsing layout data value to int.")
                append(&layout, num)
            }
        case x.Element_ID:
            print("Invalid data in map layer")
    }
    result : TileMapLayer
    result.height = height
    result.width = width
    result.data = layout[:]
    return result
}

//Call this method to calculate all rectangles in a spritesheet:
@(private)
calculate_tileSet_rects :: proc(width, height : i32, cellW, cellH : i32) -> []Rect {
	rows : i32 = height / i32(cellH)
	cols : i32 = width /  i32(cellW)

	rects := make([]Rect, cols * rows)
	
	for y in 0..<rows {
		for x in 0..<cols{
			id := i32(x) + i32(y) * cols
			rects[id] = get_rect(x, y, cellW, cellH)
		}
	}

	return rects
}

//Cache this rectangle to find tile more easily from id:
@(private)
get_rect :: proc(x, y, cellW, cellH : i32) -> Rect {
	rec := (Rect){
		x = f32(x * cellW), y = f32(y * cellH), 
		width = f32(cellW), height = f32(cellW)
	}
	
	//maybe useful to save?
	//pos := V2{f32(x * cellW), f32(y * cellH)}

	return rec
}

//Gets position to draw a tile on the tilemap render texturefrom a value in the layout data:
@(private)
get_tilemap_pos :: proc(id: int, texW, texH, cellW, cellH : f32) -> Vector2 {
	cols := texW / cellW
	rows := texH / cellH

	xOffset := id % int(cols)
	yOffset := math.floor(f32(id)/f32(rows))

	return Vector2{f32(xOffset) * cellW, (yOffset * cellH)}
}

//returns "first gid" of an  in the tilemap.
@(private)
get_tileset_firstgid::proc(id: int, gids:[]int) -> int {
    length := len(gids)
    result := -99
    for gid in gids {
        if gid <= id && gid > result {
            result = gid;
        }
    }
    
    assert(result > 0, "get_tileset_index Result must be a positive. check tilemap data.")
    return result
}

//Draws the content of tilemap to a RenderTexture2D.
@(private)
generate_map_texture :: proc(renderTex: ^rl.RenderTexture2D, tilemap: TileMap, tint : rl.Color = rl.WHITE) {

    rl.BeginTextureMode(renderTex^)

    for layer in tilemap.layers{
        
        for id, i in layer.data{
            if(id == 0){
                continue
            }
            
            gid := get_tileset_firstgid(id, tilemap.firstgids)    
            set := tilemap.gid_to_set[gid]
    
            pos := get_tilemap_pos(i, f32(renderTex.texture.width), f32(renderTex.texture.height), f32(set.cellW), f32(set.cellH))
            
            rl.DrawTextureRec(
                set.tex, 
                set.rects[id-gid],
                pos,
                tint
            )
        }

    }
    rl.EndTextureMode()
}

//Use to load XML file
@(private)
load_xml :: proc(filepath: string) -> ^x.Document{
    doc, err := x.load_from_file(filepath)

    if(err != nil) {
        print(err)
    }

    return doc
}

//Use to check contents of a Document
@(private)
log_xml :: proc(doc: ^x.Document){
    for line, i in doc.elements{
        print(i, line.ident, line.attribs)
    }
}

//DEBUG
//Example method from : https://odin-lang.org/news/read-a-file-line-by-line/
@(private)
read_file_by_lines_in_whole :: proc(filepath: string) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
		// could not read file
		return
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		print(line)
	}
}
