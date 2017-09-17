/obj/effect/proc_holder/spell
	human_req = TRUE
	var/gain_desc = null
	var/blood_used = 0
	var/vamp_req = FALSE

/obj/effect/proc_holder/spell/cast_check(skipcharge = 0, mob/user = usr)
	. = ..(skipcharge, user)
	if(vamp_req)
		if(!is_vampire(user))
			return FALSE
		var/datum/antagonist/vampire/V = user.mind.has_antag_datum(ANTAG_DATUM_VAMPIRE)
		if(!V)
			return FALSE
		if(V.usable_blood < blood_used)
			to_chat(user, "<span class='warning'>You do not have enough blood to cast this!</span>")
			return FALSE

/obj/effect/proc_holder/spell/Initialize()
	. = ..()
	if(vamp_req)
		clothes_req = FALSE
		range = 1
		human_req = TRUE


/obj/effect/proc_holder/spell/before_cast(list/targets)
	. = ..()
	if(vamp_req)
		// sanity check before we cast
		if(!is_vampire(usr))
			targets.Cut()
			return

		if(!blood_used)
			return

		// enforce blood
		var/datum/antagonist/vampire/vampire = usr.mind.has_antag_datum(ANTAG_DATUM_VAMPIRE)

		if(blood_used <= vampire.usable_blood)
			vampire.usable_blood -= blood_used
		else
			// stop!!
			targets.Cut()

		if(LAZYLEN(targets))
			to_chat(usr, "<span class='notice'><b>You have [vampire.usable_blood] left to use.</b></span>")


/obj/effect/proc_holder/spell/can_target(mob/living/target)
	. = ..()
	if(vamp_req && is_vampire(target))
		return FALSE
/datum/vampire_passive
	var/gain_desc

/datum/vampire_passive/New()
	..()
	if(!gain_desc)
		gain_desc = "You have gained \the [src] ability."


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/vampire_passive/regen
	gain_desc = "Your rejuvination abilities have improved and will now heal you over time when used."

/datum/vampire_passive/vision
	gain_desc = "Your vampiric vision has improved."

/datum/vampire_passive/full
	gain_desc = "You have reached your full potential and are no longer weak to the effects of anything holy and your vision has been improved greatly."

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/mob/living/carbon/update_sight()
	. = ..()
	if(mind && ishuman(src))
		var/datum/antagonist/vampire/V = mind.has_antag_datum(ANTAG_DATUM_VAMPIRE)
		if(V)
			if(V.get_ability(/datum/vampire_passive/full))
				sight |= SEE_TURFS|SEE_MOBS|SEE_OBJS
				see_in_dark = 8
				see_invisible = SEE_INVISIBLE_MINIMUM
			else if(V.get_ability(/datum/vampire_passive/vision))
				sight |= SEE_MOBS

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/obj/effect/proc_holder/spell/self/rejuvenate
	name = "Rejuvenate"
	desc= "Flush your system with spare blood to remove any incapacitating effects."
	action_icon_state = "rejuv"
	charge_max = 200
	stat_allowed = 1
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	vamp_req = TRUE

/obj/effect/proc_holder/spell/self/rejuvenate/cast(list/targets, mob/user = usr)
	var/mob/living/carbon/U = user
	U.stuttering = 0

	var/datum/antagonist/vampire/V = U.mind.has_antag_datum(ANTAG_DATUM_VAMPIRE)
	if(!V) //sanity check
		return
	for(var/i = 1 to 5)
		U.adjustStaminaLoss(-10)
		if(V.get_ability(/datum/vampire_passive/regen))
			U.adjustBruteLoss(-1)
			U.adjustOxyLoss(-2.5)
			U.adjustToxLoss(-1)
			U.adjustFireLoss(-1)
		sleep(7.5)


/obj/effect/proc_holder/spell/targeted/hypnotise
	name = "Hypnotize (20)"
	desc= "A piercing stare that incapacitates your victim for a good length of time."
	action_icon_state = "hypnotize"
	blood_used = 20
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	vamp_req = TRUE

/obj/effect/proc_holder/spell/targeted/hypnotise/cast(list/targets, mob/user = usr)
	for(var/mob/living/target in targets)
		user.visible_message("<span class='warning'>[user]'s eyes flash briefly as he stares into [target]'s eyes</span>")
		if(do_mob(user, target, 50))
			to_chat(user, "<span class='warning'>Your piercing gaze knocks out [target].</span>")
			to_chat(target, "<span class='warning'>You find yourself unable to move and barely able to speak.</span>")
			target.Knockdown(150)
			target.Stun(150)
			target.stuttering = 10
		else
			revert_cast(usr)
			to_chat(usr, "<span class='warning'>You broke your gaze.</span>")

