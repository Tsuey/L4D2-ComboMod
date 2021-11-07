printl( "VSCRIPT: Running mapspawn_addon.nut" );

/*****************************************************************************
**  Every addon can have its own mapspawn.nut file -- the original, from the
**  base game, is loaded first... which means g_MapName, g_BaseMode and also
**  g_UpdateName are relevant global variables I'll be utilizing for new mods.
**
**  It's too early to change g_UpdateName from "anv_mapfixes" to "tsu_jimmy"
**  here, so only RunScriptFile the new mode with round-persistent scope...
**  and that's it -- very simple mapspawn.nut unlike for the base game.
**
**  On second thought, while "g_UpdateName = "tsu_jimmy";" sounds like it'd
**  be fun (to have a unique "prefix namespace" for only this mod), functions
**  like make_prop() can occur at any time -- there's no single, known time
**  that I can change it to "tsu_jimmy" then back to "anv_mapfixes"... overall
**  it's just best to plan on settling with the "anv_mapfixes" prefix, and
**  wherever possible continue referencing the "g_UpdateName" global variable.
*****************************************************************************/

EntFire( "worldspawn", "RunScriptFile", "tsu_c1m4_jimmystealscar" );

/*****************************************************************************
**  FUNCTIONS (NEW)
**
**  On a situational, mod-by-mod basis, extend the base game anv_functions.nut
**  with new "make_" functions. Eventually these may be pooled into that file
**  officially or into a supplemental, optional file -- but for now, these are
**  new functions that Apply_Jimmy_Steals_Car() depends on specifically.
**
**  Note these only need to be declared once, and mapspawn.nut runs only once!
*****************************************************************************/

//////////////////////////////////////////////////////////////////////////////
// Spawn in a persistent "info_goal_infected_chase" to use as long as needed.
//////////////////////////////////////////////////////////////////////////////

function make_chaser ( user_strTargetname,
		       user_strOrigin,
		       user_strParent		=	"" )
{
	SpawnEntityFromTable( "info_goal_infected_chase",
	{
		targetname	=	g_UpdateName + user_strTargetname,
		origin		=	StringToVector_Valve( user_strOrigin, " " )
	} );

	// Requires explicit Enabling.

	EntFire( g_UpdateName + user_strTargetname, "Enable" );

	// Optional, where SetParenting to blank does nothing.

	EntFire( g_UpdateName + user_strTargetname, "SetParent", user_strParent );
}

//////////////////////////////////////////////////////////////////////////////
// Create a "commentary_zombie_spawner" temporarily to Spawn any zombie type.
//////////////////////////////////////////////////////////////////////////////

function make_zombie ( user_strTargetname,
		       user_strOrigin,
		       user_strModel		=	"common_male01",
		       user_intHealth		=	50 )
{
	// Create a Handle to the Spawner so it can be deleted post-Spawn. Note
	// that "info_zombie_spawn" isn't used since it requires custom populations.

	hndSpawner <- SpawnEntityFromTable( "commentary_zombie_spawner",
	{
		targetname	=	g_UpdateName + user_strTargetname + "_spawner",
		origin		=	StringToVector_Valve( user_strOrigin, " " )
	} );

	// Requires explicit Spawning. Note that whitespace after comma parameter
	// is not ignored, and does become part of the name, thus avoid whitespace.

	EntFire( g_UpdateName + user_strTargetname + "_spawner", "SpawnZombie", user_strModel + "," + g_UpdateName + user_strTargetname );

	// Optional, where "z_spawn common" is 50 health.

	EntFire( g_UpdateName + user_strTargetname, "AddOutput", "health " + user_intHealth );

	// Delete the temporary spawner (which is guaranteed to exist) with a
	// one second delay (required to give SpawnZombie time to fire). Note
	// that Handle "hndSpawner" needs to be Global so it can be found here.

	EntFire( "worldspawn", "RunScriptCode", "hndSpawner.Kill()", 0.1 );
}

//////////////////////////////////////////////////////////////////////////////
// Spawn in a persistent "env_spark" with heavily pre-determined options.
//////////////////////////////////////////////////////////////////////////////

function make_sparks ( user_strTargetname,
		       user_strOrigin,
		       user_strAngles,
		       user_strParent		=	"" )
{
	// Spawnflags 64 starts it ON, instead of requiring "StartSpark".

	SpawnEntityFromTable( "env_spark",
	{
		targetname	=	g_UpdateName + user_strTargetname,
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		angles		=	StringToVector_Valve( user_strAngles, " " ),
		spawnflags	=	64,
		Magnitude	=	1,
		MaxDelay	=	4,
		TrailLength	=	2
	} );

	// Optional, where SetParenting to blank does nothing.

	EntFire( g_UpdateName + user_strTargetname, "SetParent", user_strParent );
}

