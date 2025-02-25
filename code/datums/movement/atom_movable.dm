// Static movement denial
/datum/movement_handler/no_move/MayMove()
	return MOVEMENT_STOP

// Anchor check
/datum/movement_handler/anchored/MayMove()
	return host.anchored ? MOVEMENT_STOP : MOVEMENT_PROCEED

// Movement relay
/datum/movement_handler/move_relay/DoMove(direction, mover)
	var/atom/movable/AM = host.loc
	if(!istype(AM))
		return
	. = AM.DoMove(direction, mover, FALSE)
	if(!(. & MOVEMENT_HANDLED) && !(direction & (UP|DOWN)))
		AM.relaymove(mover, direction)
	return MOVEMENT_HANDLED

// Movement delay
/datum/movement_handler/delay
	VAR_PROTECTED/delay = 1
	VAR_PROTECTED/next_move

/datum/movement_handler/delay/New(host, delay)
	..()
	src.delay = max(1, delay)

/datum/movement_handler/delay/DoMove()
	next_move = world.time + delay

/datum/movement_handler/delay/MayMove()
	return world.time >= next_move ? MOVEMENT_PROCEED : MOVEMENT_STOP

/datum/movement_handler/delay/proc/SetDelay(delay)
	next_move = max(next_move, world.time + delay)

/datum/movement_handler/delay/proc/AddDelay(delay)
	next_move += max(0, delay)

// Relay self
/datum/movement_handler/move_relay_self/DoMove(direction, mover)
	host.relaymove(mover, direction)
	return MOVEMENT_HANDLED
