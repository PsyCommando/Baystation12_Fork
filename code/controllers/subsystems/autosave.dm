#define SAVECHUNK_SIZEX 16
#define SAVECHUNK_SIZEY 16

SUBSYSTEM_DEF(autosave)
	name = "Autosave"
	wait = 3 HOURS
	next_fire = 3 HOURS	// To prevent saving upon start.
	runlevels = RUNLEVEL_GAME

	var/saving = 0
	var/announced = 0

/datum/controller/subsystem/autosave/stat_entry()
	..(saving ? "Currently Saving" : "Next autosave in [round((next_fire - world.time) / (1 MINUTE), 0.1)] minutes.")


/datum/controller/subsystem/autosave/fire()
	Save()


/datum/controller/subsystem/autosave/proc/Save()
	if(saving)
		message_admins(SPAN_DANGER("Attempted to save while already saving!"))
	else
		saving = 1
		for(var/datum/controller/subsystem/S in Master.subsystems)
			S.disable()
		Save_World()
		for(var/datum/controller/subsystem/S in Master.subsystems)
			S.enable()
		saving = 0

/datum/controller/subsystem/autosave/proc/Save_World()
	to_world("<font size=4 color='green'>The world is saving! Characters are frozen and you won't be able to join at this time.</font>")
	sleep(20)
	var/reallow = 0
	if(config.enter_allowed) reallow = 1
	config.enter_allowed = 0
	//Prepare_Atmos_For_Saving()
	var/starttime = REALTIMEOFDAY
	var/datum/persistence/query_builder/Q = new()
	var/datum/persistence/serializer/save/S = new(Q)
	var/chunks_processed = 0
	to_world("<font size=3 color='green'>Saving chunks..</font>")
	for(var/z in 1 to world.maxz)
		for(var/x in 1 to world.maxx step SAVECHUNK_SIZEX)
			for(var/y in 1 to world.maxy step SAVECHUNK_SIZEY)
				//to_world("saving chunk [x],[y],[z]")
				Save_Chunk(S,x,y,z)
				Q.Execute()
				chunks_processed++
				if(chunks_processed > 1000)
					break
	

	// to_world("<font size=3 color='green'>Saving areas..</font>")
	// for(var/area/A in areas_to_save)
	// 	if(istype(A, /area/space)) continue
	// 	var/datum/area_holder/holder = new()
	// 	holder.area_type = A.type
	// 	holder.name = A.name
	// 	holder.turfs = A.get_turf_coords()
	// 	formatted_areas += holder
	// Save_Records(dir)

	if(reallow) config.enter_allowed = 1
	to_world("<font size=3 color='green'>Saving Completed in [(REALTIMEOFDAY - starttime)/10] seconds!</font>")
	to_world("<font size=3 color='green'>Saving Complete</font>")

/datum/controller/subsystem/autosave/proc/Save_Chunk(var/datum/persistence/serializer/save/S, var/xi, var/yi, var/zi)
	var/z = zi
	xi = (xi - (xi % SAVECHUNK_SIZEX) + 1)
	yi = (yi - (yi % SAVECHUNK_SIZEY) + 1)
	for(var/y in yi to yi + SAVECHUNK_SIZEY)
		for(var/x in xi to xi + SAVECHUNK_SIZEX)
			var/turf/T = locate(x,y,z)
			if(!T || ((T.type == /turf/space || T.type == /turf/simulated/open) && (!T.contents || !T.contents.len)))
				continue
			T.z_level = z
			try
				S.GetOrSaveThing(T)
			catch(var/exception/e)
				to_world("[e] on [e.file]:[e.line]")

/datum/controller/subsystem/autosave/proc/AnnounceSave()
	var/minutes = (next_fire - world.time) / (1 MINUTE)

	if(!announced && minutes <= 5)
		to_world("<font size=4 color='green'>Autosave in 5 Minutes!</font>")
		announced = 1
	if(announced == 1 && minutes <= 1)
		to_world("<font size=4 color='green'>Autosave in 1 Minute!</font>")
		announced = 2
	if(announced == 2 && minutes >= 6)
		announced = 0

#undef SAVECHUNK_SIZEX
#undef SAVECHUNK_SIZEY