//////////////////////////////////////////////////////////////////////////////
// Spawn in a potentially complex Particle System at a maximum of two Targets.
// The burden of entity cleanup is on the user since it's too situational.
//////////////////////////////////////////////////////////////////////////////

function make_particle ( user_strTargetname,
			 user_strOrigin,
			 user_strAngles,
			 user_strEffectName,
			 user_strTarget1	=	null,
			 user_strTarget2	=	null )
{
	// Though declared first it's spawned last. It's absolutely mandatory
	// that all Targets are created before the System or it will not work!

	local tblSystem =
	{
		targetname	=	g_UpdateName + user_strTargetname + "_system",
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		angles		=	StringToVector_Valve( user_strAngles, " " ),
		effect_name	=	user_strEffectName,
		start_active	=	1
	};

	// It's unknown if 0, 1 or 2 of these will be needed, so add as necessary.
	// Also Targets exist to give the System direction, so if Targets are used
	// then they themselves definitely do not need Angles.

	if ( user_strTarget1 != null )
	{
		SpawnEntityFromTable( "info_particle_target",
		{
			targetname	=	g_UpdateName + user_strTargetname + "_target1",
			origin		=	StringToVector_Valve( user_strTarget1, " " )
		} );

		tblSystem.cpoint1 <- g_UpdateName + user_strTargetname + "_target1";
	}

	if ( user_strTarget2 != null )
	{
		SpawnEntityFromTable( "info_particle_target",
		{
			targetname	=	g_UpdateName + user_strTargetname + "_target2",
			origin		=	StringToVector_Valve( user_strTarget2, " " )
		} );

		tblSystem.cpoint2 <- g_UpdateName + user_strTargetname + "_target2";
	}

	// We're done defining so spawn it.

	SpawnEntityFromTable( "info_particle_system", tblSystem );
}

//////////////////////////////////////////////////////////////////////////////
// Functions for colorizing, stylizing, and spawning "light_dynamic" omni/spot.
//////////////////////////////////////////////////////////////////////////////

function choose_lightcolor( user_strColor )
{
	switch ( user_strColor )
	{
		case "Red":		return "255 0 0 0";
		case "Green":		return "0 255 0 0";
		case "Blue":		return "0 0 255 0";
		case "Yellow":		return "255 255 0 0";
		case "Magenta":		return "255 0 255 0";
		case "Aqua":		return "0 255 255 0";
		case "White":		return "255 255 255 0";
		case "Crimson":		return "128 0 0 0";
		case "Grass":		return "0 128 0 0";
		case "Navy":		return "0 0 128 0";
		case "Olive":		return "128 128 0 0";
		case "Purple":		return "128 0 128 0";
		case "Teal":		return "0 128 128 0";
		case "Gray":		return "128 128 128 0";
		case "Silver":		return "192 192 192 0";
		case "Orange":		return "255 128 0 0";
		case "Lime":		return "128 255 0 0";
		case "Pink":		return "255 128 128 0";
		case "Spring":		return "128 255 128 0";
		case "Sky":		return "0 128 255 0";
		case "Rune":		return "0 255 128 0";
		case "Window":		return "128 128 20 0";
		case "Fire":		return "255 45 5 0";
		case "Ladder":		return "64 255 64 0";
		case "Black":		return "0 0 0 0";
	}
}

function choose_lightstyle( user_strStyle )
{
	switch ( user_strStyle )
	{
		case "Static":		return 0;
		case "Inferno":		return 1;
		case "PulseSlow":	return 2;
		case "PoliceCar":	return 3;
		case "Strobing":	return 4;
		case "Campfire":	return 5;
		case "Television":	return 6;
		case "Christmas":	return 7;
		case "Irregular":	return 8;
		case "Ambulance":	return 9;
		case "Haunted":		return 10;
		case "PulseHasty":	return 11;
		case "Underwater":	return 12;
	}
}

function make_lightomni ( user_strTargetname,
			  user_strOrigin,
			  user_strColor		=	"Purple",
			  user_strStyle		=	"Static",
			  user_intBrightness	=	-4,
			  user_flDistance	=	2500,
			  user_intSpawnflags	=	0 )
{
	// Ambient light to illuminate surroundings based on simple brightness
	// and distance it illuminates -- it doesn't get simpler than this!
	// Spawnflags are niche but configurable just-in-case.

	SpawnEntityFromTable( "light_dynamic",
	{
		targetname		=	g_UpdateName + user_strTargetname,
		origin			=	StringToVector_Valve( user_strOrigin, " " ),
		_light			=	choose_lightcolor( user_strColor ),
		style			=	choose_lightstyle( user_strStyle ),
		brightness		=	user_intBrightness,
		distance		=	user_flDistance,
		spawnflags		=	user_intSpawnflags
	} );
}

