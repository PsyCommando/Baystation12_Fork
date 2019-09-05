/datum/persistence/serializer
	var/datum/persistence/query_builder/Q

/datum/persistence/serializer/New(var/datum/persistence/query_builder/qb)
	Q = qb

/datum/persistence/serializer/save
	var/list/thing_ref_map = list() // Used as a map for fixing recursive references (for datums and lists).
	var/list/area_ref_map = list() // Used as a map for fixing recursive references (for areas specifically)

/datum/persistence/serializer/load
	var/list/resolved_things = list() // Used as a map to resolve indexes (ints) into objects.

/datum/persistence/serializer/load/proc/get_or_load_thing(var/index)
	var/T = resolved_things[index]
	if(T)
		return T
	
	// It is not resolved. So resolve it.
	T = deserialize_thing(index)
	return T

/datum/persistence/serializer/save/proc/get_or_save_thing(var/T)
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
			// Guard check. Don't bother saving things with a default value
			if(D.vars[V] == initial(D.vars[V]))
				continue
			serialize_thing_var(thing_id, D.vars[V], V)
		// After save cleanup.
		D.after_save()
	else if(islist(T))
		var/list/L = T // cast to list
		thing_id = Q.AddThing("/list")		
		add_thing_reference(L, thing_id)

		var/index = 1
		for(var/item in L)
			if(istype(L[item], null))
				serialize_thing_var(thing_id, L[item], item, TRUE)
			else
				serialize_thing_var(thing_id, item, index, TRUE)
			index++
	else
		crash_with("SerializeThing was passed a basic data value? Stahp.")
		return

	return thing_id

/datum/persistence/serializer/save/proc/serialize_thing_var(var/thing_id, var/V, var/var_name = "", var/is_list = FALSE)
	if(istype(V, /weakref))
		var/weakref/W = V
		var/ref = W.resolve()
		var/thing = serialize_thing(ref)
		serialize_thing_var(thing_id, thing, is_list)
	// Guard check. Ignore deleted datums.
	else if(istype(V, /datum))
		var/datum/D = V
		// Guard check. Don't save it if it says not to.
		if(!D.should_save())
			return
		// Add datum as an element to the thing.
		if(is_list)
			Q.AddThingListVar(thing_id, D.type, var_name, get_or_save_thing(D))
		else 
			Q.AddThingVar(thing_id, D.type, var_name, get_or_save_thing(D))
	// Guard check. Skip empty lists.
	else if(islist(V))
		var/list/L = V
		if(!L.len)
			return

		if(is_list)
			Q.AddThingListVar(thing_id, "/list", var_name, get_or_save_thing(L))
		else
			Q.AddThingVar(thing_id, "/list", var_name, get_or_save_thing(L))
	else
		var/basic_type = "anomalous"
		if(istype(V, null))
			return // Do not serialize nulls.
		else if(isnum(V))
			basic_type = "number"
		else if(istext(V))
			basic_type = "text"
		if(is_list)
			Q.AddThingListVar(thing_id, basic_type, var_name, V)
		else
			Q.AddThingVar(thing_id, basic_type, var_name, V)

/datum/persistence/serializer/load/proc/deserialize_thing(var/index)
	establish_db_connection()
	if(!dbcon.IsConnected())
		crash_with("Unable to execute db save query. No connection with database? Check MySQL connection details.")
	var/DBQuery/query = dbcon.NewQuery("SELECT `type` FROM `thing` WHERE `id`=[index] AND `version`=[Q.version];")
	query.Execute()
	query.NextRow()

	var/thing_type = text2path(query.item[1])
	if(!thing_type)
		crash_with("Unable to decode thing type of [query.item[1]]. Aborting deserialization.")
		return
	
	world.log << "Deserializing [thing_type]"

	query = dbcon.NewQuery("SELECT `type`,`name`,`value` FROM `thing_var` WHERE `thing_id`=index AND `version`=[Q.version];")
	query.Execute()

	// thing instance
	var/T
	if(istype(thing_type, /turf))
		// first need to pull XYZ.
		var/x = -1
		var/y = -1
		var/z = -1
		while(query.NextRow())
			if(query.item[2] == "x")
				x = text2num(query.item[3])
			else if(query.item[2] == "y")
				y = text2num(query.item[3])
			else if(query.item[2] == "z")
				z = text2num(query.item[3])
		
		if(x < 0 || y < 0 || z < 0)
			crash_with("Unable to find x,y,z coordinates for turf. Aborting deserialization.")
			return

		// special nonsense with turfs
		T = new thing_type(locate(x, y, z))
		world.log << "Deserialized turf @ [x],[y],[z]"
		// Reset the query reader and do the deserialization properly.
		query.Execute()
	else if(istype(thing_type, /datum) || islist(thing_type))
		T = new thing_type()
	else
		// No idea what this is.
		crash_with("Unable to figure out how to handle type [thing_type]. Aborting deserialization.")
		return
	
	// Cache the new reference.
	resolved_things[index] = T

	// Deserialize all variables.
	if(islist(T))
		var/list/L = T
		// lists are special, and have their own execution path..
		query = dbcon.NewQuery("SELECT `type`,`value` FROM `thing_list_var` WHERE `thing_id`=[index] AND `version`=[Q.version];")
		query.Execute()

		while(query.NextRow())
			if(query.item[1] == "basic")
				L += query.item[2]
				continue
			
			var/element_type = text2path(query.item[1])	
			if(istype(element_type, /datum) || islist(element_type))
				var/thing_index = text2num(query.item[2])
				L += get_or_load_thing(thing_index)
			else
				crash_with("I don't know what [element_type] is. List deserialization failed.")
				continue
	else
		while(query.NextRow())
			if(query.item[1] == "basic")
				T[query.item[2]] = query.item[3]
			else if(query.item[1] == "/list" || query.item[1] == "/thing")
				// value will be the index.
				var/thing_index = text2num(query.item[3])
				T[query.item[2]] = get_or_load_thing(thing_index)
			else
				crash_with("Unable to figure out what [query.item[1]] is for [index]. Variable [query.item[2]], value: [query.item[3]]")
	return T
	
