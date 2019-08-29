/datum/assignment
	var/name = ""
	var/list/accesses[0]
	var/uid = ""
	var/datum/assignment_category/parent
	var/payscale = 1.0
	var/list/ranks = list() // format-- list("Apprentice Engineer (2)" = "1.1", "Journeyman Engineer (3)" = "1.2")
	var/duty_able = 1
	var/cryo_net = "default"
	var/any_assign = 0 // this makes it so that the assignment can be assigned by anyone with the reassignment access,

	var/task
	var/edit_authority = 1
	var/authority_restriction = 1

/datum/assignment/New(var/title, var/pay)
	if(title && pay)
		var/datum/accesses/access = new()
		access.name = title
		access.pay = pay
		accesses |= access

/datum/assignment/proc/get_title(var/rank)
	if(!rank)	rank = 1
	if(!accesses.len)
		message_admins("broken assignment [src.uid]")
		return "BROKEN"
	if(accesses.len < rank)
		var/datum/accesses/access = accesses[accesses.len]
		return access.name
	else
		var/datum/accesses/access = accesses[rank]
		return access.name

/datum/assignment/after_load()
	..()