function make_lightspot ( user_strTargetname,
			  user_strOrigin,
			  user_strColor		=	"Orange",
			  user_strStyle		=	"Static",
			  user_intBrightness	=	-3,
			  user_flDistance	=	1000,
			  user_strAngles	=	"90 0 0",
			  user_flSpotRadius	=	2000,
			  user_flOuterAngle	=	120,
			  user_flInnerAngle	=	120,
			  user_intPitch		=	0,
			  user_intSpawnflags	=	0 )
{
	// Directional pointing light that doesn't illuminate too much but is
	// surprisingly much better performance-wise (and easier to use) than
	// competing "env_projectedtexture". Spots put several Keyvalues to
	// necessary use, in order: (1) Angles are necessary to set direction
	// it's pointing; (2) Radius is only used for spots and if an omni is
	// always 0 and note that it's UNIQUE from Distance; (3) Outer/Inner
	// Angles at non-0 mean it's a spot otherwise omni's always 0; (4) Pitch
	// is spots-only and is useless; and (5) Spawnflags just-in-case, too.

	// Spawnflags 0 lights world and models, 1 doesn't light world (including
	// desirable ground), and 2 doesn't light models (but otherwise when the
	// spot goes over large models i.e. Dead Center 4's stockcar-display there
	// isn't even a spotlight as it's just fully illuminated). Spawnflags 0
	// is basically saying "light everywhere" -- I recall "env_projectedtexture"
	// might've been able to draw spots on large models but entity is a mess.

	SpawnEntityFromTable( "light_dynamic",
	{
		targetname		=	g_UpdateName + user_strTargetname,
		origin			=	StringToVector_Valve( user_strOrigin, " " ),
		_light			=	choose_lightcolor( user_strColor ),
		style			=	choose_lightstyle( user_strStyle ),
		brightness		=	user_intBrightness,
		distance		=	user_flDistance,
		angles			=	StringToVector_Valve( user_strAngles, " " ),
		spotlight_radius	=	user_flSpotRadius,
		_cone			=	user_flOuterAngle,
		_inner_cone		=	user_flInnerAngle,
		pitch			=	user_intPitch,
		spawnflags		=	user_intSpawnflags
	} );
}

//////////////////////////////////////////////////////////////////////////////
// Spawn a "beam_spotlight" cone with a very custom "light_dynamic" spotlight.
//////////////////////////////////////////////////////////////////////////////

function make_discoray ( user_strTargetname,
			 user_strOrigin,
			 user_strAngles,
			 user_strColor		=	"255 255 255" )
{
	// Spawnflags 3 is start ON (1) with no dynamic light creation (2).
	// There's no apparent visual difference between 1 and 3, though.

	SpawnEntityFromTable( "beam_spotlight",
	{
		targetname	=	g_UpdateName + user_strTargetname + "_beam",
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		angles		=	StringToVector_Valve( user_strAngles, " " ),
		rendercolor	=	user_strColor,
		HDRColorScale	=	1,
		maxspeed	=	0,
		spotlightlength	=	216,
		spotlightwidth	=	42,
		spawnflags	=	3
	} );

	// Pass in a FULL SET of parameters to function already made just for this!

	// Originally I inserted "user_strColor" into the 3rd parameter, but this
	// is very wrong since for THIS function it's initialized to "255 255 255"
	// which works for "beam_spotlight", but for make_lightspot() it's not looking
	// for a "number string", it's looking for a "word string" like "White"...
	// it's a bit of a gimmick that I even allow for a color parameter in this
	// make_discoray() function, so just hard-code the "White" to avoid confusing
	// and completely unnecessary convolutedness -- I could support "255 255 255"
	// if I changed choose_lightcolor() to "default: return its input", but that
	// is a confusing change for no benefit because make_discoray() is one-time-use.

	// To be fair, the "4 number format" of the light color wouldn't be useful
	// in all scenarios anyway, and "beam_spotlight" requires a LightOff / LightOn
	// toggle for the changed color to register -- SO, hard-coding "light_dynamic"
	// color isn't exactly horrible since that's MUCH easier/faster to change !!

	// NOTE :: When Gnome Chompsky is entirely indoors, the Jimmy Gibbs script
	// changes it to "brightness 2" -- the "brightness 1" here is fairly faint!

	make_lightspot( user_strTargetname + "_spot",
			user_strOrigin,
			"White",
			"Static",
			1,
			2100,
			user_strAngles,
			320,
			64,
			0,
			0,
			0 );

	/*****************************************************************************
	******************************************************************************

	// "env_projectedtexture"... will always cost more performance b/c broken.

	// Spawnflags 3 is start ON (1) with always update because it's moving (2).

	// Regardless of "materials/" prefix or not it's ALWAYS the texture of
	// the flashlight, and appears VERY UNRELIABLY... it could be my Shader,
	// Effect, and Model settings of Low/Medium/Low, but even when blank
	// with "" it's STILL the flashlight texture. With enableshadows at 1
	// there were still no shadows (light_dynamic lacks shadows too at least
	// with these settings), shadowquality 0 isn't inferior to 1 because I
	// don't see shadows, whether spawnflags 1 or 3 it's equally unreliable,
	// lightworld doesn't exhibit any difference... the 4th parameter of
	// lightcolor DID make it much more opaque but didn't solve reliability.

	// Replacing the "light_dynamic" code with the below completely does work,
	// spotlights are produced, but it's inconsistent which ones show up, the
	// "texturename" (regardless of being an early or later Keyvalue) is still
	// always the flashlight, and walking in front of the projection will block
	// it -- and/or that's a visual anomaly from the projection getting CULLED.
	// Also my FPS drops at least 10 more than it does with 18 "light_dynamic".
	// Overall, "env_projectedtexture"... ~50% works... but costs more perf!

	// For a literal "effects/slideshow_projector_01" on a Counter-Strike map,
	// other Keyvalues "simpleprojection" "0", "colortransitiontime" "0.5", and
	// "brightnessscale" "24" were observed but weren't attempted... maybe they
	// were CS-only, but regardless even with "lightworld 1" in L4D2, and even
	// if this functioned flawlessly, "light_dynamic" is shockingly more efficient.
	// Also, "light_dynamic" doesn't show shadows for me, but may require "High"
	// graphics settings for "shadow detail". Lastly, "textureframe" (the frame
	// of an animated texture to start on) wasn't tested, but maybe set it to 1?

	SpawnEntityFromTable( "env_projectedtexture",
	{
		targetname	=	g_UpdateName + user_strTargetname + "_spot",
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		angles		=	StringToVector_Valve( user_strAngles, " " ),
		texturename	=	"effects/spotlight",
		cameraspace	=	0,
		enableshadows	=	0,
		farz		=	2100,
		lightcolor	=	user_strColor + " 2000",
		lightfov	=	40,
		lightonlytarget	=	0,
		lightworld	=	0,
		nearz		=	4,
		shadowquality	=	0,
		spawnflags	=	3
	} );

	******************************************************************************
	*****************************************************************************/
}

