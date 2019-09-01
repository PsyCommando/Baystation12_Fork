/datum/persistence/serializer/save
	var/list/thing_ref_map = list() // Used as a map for fixing recursive references (for datums and lists).
	var/list/area_ref_map = list() // Used as a map for fixing recursive references (for areas specifically)

/datum/persistence/serializer
	var/datum/persistence/query_builder/Q

/datum/persistence/serializer/New(var/datum/persistence/query_builder/qb)
	Q = qb

/datum/persistence/serializer/save/proc/GetOrSaveThing(var/T)
	// Special guard check.
	if(istype(T, /datum))
		var/datum/D = T
		if(!D.should_save())
			return -1

	var/thing_id = get_thing_index(T)
	if(thing_id)
		return thing_id
	thing_id = serialize_thing(T)
	if(!thing_id) // null guard check in case we skipped this thing.
		return -1
	add_thing_reference(T, thing_id)
	return thing_id

// Determine what we're saving on an object.
/datum/persistence/serializer/save/get_saved_vars(var/datum/D)
	var/list/saved_vars = D.get_saved_vars()
	if(!saved_vars)
		saved_vars = D.vars
	return saved_vars

// Add a new reference to the ref maps for later resolution.
/datum/persistence/serializer/save/proc/add_thing_reference(var/T, var/index)
	var/type
	if(islist(T))
		type = "/list"
	else
		var/datum/D = T
		type = D.type

	var/list/ref_map = thing_ref_map[type]
	if(!ref_map)
		ref_map = list()
		thing_ref_map[type] = ref_map
	ref_map[T] = index

// Get a cached reference index for a thing already serialized.
/datum/persistence/serializer/save/proc/get_thing_index(var/T)
	var/type
	if(islist(T))
		type = "/list"
	else
		var/datum/D = T
		type = D.type
	
	var/list/ref_map = thing_ref_map[type]
	if(!ref_map)
		return
	return ref_map[T]
		
// This is called when we have failed to GetOrSaveThing, meaning the Thing is not yet serialized.
/datum/persistence/serializer/save/proc/serialize_thing(var/T)
	//T.before_save()
	// Create the thing. First determine what it is.
	var/thing_id = 0
	if(istype(T, /datum))
		var/datum/D = T
		// Before save preparation.
		D.before_save()

		// Begin saving the thing.
		thing_id = Q.AddThing(D.type)
		add_thing_reference(D, thing_id) // To resolve recursive references

		var/list/saved_vars = get_saved_vars(D) // What we're saving
		var/foo = jointext(saved_vars, ", ")
		//to_world("saving datum [D.type], vars: [foo]")
		for(var/V in saved_vars)
			var/thing_type
			var/thing_value

			// Guard check. Don't bother saving things with a default value
			if(D.vars[V] == initial(D.vars[V]))
				continue
			// Guard check. Ignore deleted datums.
			if(istype(D.vars[V], /datum))
				var/datum/D2 = D.vars[V]
				// Guard check. Don't save it if it says not to.
				if(!D2.should_save())
					continue
				// Try to fetch the datum, in case it's already been serialized.
				thing_value = "thing/[GetOrSaveThing(D2)]"
				thing_type = D2.type
			// Guard check. Skip empty lists.
			else if(islist(D.vars[V]))
				var/list/L2 = D.vars[V]
				if(!L2.len)
					continue
				// Try to fetch the list if it's somehow already been serialized.
				thing_value = "list/[GetOrSaveThing(L2)]"
				thing_type = "/list"
			else
				thing_value = "[D.vars[V]]"
				thing_type = "basic"
			// Passed the tests. Save the thing as a variable on the master thing.
			Q.AddThingVar(thing_id, thing_type, V, thing_value)
		// After save cleanup.
		D.after_save()
	else if(islist(T))
		var/list/L = T // cast to list

		thing_id = Q.AddThing("/list")		
		add_thing_reference(L, thing_id)

		for(var/item in L)
			if(istype(item, /datum))
				var/datum/D = item
				// Guard check. Don't save it if it says not to.
				if(!D.should_save)
					continue
				Q.AddThingListVar(thing_id, D.type, "thing/[GetOrSaveThing(D)]")
			else if(istype(item, /list))
				var/list/L2 = item
				if(!L2.len)
					continue
				Q.AddThingListVar(thing_id, "/list", "list/[GetOrSaveThing(L2)]")
			else
				Q.AddThingListVar(thing_id, "basic", "[item]")
	else
		crash_with("SerializeThing was passed a basic data value? Stahp.")
		return

	//T.after_save()
	return thing_id

