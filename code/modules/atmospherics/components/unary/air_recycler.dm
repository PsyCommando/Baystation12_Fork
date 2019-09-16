obj/machinery/atmospherics/unary/air_recycler
	//icon = 'icons/obj/atmospherics/air_recycler.dmi'
	icon = 'icons/obj/atmospherics/oxygen_generator.dmi'
	icon_state = "intact_off"
	density = 1

	name = "Air Recycler"
	desc = ""

	dir = SOUTH
	initialize_directions = SOUTH

	var/on = 0

	var/recycler_efficiency = 10
	//var/oxygen_content = 10

	update_icon()
		if(node)
			icon_state = "intact_[on?("on"):("off")]"
		else
			icon_state = "exposed_off"

			on = 0

		return

	New()
		..()

		air_contents.volume = 80

	Process()
		..()
		if(!on)
			return 0

		var/co2_moles = air_contents.get_gas(GAS_CO2)
		var/extracted_co2 = min(co2_moles, recycler_efficiency)

		if(extracted_co2 <= 0)
			return 1

		var/returned_co = extracted_co2 * 0.66
		var/returned_o2 = extracted_co2 * 0.34

		air_contents.adjust_gas(GAS_OXYGEN, returned_o2, 35)
		air_contents.adjust_gas(GAS_CO, returned_co, 35)
		air_contents.adjust_gas(GAS_CO2, co2_moles - extracted_co2)

		if(network)
			network.update = 1

		return 1