//////////////////////////////////////////////////////////////////////////////
// Spawn in a "func_rotating" to spin parented objects around an X or Y axis.
//////////////////////////////////////////////////////////////////////////////

function make_rotator ( user_strTargetname,
			user_strOrigin,
			user_strAxis,
			user_strParent		=	"" )
{
	// Spawnflags 0 starts it OFF, and 64 means it's non-solid (Valve uses
	// it for c8m5's rotating skybox). The rest is custom from parameters.
	// Note that 2 is "reverse direction" but fire "Reverse" input instead,
	// in order to keep this relatively simple. The "null door" model isn't
	// needed anymore to prevent errors (thanks to Kerry). Spawnflag 16
	// would make it accelerate and decelerate according to friction, and
	// 32 would add "fan pain" (irrelevant when not using brushes with it),
	// and there's other spawnflags for sound radius -- all ignored here.

	// Important: Starting OFF is crucial because "Start" is 100% useless
	// because it starts the rotating at "maxspeed" immediately, whereas
	// "SetSpeed" is more precisely "Start spinning at this % of the max".
	// The problem encountered was when rotation started ON, if "SetSpeed"
	// was then fired the rotation would erroneously stop! It required a
	// delay of 0.2 seconds (0.1 didn't work) on the SetSpeed to work, but
	// looked janky, or simply starting it OFF... which is OK, given the
	// annoying but present behavior that "Start" is always at "maxspeed".

	// I did test "fanfriction 100" and "1000" with "spawnflags 80" (+16)
	// to see if Start / Stop / SetSpeed "eased it" in/out of a full-spin,
	// but apparently this had zero effect so I'm ignoring it now.

	local intSpawnflags = 64;

	switch( user_strAxis )
	{
		case "x":	intSpawnflags = intSpawnflags + 4;	break;
		case "y":	intSpawnflags = intSpawnflags + 8;	break;
	}

	// User Inputs to keep in mind: Start / Stop / Reverse / SetSpeed.
	// Note that SetSpeed refuses to register higher than "maxspeed" here,
	// and also doubles as its initial speed (can go up to ~2000). Finally,
	// non-solidity is only to prevent BBOX error spam, as the prop that
	// gets parented to it will still halt if a player stands in the way.

	// Important: SetSpeed is the desired % of "maxspeed", where with this
	// setup "SetSpeed 0.1" is 100/1000 of the "maxspeed"!

	SpawnEntityFromTable( "func_rotating",
	{
		targetname	=	g_UpdateName + user_strTargetname,
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		spawnflags	=	intSpawnflags,
		disableshadows	=	1,
		dmg		=	0,
		fanfriction	=	0,
		maxspeed	=	1000,
		solidbsp	=	0,
		volume		=	0
	} );

	// Optional, where SetParenting to blank does nothing.

	EntFire( g_UpdateName + user_strTargetname, "SetParent", user_strParent );
}

