datum/access_category
	var/name = ""
	var/list/accesses = list() // format-- list("11" = "Bridge Access")

/datum/access_category/core
	name = "Core Access"

/datum/access_category/core/New()
	accesses["101"] = "Access & Assignment Control"
	accesses["102"] = "Command Programs"
	accesses["103"] = "Reassignment/Promotion Vote"
	accesses["104"] = "Research Control"
	accesses["105"] = "Engineering Programs"
	accesses["106"] = "Medical Programs"
	accesses["107"] = "Security Programs"
	accesses["108"] = "Shuttle Control"
	accesses["109"] = "Machine Linking"
	accesses["110"] = "Computer Linking"
	accesses["111"] = "Budget View"
	accesses["112"] = "Contract Signing/Control"
	accesses["113"] = "Material Marketplace"