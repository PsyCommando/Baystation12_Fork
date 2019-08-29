GLOBAL_RAW(/list/datum/world_faction/all_world_factions);GLOBAL_UNMANAGED(all_world_factions, null); //Don't init as empty list, because it happens too late during init
GLOBAL_LIST_EMPTY(all_business)

GLOBAL_LIST_EMPTY(recent_articles)

/proc/get_faction(var/name, var/password)
	if(password)
		var/datum/world_faction/found_faction
		for(var/datum/world_faction/fac in GLOB.all_world_factions)
			if(fac && fac.uid == name)
				found_faction = fac
				break
		if(!found_faction) return
		if(found_faction.password != password) return
		return found_faction
	var/datum/world_faction/found_faction
	for(var/datum/world_faction/fac in GLOB.all_world_factions)
		if(fac && fac.uid == name)
			found_faction = fac
			break
	return found_faction

/proc/get_faction_tag(var/name)
	var/datum/world_faction/fac = get_faction(name)
	if(fac)
		return fac.short_tag
	else
		return "ANOMALOUS"

/datum/world_faction/proc/get_leadername()
	return leader_name

/datum/world_faction/proc/open_business()
	status = 1

/datum/world_faction/proc/get_members()
	var/list/members = list()
	//var/list/contracts = GLOB.contract_database.get_contracts(src.uid, CONTRACT_BUSINESS)
	//for(var/datum/recurring_contract/contract in contracts)
	//	if(contract.payee_cancelled || contract.payee_completed|| contract.payer_cancelled || contract.payer_completed)
	//		continue
	//	if(contract.func == CONTRACT_SERVICE_MEMBERSHIP)
	//		members |= contract
	return members

/datum/world_faction
	var/name = "" // can be safely changed
	var/abbreviation = "" // can be safely changed
	var/short_tag = "" // This can be safely changed as long as it doesn't conflict
	var/purpose = "" // can be safely changed
	var/uid = "" // THIS SHOULD NEVER BE CHANGED!
	var/password = "password" // this is used to access the faction, can be safely changed
	var/list/assignment_categories = list()
	var/list/access_categories = list()
	var/list/all_access = list() // format list("10", "11", "12", "13") used to determine which accesses are already given out.
	var/list/all_assignments
	var/datum/records_holder/records
	var/datum/ntnet/network
	//var/datum/money_account/central_account
	var/allow_id_access = 0 // allows access off the ID (the IDs access var instead of directly from faction records, assuming its a faction-approved ID
	var/allow_unapproved_ids = 0 // **THIS VAR NO LONGER MATTERS IDS ARE ALWAYS CONSIDERED APPROVED** allows ids that are not faction-approved or faction-created to still be used to access doors IF THE registered_name OF THE CARD HAS VALID RECORDS ON FILE or allow_id_access is set to 1
	var/list/connected_laces = list()

	var/all_promote_req = 3
	var/three_promote_req = 2
	var/five_promote_req = 1

	var/payrate = 100
	var/leader_name = ""
	var/list/debts = list() // format list("Ro Laren" = "550") real_name = debt amount
	var/joinable = 0

	var/list/cargo_telepads = list()
	var/list/approved_orders = list()
	var/list/pending_orders = list()

	var/list/cryo_networks = list() // "default" is always a cryo_network

	var/list/unpaid = list()

	var/tax_rate = 10
	var/import_profit = 10
	var/export_profit = 20

	var/hiring_policy = 0 // if hiring_policy, anyone with reassignment can add people to the network, else only people in command a command category with reassignment can add people
	var/last_expense_print = 0

	var/list/reserved_frequencies = list() // Reserved frequencies that the faction can create encryption keys from.

	//var/datum/machine_limits/limits

	var/datum/faction_research/research

	var/status = 1

	var/list/employment_log = list()

	var/objective = ""

	//var/datum/material_inventory/inventory

	//var/obj/machinery/telepad_cargo/default_telepad
	var/default_telepad_x
	var/default_telepad_y
	var/default_telepad_z
	//var/decl/hierarchy/outfit/starter_outfit = /decl/hierarchy/outfit/nexus/starter //Outfit members of this faction spawn with by default

	var/list/service_medical_business = list() // list of all organizations linked into the medical service for this business

	var/list/service_medical_personal = list() // list of all people linked int othe medical service for this business

	var/list/service_security_business = list() // list of all orgs linked to the security services

	var/list/service_security_personal = list() // list of all people linked to the security services

	//var/datum/NewsFeed/feed
	//var/datum/LibraryDatabase/library

	var/list/people_to_notify = list()

/datum/faction_research
	var/points = 0
	var/list/unlocked = list()
	map_storage_saved_vars = "points;unlocked"

/datum/world_faction/proc/get_assignment(var/assignment, var/real_name)
	if(!assignment) return null
	rebuild_all_assignments()
	for(var/datum/assignment/assignmentt in all_assignments)
		if(assignmentt.uid == assignment) return assignmentt

/datum/world_faction/proc/get_records()
	return records.faction_records

/datum/world_faction/proc/get_record(var/real_name)
	for(var/datum/computer_file/report/crew_record/R in records.faction_records)
		if(R.get_name() == real_name)
			return R
	var/datum/computer_file/report/crew_record/L = Retrieve_Record_Faction(real_name, src)
	return L

/datum/world_faction/proc/rebuild_all_access()
	all_access = list()
	var/datum/access_category/core/core = new()
	for(var/datum/access_category/access_category in access_categories+core)
		for(var/x in access_category.accesses)
			all_access |= x

/datum/world_faction/proc/rebuild_all_assignments()
	all_assignments = list()
	for(var/datum/assignment_category/assignment_category in assignment_categories)
		for(var/x in assignment_category.assignments)
			all_assignments |= x