//////////////////////////////////////////////////////////////////////////////
// Spawn in a "func_movelinear" to move parented objects in a straight line.
//////////////////////////////////////////////////////////////////////////////

function make_moveline ( user_strTargetname,
			 user_strOrigin,
			 user_strDirection,
			 user_intDistance,
			 user_intSpeed )
{
	// Spawnflags 8 makes it non-solid. Note that the Valve Developer Wiki
	// says "Physics objects cannot be constrained to this entity when this
	// flag is enabled", an important (and currently irrelevant) consideration.

	// User Inputs to keep in mind: Open / Close / SetPosition / SetSpeed.

	SpawnEntityFromTable( "func_movelinear",
	{
		targetname	=	g_UpdateName + user_strTargetname,
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		movedir		=	StringToVector_Valve( user_strDirection, " " ),
		movedistance	=	user_intDistance,
		speed		=	user_intSpeed,
		spawnflags	=	8,
		blockdamage	=	0,
		startposition	=	0
	} );
}

//////////////////////////////////////////////////////////////////////////////
// Spawn an "ambient_generic" with pre-determined settings for sound or music.
//////////////////////////////////////////////////////////////////////////////

function make_noise ( user_strType,
		      user_strTargetname,
		      user_strOrigin,
		      user_intRadius,
		      user_strSound,
		      user_boolSilent		=	false )
{
	// Note that "ambient_music" was attempted, but even with "c2m4.BadMan2"
	// (copied exactly from c2m5) after "PlaySound" it never played, and to
	// make matters more confusing "Jukebox.BadMan1" may be entirely different
	// but also didn't work. So I use only "ambient_generic". The problem is
	// that "ambient_generic" has a lot of bugs, most notably that the sound
	// will continue playing if the entity is deleted.

	// Spawnflags 16 is used even though it doesn't appear needed, just to be
	// sure everything starts silent, and 32 so that it's not looped, despite
	// it not looping sounds anyway if ignored. The difference in how this
	// function behaves is "sound" uses "spawnflags 48" so that "radius" is
	// used (for fireworks / lighting sound effects), and "music" jumps this
	// up to "spawnflags 49" for "Play Everywhere" -- "Play Everywhere" has
	// a bug that requires a raw *.wav filename since it won't play Soundscripts.

	// Radius as a parameter is necessary, but when it comes to music it's
	// useless since music will not play at arbitrarily lengthy distances...
	// the game's Soundscripts overly-hard-code health/volume way too much,
	// and boosting "ambient_generic" past 10 requires Sounscript editing!
	// The other Keyvalues are simple, where pitch is 1-255 (100 default),
	// and default 0 spin up/down time... so constant Keyvalues otherwise.

	// CAUTION: Valve Wiki says, "The ambient_generic will not update its
	// position while the sound is playing if parented"... so that's just one
	// more stupid bug for this entity to keep in mind. MAKING MATTERS WORSE,
	// the Wiki notes that "SourceEntityName" must refer to an entity that
	// exists on map spawn, AND explicitly specifies that it CANNOT be changed
	// using "AddOutput"... so using that, instead of SetParent, is also a
	// complete lost cause. Overall, "ambient_generic" fucking sucks, no lie.

	local intSpawnflags = 0;

	switch( user_strType )
	{
		case "sound":	intSpawnflags = 48;	break;
		case "music":	intSpawnflags = 49;	break;
	}

	SpawnEntityFromTable( "ambient_generic",
	{
		targetname	=	g_UpdateName + user_strTargetname,
		origin		=	StringToVector_Valve( user_strOrigin, " " ),
		spawnflags	=	intSpawnflags,
		radius		=	user_intRadius,
		message		=	user_strSound,
		health		=	10,
		pitch		=	100,
		pitchstart	=	100
	} );

	// Requires explicit Playing. Since "StopSound" does not register quick
	// enough to spawn sound emitters silently, "user_boolSilent" was added.

	if ( user_boolSilent == false )
	{
		EntFire( g_UpdateName + user_strTargetname, "PlaySound" );
	}
}

