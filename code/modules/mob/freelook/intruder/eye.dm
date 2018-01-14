// Reimplements a lot of the code from mob/eye so that I don't have to fuck with the visualnet code. If you know a better way, please tell me. -WrongEnd
mob/intruder_eye
	name = "Eye"
	icon = 'icons/mob/eye.dmi'
	icon_state = "default-eye"
	alpha = 127
	density = 0

	var/sprint = 10
	var/cooldown = 0
	var/acceleration = 1
	var/owner_follows_eye = 0

	see_in_dark = 7
	status_flags = GODMODE
	invisibility = INVISIBILITY_EYE

	var/mob/owner = null
	var/ghostimage = null

/mob/intruder_eye/New()
	ghostimage = image(src.icon,src,src.icon_state)
	ghost_darkness_images |= ghostimage //so ghosts can see the eye when they disable darkness
	ghost_sightless_images |= ghostimage //so ghosts can see the eye when they disable ghost sight
	updateallghostimages()
	..()

/mob/intruder_eye/Destroy()
	if (ghostimage)
		ghost_darkness_images -= ghostimage
		ghost_sightless_images -= ghostimage
		qdel(ghostimage)
		ghostimage = null
		updateallghostimages()
	return ..()

/mob/intruder_eye/Move(n, direct)
	if(owner == src)
		return EyeMove(n, direct)
	return 0

/mob/intruder_eye/airflow_hit(atom/A)
	airflow_speed = 0
	airflow_dest = null

/mob/intruder_eye/pointed()
	return 0


// Use this when setting the eye's location.
// It will also stream the chunk that the new loc is in.
/mob/intruder_eye/proc/setLoc(var/T)
	if(owner)
		T = get_turf(T)
		if(T != loc)
			forceMove(T)

			if(owner.client)
				owner.client.eye = src
			return 1

	return 0

/mob/intruder_eye/proc/getLoc()
	if(owner)
		if(!isturf(owner.loc) || !owner.client)
			return
		return loc

/mob/intruder_eye/EyeMove(n, direct)
	var/initial = initial(sprint)
	var/max_sprint = 50

	if(cooldown && cooldown < world.timeofday)
		sprint = initial

	for(var/i = 0; i < max(sprint, initial); i += 20)
		var/turf/step = get_turf(get_step(src, direct))
		if(step)
			setLoc(step)

	cooldown = world.timeofday + 5
	if(acceleration)
		sprint = min(sprint + 0.5, max_sprint)
	else
		sprint = initial
	return 1

// Spawn the actual eye.

/mob/dead/intruder/proc/destroy_eyeobj(var/atom/new_eye)
	if(!eyeobj) return
	if(!new_eye)
		new_eye = src
	eyeobj.owner = null
	qdel(eyeobj) // No AI, no Eye
	eyeobj = null
	if(client)
		client.eye = new_eye

/mob/dead/intruder/proc/create_eyeobj(atom/newloc)
	if(eyeobj) destroy_eyeobj()
	if(!newloc) newloc = src.loc
	eyeobj = new /mob/intruder_eye(newloc)
	eyeobj.owner = src
	eyeobj.name = "[src.name] (Intruder Eye)" // Give it a name
	if(client) client.eye = eyeobj

// Intiliaze the eye by assigning it's "ai" variable to us. Then set it's loc to us.
/mob/dead/intruder/Initialize()
	. = ..()
	var/cur_z = pick(current_map.station_levels)
	create_eyeobj(locate(Floor(world.maxx/2), Floor(world.maxy/2), cur_z))