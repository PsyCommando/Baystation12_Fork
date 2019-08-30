/datum/persistence/serializer/save
	var/list/thing_ref_map = list() // Used as a map for fixing recursive references (for datums and lists).
	var/list/area_ref_map = list() // Used as a map for fixing recursive references (for areas specifically)

/datum/persistence/serializer
	var/datum/persistence/query_builder/Q

/datum/persistence/serializer/New(var/datum/persistence/query_builder/qb)
	Q = qb

/datum/persistence/serializer/save/proc/GetOrSaveThing(var/T)
	var/thing_id = thing_ref_map[T]
	if(thing_id)
		return thing_id
	thing_id = SerializeThing(T)
	thing_ref_map[T] = thing_id
	return thing_id

// This is called when we have failed to GetOrSaveThing, meaning the Thing is not yet serialized.
/datum/persistence/serializer/save/proc/SerializeThing(var/T)
	//T.before_save()
	// Create the thing. First determine what it is.
	var/thing_id = 0
	if(istype(T, /datum))
		var/datum/D = T
		to_world("saving datum [D.type]")
		thing_id = Q.AddThing(D.type)
		for(var/V in D.vars)
			var/thing_type
			var/thing_value

			// Guard check. Don't bother saving things with a default value
			if(D.vars[V] == initial(D.vars[V]))
				continue
			// Guard check. Ignore deleted datums.
			if(istype(D.vars[V], /datum))
				var/datum/D2 = D.vars[V]
				if(QDELETED(D2))
					continue
				// Try to fetch the datum, in case it's already been serialized.
				thing_value = "thing/" + GetOrSaveThing(D2)
				thing_type = D2.type
			// Guard check. Skip empty lists.
			else if(islist(D.vars[V]))
				var/list/L2 = D.vars[V]
				if(!L2.len)
					continue
				// Try to fetch the list if it's somehow already been serialized.
				thing_value = "list/" + GetOrSaveThing(L2)
				thing_type = "/list"
			else
				thing_value = "[D.vars[V]]"
				thing_type = "basic"
			// Passed the tests. Save the thing as a variable on the master thing.
			Q.AddThingVar(thing_id, thing_type, V, thing_value)
	else if(islist(T))
		thing_id = Q.AddThing("/list")
		var/list/L = T // cast to list
		for(var/item in L)			
			if(istype(item, /datum))
				var/datum/D = item
				if(QDELETED(D))
					continue
				Q.AddThingListVar(thing_id, D.type, "thing/" + GetOrSaveThing(D))
			else if(istype(item, /list))
				var/list/L2 = item
				if(!L2.len)
					continue
				Q.AddThingListVar(thing_id, "/list", "list/" + GetOrSaveThing(L2))
			else
				Q.AddThingListVar(thing_id, "basic", "[item]")
	else
		crash_with("SerializeThing was passed a basic data value? Stahp.")
		return

	//T.after_save()
	return thing_id