/*****************************************************************************
**  MAKE_HINT
**
**  An "env_instructor_hint" is as complex as the user wants it to be, having
**  a lot of quirks if used to its fullest extent. I've personally messed with
**  the entity on and off over the years and have forgotten and re-researched
**  it again and again, but this is the final time -- for everyone. All's here.
**
**  All Valve Wiki and other live examples and resources are summarized here,
**  and though not all are used, all Keyvalues discovered are represented. The
**  most important thing is that if "info_target" is used, it needs spawnflags
**  1 for "Transmit to client (respect PVS)" or 2 "Always transmit ignore PVS",
**  where PVS stands for "Potential Visibility Set" of visleaves -- the hint
**  will NOT WORK if "spawnflags 0", and just use the spawnflags-less target
**  entity Valve has provided instead to conveniently ignore this problem.
**
**  Keyvalue "hint_auto_start 1" is used to instantly show the hint by default,
**  so "ShowHint" will never have to be used, just a make_hint() call at the
**  time it's required... it's assumed that "EndHint" (note "ShowHint" doesn't
**  exist) will be used to stop it, or "Kill" will delete and also stop it.
**  This Keyvalue is used because "ShowHint" otherwise requires a ~0.1 second
**  delay -- literally, it's described as "Show on First Sight" and hasn't been
**  verified, but is assumed, that if used it will display for all clients on
**  the server. When spamming hint creation, "Priority level not set for lesson"
**  and "Locator Panel has no free targets!" errors were not investigated/tested.
**
**	CAUTION:
**
**		Note that "hint_auto_start 1" is not identical to "ShowHint".
**		With that intitially set, the hint will only display when the
**		player becomes LOS to it -- the same LOS check that's used for
**		spawning is likely used here, since even if the player's back
**		is facing where the hint is, it still still show... but not if
**		it is obstructed by a solid wall. Conversely, "ShowHint" will
**		forcefully show it even through walls. This is NOT referring to
**		parameter "user_boolForceCaption" (aka "hint_forcecaption") as
**		that's completely different despite also being occlusion-related.
**
**		Comparatively, "ShowHint" can be used multiple times back to
**		back to pile the same hint on top of each other -- this likely
**		is caused by "hint_instance_type 0" for "Multiple". Objectively
**		speaking, if "info_target_instructor_hint" is indeed an entity
**		that is "replicated on the client", and every player on the
**		server can independently render it at the "visibility leisure"
**		of their LOS to it, then "hint_auto_start 1" is the best way
**		to go since otherwise there'd potentially need to be multiple
**		firings of "ShowHint", or in some cases the hint could display
**		when the player is arbitrarily far away from the leader.
**
**		So, just know that the hint will only show if the player is
**		within LOS of it... which is better than a hard-coded "ShowHint"
**		even though it will result in potential non-simultaneous viewing
**		of the hint, and potential scenarios where the player might've
**		not come within LOS of the entity during its existence, and then
**		ended up never seeing it. As long as the entity exists, it's up
**		to "visibility leisure" to LOS it, render it, and it'll cease for
**		everybody once "Kill" is fired to it.
**
**	user_boolAutoStart:
**
**		Two vital realizations came to light: (1) fellow Survivor teammates
**		can obstruct visibility of the hint causing them to potentially see
**		it very late against their own control, and (2) func_brush LOS fixes
**		which are also used to block bullets can also permanently obstruct
**		visibility of the hint to a client.
**
**		Thus... "user_boolAutoStart" defaults to "true" which sets Keyvalue
**		"hint_auto_start 1", and if the parameter is "false" it's set to 0,
**		which then absolutely requires "ShowHint" -- and "ShowHint" avoids
**		all LOS visibility pitfalls. Recall again that "user_boolForceCaption"
**		is also occlusion-related, and even if "true" (which is the default)
**		when using "hint_auto_start 1" it still resorts to an LOS visibility
**		check to display it for the first time... so ignore that, it's unrelated.
**
**  The configurable parameters are confirmed to actually be useful and if not
**  mentioned are assumed self-explanatory:
**
**		NOTE: Caption has a 100 character limit.
**
**	user_intRange: Where 0 is any distance. If not within Range when it's
**	spawned it will not appear even when you get within range, and ceases
**	if you leave Range. Only set non-0 if Survivors can be split out.
**
**	user_intAlpha: Stationary transparency blink, where 0 is none, and
**	1 slow, 2 fast, 3 urgent -- note that if near a second simultaneous
**	hint that is pulsing, this will bounce up/down "colliding" with it.
**
**	user_intPulse: Will grow/shrink, w/ 0 none, 1 slow, 2 fast, 3 urgent.
**
**	user_intShake: Shaking, w/ 0 none, 1 is slight, and 2 is intense.
**
**	user_boolStatic: Default of 0 follows and uses the "info_target" and
**	is assumed to require it, but setting to 1 would exclusively show it
**	on the HUD and in theory have no need for but is still given a target.
**	It's this option that likely makes hints require a target instead of
**	just using the location of the hint entity itself.
**
**	user_boolSuppressRest: Default of 1 prevents it from appearing center
**	in the screen before moving to its world's target location afterwards.
**	Changing to 0 would make it behave more like an ordinary Valve hint.
**
**	user_boolNoOffScreen: Default of 0 shows arrows when the target entity
**	is off-screen, where changing to 1 won't show anything if facing away.
**
**	user_boolForceCaption: Default of 1 shows hint even when occluded, but
**	in more practical use captions will vanish and leave only the icon
**	showing if ~700 units away from the target's location -- setting to 1
**	here ensures that, while the icon will get smaller when this far away
**	(regardless of whatever "user_intRange" is set to), the text itself
**	will remain persistent and never vanish even if arbitrarily far away.
**
**  A few Keyvalues expressly don't have any use, and thus lack parameters:
**
**	hint_allow_nodraw_target: Targets are provided with hints created by
**	this function -- but presumably, a "prop_dynamic" that's Disabled will
**	have its EF_NODRAW flag set, and be invisible, so for the hint to show
**	at its location this would need to be changed from 0 to 1. Note that,
**	with this set to 0, SetParent and ent_teleport were confirmed working.
**
**	hint_display_limit: Untested, but 0 means it can be seen an unlimited
**	number of times, which will always be desirable given function usage.
**
**	hint_icon_offset: Height offset from the target entity's origin to
**	show the hint -- 100% useless since you can just MOVE the target itself.
**	Note the Valve Wiki does NOT specify if this would offset a "static"
**	screen hint up or down, but player's screen resolutions differ anyway,
**	so it's assumed such a thing is impossible.
**
**	hint_instance_type: Default of 0 allows multiple hints at the same time,
**	but after extensive testing ALL options did this anyway -- it could be
**	the function / per-entity implementation, every hint entity is assumed
**	to have a unique "targetname", but when hints shared the same names it's
**	possible the settings here worked under that condition. Anyway, if set
**	to 1 it's supposed to "prevent new hints from opening", but a uniquely
**	named 1st and 2nd hint still showed the 2nd. If set to 2 it's supposed
**	to end old hints if new one is shown, but all kept showing. if set to 3
**	instead of "ending other hints" it "hides other hints", so Valve Wiki's
**	language makes it hard to discern what difference there actually is,
**	and testing never showed any difference anyway. If this is related to
**	support for "lesson types", that's beyond function implementation scope.
**
**	hint_local_player_only: Why would you not want to show to all players?
**	And if an Official Dedicated, I guess it chooses the "first" player?
**
**	hint_timeout: Default of 0 never auto-EndHint's... it's assumed users
**	will always want to do this manually, as these are entity-based maker
**	functions and auto-EndHint's would leave the entity uselessly persisting
**	so it's better to enforce a habit of having users Kill them manually.
**
**	hint_activator_caption: Untested, color specific to the !activator,
**	and is same format as "user_strColor" (called "color255").
**
**	hint_binding & hint_gamepad_binding: Allegedly if "user_strIconOnScreen"
**	is "use_binding" instead of an actual icon it will show a keybind from
**	"key_listboundkeys" instead. This is for keyboard/controller stuff and
**	is untested and outside scope of this function.
**
**	hint_name: Just use "targetname" instead. Untested lesson-related stuff.
**
**	hint_entindex & hint_flags & userid: Untested, no online documentation.
**	Assumed userid is the same as !activator who "triggered" the hint, but
**	with this function's implementation there never will be an !activator
**	and any "activation" would be handled by supplemental triggers instead.
**	And entindex is the entity ID of the "env_instructor_hint" itself, so
**	these seem more relevant as Game Events than Keyvalues.
**
**  Parameters "user_strIconOnScreen" & "user_strIconOffScreen" have a LOT of
**  possibilities. These are the main ones from the Valve Wiki:
**
**	icon_alert			! mark
**	icon_alert_red			! inside triangle
**	icon_arrow_plain		red down triangle
**	icon_arrow_plain_white_dn	white down triangle
**	icon_arrow_plain_white_up	white up triangle
**	icon_arrow_right		white right arrow
**	icon_arrow_up			white up arrow
**	icon_button			hand button
**	icon_info			i inside box
**	icon_interact			hand pickup
**	icon_no				red crossout
**	icon_shield			gray shield
**	icon_skull			white skull
**	icon_tip			lightbulb
**
**  File "scripts/mod_textures.txt" (update VPK) https://pastebin.com/U1QpzMLz
**  offers several more possibilities. All entries prefixed with "icon_" were
**  tested along with some others with names of interest and completely random
**  ones picked out. All items and weapons have icons so, there's many options,
**  but very few of them are good, but a lot of them are still interesting.
**  There are some "erroneously same" hints that are identified, as well -- but
**  know that, while this is all the "unique" cool stuff, coolness is subjective.
**
**  These are good (and non-identifying) enough to belong on the Valve Wiki:
**
**	clock_1				pretty clock
**	d_headshot			zombie with bullet hole in head
**	d_skull_cs			RIP gravestone
**	icon_blank			! mark but colored red
**	icon_defibrillator		non-identifying zig-zag
**	icon_explosive_ammo		could sell as fireworks
**	icon_incendiary_ammo		generic fire icon ("zombie_team_common" same)
**	icon_laser_sight		Crosshair ("icon_ammopack" same)
**	icon_run			Portal-esque run icon
**	icon_upgrade			Christmas gift (seriously)
**
**  These are only worth noting for informational / reference purposes:
**
**	Don't work / nothing shows	icon_molotov & icon_painpills & icon_pipebomb & number_9
**	SkullIcon			extremely low resolution/bad
**	Stat_Most_Infected_Kills	basically main menu icons
**	Unknown & TeenGirl		if can't figure out Survivor, show Zoey
**	icon_cola_bottles		exactly as it sounds
**	icon_dpad			controller + buttons
**	icon_equip_flashlight		exactly as it sounds
**	icon_equip_medkit		med + sign
**	icon_equip_pipebomb		pipe bomb icon, these all have _small variant too
**	icon_gold_medal			exactly as it sounds
**	icon_key_generic & _wide	could maybe overlay any key number/letter
**	icon_knife			knife icon
**	icon_medkit			med + sign colored red
**	icon_mouseRight			RMB / M2
**	icon_noMedKit			med w/ cross through it
**	icon_reviving			hands holding
**	icon_world_record		Survival timer with a globe inside it (cut leaderboard?)
**	pain_up				red up arrow
**	rating_5_stars			not stars they're bullets
**	rounded_background_glow_green	black box with green border
**	s_panel_healing_mini_prog	gray gradient
**	teengirl_outline		just her outline for w/e reason
**	tip_checkpoint			picture of a safe door
**	tip_doorbreak			lazy picture of a colored door
**	tip_heal			erroneously a lazy colored picture of a pipebomb
**	tip_items			guns criss-crossing, intro movie style
**	tip_revive			erroneously uses Ellis' Beta white shirt and tan pants
**	whiteAdditive			all plain white
**
**  The only downsides to "env_instructor_hint" is that there's no way to adjust
**  the location of a "static"-on-screen text popup, and of course that they can't
**  be suppressed after seen X amount of times since "instructor_lessons.txt"
**  would need official editing, and at that point just use "info_game_event_proxy"
**  instead. Also clients may have "gameinstructor_enable 0" which is assumed to
**  suppress even "env_instructor_hint" entirely making it potentially useless!
**
**  Further downsides are: (1) the hint will unpreventably show for BOTH TEAMS,
**  so it's a bit weird SI/Infected players will see the hint but it's necessary;
**  and (2) when the hint pops up it'll always sound the "bloop" noise. If all
**  these downsides could be solved with new Keyvalues that'd be great, but there
**  is already tremendous Keyvalue bloat here as it is!
*****************************************************************************/

