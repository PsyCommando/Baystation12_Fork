
/datum/small_business
	var/name = "" // can should never be changed and must be unique
	var/list/stock_holders = list() // Format list("real_name" = numofstocks) adding up to 100
	var/list/employees = list() // format list("real_name" = employee_data)

	//var/datum/NewsFeed/feed

	//var/datum/money_account/central_account

	var/ceo_name = ""
	var/ceo_payrate = 100
	var/ceo_title
	var/ceo_dividend = 0

	var/stock_holders_dividend = 0


	var/list/debts = list() // format list("Ro Laren" = "550") real_name = debt amount
	var/list/unpaid = list() // format list("Ro Laren" = numofshifts)

	var/list/connected_laces = list()

	var/tasks = ""
	var/sales_short = 0

	var/list/sales_long = list() // sales over the last 6 active hours
	var/list/proposals = list()
	var/list/proposals_old = list()

	var/tax_network = ""
	var/last_id_print = 0
	var/last_expense_print = 0
	var/last_balance = 0
	var/status = 1 // 1 = opened, 0 = closed

/datum/small_business/New()
	//central_account = create_account(name, 0)
	// feed = new()
	// feed.name = name
	// feed.parent = src

/datum/small_business/proc/get_debt()
	var/debt = 0
	for(var/x in debts)
		debt += text2num(debts[x])
	return debt

/datum/small_business/proc/pay_debt()
	//for(var/x in debts)
		//var/debt = text2num(debts[x])
		//if(!money_transfer(central_account,x,"Postpaid Payroll",debt))
		//	return 0
		//debts -= x

/datum/small_business/proc/get_employee_data(var/real_name)
	if(real_name in employees)
		var/datum/employee_data/employee = employees[real_name]
		return employee
	return 0

/datum/small_business/proc/is_employee(var/real_name)
	if(real_name in employees)
		return 1
	return 0

/datum/small_business/proc/add_employee(var/real_name)
	if(real_name in employees)
		return 0
	var/datum/employee_data/employee = new()
	employee.name = real_name
	employees[real_name] = employee
	return 1

/datum/small_business/proc/get_access(var/real_name)
	if(real_name in employees)
		var/datum/employee_data/employee = employees[real_name]
		return employee.accesses
	return 0

/datum/small_business/proc/has_access(var/real_name, access)
	if(real_name == ceo_name) return 1
	if(real_name in employees)
		var/datum/employee_data/employee = employees[real_name]
		if(access in employee.accesses)
			return 1
	return 0

/proc/get_business(var/name)
	var/datum/small_business/found_faction
	for(var/datum/small_business/fac in GLOB.all_business)
		if(fac.name == name)
			found_faction = fac
			break
	return found_faction

/proc/get_businesses(var/real_name)
	var/list/lis = list()
	//for(var/datum/small_business/fac in GLOB.all_business)
		//if(fac.is_allowed(real_name)) lis |= fac
	return lis