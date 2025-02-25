/obj/item/projectile/spell_projectile
	name = "spell"
	icon = 'icons/obj/projectiles.dmi'

	nodamage = TRUE

	var/spell/targeted/projectile/carried

	penetrating = 0
	life_span = 10 //set by the duration of the spell

	var/proj_trail = 0 //if it leaves a trail
	var/proj_trail_lifespan = 0 //deciseconds
	var/proj_trail_icon = 'icons/obj/cult.dmi'
	var/proj_trail_icon_state = "trail"
	var/list/trails = new()

/obj/item/projectile/spell_projectile/Destroy()
	for(var/trail in trails)
		qdel(trail)
	carried = null
	return ..()

/obj/item/projectile/spell_projectile/ex_act()
	return

/obj/item/projectile/spell_projectile/before_move()
	if(proj_trail && src && src.loc) //pretty trails
		var/obj/overlay/trail = new /obj/overlay(loc)
		trails += trail
		trail.icon = proj_trail_icon
		trail.icon_state = proj_trail_icon_state
		trail.set_density(0)
		spawn(proj_trail_lifespan)
			trails -= trail
			qdel(trail)

/obj/item/projectile/spell_projectile/proc/prox_cast(list/targets)
	if(loc)
		carried.prox_cast(targets, src)
		qdel(src)
	return

/obj/item/projectile/spell_projectile/Bump(atom/A, called)
	if(loc && carried)
		prox_cast(carried.choose_prox_targets(user = carried.holder, spell_holder = src))
	return 1

/obj/item/projectile/spell_projectile/on_impact()
	if(loc && carried)
		prox_cast(carried.choose_prox_targets(user = carried.holder, spell_holder = src))
	return 1

/obj/item/projectile/spell_projectile/seeking
	name = "seeking spell"