function make_hint ( user_strTargetname,
		     user_strOrigin,
		     user_strCaption,
		     user_strIconOnScreen	=	"icon_info",
		     user_strIconOffScreen	=	"icon_info",
		     user_strColor		=	"255 255 255",
		     user_intRange		=	0,
		     user_intAlpha		=	0,
		     user_intPulse		=	0,
		     user_intShake		=	0,
		     user_boolStatic		=	false,
		     user_boolSuppressRest	=	true,
		     user_boolNoOffScreen	=	false,
		     user_boolForceCaption	=	true,
		     user_boolAutoStart		=	true )
{
	SpawnEntityFromTable( "info_target_instructor_hint",
	{
		targetname	=	g_UpdateName + user_strTargetname + "_target",
		origin		=	StringToVector_Valve( user_strOrigin, " " )
	} );

	SpawnEntityFromTable( "env_instructor_hint",
	{
		targetname			=	g_UpdateName + user_strTargetname,
		hint_target			=	g_UpdateName + user_strTargetname + "_target",
		origin				=	StringToVector_Valve( user_strOrigin, " " ),
		hint_caption			=	user_strCaption,
		hint_icon_onscreen		=	user_strIconOnScreen,
		hint_icon_offscreen		=	user_strIconOffScreen,
		hint_color			=	user_strColor,
		hint_range			=	user_intRange,
		hint_alphaoption		=	user_intAlpha,
		hint_pulseoption		=	user_intPulse,
		hint_shakeoption		=	user_intShake,
		hint_static			=	user_boolStatic,
		hint_suppress_rest		=	user_boolSuppressRest,
		hint_nooffscreen		=	user_boolNoOffScreen,
		hint_forcecaption		=	user_boolForceCaption,
		hint_auto_start			=	user_boolAutoStart,
		hint_allow_nodraw_target	=	0,
		hint_display_limit		=	0,
		hint_entindex			=	0,
		hint_flags			=	0,
		hint_icon_offset		=	0,
		hint_instance_type		=	0,
		hint_local_player_only		=	0,
		hint_timeout			=	0,
		hint_activator_caption		=	"",
		hint_binding			=	"",
		hint_gamepad_binding		=	"",
		hint_name			=	"",
		userid				=	0
	} );
}