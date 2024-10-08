package classes

import "core:slice"
import "core:fmt"

import "core:strings"
import "core:strconv"

print :: fmt.println
printf :: fmt.printfln



Nothing :: struct {}

/*
A stat block describes the base attribute **modifiers** of a class. These include:
    /*
    - dmg : Damage
    - def : Defense,
    - bhp : Base HP
    - mov : Movement Speed
    - asp : Attack Speed
    */
*/
StatBlock :: struct {
    dmg, def, bhp, mov, asp : f32
}

//Describes a character class.
CharacterClass :: struct {
    name, desc : string,
    using stats : StatBlock,
    promoted_by : union { Nothing, ClassLevelsCollection },
    promotes_to : union { Nothing, ClassLevelsCollection }
}

ClassNode :: struct {
    value : ^CharacterClass,

    //classes that promote to the class in "Value"
    promoted : union{Nothing, ClassHashset},
    promotes : union{Nothing, ClassHashset},
}

ClassHashset :: map[^CharacterClass]Nothing

ClassProgressionGraph :: struct {
    nodes : [dynamic]^ClassNode,
}

ClassProgressionGrapher :: [dynamic]^ClassNode

ClassLevelsCollection :: map[^CharacterClass]int

ClassConstantReference :: struct {
    class : CharacterClass
} 

Fighter :: CharacterClass {}

Archer :: CharacterClass {}

Mage :: CharacterClass {}

BattleMage :: CharacterClass{}

Rogue :: CharacterClass {}

TestEntity :: struct {
    levels : ClassLevelsCollection
}

ClassProgressionMap :: map[^ClassConstantReference][]^ClassConstantReference

build_classes_promotions :: proc() -> ^ClassProgressionMap
{
    //Ultimately this should be parsed from a csv sheet or whatever.

    allClasses := []CharacterClass{
        Fighter,
        Archer,
        Mage,
        BattleMage,
        Rogue
    }


    Fighter := CharacterClass {
        dmg = 1,
        def = 2
    }

    mapper := new(ClassProgressionMap)
    classReferences := make([]^ClassConstantReference, len(allClasses))
    for class, i in allClasses{
        classRef := new(ClassConstantReference)
        classRef.class = class
        classReferences[i] = classRef 
    }

    return mapper
}


main::proc(){

    lst := make([dynamic]^ClassConstantReference)

    Fighter := CharacterClass {
        dmg = 1,
        def = 2
    }

    print("FIGHTER:", Fighter.dmg, "DMG,", Fighter.def, "DEF")

    ref := new(ClassConstantReference)
    ref.class = Fighter

    append(&lst, ref)

    print("FIGHTER:", lst[0].class.dmg, "DMG,", lst[0].class.dmg, "DEF")
}

graph_log ::proc (graph : ClassProgressionGraph) {

    sb := new (strings.Builder)
    strings.builder_init(sb)
}
get_test_entity :: proc (startingLevels : ClassLevelsCollection) -> (entity:^TestEntity) {
    
    entity = new(TestEntity, context.allocator)

    if entity != nil {
        startingLevelCopy, err := new_clone(startingLevels)
        entity.levels = startingLevelCopy^
    }
    return entity 
}

//Adds one (by default) or more points in a particular class to an entity.
entity_add_class :: proc (entity : ^TestEntity, class : ^CharacterClass, quant : int = 1) -> (ok : bool) {
    
    entity.levels[class] += quant
    return ok

}

get_all_possible_promotions ::proc(entity : ^TestEntity, graph : ^ClassProgressionGraph) -> []CharacterClass {

    result := make([dynamic]CharacterClass)

    for class in entity.levels{
        if(graph_contains_class(graph, class)){

            

        }
    }

    return result[:]
}

graph_try_add_node :: proc (graph : ^ClassProgressionGraph, node : ^ClassNode) -> bool {
    
    if slice.contains(graph.nodes[:], node){
        return false
    }
    
    append(&graph.nodes, node)

    switch promoter in node.promotes {
        case Nothing: 
            print("Nothing")
        case ClassHashset:
            for class in node.promotes.(ClassHashset){
                if graph_contains_class(graph, class){
                    continue
                }

                graph_try_add_node(graph, class_to_node(class))
            } 
    }

    return true
}

class_to_node :: proc(class:^CharacterClass) -> ^ClassNode {
    node := new(ClassNode)
    node.value = class
    
    //TODO : IF PROMOTERS/PROMOTED, ADD
    

    return node
}

add_promoter :: proc (node : ^ClassNode, promoter : ^CharacterClass){
    //err := append(&node.promotes_to, promoter)
}

@(require_results)
graph_contains_class :: proc(graph : ^ClassProgressionGraph, class : ^CharacterClass) -> (found:bool) {
    
    found = false
    for node in graph.nodes{
        if node.value == class {
            found = true
            break
        }
    }

    return found
}