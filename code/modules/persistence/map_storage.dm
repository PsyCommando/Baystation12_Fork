/datum
	var/should_save = 1 // A special override that can tell the persistence system to not save this datum.

/mob
	var/stored_ckey = "" // Special component for character persistence to maintain links to owner ckeys.

/datum/proc/should_save()
	if(QDELETED(.))
		return FALSE
	if(gc_destroyed)
		return FALSE
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

/atom/movable/lighting_overlay
	should_save = 0 // Do not save lighting overlays.

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

/obj/after_load()
	..()
	queue_icon_update() // Update icon updates after obj loads.

/area/after_load()
	power_change() // Refresh power systems after loading an area.