/obj/effect/proc_holder/spell/self/shapeshift
	name = "Shapeshift (50)"
	desc = "Changes your name and appearance at the cost of 50 blood and has a cooldown of 3 minutes."
	gain_desc = "You have gained the shapeshifting ability, at the cost of stored blood you can change your form permanently."
	action_icon_state = "genetic_poly"
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	blood_used = 50
	vamp_req = TRUE

/obj/effect/proc_holder/spell/self/shapeshift/cast(list/targets, mob/user = usr)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		user.visible_message("<span class='warning'>[H] transforms!</span>")
		randomize_human(H)
	user.regenerate_icons()

/obj/effect/proc_holder/spell/self/cloak
	name = "Cloak of Darkness"
	desc = "Toggles whether you are currently cloaking yourself in darkness."
	gain_desc = "You have gained the Cloak of Darkness ability which when toggled makes you near invisible in the shroud of darkness."
	action_icon_state = "cloak"
	charge_max = 10
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	vamp_req = TRUE

/obj/effect/proc_holder/spell/self/cloak/Initialize()
	. = ..()
	update_name()

/obj/effect/proc_holder/spell/self/cloak/proc/update_name()
	var/mob/living/user = loc
	if(!ishuman(user) || !is_vampire(user))
		return
	var/datum/antagonist/vampire/V = user.mind.has_antag_datum(ANTAG_DATUM_VAMPIRE)
	name = "[initial(name)] ([V.iscloaking ? "Deactivate" : "Activate"])"

/obj/effect/proc_holder/spell/self/cloak/cast(list/targets, mob/user = usr)
	var/datum/antagonist/vampire/V = user.mind.has_antag_datum(ANTAG_DATUM_VAMPIRE)
	if(!V)
		return
	V.iscloaking = !V.iscloaking
	update_name()
	to_chat(user, "<span class='notice'>You will now be [V.iscloaking ? "hidden" : "seen"] in darkness.</span>")

/obj/effect/proc_holder/spell/targeted/disease
	name = "Diseased Touch (100)"
	desc = "Touches your victim with infected blood giving them Grave Fever, which will, left untreated, causes toxic building and frequent collapsing."
	gain_desc = "You have gained the Diseased Touch ability which causes those you touch to become weak unless treated medically."
	action_icon_state = "disease"
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	blood_used = 100
	vamp_req = TRUE

/obj/effect/proc_holder/spell/targeted/disease/cast(list/targets, mob/user = usr)
	for(var/mob/living/carbon/target in targets)
		to_chat(user, "<span class='warning'>You stealthily infect [target] with your diseased touch.</span>")
		target.help_shake_act(user)
		if(is_vampire(target))
			to_chat(user, "<span class='warning'>They seem to be unaffected.</span>")
			continue
		var/datum/disease/D = new /datum/disease/vampire
		target.ForceContractDisease(D)

/obj/effect/proc_holder/spell/self/screech
	name = "Chiropteran Screech (30)"
	desc = "An extremely loud shriek that stuns nearby humans and breaks windows as well."
	gain_desc = "You have gained the Chiropteran Screech ability which stuns anything with ears in a large radius and shatters glass in the process."
	action_icon_state = "reeee"
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	blood_used = 30
	vamp_req = TRUE

/obj/effect/proc_holder/spell/self/screech/cast(list/targets, mob/user = usr)
	user.visible_message("<span class='warning'>[user] lets out an ear piercing shriek!</span>", "<span class='warning'>You let out a loud shriek.</span>", "<span class='warning'>You hear a loud painful shriek!</span>")
	for(var/mob/living/carbon/C in hearers(4))
		if(C == user || (ishuman(C) && C.get_ear_protection()) || is_vampire(C))
			continue
		to_chat(C, "<span class='warning'><font size='3'><b>You hear a ear piercing shriek and your senses dull!</font></b></span>")
		C.Knockdown(4)
		C.adjustEarDamage(0, 30)
		C.stuttering = 250
		C.Stun(4)
		C.Jitter(150)
	for(var/obj/structure/window/W in view(4))
		W.take_damage(75)
	playsound(user.loc, 'sound/effects/screech.ogg', 100, 1)

