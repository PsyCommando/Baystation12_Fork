/datum/persistence/query_builder
	var/thing_index = 1
	var/thing_var_index = 1
	var/thing_list_var_index = 1
	var/area_index = 1
	var/version = 1
	var/list/Q = list()

/datum/persistence/query_builder/New(var/V = 1)
	version = V

/datum/persistence/query_builder/proc/AddThing(var/type)
	thing_index++
	Q += "INSERT INTO `thing` (`id`,`type`,`version`) VALUES([thing_index],'[type]',[version])"
	return thing_index

/datum/persistence/query_builder/proc/AddThingVar(var/thing_id, var/type, var/name, var/value)
	thing_var_index++
	var/sname = sql_sanitize_text(name)
	var/svalue = sql_sanitize_text(value)
	Q += "INSERT INTO `thing_var` (`id`, thing_id,`type`,`name`,`value`,`version`) VALUES([thing_var_index],[thing_id],'[type]','[sname]','[svalue]',[version])"
	return thing_var_index

/datum/persistence/query_builder/proc/AddThingListVar(var/thing_id, var/type, var/value)
	thing_list_var_index++
	var/svalue = sql_sanitize_text(value)
	Q += "INSERT INTO `thing_list_var` (`id`, thing_id, `type`, `value`, `version`) VALUES([thing_list_var_index],[thing_id],'[type]','[svalue]',[version])"
	return thing_list_var_index

/datum/persistence/query_builder/proc/AddArea(var/name)
	area_index++
	var/sname = sql_sanitize_text(name)
	Q += "INSERT INTO `area` (`id`,`name`,`version`) VALUES([area_index],'[sname]',[version])"
	return area_index

/datum/persistence/query_builder/proc/AddAreaTurf(var/area_id, var/thing_id, var/pixel_x, var/pixel_y, var/z_layer)
	Q |= "INSERT INTO `area_turf (`area_id`,`thing_id`,`pixel_x`,`pixel_y`,`z_layer`,`version`) VALUES([area_id],[thing_id],[pixel_x],[pixel_y],[z_layer],[version])"

/datum/persistence/query_builder/proc/Execute()
	to_world("executing save query")
	//world.log << jointext(Q, ";")
	try
		establish_db_connection()
		if(!dbcon.IsConnected())
			crash_with("Unable to execute db save query. No connection with database? Check MySQL connection details.")
		var/DBQuery/q = dbcon.NewQuery(jointext(Q, ";"))
		q.Execute()
	catch(var/exception/e)
		to_world("[e] on [e.file]:[e.line]")
	Q = list()

/datum/persistence/query_builder/proc/RefreshIndexes()
	// var/database/query/query = new
	// query.Add("SHOW INDEX FROM thing;")
	// query.Add("SHOW INDEX FROM thing_var;")
	// query.Add("SHOW INDEX FROM thing_list_var;")
	// query.Add("SHOW INDEX FROM area;")
	// query.Execute(D)

	// query.NextRow()
	// thing_index = query.GetColumn(4)
	// query.NextRow()
	// thing_var_index = query.GetColumn(4)
	// query.NextRow()
	// thing_list_var_index = query.GetColumn(4)
	// query.NextRow()
	// area_index = query.GetColumn(4)