package mem_tracking

import "core:fmt"
import "core:mem"

track :: proc(tracking: ^mem.Tracking_Allocator) 
{
	if len(tracking.allocation_map) > 0 {
		fmt.eprintf("=== %v allocations not freed: ===\n", len(tracking.allocation_map))
		for _, entry in tracking.allocation_map {
			fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
		}
	}
	if len(tracking.bad_free_array) > 0 {
		fmt.eprintf("=== %v incorrect frees: ===\n", len(tracking.bad_free_array))
		for entry in tracking.bad_free_array {
			fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
		}
	}
	mem.tracking_allocator_destroy(tracking)
}
