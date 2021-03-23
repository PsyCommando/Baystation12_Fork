/***********************************************
	Standard damage handling for objects
***********************************************/
/obj
	var/stat					//State flag, shared with machines stat
	var/health					//Current health
	var/max_health				//Maximum health
	var/broken_threshold		//Below this health threshold the object will be considered broken
	var/melt_point = 500		//Temperature in K at which this object may spontaneously melt/dust
	var/burn_damage = 4			//Default maximum rate at which the object may burn

	//Resistance
	var/list/armor				//Armor values for the object

	//Effects
	var/sound_destroyed			//Sound to play when the object is destroyed
	var/sound_melted			//Sound to play when the object is melted
	var/sound_hit				//Sound to play when the object is hit by something

	var/destroyed_verbs			//The verbs that are used when describing the object being destroyed (Can be a list or a string)
	var/melt_verbs				//The verbs that are used when describing the object being melted (Can be a list or a string)
	var/broken_verbs			//The verbs that are used when describing the object being broken (Can be a list or a string)
	var/repaired_verbs			//The verbs that are used when describing the object being repaired (Can be a list or a string)

/obj/Initialize()
	. = ..()
	if(armor)
		set_extension(src, /datum/extension/armor, armor)

/obj/InitDefaultValues()
	. = ..()
	//If the health var wasn't set to something already, set it to max health
	if(!health)
		health = max_health

//--------------------------------------------
//	Damage Calculation
//--------------------------------------------
//Since some things are immune to several of the existing damage types, this proc allows us to determine that
/obj/proc/is_vulnerable_to(var/damage_type, var/damflags)
	return damtype == BRUTE || damtype == BURN

//--------------------------------------------
// Interactions
//--------------------------------------------
/obj/proc/damage_description(var/mob/user)
	if(!is_damaged())
		return SPAN_NOTICE("It looks fully intact.")
	else
		var/perc = health_percentage()
		if(perc > 75)
			return SPAN_NOTICE("It has a few scratches.")
		else if(perc > 50)
			return SPAN_WARNING("It looks slightly damaged.")
		else if(perc > 25)
			return SPAN_NOTICE("It looks moderately damaged.")
		else
			return SPAN_DANGER("It looks heavily damaged.")
	if(is_broken())
		return SPAN_WARNING("It seems broken.")

/obj/examine(mob/user, distance)
	. = ..()
	if(!is_damageable())
		to_chat(user, damage_description(user))

/obj/attack_generic(var/mob/user, var/damages, var/attack_verb, var/environment_smash = FALSE, var/damtype = BRUTE, var/damflags = 0)
	var/applied_damage = apply_damage(damages, damtype, null, damflags, 0, user)
	if(applied_damage)
		visible_message(SPAN_DANGER("\The [user] [attack_verb] into \the [src]!"))
	else
		visible_message(SPAN_NOTICE("\The [user] bonks \the [src] harmlessly."))
	return 1

/obj/attackby(obj/item/I, mob/user)
	if(istype(I))
		I.attack(src, user, user.zone_sel.selecting)
		return
	//The code in atom/movable/attackby is causing more trouble than it solves.. AKA, prints messages to chat, when there's no actual damage being done

/obj/ex_act(var/severity)
	if(!is_damageable() || severity > 0)
		return
	switch(severity)
		if(1)
			break_apart(TRUE, TRUE) //insta-destroyed, with no text or sound plz
		else
			take_damage(max_health/severity, BRUTE, DAM_EXPLODE, 0, "explosion", TRUE) //Don't spam text

/obj/fire_act(var/datum/gas_mixture/air, var/exposed_temperature, var/exposed_volume)
	if(!is_damageable())
		return
	if(exposed_temperature >= melt_point)
		//The closer to the melt point, the more damage it'll take
		var/temp_damage = between(0.1, round((exposed_temperature * 100 / melt_point) * burn_damage, 0.1), burn_damage)
		take_damage(temp_damage, BURN, used_weapon = "fire", silent = TRUE)

/obj/lava_act()
	if(!is_damageable())
		return
	. = ..()

//--------------------------------------------
// Projectile Hits Stuff
//--------------------------------------------
/obj/hitby(atom/movable/AM, var/datum/thrownthing/TT)
	. = ..()
	//Most damage handling was moved to the throw_impact proc of the thrown object instead. Since we avoid a whole lot of casts

//When we hit something
//Its better to handle the damage's specifics in the object making the attack in this case
// since otherwise we have to do a lot of superfluous casting to do the same thing in the receiving atom's hitby() proc.
/obj/throw_impact(var/atom/hit_atom, var/datum/thrownthing/TT)
	//Handle miss chance
	if (prob( max(15*(TT.dist_travelled-2),0) ))
		visible_message(SPAN_NOTICE("\The [src] misses [hit_atom] narrowly!"))
		return

	//Call hitby
	. = ..()

	if(sound_hit)
		playsound(hit_atom, sound_hit, 90, TRUE)
	//transfer some damages
	apply_damage(throwforce * (TT.speed * mass), damage_type, TT.target_zone, damage_flags(), src, armor_penetration)
	//Handle embeding projectiles
	if(can_embed())
		hit_atom.embed_check(src, TT)
	//Handle Knockback
	if(!anchored)
		hit_atom.knockback_check(src, TT)

