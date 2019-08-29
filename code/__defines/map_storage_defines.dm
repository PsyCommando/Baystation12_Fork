#define ADD_SAVED_VAR(X) map_storage_saved_vars = "[map_storage_saved_vars][length(map_storage_saved_vars)? ";" : null][#X]"
#define ADD_SKIP_EMPTY(X) skip_empty = "[skip_empty][length(skip_empty)? ";" : null][#X]"

#define SAVED_ZLEVELS GetNbSavedZLevels() //Returns the number of z-levels to save from z-level 1 to x.

proc/GetNbSavedZLevels()
	return 20