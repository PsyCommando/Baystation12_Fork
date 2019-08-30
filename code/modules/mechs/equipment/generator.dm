/obj/item/mech_equipment/generator
	name = "exo-pacman reactor"
	desc = "An exosuit module that generates power using uranium as fuel. Pollutes the environment."
	icon_state = "tesla"
	restricted_hardpoints = list(HARDPOINT_BACK)
	var/obj/machinery/power/port_gen/pacman/mounted/generator = null

/obj/item/mech_equipment/generator/Initialize()
	. = ..()
	generator = new /obj/machinery/power/port_gen/pacman/mounted(src)
	generator.forceMove(src)


/obj/item/mech_equipment/generator/Destroy()
	QDEL_NULL(generator)
	. = ..()


/obj/item/mech_equipment/generator/attack_self(var/mob/user)
	. = ..()
	if(.)
		generator.ui_interact(user)
		if(generator.active)
			active_power_usage = generator.power_gen * generator.power_output * -1
		else
			active_power_usage = 0

/obj/machinery/power/port_gen/pacman/mounted
	name = "\improper mounted pacman generator"
	density = 0
	anchored = 0
	idle_power_usage = 0
	active_power_usage = 0
	interact_offline = TRUE
	stat_immune = NOPOWER

/obj/machinery/power/port_gen/pacman/mounted/ui_interact(var/mob/user, var/ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = GLOB.mech_state)
	. = ..()

/obj/machinery/power/port_gen/pacman/mounted/nano_host()
	var/obj/item/mech_equipment/gnerator/S = loc
	if(istype(S))
		return S.owner
	return null

/obj/machinery/power/port_gen/pacman/mounted/attackby(var/obj/item/O, var/mob/user)
	if(istype(O, sheet_path))
		var/obj/item/stack/addstack = O
		var/amount = min((max_sheets - sheets), addstack.amount)
		if(amount < 1)
			to_chat(user, "<span class='notice'>The [src.name] is full!</span>")
			return
		to_chat(user, "<span class='notice'>You add [amount] sheet\s to the [src.name].</span>")
		sheets += amount
		addstack.use(amount)
		updateUsrDialog()
		return