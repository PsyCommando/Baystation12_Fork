/datum/admins/proc/savenow()
	set category = "Server"
	set desc="Saves Station"
	set name="Save Station"

	if(!check_rights(R_ADMIN))
		return
	SSautosave.Save()