/obj/effect/proc_holder/spell/bats
	name = "Summon Bats (75)"
	desc = "You summon a pair of space bats who attack nearby targets until they or their target is dead."
	gain_desc = "You have gained the Summon Bats ability."
	action_icon_state = "bats"
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	charge_max = 1200
	vamp_req = TRUE
	blood_used = 75
	var/num_bats = 2

/obj/effect/proc_holder/spell/bats/choose_targets(mob/user = usr)
	var/list/turf/locs = new
	for(var/direction in GLOB.alldirs) //looking for bat spawns
		if(locs.len == num_bats) //we found 2 locations and thats all we need
			break
		var/turf/T = get_step(usr, direction) //getting a loc in that direction
		if(AStar(user, T, /turf/proc/Distance, 1, simulated_only = 0)) // if a path exists, so no dense objects in the way its valid salid
			locs += T

	// pad with player location
	for(var/i = locs.len + 1 to num_bats)
		locs += user.loc

	perform(locs, user = user)

/obj/effect/proc_holder/spell/bats/cast(list/targets, mob/user = usr)
	for(var/T in targets)
		var/mob/living/simple_animal/hostile/retaliate/bat/B = new /mob/living/simple_animal/hostile/retaliate/bat(T, user)
		B.faction = list("vampire") //make bats not attack vampires, but attack everyone else


/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/mistform
	name = "Mist Form (30)"
	gain_desc = "You have gained the Mist Form ability which allows you to take on the form of mist for a short period and pass over any obstacle in your path."
	blood_used = 30
	action_background_icon_state = "bg_demon"
	vamp_req = TRUE


/obj/effect/proc_holder/spell/targeted/vampirize
	name = "Lilith's Pact (500)"
	desc = "You drain a victim's blood, and fill them with new blood, blessed by Lilith, turning them into a new vampire."
	gain_desc = "You have gained the ability to force someone, given time, to become a vampire."
	action_icon = 'hippiestation/icons/mob/vampire.dmi'
	action_background_icon_state = "bg_demon"
	blood_used = 500
	vamp_req = TRUE

/obj/effect/proc_holder/spell/targeted/vampirize/cast(list/targets, mob/user = usr)
	for(var/mob/living/carbon/target in targets)
		if(is_vampire(target))
			to_chat(user, "<span class='warning'>They're already a vampire!</span>")
			continue
		target.visible_message("<span class='warning'>[user] latches onto [target]'s neck, and a pure dread eminates from them.</span>", "<span class='warning'>You latch onto [target]'s neck, preparing to transfer your unholy blood to them.</span>", "<span class='warning'>A dreadful feeling overcomes you</span>")
		target.reagents.add_reagent("salbutamol", 10) //incase you're choking the victim
		for(var/progress = 0, progress <= 3, progress++)
			switch(progress)
				if(1)
					to_chat(target, "<span class='warning'>Visions of dread flood your vision...</span>")
					to_chat(user, "<span class='notice'>We begin to drain [target]'s blood in, so Lilith can bless it.</span>")
				if(2)
					to_chat(target, "<span class='danger'>Demonic whispers fill your mind, and they become irressistible...</span>")
				if(3)
					to_chat(target, "<span class='danger'>The world blanks out, and you see a demo- no ange- demon- lil- glory- blessing... Lilith.</span>")
					to_chat(user, "<span class='notice'>Excitement builds up in you as [target] sees the blessing of Lilith.</span>")
			if(!do_mob(user, target, 70))
				to_chat(user, "<span class='danger'>The pact has failed! [target] has not became a vampire.</span>")
				to_chat(target, "<span class='notice'>The visions stop, and you relax.</span>")
				return
		if(!QDELETED(user) && !QDELETED(target))
			to_chat(user, "<span class='notice'>. . .</span>")
			to_chat(target, "<span class='italics'>Come to me, child.</span>")
			sleep(10)
			to_chat(target, "<span class='italics'>The world hasn't treated you well, has it?</span>")
			sleep(15)
			to_chat(target, "<span class='italics'>Strike fear into their hearts...</span>")
			to_chat(user, "<span class='notice italics bold'>They have signed the pact!</span>")
			to_chat(target, "<span class='userdanger'>You sign Lilith's Pact.</span>")
			target.mind.store_memory("<B>[user] showed you the glory of Lilith. <I>You are not required to respect or obey [user] in any way</I></B>")
			add_vampire(target)
