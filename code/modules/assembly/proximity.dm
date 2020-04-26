/obj/item/device/assembly/prox_sensor
	name = "proximity sensor"
	desc = "Used for scanning and alerting when someone enters a certain proximity."
	icon_state = "prox"
	origin_tech = list(TECH_MAGNET = 1)
	matter = list(DEFAULT_WALL_MATERIAL = 800, "glass" = 200, "waste" = 50)
	flags = PROXMOVE
	wires = WIRE_PULSE

	secured = 0

	var/scanning = 0
	var/timing = 0
	var/time = 10

	var/range = 2

/obj/item/device/assembly/prox_sensor/activate()
	if(!..())
		return FALSE
	timing = !timing
	update_icon()
	return FALSE

/obj/item/device/assembly/prox_sensor/toggle_secure()
	secured = !secured
	if(secured)
		START_PROCESSING(SSobj, src)
	else
		scanning = 0
		timing = 0
		STOP_PROCESSING(SSobj, src)
	update_icon()
	return secured

/obj/item/device/assembly/prox_sensor/HasProximity(atom/movable/AM as mob|obj)
	if(!istype(AM))
		log_debug("DEBUG: HasProximity called with [AM] on [src] ([usr]).")
		return
	if (istype(AM, /obj/effect/beam))
		return
	if (!isobserver(AM) && AM.move_speed < 12)
		sense()

/obj/item/device/assembly/prox_sensor/proc/sense()
	if((!holder && !secured) || !scanning || !process_cooldown())
		return FALSE
	var/turf/mainloc = get_turf(src)
	pulse(0)
	if(!holder)
		mainloc.visible_message("[bicon(src)] *beep* *beep*", "*beep* *beep*")

/obj/item/device/assembly/prox_sensor/process()
	if(scanning)
		var/turf/mainloc = get_turf(src)
		for(var/mob/living/A in range(range,mainloc))
			if (A.move_speed < 12)
				sense()

	if(timing && (time >= 0))
		time--
	if(timing && time <= 0)
		timing = 0
		toggle_scan()
		time = initial(time)

/obj/item/device/assembly/prox_sensor/dropped()
	sense()

/obj/item/device/assembly/prox_sensor/proc/toggle_scan()
	if(!secured)
		return FALSE
	scanning = !scanning
	update_icon()

/obj/item/device/assembly/prox_sensor/update_icon()
	cut_overlays()
	LAZYCLEARLIST(attached_overlays)
	if(timing)
		add_overlay("prox_timing")
		LAZYADD(attached_overlays, "prox_timing")
	if(scanning)
		add_overlay("prox_scanning")
		LAZYADD(attached_overlays, "prox_scanning")
	if(holder)
		holder.update_icon()
	if(holder && istype(holder.loc,/obj/item/weapon/grenade/chem_grenade))
		var/obj/item/weapon/grenade/chem_grenade/grenade = holder.loc
		grenade.primed(scanning)

/obj/item/device/assembly/prox_sensor/Moved(atom/old_loc, direction, forced = FALSE)
	. = ..()
	sense()

/obj/item/device/assembly/prox_sensor/interact(mob/user as mob)//TODO: Change this to the wires thingy
	if(!secured)
		user.show_message("<font color='red'>The [name] is unsecured!</font>")
		return 0
	var/second = time % 60
	var/minute = (time - second) / 60
	var/dat = text("<TT><B>Proximity Sensor</B>\n[] []:[]\n<A href='?src=\ref[];tp=-30'>-</A> <A href='?src=\ref[];tp=-1'>-</A> <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=30'>+</A>\n</TT>", (timing ? text("<A href='?src=\ref[];time=0'>Arming</A>", src) : text("<A href='?src=\ref[];time=1'>Not Arming</A>", src)), minute, second, src, src, src, src)
	dat += text("<BR>Range: <A href='?src=\ref[];range=-1'>-</A> [] <A href='?src=\ref[];range=1'>+</A>", src, range, src)
	dat += "<BR><A href='?src=\ref[src];scanning=1'>[scanning?"Armed":"Unarmed"]</A> (Movement sensor active when armed!)"
	dat += "<BR><BR><A href='?src=\ref[src];refresh=1'>Refresh</A>"
	dat += "<BR><BR><A href='?src=\ref[src];close=1'>Close</A>"
	user << browse(dat, "window=prox")
	onclose(user, "prox")

/obj/item/device/assembly/prox_sensor/Topic(href, href_list, state = deep_inventory_state)
	if(..())
		return TRUE
	
	if(!usr.canmove || usr.stat || usr.restrained() || !in_range(loc, usr))
		usr << browse(null, "window=prox")
		onclose(usr, "prox")
		return

	if(href_list["scanning"])
		toggle_scan()

	if(href_list["time"])
		timing = text2num(href_list["time"])
		update_icon()

	if(href_list["tp"])
		var/tp = text2num(href_list["tp"])
		time += tp
		time = min(max(round(time), 0), 600)

	if(href_list["range"])
		var/r = text2num(href_list["range"])
		range += r
		range = min(max(range, 1), 5)

	if(href_list["close"])
		usr << browse(null, "window=prox")
		return

	if(usr)
		attack_self(usr)
