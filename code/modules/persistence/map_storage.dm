/datum
	var/should_save = 1 // A special override that can tell the persistence system to not save this datum.
	var/list/persistent_saved_vars

/datum/proc/should_save()
	if(QDELETED(src))
		return FALSE
	//if(gc_destroyed)
	//	return FALSE
	return should_save

/datum/proc/before_load()
	return

/datum/proc/after_load()
	return

/datum/proc/before_save()
	// Sometimes we change the value of some variables for saving purpose only..
	// and want to change them back after
	return

/datum/proc/after_save()
	// Sometimes we change the value of some variables for saving purpose only..
	// and want to change them back after
	return

/datum/proc/get_saved_vars()
	// If FALSY is returned, everything will be serialized. (if should_save is 1)
	// If a /list is returned, only variables in the list will be saved.
	return persistent_saved_vars

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Turf
//
/turf
	persistent_saved_vars = list("density","icon_state","name","pixel_x","pixel_y","contents","dir","x","y","z")

/turf/space
	persistent_saved_vars = list("pixel_x","pixel_y","contents","x","y","z")

/turf/space/after_load()
	..()
	for(var/atom/movable/lighting_overlay/overlay in contents) // Reset lighting overlays on space tiles.
		overlay.loc = null
		qdel(overlay)

/turf/after_load()
	..()
	//decals = saved_decals.Copy()
	queue_icon_update()
	// rebuild lighting after loading turf.
	if(dynamic_lighting)
		lighting_build_overlay()
	else
		lighting_clear_overlay()

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Area
//
/area/after_load()
	power_change() // Refresh power systems after loading an area.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Obj
//
/obj
	persistent_saved_vars = list("density","icon_state","name","pixel_x","pixel_y","contents","dir")

/obj/after_load()
	..()
	queue_icon_update() // Update icon updates after obj loads.

/obj/effect/overlay
	should_save = 0

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Atoms
//
/atom/movable/lighting_overlay
	should_save = 0 // Do not save lighting overlays.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Mobs
//
/mob
	var/stored_ckey = "" // Special component for character persistence to maintain links to owner ckeys.
	//persistent_saved_vars = list("lastKnownIP", "stat", "sdisabilities", "disabilities", "phoronation", "radiation", "timeofdeath", "blinded", "ear_def", "paralysis", "stunned", "druggy", "confused", "sleeping", "resting", "weakened", "drowsyne)