//Since bullets don't directly apply damages, only effects, we have to apply it ourselves
/obj/bullet_act(var/obj/item/projectile/P, var/def_zone, var/silent = FALSE)
	. = ..()
	apply_damage(P.force, P.damage_type, hit_zone, P.damage_flags(), P, P.armor_penetration, silent)

/obj/get_bullet_impact_effect_type()
	return BULLET_IMPACT_METAL

//--------------------------------------------
// Misc Accessors
//--------------------------------------------
/obj/proc/add_health(var/added, var/silent = FALSE)
	set_health(health + added, silent = silent)

/obj/proc/rem_health(var/removed, var/damtype = null, var/damflags = 0, var/silent = FALSE)
	if(health == 0) //Don't bother if our health is at 0 already
		return
	set_health(health - removed, damtype, damflags, silent)

//Changes the health of the object and runs the update_health proc
//The damagetype and flags passed are used by update_health to figure out the kind of destruction effect to do if the object is destroyed by new health value
/obj/proc/set_health(var/health, var/damtype = null, var/damflags = 0, var/silent = FALSE)
	src.health = between(0, round(newhealth, 0.1), max_health)
	update_health(damtype, damflags, silent)

//Changes the maximum health of the object and runs the update_health proc
/obj/proc/set_max_health(var/max_health, var/silent = FALSE)
	src.max_health = max_health
	update_health(silent = silent) //Since the value changed, re-check our health

//Returns the damages the object took so far
/obj/proc/get_damages()
	return maxhealth - health

//The minimum health is not included in this.
/obj/proc/health_percentage()
	if(!is_damageable())
		return 100
	if(max_health != 0)
		return health * 100 / max_health
	else
		return 0

//Whether the object's health is past the broken threshold
/obj/proc/is_broken()
	return stat & BROKEN

//For things that stick around when destroyed
/obj/proc/is_destroyed()
	return stat & DESTROYED

//Whether object can be damaged/destroyed
/obj/proc/is_damageable()
	return !(obj_flags & OBJ_FLAG_NODAMAGE)

//Returns whether the object is damaged or not
/obj/proc/is_damaged()
	return  health < max_health

//--------------------------------------------
// State Handling
//--------------------------------------------

//Called after each changes to the health var
//The last_damtype and last_damflags are used to figured out what destruction proc to call when the thing is destroyed
//silent suppress text output to mobs in view range
/obj/proc/update_health(var/last_damtype = BRUTE, var/last_damflags = 0, var/silent = FALSE)
	if(health <= 0)
		on_destruction(last_damtype, last_damflags, silent)
		return
	if(!(stat & BROKEN))
		if(health <= broken_threshold)
			on_broken(last_damtype, last_damflags, silent) //Should run exactly once after the health goes under the threshold
	else if(health > broken_threshold)
		on_repaired(silent) //Should run exactly once after the health goes above the broken threshold

//Handles effects when health reaches 0
/obj/proc/on_destruction(var/last_damtype = BRUTE, var/last_damflags = 0, var/silent = FALSE)
	health = 0
	stat |= DESTROYED
	if(last_damtype == BURN)
		melt(silent)
	else
		break_apart(silent)

//Handles effects when health goes below broken_threshold
/obj/proc/on_broken(var/last_damtype = BRUTE, var/last_damflags = 0, var/silent = FALSE)
	stat |= BROKEN

//Handles effects when health goes back above broken_threshold
/obj/proc/on_repaired(var/silent = FALSE)
	stat = stat & (~DESTROYED) //Don't clear before repair threshold, or it could result in weirdness
	stat = stat & (~BROKEN)

//--------------------------------------------
// Destruction Effects
//--------------------------------------------
//Called when the object is destroyed by burn damage
/obj/melt(var/silent = FALSE, var/nosound = FALSE)
	if(!nosound && sound_melted)
		playsound(loc, sound_melted, vol=70, vary=TRUE, extrarange=10, falloff=5)
	if(!silent)
		visible_message(SPAN_WARNING("\The [src] [melted_verbs? pick(melted_verbs) : "melted away"]!"))
	qdel(src)

//Called when the object is destroyed by non-burn damage
/obj/proc/break_apart(var/silent = FALSE, var/nosound = FALSE)
	if(!nosound && sound_destroyed)
		playsound(loc, sound_destroyed, vol=70, vary=TRUE, extrarange=10, falloff=5)
	if(!silent)
		visible_message(SPAN_WARNING("\The [src] [destroyed_verbs? pick(destroyed_verbs) : "breaks appart"]!"))
	qdel(src)


//
// Common with mob procs
//

