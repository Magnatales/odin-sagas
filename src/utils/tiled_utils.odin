package tiled_utils

import "core:os"
import "core:strings"
import "core:strconv"
import "core:fmt"
import x "core:encoding/xml"
import fp "core:path/filepath"
import rl "vendor:raylib"


TILED_RESOURCES::"resources\\tiled\\"

Image :: rl.Image
Document :: x.Document
Attribute :: x.Attribute
toInt :: strconv.parse_int

TileSet :: struct {
    file : Image,
    tiled_version : string,
    cell_count, cell_w, cell_h : int,
}

TileMapLayer :: struct {
    data: []int,
    width, height : int
}

TileMap :: struct {
    width, height : int,

    tiles : []TileSet,
    firstgids : map[int]int,
    
    layers: []TileMapLayer
}

//Use to load TileMap from a .tmx file.
load_tilemap :: proc(filepath:string) -> TileMap {
    doc, err := x.load_from_file(filepath)
    
    if(err != nil){
        fmt.println(err)
    }

    dir := fp.dir(filepath)
    
    tilemap : TileMap
    sets : [dynamic]TileSet
    layers:[dynamic]TileMapLayer
    for e, i in doc.elements{
        if e.ident == "map"{
            for a in e.attribs{
                switch a.key {
                    case "width":
                        num, err := toInt(a.val)
                        tilemap.width = num
                        
                    case "height": 
                        num, err := toInt(a.val)
                        tilemap.height = num
                }
            }
        }

        
        if e.ident == "tileset"{
            p := strings.concatenate({dir, "\\", e.attribs[1].val})
        
            fmt.println("Tileset located at:", p)
            tileset, err := load_tileset(p)
            
            setId := len(sets)
            firstgid, errGid := toInt(e.attribs[0].val)
            tilemap.firstgids[setId] = firstgid
            append(&sets, tileset)
        }

        if e.ident == "data"{
            parent := doc.elements[e.parent]
            
            w, errW:= toInt(parent.attribs[2].val)
            h, errH:= toInt(parent.attribs[3].val)
            
            layer_data := e.value[0]
            
            append(&layers, load_map_layer(e, w,h))
        }
    }

    tilemap.tiles = sets[:]
    tilemap.layers = layers[:]
    return tilemap
}

//Use to load a Tileset (called automatically by load_tilemap())
@(private)
load_tileset :: proc(filepath:string) -> (set: TileSet, err: string){

    doc := load_xml(filepath)

    derp := doc.element_count == 2 && doc.elements[0].ident == "tileset"
    assert(derp)

    tile : TileSet

    for attr in doc.elements[0].attribs{
        if(attr.key == "version"){
            tile.tiled_version = attr.val
        }

        if(attr.key == "name"){

        }

        if(attr.key == "tileWidth"){
            cell_w, ok := toInt(attr.val)
            tile.cell_w = cell_w
        }

        if(attr.key == "tileHeight"){
            cell_h, ok := toInt(attr.val)
            tile.cell_h = cell_h
        }

        if(attr.key == "tilecount"){
            cell_count, ok := toInt(attr.val)
            tile.cell_count = cell_count
        }

    }


    dir := fp.dir(filepath)
    for attr in doc.elements[1].attribs{
        if attr.key == "source"{
            imgPath := strings.clone_to_cstring(strings.concatenate({dir,"\\",attr.val}))
            tile.file = rl.LoadImage(imgPath)
        }
    }

    return tile, "nope"
}

//Loads a tilemap layer
@(private)
load_map_layer::proc(data:x.Element, width,height:int) -> TileMapLayer{
    layout : [dynamic]int
    defer delete(layout)

    switch v in data.value[0] {
        case string:
            split, err := strings.split(v, ",")
            for s in split{
                num, err := toInt(s)
                append(&layout, num)
            }
        case x.Element_ID:
            fmt.println("Invalid data")
    }

    result : TileMapLayer
    result.height = height
    result.width = width
    result.data = layout[:]

    return result
}


//Use to load XML file
load_xml :: proc(filepath: string) -> ^x.Document{
    doc, err := x.load_from_file(filepath)

    if(err != nil) {
        fmt.println(err)
    }

    return doc
}

//Use to check contents of a Document
log_xml :: proc(doc : ^x.Document){
    for line, i in doc.elements{
        fmt.println(i, line.ident, line.attribs)
    }
}

//DEBUG
//Example method from : https://odin-lang.org/news/read-a-file-line-by-line/
read_file_by_lines_in_whole :: proc(filepath: string) {
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
		// could not read file
		return
	}
	defer delete(data, context.allocator)

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		fmt.println(line)
	}
}