/obj/hit_with_weapon(var/obj/item/I, var/mob/living/user, var/effective_force = 0, var/hit_zone = null)
	visible_message(SPAN_DANGER("[src] has been [I.attack_verb.len? pick(I.attack_verb) : "attacked"] with [I.name] by [user]!"))
	. = standard_weapon_hit_effects(I, user, effective_force, hit_zone)

/obj/standard_weapon_hit_effects(obj/item/I, mob/living/user, var/effective_force, var/hit_zone)
	if(!effective_force)
		return 0
	//Hulk modifier
	if(MUTATION_HULK in user.mutations)
		effective_force *= 2

	//Apply weapon damage
	return apply_damage(effective_force, I.damage_type, hit_zone, I.damage_flags(), used_weapon=I)

//Standard damage taking proc for most things
/obj/take_damage(var/damages, var/damage_type = BRUTE, var/damage_flags = 0, var/used_weapon = null, var/armor_pen = 0, var/silent = FALSE)
	if(!is_damageable() || !is_vulnerable_to(damage_type, damage_flags))
		return

	//Apply armor datums to our values
	var/list/after_armor = list(damages, damage_type, damage_flags, src, armor_pen, silent)
	for(var/datum/extension/armor/armor_datum/A in get_armors())
		after_armor = A.apply_damage_modifications(arglist(after_armor))

	damages = after_armor[1]
	damage_type = after_armor[2]
	damage_flags = after_armor[3] // args modifications in case of parent calls

	//Apply damage
	rem_health(damages, damage_type, damage_flags, silent)
	. = damages

//
// Atom Overrides
//
//If the atom can be knocked back, do it, otherwise return false
/atom/proc/knockback_check(var/obj/O, var/datum/thrownthing/TT, var/knockback_verb = "knocked around")
	return FALSE

/atom/movable/proc/knockback_check(obj/O, datum/thrownthing/TT, knockback_verb = "knocked around")
	if(anchored)
		return FALSE
	var/momentum = max(0, (TT.speed * O.mass) - mass)
	if(momentum < THROWNOBJ_KNOCKBACK_SPEED)
		return FALSE
	var/dir = TT.init_dir
	visible_message(SPAN_WARNING("\The [src] is [pick(knockback_verb)]!"), SPAN_WARNING("You are [pick(knockback_verb)] by \the [O]!"))
	throw_at(get_edge_target_turf(src, dir), 1, momentum)
	return TRUE

//Generic damage handling proc
/atom/proc/take_damage(var/damages, var/damage_type = BRUTE, var/damage_flags = 0, var/used_weapon = null, var/armor_pen = 0, var/silent = FALSE)
	return 0
//Generic mob damage taking proc
/atom/proc/apply_damage(var/damages, var/damage_type = BRUTE, var/hit_zone = null, var/damage_flags = 0, var/used_weapon = null, var/armor_pen = 0, var/silent = FALSE)
	return take_damage(damages, damage_type, damage_flags, used_weapon, armor_pen, silent)

//Embeds the projectile O if possible, otherwise returns false
/atom/proc/embed_check(var/obj/O, var/datum/thrownthing/TT)
	return FALSE
/atom/proc/embed(var/obj/O, var/def_zone=null, var/datum/wound/supplied_wound = null)
	return FALSE
//Called when the mob is hit with an item in combat. Returns the blocked result
/atom/proc/hit_with_weapon(var/obj/item/I, var/mob/living/user, var/effective_force = 0, var/hit_zone = null)
	return 0
/atom/proc/standard_weapon_hit_effects(var/obj/item/I, var/mob/living/user, var/effective_force = 0, var/hit_zone = null)
	return 0
/atom/proc/resolve_item_attack(obj/item/I, mob/living/user, var/target_zone)
	return target_zone

//Calculates armor blocked ratio for both mobs and objects
/atom/proc/get_blocked_ratio(var/def_zone, var/damage_type = BRUTE, var/damage_flags = 0, var/armor_pen = 0, var/damage = 0)
	var/list/armors = get_armors_by_zone(def_zone, damage_type, damage_flags)
	. = 0
	for(var/armor in armors)
		var/datum/extension/armor/armor_datum = armor
		. = 1 - (1 - .) * (1 - armor_datum.get_blocked(damage_type, damage_flags, armor_pen, damage)) // multiply the amount we let through
	. = min(1, .)

/atom/proc/get_armors_by_zone(var/def_zone, var/damage_type = BRUTE, var/damage_flags = 0)
	. = list()
	var/natural_armor = get_extension(src, /datum/extension/armor)
	if(natural_armor)
		. += natural_armor

//Unarmed attacks are passed as attack_hands
/atom/proc/attack_hand(var/mob/living/carbon/human/user)
	if(!ishuman(user) || user.a_intent != I_HURT)
		return .
	var/datum/unarmed_attack/AT = user.get_unarmed_attack(src)
	if(!AT)
		return .
	var/damages_received = apply_damage(max(1, AT.get_unarmed_damage(H)), AT.get_damage_type(), null, AT.damage_flags(), 0, user)
	AT.show_attack(user, src, null, damages_received)