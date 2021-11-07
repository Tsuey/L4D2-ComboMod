printl( "VSCRIPT: Running tsu_c1m4_jimmystealscar.nut" );

/*****************************************************************************
**  The base game already has anv_mapfixes.nut, so in order to avoid conflicts
**  due to the fact that official implementation dodged scope complications by
**  running all code on "worldspawn", here I'm also running my code for new
**  standalone mods on it so copy the base game's Game Events 1:1 but include
**  the original Apply_Quadmode_Map_Specific_Fixes() call followed by my new
**  one, so it overall extends functionality by overriding the base original.
**
**  This is a sloppy workaround and has the same problem as all original use
**  of mapspawn.nut in that all authors would need to call the functions for
**  all mods for this to work... but for the current once-off, it'll be OK.
**
**  Several alternatives were attempted. If Apply_Jimmy_Steals_Car() changed
**  to ::Apply_Quadmode_Map_Specific_Fixes but with an attempted overloaded
**  function "<- function( strMod = "tsu_c1m4_jimmystealscar" )" to "layer"
**  on top of it "tricking" the base game into running the new code, it just
**  takes the last-most declared function. Identical result without the phony
**  parameter. I'll need to properly implement scope for this to work best.
*****************************************************************************/

function OnGameEvent_player_connect_full( params )
{
	if ( g_UpdateRanOnce == null )
	{
		g_UpdateRanOnce = false;

		Apply_Quadmode_Map_Specific_Fixes();

		Apply_Jimmy_Steals_Car();
	}
}

function OnGameEvent_round_start( params )
{
	if ( g_UpdateRanOnce == true )
	{
		Apply_Quadmode_Map_Specific_Fixes();

		Apply_Jimmy_Steals_Car();
	}
}

__CollectEventCallbacks( this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener );

/*****************************************************************************
**  My new function for the active mod. Note that the base game's function ran
**  first, followed by this, so SpawnGlobalFilters() stuff already spawned,
**  files anv_maptrigs.nut and anv_versus.nut already ran, and g_Chapter has
**  already been console-stamped by devchap() -- so all that's left to do is
**  the brand new event code. Spawn for all modes; handle exceptions enroute.
**
**  Caution that at the end of anv_mapfixes.nut the last line of code ran is
**  "EntFire( "worldspawn", "RunScriptCode", "g_UpdateRanOnce = true", 1 );"
**  which, if g_UpdateRanOnce is actually used in my new standalone mods, will
**  potentially cause mysterious issues... so just keep note of that for now!
*****************************************************************************/

::Apply_Jimmy_Steals_Car <- function()
{
	switch( g_MapName )
	{
		case "c1m4_atrium":
		{

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// STAGE 01 :: INITIALIZE
/////////////////////////

function tsu_c1m4_jimmy_01_precaches()
{
	// Resolving only known console-logged precache-related red errors. Mostly
	// necessary for the "wooden box pseudo-particle" since the game frame-skips
	// then, but I just went through everything as a blanket for this. Note that
	// the red "Late precache of models/error.mdl" is caused by IDK, didn't look
	// into it, but "models/props_junk/gascan001a.mdl" is an example of a model
	// that's naturally already precached by the map's BSP so isn't re-done here.
	// I'm assuming "Late precache of models/error.mdl" is a result of Jimmy Gibbs
	// script and NOT the base games... but NEEDS_TO_BE_LOOKED_INTO_SOMETIME !!

	// Official fixes had models spawn in instantly -- here, there's a lot going
	// on and new models being spawned in mid-play, hence the frame-skips. Given
	// previously experience with "env_shake", just in case I use it eventually
	// precache it to get it over with since that's a freak occurrence of spawn-lag.

	PrecacheEntityFromTable( { classname = "env_shake" } );

	// Just b/c, "models/infected/common_male_jimmy.mdl" is precached outside this
	// function... but here, "models/infected/common_male_riot.mdl" (which is the
	// model Jimmy Gibbs starts out as) needs precaching, too. Some models like
	// "models/props_junk/wood_crate001a_chunk01.mdl" + 2/3/4/5/7/9 only need the
	// initial model (not the break-pieces) precached, and "models/props_junk/gnome.mdl"
	// may apparently already be precached by Valve for all maps.

	// In order of occurrence of red errors and script use (same order, making OCD-easy).

	Entities.First().PrecacheModel( "models/infected/common_male_riot.mdl" );
	Entities.First().PrecacheModel( "models/props_placeable/wrong_way.mdl" );
	Entities.First().PrecacheModel( "models/props_interiors/teddy_bear.mdl" );
	Entities.First().PrecacheModel( "models/props/de_prodigy/fan.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/single_light.mdl" );
	Entities.First().PrecacheModel( "models/props/de_prodigy/pushcart.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/alligator.mdl" );
	Entities.First().PrecacheModel( "models/weapons/melee/w_pitchfork.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/mortar_rack.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/pyrotechnics_launcher.mdl" );
	Entities.First().PrecacheModel( "models/props_urban/chimney002.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/kiddyland_ridecar.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/tol_tunnel_heart.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/hanging_amp.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/stage_scaffold_128.mdl" );
	Entities.First().PrecacheModel( "models/props_fairgrounds/front_speaker.mdl" );

	// Actually, scratch that, PrecacheModel doesn't precache the break-pieces,
	// but the red console errors for the break pieces when the prop is actually
	// broken do not produce frame-skips. INSTEAD, below is a functional (astute)
	// alternative which does force-include the break-pieces !! Note that this
	// does a full-spawn-delete of the entity, if "prop_dynamic" the precache still
	// worked but on map load it complained about propdata and said DELETED... so
	// changed it to "prop_physics", even though it's deleted b/c precache anyway.

	PrecacheEntityFromTable( { classname = "prop_physics", model = "models/props_junk/wood_crate002a.mdl" } );

	// Precache on "keyframe_rope" instead of "move_rope" as keyframes must exist before.

	PrecacheEntityFromTable( { classname = "keyframe_rope", RopeMaterial = "cable/metal.vmt" } );

	// Precache all songs of (unique) interest. SoundScript names aren't used
	// because these are fail-safed with a copied "Play Everywhere" which requires
	// the raw *.wav files, but they are: "Jukebox.SaveMeSomeSugar", "Jukebox.re_your_brains",
	// "Jukebox.still_alive", and finally "Jukebox.AllIWantForXmas".

	Entities.First().PrecacheScriptSound( "music/flu/jukebox/save_me_some_sugar_mono.wav" );
	Entities.First().PrecacheScriptSound( "music/flu/jukebox/re_your_brains.wav" );
	Entities.First().PrecacheScriptSound( "music/flu/jukebox/portal_still_alive.wav" );
	Entities.First().PrecacheScriptSound( "music/flu/jukebox/all_i_want_for_xmas.wav" );

	// More sounds -- THIS IS GRATUITOUS, definitely all these don't need precaching,
	// but what the hell, let's just go for a comprehensive "in order of occurrence"
	// list. Note that "SmashCave.WoodRockCollapse" may log red errors to console for
	// "physics/destruction/Smash_Cave_WoodRockCollapse2.wav", and also full filepath
	// "physics/destruction/Smash_Cave_WoodRockCollapse4.wav" and finally filepath
	// "physics/destruction/smash_rockcollapse1.wav" since console may only complain
	// about specific sound files and not all-encompassing SoundScripts... like break
	// pieces of models, though, just precache the SoundScript.

	Entities.First().PrecacheScriptSound( "Breakable.MatGlass" );
	Entities.First().PrecacheScriptSound( "Bounce.Glass" );
	Entities.First().PrecacheScriptSound( "Breakable.Glass" );
	Entities.First().PrecacheScriptSound( "Glass.Break" );
	Entities.First().PrecacheScriptSound( "c2m5.burn_baby_burn" );
	Entities.First().PrecacheScriptSound( "c2m5.fireworks_launch" );
	Entities.First().PrecacheScriptSound( "c2m5.fireworks_burst" );
	Entities.First().PrecacheScriptSound( "c2m5.house_light_off" );
	Entities.First().PrecacheScriptSound( "c2m5.stage_light_on" );
	Entities.First().PrecacheScriptSound( "WoodenDoor.Break" );
	Entities.First().PrecacheScriptSound( "SmashCave.WoodRockCollapse" );
	Entities.First().PrecacheScriptSound( "Chainsaw.FullThrottle" );

	// Definition of gratuitous... more for "completionism" at this point... there
	// is no doubt Valve already has these cached...

	Entities.First().PrecacheScriptSound( "PipeBomb.TimerBeep" );
	Entities.First().PrecacheScriptSound( "PipeBomb.Bounce" );

	// Particles definitely unique to this map that Valve would have no reason to
	// precache otherwise... but do note that there's no red console errors for them.
	// This is just TO_BE_ABSOLUTELY_SURE there's no hiccups mid-play to ruin experience.

	// Example with THE MOST FRAME-SKIP is when the elevator glass breaks, so in that
	// case these precaches 100% eliminate hiccups there... so that's very nice!

	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "window_glass_child_bits" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "window_glass_child_smoke" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "fireworks_explosion_glow_02" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "fireworks_sparkshower_01" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "mini_fireworks" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "fireworks_01" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "fireworks_02" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "fireworks_03" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "fireworks_04" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "balloon" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "string_lights_heart_02" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "bridge_smokepuff" } );

	// Gratuitous again but w/e... (top is the explosion btw)

	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "weapon_pipebomb" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "weapon_pipebomb_blinking_light" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "weapon_pipebomb_blinking_light_b" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "weapon_pipebomb_blinking_light_c" } );
	PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "weapon_pipebomb_fuse" } );
}

// Get the precache over with to avoid frame-lag when it happens.

PrecacheModel( "models/infected/common_male_jimmy.mdl" );

tsu_c1m4_jimmy_01_precaches();

// SetTotalItems is on round_start which is way after Valve's VScript might've set it lower
// that 13 cans if it's Single Player... it's simpler to just set it to 0 for this gag.
// Delete the info_game_event_proxy that explains the "steps" of the finale b/c obsolete.
// Also prevent the elevator doors from opening. Note "relay_elevator_bottom" merely sets
// a door outside to be breakable, so more specificity is required here.

// Note that "SetTotalItems" is set as a String "0", because 0 by itself is seen as null.

// CAUTION :: Note the 1 second delay on SetTotalItems. Originally had this at no delay,
// but for the 2nd round in Versus it said 0/13 -- to be clear, 1st round said 0/0 then
// 2nd round 0/13. 1st load uses "player_connect_full" which occurs later than 2nd round
// usage of "round_start", so in this case "game_scavenge_progress_display" as an entity
// does not exist until after "player_connect_full", hence the 1 second delay for it to work!

EntFire( "progress_display", "SetTotalItems", "0", 1 );

EntFire( "trigger_finale", "AddOutput", "type 0" );
EntFire( "event_explain_c1m4_finale", "Kill" );
EntFire( "relay_force_finale_start", "Kill" );
EntFire( "pour_target", "Kill" );

// Add an "env_spark" to the elevator button and askew it accordingly.

make_sparks( "_jimmy_elevator_sparks", "-3944 -3478 592.24", "0 0 0", "prop_elev_button" );
EntFire( "prop_elev_button", "AddOutput", "angles 0 180 -10" );

// Disable the glow on the "backup start" kiosk button so Survivors cannot see or press it.
// It can still be "ForceFinaleStart" in this state, but I create my own new one.

EntFire( "trigger_finale", "Disable" );

// Create my own new finale because the "event_gas_car" GenerateGameEvent has a Survivor
// scream "Let's gas up this car", which severely breaks immersion, and Valve's kiosk is
// more ideally deleted by Gnome Chompsky's toycar a bit earlier on so it won't exist.
// Contrary to some belief, no origin is needed, it doesn't need to exist on FINALE navmesh.

// RAINCHECK :: Actually, even if Valve's original "trigger_finale" doesn't, exist AT ALL,
// Coach and others still say "Let's get this car gassed up"... maybe they're pre-computed,
// maybe it's handled on a map-based or even silly-hard-coded level... regardless, the only
// apparent way to stop it is to override with a *.VCD play... and, either way, creating a
// new "alternative_finale" from scratch is easier to wrap my head around even still.

SpawnEntityFromTable( "trigger_finale", { targetname = "alternative_finale", type = 0, VersusTravelCompletion = 0.1 } );

// Can't "delete outputs" like Stripper:Source can, so instead just revert it immediately.
// Note that the outer doors when OnOpen open the inner doors with 0.01 second delay.

EntFire( "elevator", "AddOutput", "OnReachedBottom door_elevator:Close::0.0001:-1" );
EntFire( "elevator", "AddOutput", "OnReachedBottom door_elevator_inside:Close::0.0101:-1" );

// Re-initialize 2x "env_fog_controller" entities to Valve's BSP defaults. Settings
// on this entity persist round transition, so the darkness from round 1 would persist
// to round 2 in Versus / all successive Coop rounds, etc. Refer to function named
// tsu_c1m4_jimmy_05_lightsout() for the changes made, but in summary: (1) SetColor
// to 0+0+0; (2) SetStartDist to 0; (3) SetEndDist to 0; (4) SetMaxDensity to 0.95.
// Respectively, those changes: alter the opaque color of the fog, then set it to
// basically make the screen full-black, and then finally make it less dense so it's
// actually possible to see and play. Darker it is, less flashlight effectiveness btw.

// Originally, blanket changes on BOTH were done with "env_fog_controller", but having
// observed that changes to "foginteriorcontroller" don't effect anything (it's 100%
// non-discernible to me), just change "fog_master". So, for "fog_master", Keyvalue of
// "fogcolor2" "130 117 107" is ignored (it's very white) whereas "fogcolor" "5 11 13"
// is the visual/tested equivalent of SetColor, so let's re-initialize to that. Its
// "fogmaxdensity" "1" means SetMaxDensity 1.0. Ignore "farz" "5000" in favor of more
// similarly-named "fogstart" "1" and "fogend" "4000" -- use those values, as well.

EntFire( "fog_master", "SetColor", "5+11+13" );
EntFire( "fog_master", "SetStartDist", "1" );
EntFire( "fog_master", "SetEndDist", "4000" );
EntFire( "fog_master", "SetMaxDensity", "1.0" );

// TODO :: FIX STILL PENDING (after remnant 10/21/2020-10/29/2020 typos were corrected on 3/7/2021):
//
//	When tested with Alex aka HUMAN BEAN aka godmachine, while on Coop mode, the end-round's
//	fade-out still happened, I think to the "statsroll" but don't recall exactly.
//
//	Versus doesn't have this problem, but Coop would as it handles stats/outros a bit different.
//	Most likely solution: Fix Coop fadeing to black by deleting the outro credits entity, too.

// TODO_FIX_ABOVE_FOR_COOP

// TODO :: OTHER ISSUES (documented here on 7/24/2021):
//
//	1. For unknowable reasons, Tank bot AI is 50% pacifist. They will get close then not
//	   attack... at all. If you step away, they'll punch, if you're far away, they'll throw
//	   a rock. This is unplayably broken and might be caused by how I delete finale logic.
//
//	2. Even with "_jimmy_nav_step", if 3 Survivor bots run through from the outside and into
//	   the elevator, it's possible one will get stuck on the sides -- "r_drawclipbrushes 2"
//	   reveals that Valve's clip is thick, so I thought to thicken mine, but I doubt that
//	   would be 100% anyway... trigger_push? Too much effort... just keep it in mind.
//
//	3. When Gnome Chompsky enters (NOTE: "Gnome Chompski" is often how I spell it which is
//	   WRONG so do correct it, based on the linguist "Noam Chomsky") the disco ball needs
//	   a vertical-moving func_movelinear to move it DOWN then back UP so it doesn't hit part
//	   of the map. Should be simple, but will take time / testing I don't want to spend now.
//
//	4. The big one: I need to actually change this into a "Holdout / Standard finale". With
//	   proper points awarded. Or hard-code in "fake gascan pours" depending on time spent
//	   in the finale. This also makes it unplayably broken... in Versus mode, at least.

// TODO_FIX_ABOVE_FOR_VERSUS

// Quarantine stages into separate functions.

function tsu_c1m4_jimmy_01_initialize()
{
	// Runs OnGameEvent to spawn in gascans, alter count to 0/0, inject I/O, etc.

	EntFire( "weapon_gascan", "Kill" );
	EntFire( "weapon_scavenge_item_spawn", "Kill" );

	// Ensures Survivors cannot kill Jimmy Gibbs. Infected players can scratch him
	// but that doesn't result in stuns or insta-kills, luckily/thankfully. Note that
	// these need to be relatively thick to block bullets. This combined with the
	// fact that Jimmy is really a RIOTCOP should ensure no murdering of Mr. Gibbs.

	make_brush( "_jimmy_blockbullets_1", "-13 -111 0", "11 111 137", "-4151 -3404 -1" );
	make_brush( "_jimmy_blockbullets_2", "-84 -13 0", "84 13 146", "-4084 -3515 4" );
	make_brush( "_jimmy_blockbullets_3", "-84 -13 0", "84 13 146", "-4084 -3293 4" );

	// There's no NAV connection into the elevator, and while Commons will inevitably
	// wave, at least have a clip sliver for Tank AI to "push forward" to possibly get
	// inside. Occasional Commons will still get in as well. IN THE FUTURE, consider
	// having a push trigger and blocking access... but, players were trapped inside
	// the elevator, last thing they'll think during a disco/fireworks show is go back in.

	// UPDATE: Thanks to Rayman1103 et. al / myself / TLS / Community Update Team, we can
	// now connect nav areas -- so changed from "SI Players and AI" (originally meant to
	// ensure players could still be somewhat attacked if camping inside elevator) to now
	// be "Everyone" since VScript nav connections have been trivialized.

	make_clip( "_jimmy_nav_step", "Everyone", 1, "-0.1 -61 0", "0 61 11", "-4166 -3404 0" );

	// Dynamically throw gascans around and Jimmy will pick one at random to kick. It's
	// not really that random, and one always falls far away -- the car used to actually
	// hit a gascan as it drove off (IDK how, Valve's triggers I guess) which I've disabled
	// due to "DisableMotion" to prevent Survivors from picking them up -- the alternative
	// would've been substituting in the final destinations with prop_dynamic, anyways.

	local intNumGascans = 1;

	while ( intNumGascans <= 13 )
	{
		make_prop( "physics_ovr", "_jimmy_empty_gascan_" + intNumGascans, "models/props_junk/gascan001a.mdl", "-4700 -3550 216" );

		intNumGascans++;
	}

	EntFire( g_UpdateName + "_jimmy_empty_gascan_*", "Skin", 1 );

	// Fire DisableMotion to them... as a lazy means of disabling their pickup.

	EntFire( g_UpdateName + "_jimmy_empty_gascan_*", "DisableMotion", null, 10 );
}

tsu_c1m4_jimmy_01_initialize();

// STAGE 02 :: RUNNING PAST
///////////////////////////

// This stage has multiple phases, all uniquely named.

function tsu_c1m4_jimmy_02_hintwaitwhat()
{
	// Use unique On/Off screen icons, then defaults for everything, until
	// add a moderate "alpha blink" to it just because I easily can and then
	// uniquely NOT "Suppress Rest" so it's truer to Valve's original.

	// By design, make_hint() displays the hint immediately, so in order to
	// delay it I need to call it as a function... BUT I CHANGED MY MIND...

	// It was later re-considered that Valve's hint technically shows itself
	// immediately, even if the Survivor isn't LOS to the "info_game_event_proxy".
	// So, set the final parameter "user_boolAutoStart" to "false" which makes
	// "hint_auto_start 0" which requires a "ShowHint", but will finally display
	// it at the same time for everybody. I'm only doing this for accuracy... plus
	// it's for the best, because more experienced players may just not move near
	// the glass to ever see it... now they'll ALWAYS see it... and, while default
	// of "hint_auto_start 1" is more user-friendly, and better when the Survivors
	// are split-up, the guarantee they'll be in the elevator makes this a unique case.

	make_hint( "_jimmy_hint_waitwhat", "-4800 -3520 168", "You'll need to fill the car with... wait, what?!", "d_skull_cs", "icon_blank", "255 255 255", 0, 2, 0, 0, false, false, false, true, false );
}

function tsu_c1m4_jimmy_02_glowsandscavui()
{
	// Change glow color from blue default to white so it matches Scavenge's
	// colors, then mimic Valve's own delays by showing glows, then trickling
	// everything off at 2-second "stops" just to "clean up" player's screens.

	EntFire( g_UpdateName + "_jimmy_empty_gascan_*", "SetGlowOverride", "255 255 255" );
	EntFire( g_UpdateName + "_jimmy_empty_gascan_*", "StartGlowing", null, 4 );
	EntFire( g_UpdateName + "_jimmy_empty_gascan_*", "StopGlowing", null, 17 );
	EntFire( "gas_nozzle", "StopGlowing", null, 19 );
	EntFire( "progress_display", "TurnOff", null, 21 );

	// Along with the cans (same 4 second delay), show this hint -- note that
	// given that "ShowHint" is not used (and "Kill" deletes plus "EndHint"'s)
	// the auto-start Keyvalue being 1 with this make_hint() function means
	// that the hint will appear after the player becomes within LOS to it, so
	// all Survivors may not see it simultaneously, but they will inevitably
	// see it since their forced position in the elevator will guarantee it.

	// This was changed from 4 second delay on the CallScriptFunction to 0 so
	// it now spawns in immediately, but is initially disabled... then mandatory
	// delay of 0.1 for the "ShowHint" will instantly show it same time for everybody.
	// Instead of just 0.1 second delay, and instead of the 4 to match "StartGlowing",
	// instead use 3 second delay to match Valve's hint appearing on "elevator stutter".

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_02_hintwaitwhat", 0 );
	EntFire( g_UpdateName + "_jimmy_hint_waitwhat", "ShowHint", null, 3 );
	EntFire( g_UpdateName + "_jimmy_hint_waitwhat", "Kill", null, 21 );
}

EntFire( "button_elev_3rdfloor", "AddOutput", "OnPressed worldspawn:CallScriptFunction:tsu_c1m4_jimmy_02_glowsandscavui:0:-1" );

function tsu_c1m4_jimmy_02_runningpast()
{
	// Instantly turn off further and delete all existing Commons, because once that chase
	// has spawned they'd be running toward it. Avoid distraction/confusion away from Jimmy.
	// Restored back to 30 in function "_04_glassbreak". Can't "SetHealth 0" at Commons.
	// Kerry's "systemic change" with TLS that resets these on round transition makes it safe.

	Convars.SetValue( "z_common_limit", 0 );
	EntFire( "infected", "Kill" );

	// Shortly after elevator button press, have Jimmy spawn and run by toward the gascans,
	// once he's close to the gascans have the "What?!"-Objective hint re-direct attention
	// over to the car itself -- Jimmy will kick a random gascan until elevator reaches bottom.

	local strGascanTarget = g_UpdateName + "_jimmy_empty_gascan_" + RandomInt( 1, 13 );
	local vecGascanOrigin = Entities.FindByName( null, strGascanTarget ).GetOrigin()

	SpawnEntityFromTable( "info_goal_infected_chase", { targetname = g_UpdateName + "_jimmygibbs_goalchaser", origin = vecGascanOrigin } );

	EntFire( g_UpdateName + "_jimmygibbs_goalchaser", "SetParent", strGascanTarget );
	EntFire( g_UpdateName + "_jimmygibbs_goalchaser", "Enable" );

	SpawnEntityFromTable( "commentary_zombie_spawner", { targetname = g_UpdateName + "_jimmygibbs_spawner", origin = Vector( -3620, -3632, 0 ) } );

	// CAUTION: Originally this was "common_male_riot" to try and take advantage of possible
	// extra immunity (just to be 100% sure it cannot be killed), but "common_male01" proved
	// equally immune to killing (I guess due to high health and headshots not necessarily
	// being insta-kills), so that's used instead. It's necessary since when it was spawned as
	// a Riot, even though I changed its model to Jimmy Gibbs it still had the RIOT FACE SHIELD,
	// I can only presume because some Commons come with built-in entity attachments... which
	// I'd guess isn't much/any different from zombies spawning with bile/tonfas attached.
	// Actually, I reduced the map down to 34 entities and 33 edicts (report_entities) and
	// the FACE SHIELD persisted, and it's not always made -- it's built-in to "infected" entity,
	// since after deleting Jimmy entities/edict count both went down only by 1 and not 2.

	EntFire( g_UpdateName + "_jimmygibbs_spawner", "SpawnZombie", "common_male01,anv_mapfixes_jimmygibbs" );

	// NOTE: One Katana slash to the head can still kill it, I guess RIOT's are immune to that.
	// Survivors can't melee through the glass, and I tested Hunter/Charger and they can't kill
	// or deal reasonable damage to Jimmy, and Tank punches deal a flat 1000 damage -- which I'm
	// lucky about, since Tank vs. Common damage could be hard-coded, and it's good that it's
	// not hard-coded to insta-kill. Overall, nothing to really worry about here. Endless barrages
	// of AK-47 or sniper bullets to the face would take 100's of hours at 10x timescale to kill.

	EntFire( g_UpdateName + "_jimmygibbs", "AddOutput", "health 2147483647" );

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_02_changemodel", 0.1 );
}

// Necessary delay so the EntFire() had time to actually spawn Jimmy Gibbs in.

function tsu_c1m4_jimmy_02_changemodel()
{
	Entities.FindByName( null, g_UpdateName + "_jimmygibbs" ).SetModel( "models/infected/common_male_jimmy.mdl" );

	Entities.FindByName( null, g_UpdateName + "_jimmygibbs" ).SetSequence( 118 );
}

EntFire( "button_elev_3rdfloor", "AddOutput", "OnPressed worldspawn:CallScriptFunction:tsu_c1m4_jimmy_02_runningpast:24:-1" );

// STAGE 03 :: ELEVATOR BASH
////////////////////////////

function tsu_c1m4_jimmy_03_elevatorbash()
{
	// When elevator reaches the bottom, Jimmy's attention turns over the glass where he'll
	// proceed to bash it and be indestructible for at least 10 seconds. Find a SetSequence
	// that, after enough bashing, he stands still and contemplates.

	Entities.FindByName( null, g_UpdateName + "_jimmygibbs" ).SetSequence( 120 );

	EntFire( g_UpdateName + "_jimmygibbs_goalchaser", "AddOutput", "origin -4170 -3401 42" );

	// Create sounds which start silently then play them intermittently while Jimmy Gibbs
	// is bashing the glass. Originally I wanted to add a "trigger_multiple" placed exactly
	// right so his "arm hitboxes" would go in and play the sounds that way, but it's too
	// high-effort for just a few sound effects and completely reasonable for "crackling"
	// to occur in between actual visual hits.

	make_noise( "sound", "_jimmy_sound_glass_punch", "-4151 -3404 17", 5000, "Breakable.MatGlass", true );
	make_noise( "sound", "_jimmy_sound_glass_crack", "-4151 -3404 17", 5000, "Bounce.Glass", true );

	EntFire( g_UpdateName + "_jimmy_sound_glass_punch", "PlaySound", null, 6 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_punch", "PlaySound", null, 8 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_crack", "PlaySound", null, 9 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_punch", "PlaySound", null, 11 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_crack", "PlaySound", null, 13 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_crack", "PlaySound", null, 15 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_punch", "PlaySound", null, 17 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_punch", "PlaySound", null, 18 );
	EntFire( g_UpdateName + "_jimmy_sound_glass_punch", "PlaySound", null, 20 );

	EntFire( g_UpdateName + "_jimmy_sound_glass_*", "Kill", null, 21 );

	// Pass control over to the next stage's function.

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_04_stealscar", 22 );
}

EntFire( "elevator", "AddOutput", "OnReachedBottom worldspawn:CallScriptFunction:tsu_c1m4_jimmy_03_elevatorbash:8:-1" );

// STAGE 04 :: STEALS CAR
/////////////////////////

function tsu_c1m4_jimmy_04_hintstealcar()
{
	// A nearly all-default hint, just the way they're simplest.

	// Actually, nevermind: All I really need here is up to the custom color
	// of "120 0 240" -- the rest is all 100% default parameters, purely to
	// set "user_boolAutoStart" away from default of "true" to "false". It's
	// necessary that "hint_auto_start" is "0" here because fellow Survivors
	// (who are likely to be standing still and not moving) can obstruct hint
	// visibility and prevent it from appearing entirely -- func_brush LOS fixes
	// also prevent it, which in this case since it's 100% mandatory the entire
	// time Jimmy Gibbs exists, "ShowHint" is REQUIRED as it completely ignores
	// that "Show on First Sight" condition. Notice that "user_boolForceCaption"
	// is occluded-related too, but this problem occurred even with it set to
	// its default of "true" -- "hint_auto_start"'s LOS check is independent !!

	// Since the "RUN" icon felt odd being stationary, added the weakest shake
	// as the 1 parameter just to add some movement to it to help sell urgency,
	// without making it overt / distracting (pulsing is VERY distracting).

	// It's technically Jimmy Gibbs' CAR, but it is the Survivor's RIDE.

	make_hint( "_jimmy_hint_stealcar", "-4790 -3460 128", "Jimmy's stealin' your ride!", "icon_run", "icon_alert_red", "120 0 240", 0, 0, 0, 1, false, true, false, true, false );
}

function tsu_c1m4_jimmy_04_stealscar()
{
	// Jimmy runs over to the car, slides over the hood, hint warns car is being stolen, he
	// drives out breaking the glass with it -- sometime later, Gnome Chompky emerges.

	EntFire( g_UpdateName + "_jimmygibbs_goalchaser", "AddOutput", "origin -4822 -3381 48.4" );

	// With a 0.15 second delay (just to give Jimmy time to turn around and start
	// gunning it), CallScriptFunction the function to spawn in the hint! Since
	// I changed this to a "ShowHint", note that the hint is spawned in initially
	// disabled with 0 second delay, then "ShowHint" with 0.15 delay, but only a
	// delay of 0.1 is required to ensure it exists.

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_04_hintstealcar", 0 );
	EntFire( g_UpdateName + "_jimmy_hint_stealcar", "ShowHint", null, 0.15 );

	// Spawn in the "trigger_once" that will "dynamically conclude" when Jimmy has reached
	// the car, since it can potentially vary arbitrarily. It's filtered for his model and
	// will only activate for NPC given the "spawnflags 2".

	SpawnEntityFromTable( "filter_activator_model",
	{
		targetname	= g_UpdateName + "_jimmy_filter",
		Negated		= "Allow entities that match criteria",
		model		= "models/infected/common_male_jimmy.mdl"
	} );

	SpawnEntityFromTable( "trigger_once",
	{
		targetname	= g_UpdateName + "_jimmy_trigonce",
		StartDisabled	= 0,
		spawnflags	= 2,
		filtername	= g_UpdateName + "_jimmy_filter",
		origin		= Vector( -4822, -3381, 48.4 )
	} );

	EntFire( g_UpdateName + "_jimmy_trigonce", "AddOutput", "mins -45 -45 0" );
	EntFire( g_UpdateName + "_jimmy_trigonce", "AddOutput", "maxs 45 45 1" );
	EntFire( g_UpdateName + "_jimmy_trigonce", "AddOutput", "solid 2" );

	EntFire( g_UpdateName + "_jimmy_trigonce", "AddOutput", "OnStartTouch !activator:Kill::0:-1" );
	EntFire( g_UpdateName + "_jimmy_trigonce", "AddOutput", "OnStartTouch worldspawn:CallScriptFunction:tsu_c1m4_jimmy_04_chargerexit:0:-1" );
}

function tsu_c1m4_jimmy_04_glassbreak()
{
	// Originally set to 0 in function "_02_runningpast", now restored to default 30.

	Convars.SetValue( "z_common_limit", 30 );

	// Lots of over-laying particle and sound effects.

	make_particle( "_jimmy_glass_bits", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	make_particle( "_jimmy_glass_bits", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	make_particle( "_jimmy_glass_bits", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	make_particle( "_jimmy_glass_bits", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	make_particle( "_jimmy_glass_bits", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	make_particle( "_jimmy_glass_bits", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	make_particle( "_jimmy_glass_smoke", "-4084 -3404 80", "0 0 0", "window_glass_child_smoke" );
	make_particle( "_jimmy_glass_smoke", "-4084 -3404 80", "0 0 0", "window_glass_child_smoke" );
	make_particle( "_jimmy_glass_smoke", "-4084 -3404 80", "0 0 0", "window_glass_child_smoke" );
	make_particle( "_jimmy_glass_smoke", "-4084 -3404 80", "0 0 0", "window_glass_child_smoke" );

	make_noise( "sound", "_jimmy_glass_breaka", "-4084 -3404 155", 5000, "Breakable.Glass" );
	make_noise( "sound", "_jimmy_glass_breaka", "-4084 -3404 155", 5000, "Breakable.Glass" );
	make_noise( "sound", "_jimmy_glass_breaka", "-4084 -3404 155", 5000, "Breakable.Glass" );
	make_noise( "sound", "_jimmy_glass_breaka", "-4084 -3404 155", 5000, "Breakable.Glass" );
	make_noise( "sound", "_jimmy_glass_breakb", "-4084 -3404 155", 5000, "Glass.Break" );
	make_noise( "sound", "_jimmy_glass_breakb", "-4084 -3404 155", 5000, "Glass.Break" );
	make_noise( "sound", "_jimmy_glass_breakb", "-4084 -3404 155", 5000, "Glass.Break" );
	make_noise( "sound", "_jimmy_glass_breakb", "-4084 -3404 155", 5000, "Glass.Break" );

	// IDK? :: This actually successfully deletes, for example, "anv_mapfixes_jimmy_glass_breakb"
	// and "anv_mapfixes_jimmy_glass_smoke_system"... IDK how the wildcard is working, but it is
	// working, didn't know wildcards could work with "in betweens", I thought wildcards could
	// only be at the end... guess not, or this is broken but works... just LEAVE IT AS IS, idk.
	// I could change this to just the "_jimmy_glass_*" w/o "_system" and it'd be less weird.

	EntFire( g_UpdateName + "_jimmy_glass_*" + "_system", "Kill", null, 2 );

	// Gratuitous but doing it this way just because I can -- even though "material 0"
	// is the default and still doesn't even play the sound effect or show breakage of
	// particles, all I actually have to do is "Kill" Valve's func_brush... which does
	// unpreventably include the elevator wall which is luckily difficult to notice and
	// nobody will care... but, anyway, I spawn in a duplicate of Valve's func_brush as
	// a cloned func_breakable, delete their original, then "Break" the func_breakable.

	SpawnEntityFromTable( "func_breakable", { targetname = g_UpdateName + "_jimmy_breakable_glass", model = Entities.FindByClassnameNearest( "func_brush", Vector( -4043, -3408, 158 ), 1 ).GetModelName(), origin = Vector( -4043, -3408, 158 ), material = 0 } );

	kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( -4043, -3408, 158 ), 1 ) );

	EntFire( g_UpdateName + "_jimmy_breakable_glass", "Break" );

	// FINALLY delete the annoying elevator lights up top, Stripper:Source could indeed
	// filter these out, but SourceMod (or ideally, VScript) would be needed to delete
	// them when they're no longer necessary -- like right un momento !!

	kill_entity( Entities.FindByClassnameNearest( "prop_dynamic", Vector( -4000, -3360, 156 ), 1 ) );
	kill_entity( Entities.FindByClassnameNearest( "prop_dynamic", Vector( -4000, -3448, 156 ), 1 ) );
	kill_entity( Entities.FindByClassnameNearest( "prop_dynamic", Vector( -4072, -3448, 156 ), 1 ) );
	kill_entity( Entities.FindByClassnameNearest( "prop_dynamic", Vector( -4072, -3360, 156 ), 1 ) );

	// Delete the bullet protection as it's no longer needed. Note that shooting the RIOT
	// originally caused it to stun, but NOT the normal Common I changed it to. And these
	// blockers prevented the RIOT stun anyway. They're still extra safety, but genuinely
	// aren't necessary anymore since the normal Common doesn't get stunned back (which by
	// design is how RIOT's are to increase the likelihood of exposing their vulnerable back).

	EntFire( g_UpdateName + "_jimmy_blockbullets_*", "Kill" );

	// Thanks to Post-TLS / Rayman1103 / Alien Swarm Reactive Drop code / Kerry, this is
	// now possible -- connect "nav_edit 1" area 51 (inside elevator) to 13730 (outside),
	// which -1 direction (so it's automatically set, I guess instead of NEWS/NSWE). This
	// will allow Survivors to enter/exit, and "_jimmy_nav_step" was "SI Players and AI"
	// originally but changed to "Everyone" since Survivors can't jump back in and ended
	// up just teleporting after sometime. ("Area 51" is a funny coincidence, I assure.)

	NavMesh.GetNavAreaByID( 51 ).ConnectTo( NavMesh.GetNavAreaByID( 13730 ), -1 );
	NavMesh.GetNavAreaByID( 13730 ).ConnectTo( NavMesh.GetNavAreaByID( 51 ), -1 );
}

function tsu_c1m4_jimmy_04_gnomeburst()
{
	// Gnome Chompsky's function spawns it with 0 delay, but the actual burst from this
	// firework glow has a bit of a delay itself, so handle it right now -- Chompsky's
	// own function adds 3 "mysts of confetti" to further help sell his appearance.

	// Observe that the "info_particle_target" is REQUIRED, but can be identical to System.

	make_particle( "_jimmy_gnome_burst", "-4430 -2074 64", "0 0 0", "fireworks_explosion_glow_02", "-4430 -2074 64" );

	EntFire( g_UpdateName + "_jimmy_gnome_burst" + "_*", "Kill", null, 4 );
}

function tsu_c1m4_jimmy_04_chargerexit()
{
	// This function is called when Jimmy has landed beside the car and has effectively
	// entered it, revs it up, and drives away. With 2.7 second delay so the hint persists
	// during his entire revving of it up, delete the hint to cease it for everybody.

	EntFire( g_UpdateName + "_jimmy_hint_stealcar", "Kill", null, 2.7 );

	// Play the actual animation where Jimmy is (supposedly) driving away. First off,
	// choose a random Integer between 1 and 2 to decide necessity of further steps.
	// Delete the outro camera and fades so Valve's relay can still be used otherwise!
	// Delete the obstructive "env_player_blocker" over the mall directory (aka map).
	// Then delete "mall_directory" which is just a permanent and solid prop-dynamic
	// copy of the animated "escape_directory". Inject "Cam_selector_1" with I/O that
	// deletes "escape_directory" with an 8 sec delay since it will "originate" back
	// to its solid form after Valve's relay plays the animation, which is unwanted.
	// Once everything is over, delete all "escape_" stuff to cease the flipping zombie.
	// Opening the "func_areaportal" was an easily-accessible bonus to see outside!!
	// Also prevent the car's glass from "popping in" briefly when it blasts through door.

	EntFire( "exitdoor_portal", "Open" );

	make_prop( "dynamic", "_jimmy_wrongway", "models/props_placeable/wrong_way.mdl", "-4448 -2293 -23", "0 270 0", "shadow_no", "solid_no", "255 255 255", "17", "217" );

	EntFire( "gas_nozzle", "Kill" );
	EntFire( "escape_car_glass_out", "Kill" );

	EntFire( "camera_outro_*", "Kill" );
	EntFire( "fade_outro_*", "Kill" );

	local intRandom = RandomInt( 1, 2 );

	switch( intRandom )
	{
		case 1:

			// Observe that this "env_player_blocker" is only spawned once
			// ever by _commentary.txt -- this would give an error 2nd round
			// if Kill() was used, but the below or kill_entity() are safe!

			DoEntFire( "!self", "Kill", "", 0.0, null, Entities.FindByClassnameNearest( "env_player_blocker", Vector( -4492, -2767, 9 ), 1 ) );

			EntFire( "mall_directory", "Kill" );

			EntFire( "Cam_selector_1", "AddOutput", "OnTrigger escape_directory:Kill::7:-1" );

			EntFire( "Cam_selector_1", "Trigger" );

			EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_04_glassbreak", 10 );

			break;

		case 2:

			EntFire( "Cam_selector_2", "Trigger" );

			EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_04_glassbreak", 5 );

			break;
	}

	EntFire( "escape_*", "Kill", null, 8 );

	// Finally hand over control to Gnome Chompsky, after a "WTF?!" delay.

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_04_gnomeburst", 32 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_gnomehero", 34 );

	// Not sure how this hasn't been a huge oversight/problem as Commons did seem
	// to function enough, but it's the best time to delete "info_goal_infected_chase".

	EntFire( g_UpdateName + "_jimmygibbs_goalchaser", "Kill" );
}

// STAGE 05 :: GNOME HERO
/////////////////////////

function tsu_c1m4_jimmy_05_entities()
{
	// As the "env_physics_blocker" parent is the non-solid "func_movelinear",
	// note that BBOX error spam resulted and the clip wasn't solid because my
	// original clip was lazily rotated (instead of adjusting the mins/maxs),
	// causing it to become a "Physics Object", hence the Valve Wiki's warning.

	// Overall: Clip Survivor access away because they can clog the rotators
	// which SI Players will still be able to do but only if Survivor players
	// allow it; Push Survivor+Infected away from the blades; and finally, Hurt
	// and instantly FULLGIB all Commons to touch the blade (BILE HEAVEN)!!

	make_clip( "_jimmy_xtra_clip", "Survivors", 1, "-29 -61 0", "29 53 1337", "-4430 -2073 0" );
	make_trigpush( "_jimmy_xtra_push", "Everyone", 216, "0 270 0", "-30 -62 0", "30 -61 52", "-4430 -2073 0" );
	make_trighurt( "_jimmy_xtra_hurt", "Infected", "-29 -61 0", "29 -53 52", "-4430 -2073 0" );

	// The spawned trighurt is "spawnflags 1" for Clients Only (players / SI bots),
	// instead change it to NPC for Commons-only with "FULLGIB" -- which is FGD-only
	// and not on Valve Wiki http://src-ents.shoutwiki.com/wiki/Left_4_Dead_2/base.fgd.

	EntFire( g_UpdateName + "_jimmy_xtra_hurt", "AddOutput", "damagetype 16777216" );
	EntFire( g_UpdateName + "_jimmy_xtra_hurt", "AddOutput", "spawnflags 2" );

	// Repeat the above gimmick with a new "trigger_hurt" that spans the length and
	// width of the entire car, does "damagetype 8" for FIRE, and still to NPC / Commons
	// only, but initially-Disabled to only Enable it during "Sparkshower sequences".

	make_trighurt( "_jimmy_xtra_fire", "Infected", "-48 -80 0", "48 80 128", "-4430 -2074 0" );
	EntFire( g_UpdateName + "_jimmy_xtra_fire", "AddOutput", "damagetype 8" );
	EntFire( g_UpdateName + "_jimmy_xtra_fire", "AddOutput", "spawnflags 2" );
	EntFire( g_UpdateName + "_jimmy_xtra_fire", "Disable" );

	// Killed on STAGE 6, these are easy additions to prevent Survivors/Infected from
	// boarding the trolley in advance which, once the kiosk is reached, collision with
	// its UNDELETABLE BSP CLIP could obstruct movement of the toycar/movelinear. Note
	// that this 100% confirmed that if you're standing in 2 "trigger_push" at once,
	// then you experience the effect of neither -- hence, front and back have their
	// own devoted triggers which cover the entire front/back and only push 1 direction.

	make_trigpush( "_jimmy_xtra_push_right", "Everyone", 220, "0 180 0", "-29 -64 0", "0 166 128", "-4430 -2074 0" );
	make_trigpush( "_jimmy_xtra_push_left", "Everyone", 220, "0 0 0", "0 -64 0", "29 166 128", "-4430 -2074 0" );
	make_trigpush( "_jimmy_xtra_push_front", "Everyone", 220, "0 180 0", "-29 -80 0", "29 -64 128", "-4430 -2074 0" );
	make_trigpush( "_jimmy_xtra_push_back", "Everyone", 220, "0 0 0", "-29 166 0", "29 182 128", "-4430 -2074 0" );

	// Ordinary model props where only the toycar is colored.

	make_prop( "dynamic_ovr", "_jimmy_main_chompsky", "models/props_junk/gnome.mdl", "-4419 -2069 33", "0 50.5 0", "shadow_no" );

	// For future particle-adjusting reference: "_pyro_left" was originally Z = 11 and
	// "0 0 0" changed to Z = 12 "20 0 0", and "_pyro_right" was originally Z = 11 and
	// "0 0 0" changed to Z = 12 and "-20 0 0" -- match these for identical "angel wings".
	// Both sides are "solid_no" so that I didn't have to make the clip/push/hurt wider.

	make_prop( "dynamic", "_jimmy_main_bear", "models/props_interiors/teddy_bear.mdl", "-4443 -2034 10.5", "0 296 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_prop_blades", "models/props/de_prodigy/fan.mdl", "-4430 -2129 25", "90 90 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball01", "models/props_fairgrounds/single_light.mdl", "-4427.9 -2072.9 131.2", "44.09 258.84 -15.79" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball02", "models/props_fairgrounds/single_light.mdl", "-4427.8 -2071.53 131.2", "44.09 303.84 -15.79" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball03", "models/props_fairgrounds/single_light.mdl", "-4428.7 -2070.1 131.2", "44.09 348.84 -15.79" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball04", "models/props_fairgrounds/single_light.mdl", "-4427.8 -2072.27 112.4", "-44.09 56.16 164.21" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball05", "models/props_fairgrounds/single_light.mdl", "-4431.1 -2070.8 131.4", "44.09 78.84 -15.79" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball06", "models/props_fairgrounds/single_light.mdl", "-4428.93 -2070 112.4", "-44.09 146.16 164.21" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball07", "models/props_fairgrounds/single_light.mdl", "-4430.3 -2073.7 131.4", "44.09 168.84 -15.79" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball08", "models/props_fairgrounds/single_light.mdl", "-4428.93 -2073.8 131.2", "44.09 213.84 -15.79" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball09", "models/props_fairgrounds/single_light.mdl", "-4431.3 -2065.9 114.6", "-0.13 278 172" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball10", "models/props_fairgrounds/single_light.mdl", "-4420 -2069.9 120.8", "44.8 191.3 -179.96" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball11", "models/props_fairgrounds/single_light.mdl", "-4427.7 -2077.6 114.4", "-0.13 98 172" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball12", "models/props_fairgrounds/single_light.mdl", "-4431.3 -2078 129.4", "0.13 82 -8" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball13", "models/props_fairgrounds/single_light.mdl", "-4439 -2070.3 123", "-44.8 348.7 0.04" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball14", "models/props_fairgrounds/single_light.mdl", "-4427.7 -2066.3 129.2", "0.13 262 -8" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball15", "models/props_fairgrounds/single_light.mdl", "-4435.4 -2073.5 114.4", "-0.13 8 172" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball16", "models/props_fairgrounds/single_light.mdl", "-4435.3 -2070.3 129.2", "0.13 352 -8" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball17", "models/props_fairgrounds/single_light.mdl", "-4423.7 -2069.9 114.6", "-0.13 188 172" );
	make_prop( "dynamic", "_jimmy_prop_disco_ball18", "models/props_fairgrounds/single_light.mdl", "-4423.6 -2073.9 129.4", "0.13 172 -8" );
	make_prop( "dynamic", "_jimmy_main_escapecart", "models/props/de_prodigy/pushcart.mdl", "-4430 -1949 16", "0 270 0" );
	make_prop( "dynamic", "_jimmy_main_gator", "models/props_fairgrounds/alligator.mdl", "-4423 -2043 10.5", "0 138 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_main_pole", "models/weapons/melee/w_pitchfork.mdl", "-4430.4 -2072.2 81", "0 0 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_main_pyro_back", "models/props_fairgrounds/mortar_rack.mdl", "-4430 -2024 40", "0 180 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_main_pyro_left", "models/props_fairgrounds/pyrotechnics_launcher.mdl", "-4406 -2068 12", "20 0 0", "shadow_no", "solid_no" );
	make_prop( "dynamic", "_jimmy_main_pyro_right", "models/props_fairgrounds/pyrotechnics_launcher.mdl", "-4454 -2068 12", "-20 0 0", "shadow_no", "solid_no" );
	make_prop( "dynamic", "_jimmy_main_pyro_top", "models/props_fairgrounds/pyrotechnics_launcher.mdl", "-4430 -2047 65", "0 270 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_main_stout", "models/props_urban/chimney002.mdl", "-4430 -2129 25", "90 90 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_main_toycar", "models/props_fairgrounds/kiddyland_ridecar.mdl", "-4430 -2074 0", "0 270 0", "shadow_yes", "solid_yes", "48 16 107" );

	// Sell even more character -- he's FUCKING NUCLEAR. Gascans can be purple or black, too.
	// Shadows need disabling b/c toycar's is the main shadow, and regarding bullet holes in
	// an "active gascan with fluid inside" looks weird, so disable collision as well -- note
	// that the already-poured Jimmy Gibbs gascans are solid and do get bullet holes, which
	// makes consistent sense to the game's logic of those cans being empty.

	make_prop( "dynamic_ovr", "_jimmy_main_nuclear_left", "models/props_junk/gascan001a.mdl", "-4423 -2025 32", "0 90 0", "shadow_no", "solid_no", "170 216 0" );
	make_prop( "dynamic_ovr", "_jimmy_main_nuclear_right", "models/props_junk/gascan001a.mdl", "-4437 -2025 32", "0 270 0", "shadow_no", "solid_no", "145 188 17" );

	// Infinite Golden Crowbar to MATCH **Official** Jeff+Ricky c12m2 easter egg.

	SpawnEntityFromTable( "weapon_melee_spawn", { targetname = g_UpdateName + "_jimmy_weapon_jeffricky", origin = Vector( -4446, -2038, 11 ), angles = Vector( 14, -112, 0 ), melee_weapon = "crowbar", skin = 1, weaponskin = 1, count = 99 } );

	// Bile jars... BECAUSE THIS FINALE WILL BE FUCKING INTENSE AND CHOMPSKY WILL HELP KILL.

	SpawnEntityFromTable( "weapon_vomitjar_spawn", { targetname = g_UpdateName + "_jimmy_weapon_bile_1", origin = Vector( -4440, -2069, 27 ), angles = Vector( 0, 0, 0 ), count = 1 } );
	SpawnEntityFromTable( "weapon_vomitjar_spawn", { targetname = g_UpdateName + "_jimmy_weapon_bile_2", origin = Vector( -4440, -2065, 24 ), angles = Vector( 0, 80, 90 ), count = 1 } );
	SpawnEntityFromTable( "weapon_vomitjar_spawn", { targetname = g_UpdateName + "_jimmy_weapon_bile_3", origin = Vector( -4418, -2069, 27 ), angles = Vector( 0, 45, 0 ), count = 1 } );
	SpawnEntityFromTable( "weapon_vomitjar_spawn", { targetname = g_UpdateName + "_jimmy_weapon_bile_4", origin = Vector( -4414, -2065, 27 ), angles = Vector( 0, 170, 0 ), count = 1 } );

	// PARTICLES -- which are SetParented seconds later, Parenting sounds is OK when they're Stop/Started again

	// Unintended but OK side effect: particles are Started with * wildcards,
	// this means that for most if not all my uses sparkshowers will include
	// the confetti... the confetti is OK as it'll hardly be seen and isn't
	// the "main attraction"... in words of Bob Ross, "happy little accident".

	make_particle( "_jimmy_particle_top_1_sparks", "-4414 -2047 81", "-60 0 0", "fireworks_sparkshower_01" );
	make_particle( "_jimmy_particle_top_2_sparks", "-4430 -2047 85", "-90 0 0", "fireworks_sparkshower_01" );
	make_particle( "_jimmy_particle_top_3_sparks", "-4446 -2047 81", "-60 180 -180", "fireworks_sparkshower_01" );

	make_particle( "_jimmy_particle_left_1_sparks", "-4400 -2084 28", "-40 290 -180", "fireworks_sparkshower_01" );
	make_particle( "_jimmy_particle_left_2_sparks", "-4398 -2068 32", "-70 0 0", "fireworks_sparkshower_01" );
	make_particle( "_jimmy_particle_left_3_sparks", "-4400 -2052 28", "-40 70 0", "fireworks_sparkshower_01" );

	make_particle( "_jimmy_particle_right_1_sparks", "-4460 -2084 28", "-40 250 180", "fireworks_sparkshower_01" );
	make_particle( "_jimmy_particle_right_2_sparks", "-4462 -2068 32", "-70 180 0", "fireworks_sparkshower_01" );
	make_particle( "_jimmy_particle_right_3_sparks", "-4460 -2052 28", "-40 110 0", "fireworks_sparkshower_01" );

	make_particle( "_jimmy_particle_top_1_confetti", "-4414 -2047 81", "-60 0 0", "mini_fireworks" );
	make_particle( "_jimmy_particle_top_2_confetti", "-4430 -2047 85", "-90 0 0", "mini_fireworks" );
	make_particle( "_jimmy_particle_top_3_confetti", "-4446 -2047 81", "-60 180 -180", "mini_fireworks" );

	make_particle( "_jimmy_particle_left_1_confetti", "-4400 -2084 28", "-40 290 -180", "mini_fireworks" );
	make_particle( "_jimmy_particle_left_2_confetti", "-4398 -2068 32", "-70 0 0", "mini_fireworks" );
	make_particle( "_jimmy_particle_left_3_confetti", "-4400 -2052 28", "-40 70 0", "mini_fireworks" );

	make_particle( "_jimmy_particle_right_1_confetti", "-4460 -2084 28", "-40 250 180", "mini_fireworks" );
	make_particle( "_jimmy_particle_right_2_confetti", "-4462 -2068 32", "-70 180 0", "mini_fireworks" );
	make_particle( "_jimmy_particle_right_3_confetti", "-4460 -2052 28", "-40 110 0", "mini_fireworks" );

	// Originally all angles were "0 180 0" which shot them all straight up
	// and they all sorta uselessly blended into one big explosion. Originally
	// _back_1 was "-4414", 2 "-4430" and 3 "-4446", but due to the fact that
	// these are -700 units into the ground, they need to "criss-cross" more
	// because of the introduced angles, so 1 and 3 were flipped. Furthermore,
	// they were moved 30 more units to allow a more extreme 5-angle.

	make_particle( "_jimmy_particle_back_1_pink", "-4476 -2024 -700", "-5 180 0", "fireworks_01" );
	make_particle( "_jimmy_particle_back_1_blue", "-4476 -2024 -700", "-5 180 0", "fireworks_02" );
	make_particle( "_jimmy_particle_back_1_cone", "-4476 -2024 -700", "-5 180 0", "fireworks_03" );
	make_particle( "_jimmy_particle_back_1_boom", "-4476 -2024 -700", "-5 180 0", "fireworks_04" );

	make_particle( "_jimmy_particle_back_2_pink", "-4430 -2024 -700", "0 180 0", "fireworks_01" );
	make_particle( "_jimmy_particle_back_2_blue", "-4430 -2024 -700", "0 180 0", "fireworks_02" );
	make_particle( "_jimmy_particle_back_2_cone", "-4430 -2024 -700", "0 180 0", "fireworks_03" );
	make_particle( "_jimmy_particle_back_2_boom", "-4430 -2024 -700", "0 180 0", "fireworks_04" );

	make_particle( "_jimmy_particle_back_3_pink", "-4384 -2024 -700", "5 180 0", "fireworks_01" );
	make_particle( "_jimmy_particle_back_3_blue", "-4384 -2024 -700", "5 180 0", "fireworks_02" );
	make_particle( "_jimmy_particle_back_3_cone", "-4384 -2024 -700", "5 180 0", "fireworks_03" );
	make_particle( "_jimmy_particle_back_3_boom", "-4384 -2024 -700", "5 180 0", "fireworks_04" );

	// Tricky finessing required for these.

	make_particle( "_jimmy_particle_balloon_1a", "-4410.05 -1984.07 17", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_1b", "-4410.05 -1984.07 17", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_2a", "-4450.05 -1984.07 17", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_2b", "-4450.05 -1984.07 17", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_3a", "-4418.05 -1916.07 51", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_3b", "-4418.05 -1916.07 51", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_4a", "-4442.05 -1916.07 51", "0 0 0", "balloon" );
	make_particle( "_jimmy_particle_balloon_4b", "-4442.05 -1916.07 51", "0 0 0", "balloon" );

	// Stop all particles before they have time to initially activate, as make_particle() automatically does.

	EntFire( g_UpdateName + "_jimmy_particle_*", "Stop" );

	// Now manually activate each of the balloons, one by one with a delay, so they're all different seeds/colors.

	EntFire( g_UpdateName + "_jimmy_particle_balloon_1a" + "_system", "Start", null, 0.1 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_1b" + "_system", "Start", null, 0.2 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_2a" + "_system", "Start", null, 0.3 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_2b" + "_system", "Start", null, 0.4 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_3a" + "_system", "Start", null, 0.5 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_3b" + "_system", "Start", null, 0.6 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_4a" + "_system", "Start", null, 0.7 );
	EntFire( g_UpdateName + "_jimmy_particle_balloon_4b" + "_system", "Start", null, 0.8 );

	// ROPES -- for trolley connection (strung Christmas lights cannot be parented or deleted even on round transition!)

	// It is 100% required for the keyframe to be created BEFORE the move!

	SpawnEntityFromTable( "keyframe_rope", { targetname = g_UpdateName + "_jimmy_rope_left_key", RopeMaterial = "cable/metal.vmt", origin = Vector( -4410.07, -2026.95, 30 ) } );
	SpawnEntityFromTable( "keyframe_rope", { targetname = g_UpdateName + "_jimmy_rope_right_key", RopeMaterial = "cable/metal.vmt", origin = Vector( -4450.07, -2026.95, 30 ) } );
	SpawnEntityFromTable( "move_rope", { targetname = g_UpdateName + "_jimmy_rope_left_move", NextKey = g_UpdateName + "_jimmy_rope_left_key", RopeMaterial = "cable/metal.vmt", origin = Vector( -4410.05, -1984.07, 18 ) } );
	SpawnEntityFromTable( "move_rope", { targetname = g_UpdateName + "_jimmy_rope_right_move", NextKey = g_UpdateName + "_jimmy_rope_right_key", RopeMaterial = "cable/metal.vmt", origin = Vector( -4450.05, -1984.07, 18 ) } );

	// SOUND EFFECTS -- can be parented to main "func_movelinear" but must be Stop/Play'd to update emit location

	// Sparkshower sounds will always play as 2-3 so will multiply accidentally
	// to be louder. If the player is near extreme ends of the atrium then noclips
	// to the car, the sound won't be heard, but players naturally cannot move that
	// quickly -- but I should account for faster-moving SI Players, so I changed it
	// from 5000 radius to 10000 to accommodate their auditory experience better.

	make_noise( "sound", "_jimmy_sound_top_sparks", "-4430 -2047 85", 10000, "c2m5.burn_baby_burn", true );
	make_noise( "sound", "_jimmy_sound_left_sparks", "-4398 -2068 32", 10000, "c2m5.burn_baby_burn", true );
	make_noise( "sound", "_jimmy_sound_right_sparks", "-4462 -2068 32", 10000, "c2m5.burn_baby_burn", true );

	// Fireworks launch needs to be where the "mortar rack" emitter model is, then
	// the actual burst/explosion just a bit higher up (but not too high, as players
	// will be near the ground most of the time). To compensate for the increased
	// music volume and stereoness of it, increased these radius 5000 to 10000. While
	// I originally had them -700 units under the map and their volume was erroneously
	// low, I'm still creating duplicates of them since fireworks SHOULD be heard
	// over the music, but only slightly, and DEFINITELY anywhere inside the atrium!

	make_noise( "sound", "_jimmy_sound_back_launch", "-4430 -2024 40", 10000, "c2m5.fireworks_launch", true );
	make_noise( "sound", "_jimmy_sound_back_launch", "-4430 -2024 40", 10000, "c2m5.fireworks_launch", true );
	make_noise( "sound", "_jimmy_sound_back_burst", "-4430 -2024 640", 10000, "c2m5.fireworks_burst", true );
	make_noise( "sound", "_jimmy_sound_back_burst", "-4430 -2024 640", 10000, "c2m5.fireworks_burst", true );
}

function tsu_c1m4_jimmy_05_lightroll()
{
	// The small problem here is the fact that this "off" SoundScript isn't
	// that loud, the "on" variant is slightly louder, but in both cases there
	// are extreme ends of the map where the sound cannot be heard when it
	// should be, as this is a dramatic moment. Another issue was both of
	// these light on/off sounds are NOT parented but were erroneously at
	// the toycar's "-2074" position, corrected by -1400 from it to bring it
	// towards the final toycar's center place.

	// In short, moved both these sounds 1400 units and increased radius 5000
	// to 15000 to help it be heard anywhere -- the "rolling redundancy" will
	// still create the effect of the sound getting progressively louder.
	// They were also both moved up 170 units so it sounds a bit "higher up".

	make_noise( "sound", "_jimmy_lightroll", "-4430 -3474 170", 15000, "c2m5.house_light_off" );
}

function tsu_c1m4_jimmy_05_lightsout()
{
	// Respective BSP defaults for reference: "5+11+13" / "1" / "4000" / "1.0".
	// The other "foginteriorcontroller" seemed to do nothing so is ignored!!

	EntFire( "fog_master", "SetColor", "0+0+0" );
	EntFire( "fog_master", "SetStartDist", "0" );
	EntFire( "fog_master", "SetEndDist", "0" );
	EntFire( "fog_master", "SetMaxDensity", "0.95" );

	// As the "rolling effect" gets quite loud, double-up on this one's volume,
	// too, so it's abundantly audible. Multiplying "ambient_generic" is, as always,
	// a workaround from being unable to edit SoundScripts server-side.

	make_noise( "sound", "_jimmy_lighthard", "-4430 -3474 170", 15000, "c2m5.stage_light_on" );
	make_noise( "sound", "_jimmy_lighthard", "-4430 -3474 170", 15000, "c2m5.stage_light_on" );

	// CLEAN UP THIS RIDICULOUS AMOUNT OF AMBIENT_GENERICS !!

	EntFire( g_UpdateName + "_jimmy_light*", "Kill", null, 2 );
}

function tsu_c1m4_jimmy_05_lightsoff()
{
	// Originally it was just the CallScriptFunctions to have sound effects that
	// roll, with ultimately the lights all going off all at once at the very end.
	// This was updated so that _lightsout() still represents the "final state" of
	// everything, but here I add some extra in-betweens. The first time the sound
	// effect plays, Valve's default fog color looks wrong so immediately change it
	// to SetColor 0+0+0 and never go back (hence _lightsout() is redundant but play
	// along with me here). Valve's Density default of 1 is far too harsh, so to
	// create the best illusion change color to all-Black, then work up from Density
	// 0.50 until the "rolling blackout" is done with, StartDist can be the same but
	// will become 0 at the very end, and EndDist is also in-betweened.

	EntFire( "fog_master", "SetColor", "0+0+0" );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightroll", 0.1 );
	EntFire( "fog_master", "SetEndDist",	"4000",	0.1 );
	EntFire( "fog_master", "SetMaxDensity",	"0.50",	0.1 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightroll", 1.0 );
	EntFire( "fog_master", "SetEndDist",	"3000",	1.0 );
	EntFire( "fog_master", "SetMaxDensity",	"0.55",	1.0 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightroll", 1.8 );
	EntFire( "fog_master", "SetEndDist",	"2000",	1.8 );
	EntFire( "fog_master", "SetMaxDensity",	"0.65",	1.8 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightroll", 2.5 );
	EntFire( "fog_master", "SetEndDist",	"1000",	2.5 );
	EntFire( "fog_master", "SetMaxDensity",	"0.75",	2.5 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightroll", 3.1 );
	EntFire( "fog_master", "SetEndDist",	"500",	3.1 );
	EntFire( "fog_master", "SetMaxDensity",	"0.85",	3.1 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightroll", 3.6 );
	EntFire( "fog_master", "SetEndDist",	"250",	3.6 );
	EntFire( "fog_master", "SetMaxDensity",	"0.90",	3.6 );

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightsout", 4.5 );
}

function tsu_c1m4_jimmy_05_discorays()
{
	make_discoray( "_jimmy_disco_01",	"-4429.57 -2056.85 122",	"0 90 0" );
	make_discoray( "_jimmy_disco_02",	"-4440.22 -2061.3 121.982",	"0 135 180" );
	make_discoray( "_jimmy_disco_03",	"-4444.62 -2071.9 121.982",	"0 180 -180" );
	make_discoray( "_jimmy_disco_04",	"-4440.24 -2082.51 121.982",	"0 225 180" );
	make_discoray( "_jimmy_disco_05",	"-4429.55 -2086.97 122",	"0 270 0" );
	make_discoray( "_jimmy_disco_06",	"-4418.93 -2082.51 122",	"0 315 0" );
	make_discoray( "_jimmy_disco_07",	"-4414.5 -2071.9 122",		"0 0 0" );
	make_discoray( "_jimmy_disco_08",	"-4418.93 -2061.3 122",		"0 45 0" );
	make_discoray( "_jimmy_disco_09",	"-4429.57 -2061.27 132.651",	"-45 90 0" );
	make_discoray( "_jimmy_disco_10",	"-4429.57 -2071.9 137.053",	"-90 0 0" );
	make_discoray( "_jimmy_disco_11",	"-4429.55 -2082.55 132.639",	"-45 270 0" );
	make_discoray( "_jimmy_disco_12",	"-4429.55 -2082.57 111.351",	"45 270 0" );
	make_discoray( "_jimmy_disco_13",	"-4429.55 -2071.9 106.93",	"90 0 0" );
	make_discoray( "_jimmy_disco_14",	"-4429.57 -2061.25 111.338",	"45 90 0" );
	make_discoray( "_jimmy_disco_15",	"-4440.23 -2071.9 132.589",	"-45 180 -180" );
	make_discoray( "_jimmy_disco_16",	"-4440.23 -2071.9 111.375",	"45 180 180" );
	make_discoray( "_jimmy_disco_17",	"-4418.94 -2071.9 132.688",	"-45 0 0" );
	make_discoray( "_jimmy_disco_18",	"-4418.92 -2071.9 111.301",	"45 0 0" );
}

function tsu_c1m4_jimmy_05_parenting()
{
	// Create the "func_movelinear" Gnome Chompsky and Co. will move across.
	// Note that "func_tracktrain" would be unnecessarily more complex.

	make_moveline( "_jimmy_moveline_main", "-4430 -2074 0", "0 270 0", 1400, 80 );

	// Parent the "_main"-prefixes to it -- rotators handle the rest!

	EntFire( g_UpdateName + "_jimmy_main_*", "SetParent", g_UpdateName + "_jimmy_moveline_main" );
	EntFire( g_UpdateName + "_jimmy_xtra_*", "SetParent", g_UpdateName + "_jimmy_moveline_main" );

	// I wasted several hours debugging a crash because of "_jimmy_disco_*",
	// which required "_jimmy_rotator"-prefixing for the rotators since I
	// originally named them "_jimmy_disco_" so I entered Parenting Hell.
	// It's fixed now... just be cautious to NEVER get stuck in that again!

	make_rotator( "_jimmy_rotator_disco_x", "-4429.5 -2071.5 122", "x", g_UpdateName + "_jimmy_moveline_main" );
	make_rotator( "_jimmy_rotator_disco_y", "-4429.5 -2071.5 122", "y", g_UpdateName + "_jimmy_moveline_main" );
	make_rotator( "_jimmy_rotator_blades_y", "-4430 -2129 25", "y", g_UpdateName + "_jimmy_moveline_main" );

	EntFire( g_UpdateName + "_jimmy_disco_*", "SetParent", g_UpdateName + "_jimmy_rotator_disco_x" );
	EntFire( g_UpdateName + "_jimmy_prop_disco_*", "SetParent", g_UpdateName + "_jimmy_rotator_disco_x" );
	EntFire( g_UpdateName + "_jimmy_rotator_disco_x", "SetParent", g_UpdateName + "_jimmy_rotator_disco_y" );
	EntFire( g_UpdateName + "_jimmy_prop_blades", "SetParent", g_UpdateName + "_jimmy_rotator_blades_y" );

	// SetParent weapons, particles, ropes and sounds to the main "func_movelinear".

	EntFire( g_UpdateName + "_jimmy_weapon_*", "SetParent", g_UpdateName + "_jimmy_moveline_main" );
	EntFire( g_UpdateName + "_jimmy_particle_*", "SetParent", g_UpdateName + "_jimmy_moveline_main" );
	EntFire( g_UpdateName + "_jimmy_rope_*", "SetParent", g_UpdateName + "_jimmy_moveline_main" );
	EntFire( g_UpdateName + "_jimmy_sound_*", "SetParent", g_UpdateName + "_jimmy_moveline_main" );

	// Note that the make_rotator() function itself was altered for better
	// support here -- "SetSpeed" means "Start spinning at this % of the max",
	// whereas "Start" means "Start at 'maxspeed'" (which is annoying). Thus,
	// make_rotator() starts everything initially OFF since "maxspeed" sucks
	// and, if I don't do that, "SetSpeed" too soon post-creation halts spin.

	EntFire( g_UpdateName + "_jimmy_rotator_disco_*", "SetSpeed", 0.03 );
	EntFire( g_UpdateName + "_jimmy_rotator_blades_y", "SetSpeed", 0.5 );
}

function tsu_c1m4_jimmy_05_tolhearts()
{
	// Separated into a function for necessary delay since I don't want these
	// to appear until the speaker / "heart gateway" has "OnFullyOpen" risen.

	make_particle( "_jimmy_heart_tol_left1", "-4593 -3226 179", "-30 180 0", "string_lights_heart_02", "-4593 -3226 133" );
	make_particle( "_jimmy_heart_tol_left2", "-4593 -3226 179", "-30 0 0", "string_lights_heart_02", "-4593 -3226 133" );
	make_particle( "_jimmy_heart_tol_right1", "-4309 -3226 179", "-30 180 0", "string_lights_heart_02", "-4309 -3226 133" );
	make_particle( "_jimmy_heart_tol_right2", "-4309 -3226 179", "-30 0 0", "string_lights_heart_02", "-4309 -3226 133" );
}

function tsu_c1m4_jimmy_05_savesugar()
{
	// SAVE ME SOME SUGAR (without delay)

	make_noise( "music", "_jimmy_music_savesugar_everywhere", "0 0 0", 0, "music/flu/jukebox/save_me_some_sugar_mono.wav" );

	// Experimental: The above is "Play Everywhere" but still isn't exactly as loud
	// as maybe it should be -- so, supplement it with a "local, normal" sound emission
	// from the location of the "Heart Gateway" (where the speakers rise up) so that
	// it's "layered loud" when near Gnome Chompsky with a radius, plus Plays Everywhere.

	// Experimental Continued: ACTUALLY MORE LOGICAL THAN EXPECTED... while 20000 radius
	// isn't very far, nor even entirely functional, it still does sound good, and if
	// there's several "layered copies" -- in this case LEFT speakers have 2 copies and
	// the RIGHT speakers have 2 copies, combined with the "Play Everywhere" -- the end
	// result is a very realistic audible experience !!

	// EXPLANATION :: The "_everywhere" copy isn't mandatory, BUT if the player isn't
	// within vicinity of the 20000 radius or walks out of that radius after the song
	// starts, it won't play when walking back in -- this is just an "ambient_generic"
	// quirk because the same can be seen by being far away from Gnome Chompsky when
	// the "sparkshower" sound effect plays, then rapidly noclipping at him, where it
	// is clearly not audible because player wasn't in radius. At 5000 radius, music
	// started dampening far before either extreme end of the atrium... at 10000, it
	// lasted until at least the extreme end walls of the atrium... at 20000, it was
	// increased to this and even though the music seemed to fade with mitigated return
	// this number ensures a Survivor can't step outside of the radius. Overall, the
	// "_everywhere" copy can be done without, as it's the 4x "_stereo" that localize
	// the music in a believable way and are still loud enough to be heard everywhere,
	// reducing the "_everywhere" copy to more of a failsafe. Overall, it was important
	// to me that the speaker models sound like they're emitting sound, but at the
	// original 5000 radius it ceased when walking too far away -- but not at 20000 !!

	// UNKNOWNS: The "_everywhere" will hopefully be persistent for players joining after
	// the music had already started... if not, maybe "ambient_music" is necessary to
	// look into, but even that on c2m5 Dark Carnival 5 has quirks like not being audible
	// to SI Players who are currently in Ghost mode.

	make_noise( "sound", "_jimmy_music_savesugar_stereol", "-4596 -3207 0", 20000, "music/flu/jukebox/save_me_some_sugar_mono.wav" );
	make_noise( "sound", "_jimmy_music_savesugar_stereol", "-4596 -3207 0", 20000, "music/flu/jukebox/save_me_some_sugar_mono.wav" );
	make_noise( "sound", "_jimmy_music_savesugar_stereor", "-4306 -3207 0", 20000, "music/flu/jukebox/save_me_some_sugar_mono.wav" );
	make_noise( "sound", "_jimmy_music_savesugar_stereor", "-4306 -3207 0", 20000, "music/flu/jukebox/save_me_some_sugar_mono.wav" );

	// HEART GATEWAY -- includes its own parenting steps... because it was cleaner to bundle it all here.

	// Immediately for the song's "first long guitar string" intro (w/e its called),
	// block the navmesh and spawn a "trigger_push" to push player out of clip's way.

	make_navblock( "_jimmy_speaker_navblock", "Everyone", "Apply", "-164 -8 -32", "164 8 32", "-4451 -3188 0" );
	make_trigpush( "_jimmy_speaker_push", "Everyone", 440, "0 90 0", "-178 -23 -32", "178 23 1016", "-4451 -3207 32" );

	// Immediately spawn in an initially-Disabled clip, but with 2 second delay fire
	// Enable to it and also Kill the above "trigger_push".

	make_clip( "_jimmy_speaker_clip", "Survivors", 0, "-178 -23 -32", "178 23 1016", "-4451 -3207 32" );

	EntFire( g_UpdateName + "_jimmy_speaker_clip", "Enable", null, 2 );
	EntFire( g_UpdateName + "_jimmy_speaker_push", "Enable", null, 3 );

	// Spawn props for "speaker1" (the archway, speakers and top girder) and
	// props for "speaker2" (the visual rationale for kiosk's UNDELETABLE CLIP).
	// Note that "speaker1" is embedded 200 units into the ground and "speaker2"
	// is embedded 102 units into the ground.

	make_prop( "dynamic", "_jimmy_speaker1_tol", "models/props_fairgrounds/tol_tunnel_heart.mdl", "-4451 -3207 -102", "0 90 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_speaker1_ampl", "models/props_fairgrounds/hanging_amp.mdl", "-4596 -3207 0", "0 180 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_speaker1_ampr", "models/props_fairgrounds/hanging_amp.mdl", "-4306 -3207 0", "0 0 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_speaker1_topl", "models/props_fairgrounds/stage_scaffold_128.mdl", "-4515 -3207.5 -13.1", "0 90 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_speaker1_topr", "models/props_fairgrounds/stage_scaffold_128.mdl", "-4387 -3207.5 -13.1", "0 90 0", "shadow_no" );

	make_prop( "dynamic", "_jimmy_speaker2_ampl", "models/props_fairgrounds/front_speaker.mdl", "-4467 -3207 -104", "0 -90 0", "shadow_no" );
	make_prop( "dynamic", "_jimmy_speaker2_ampr", "models/props_fairgrounds/front_speaker.mdl", "-4435 -3207 -104", "0 -90 0", "shadow_no" );

	// Create 2 "func_movelinear" for both of these "centerpieces", which will
	// raise up the number of units explained further above.

	make_moveline( "_jimmy_moveline_speaker1", "-4451 -3207 -102", "-90 0 0", 200, 80 );
	make_moveline( "_jimmy_moveline_speaker2", "-4451 -3207 -102", "-90 0 0", 102, 40 );

	EntFire( g_UpdateName + "_jimmy_speaker1_*", "SetParent", g_UpdateName + "_jimmy_moveline_speaker1" );
	EntFire( g_UpdateName + "_jimmy_speaker2_*", "SetParent", g_UpdateName + "_jimmy_moveline_speaker2" );

	// Cannot SetParent these particles for them to move with the entity, HOWEVER
	// unlike the "CHRISTMAS LIGHTS", **round transition does actually clear these**
	// so they're the only "strung light" viable option for use. Note that I tested
	// on c2m3 / Dark Carnival 3 with "ent_fire info_part* stop; ent_fire info_part* start"
	// by spamming Valve's strung-lights... they, too, don't all clear on transition
	// but CONFUSINGLY some do, just it's inconsistent which ones, and IDK if Valve
	// accounts for successive rounds not needing those particles Start'd again --
	// something tells me sometimes they may have settled on map-specific hard-coding
	// given just how broken/inconsistent these seem to be... heart works OK, though !!

	EntFire( g_UpdateName + "_jimmy_moveline_speaker1", "AddOutput", "OnFullyOpen worldspawn:CallScriptFunction:tsu_c1m4_jimmy_05_tolhearts:0:-1" );

	// For now we're only firing "Open" to "speaker1"... whereas "speaker2" will
	// get its turn when STAGE 6 has officially started with toycar at destination.

	EntFire( g_UpdateName + "_jimmy_moveline_speaker1", "Open" );

	// OMNI LIGHTS

	// Inconsistent place for a toycar SetParent, but just keeping it w/ other omni's.

	make_lightomni( "_jimmy_lightomni_toycar", "-4430 -2074 0", "Purple", "Underwater", 0, 400, 0 );
	EntFire( g_UpdateName + "_jimmy_lightomni_toycar", "SetParent", g_UpdateName + "_jimmy_main_toycar" );

	// Gateway omni's. SetParent is just easier than a new function to spawn them in late.
	// Plus it gives the effect of having lighting even before the particle-hearts spawn in.
	// The final resting Z of these is 156 but recall that the "func_movelinear" is 200 units
	// into the ground, so don't forget to make these initially start at -44!

	// NOTE: There's some quirk going on here where, after the discoball's light_dynamics are
	// deleted (all 18 of them for testing reasons), the gateway's omnis no longer illuminate
	// the model itself -- but do still illuminate the world. Why, I don't know, I don't change
	// their Spawnflags at any time, but could be a quirk from originating underneath the map
	// in a space that would "void leak" with ordinary BSP compilation and may be quirky here.
	// The lights still serve their exact temporary purpose, though.

	make_lightomni( "_jimmy_lightomni_left", "-4593 -3240 -44", "Purple", "Static", 2, 500, 0 );
	make_lightomni( "_jimmy_lightomni_right", "-4309 -3240 -44", "Purple", "Static", 2, 500, 0 );
	EntFire( g_UpdateName + "_jimmy_lightomni_left", "SetParent", g_UpdateName + "_jimmy_speaker1_tol" );
	EntFire( g_UpdateName + "_jimmy_lightomni_right", "SetParent", g_UpdateName + "_jimmy_speaker1_tol" );

	// LIGHT_DYNAMIC LIMIT
	//
	//	"For the 2013 SDK this is limited to 17 lights on at any one time so use wisely",
	//	according to the Valve Wiki. With find_ent and ent_fire TurnOff as well as ent_fire
	//	color, I doubly-confirmed (one-by-one) that this limit is actually 18 instead, the
	//	exact number of lights that I have/need by sheer accident... as if Valve intended
	//	for someone to someday create a discoball.
	//
	//	The above 3 new light_dynamic entities will come into existence and will correctly
	//	SetParent -- but they'll initially be turned off. If the discoball's 18 lights are
	//	off, the above 3 will work... if discoball's 18 lights are on, the above 3 will
	//	not work but WILL WORK if the last 3 of the discoball's lights are turned off in
	//	order to restore some of the "activation room". If there's say 21 dynamics spawned,
	//	and then you do "ent_fire light_dynamic TurnOff" then "TurnOn" toggle, they'll turn
	//	on in "entity ID order" so the last 3 spawned are not turned on.

	// Overall, the 3 omni's above are spawned in -- discoball's 18 lights are already spawned,
	// so it's expected these 3 will be off... TO FIX THIS, TurnOff the last 3 (16/17/18) to
	// make room, then TurnOn the 3 new ones... so that the "Heart Gateway" is instantaneously
	// illuminated and Gnome Chompsky has the "pimp light". For "OnFullyOpen" when Chompsky has
	// reached his end, the 2 gateway and car lights will be washed out anyway, so fire Kill to
	// to them then fire TurnOn to 16/17/18 once again. Viola, there's a lot of action when he
	// is moving into place to distract from the 3 missing lights.

	EntFire( g_UpdateName + "_jimmy_disco_16_spot", "TurnOff" );
	EntFire( g_UpdateName + "_jimmy_disco_17_spot", "TurnOff" );
	EntFire( g_UpdateName + "_jimmy_disco_18_spot", "TurnOff" );

	EntFire( g_UpdateName + "_jimmy_lightomni_*", "TurnOn" );
}

function tsu_c1m4_jimmy_05_mapsoundfx()
{
	// Problem with Valve's map model having a delay before the desired break
	// aniimation is that I need functions to enforce very specific delays, so
	// I need sounds separate, but also need to check here as well if it still
	// exists (which by a narrow 2 second window from _mapanimate(), it will).
	// This is required because it already doesn't animate if it was the other
	// escape animation, but it requires this check so the sound doesn't play too.

	local hndMap = Entities.FindByName( null, "mall_directory" );

	if ( SafelyExists( hndMap ) )
	{
		// Need to have sound effects play on a delay, so a function is created.

		make_noise( "sound", "_jimmy_wood_break_map", "-4448 -2784 1.6", 5000, "WoodenDoor.Break" );
		make_noise( "sound", "_jimmy_wood_break_map", "-4448 -2784 1.6", 5000, "WoodenDoor.Break" );
		make_noise( "sound", "_jimmy_wood_break_map", "-4448 -2784 1.6", 5000, "WoodenDoor.Break" );

		EntFire( g_UpdateName + "_jimmy_wood_break_map", "Kill", 2 );
	}
}

function tsu_c1m4_jimmy_05_kioskbreak()
{
	EntFire( "trigger_finale", "Kill" );

	// For the kiosk, the sound effects and the "pseudo-particle effect" can be in the same function.

	make_noise( "sound", "_jimmy_wood_break_kiosk", "-4451.92 -3207.61 2", 5000, "SmashCave.WoodRockCollapse" );
	make_noise( "sound", "_jimmy_wood_break_kiosk", "-4451.92 -3207.61 2", 5000, "SmashCave.WoodRockCollapse" );
	make_noise( "sound", "_jimmy_wood_break_kiosk", "-4451.92 -3207.61 2", 5000, "SmashCave.WoodRockCollapse" );

	EntFire( g_UpdateName + "_jimmy_wood_break_kiosk", "Kill", 2 );

	make_prop( "physics", "_jimmy_wood_break_prop", "models/props_junk/wood_crate002a.mdl", "-4451.92 -3207.61 64", "0 0 90" );
	make_prop( "physics", "_jimmy_wood_break_prop", "models/props_junk/wood_crate002a.mdl", "-4451.92 -3207.61 64", "0 180 90" );

	EntFire( g_UpdateName + "_jimmy_wood_break_prop", "Break" );

	make_particle( "_jimmy_wood_break_puff", "-4451.92 -3207.61 10", "0 0 0", "bridge_smokepuff" );

	EntFire( g_UpdateName + "_jimmy_wood_break_puff" + "_system", "Kill", null, 2 );
}

function tsu_c1m4_jimmy_05_mapanimate()
{
	// Check if the "escape_directory" map exists, if it doesn't exist then that means RandomInt()
	// 1 happened which played the "a" escape animation, so there's no need to do anything for it.
	// Conversely, if it exists, then 2 happened (with "b" escape) so Chompsky needs to destroy it.

	// ACTUALLY, turns out that BOTH animations delete "escape_directory", so instead check to see
	// if "mall_directory" exists, and if it does, instead of re-creating it from scratch, instead
	// just SetModel() to change it to the "animated variant" to animate it directly! Also need
	// to update its Origin since that is different... being an animated variant and whatnot. To
	// make matters a bit more perplexing, it also needs to be rotated... Valve-think-what?

	local hndMap = Entities.FindByName( null, "mall_directory" );

	if ( SafelyExists( hndMap ) )
	{
		DoEntFire( "!self", "Kill", "", 0.0, null, Entities.FindByClassnameNearest( "env_player_blocker", Vector( -4492, -2767, 9 ), 1 ) );

		hndMap.SetModel( "models/c1_chargerexit/mall_directory_dest.mdl" );
		hndMap.SetOrigin( Vector( -4576, -3296, 0 ) );
		hndMap.SetAngles( QAngle( 0, 0, 0 ) );

		EntFire( "mall_directory", "SetAnimation", "escape_a" );
		EntFire( "mall_directory", "Kill", null, 7 );
	}
}

function tsu_c1m4_jimmy_05_sparkstest()
{
	// Sparks that Chompsky tests and are malfunction-like while he's still outside.

	// CAUTION :: ALWAYS PLAN FOR SOUNDS TO PLAY TO COMPLETION BEFORE TIMING THEIR USE AGAIN.

	// CAUTION :: ALWAYS MANUALLY "STOP" PARTICLE EFFECTS AS IT'S MANDATORY TO "START" THEM LATER.

	EntFire( g_UpdateName + "_jimmy_sound_top_sparks", "Volume", 5 );

	EntFire( g_UpdateName + "_jimmy_particle_left_3_*", "Start", null, 0.10 );
	EntFire( g_UpdateName + "_jimmy_particle_right_3_*", "Start", null, 0.15 );
	EntFire( g_UpdateName + "_jimmy_particle_left_2_*", "Start", null, 1.20 );
	EntFire( g_UpdateName + "_jimmy_particle_right_2_*", "Start", null, 1.35 );
	EntFire( g_UpdateName + "_jimmy_particle_left_1_*", "Start", null, 2.50 );
	EntFire( g_UpdateName + "_jimmy_particle_right_1_*", "Start", null, 2.65 );
	EntFire( g_UpdateName + "_jimmy_particle_left_*", "Stop", null, 4.20 );
	EntFire( g_UpdateName + "_jimmy_particle_right_*", "Stop", null, 4.45 );

	EntFire( g_UpdateName + "_jimmy_particle_top_*", "Start", null, 3.65 );
	EntFire( g_UpdateName + "_jimmy_particle_top_*", "Stop", null, 4.90 );
	EntFire( g_UpdateName + "_jimmy_particle_top_*", "Start", null, 6.10 );
	EntFire( g_UpdateName + "_jimmy_particle_top_*", "Stop", null, 8.40 );
}

function tsu_c1m4_jimmy_05_sparksangel()
{
	// Sparks that look like angel wings once Chompsky is inside.

	EntFire( g_UpdateName + "_jimmy_sound_left_sparks", "PlaySound" );
	EntFire( g_UpdateName + "_jimmy_sound_right_sparks", "PlaySound" );

	EntFire( g_UpdateName + "_jimmy_particle_left_*", "Start" );
	EntFire( g_UpdateName + "_jimmy_particle_right_*", "Start" );
	EntFire( g_UpdateName + "_jimmy_particle_left_*", "Stop", null, 8 );
	EntFire( g_UpdateName + "_jimmy_particle_right_*", "Stop", null, 8 );

	// There shouldn't be any Commons, but just in case there are get into
	// the "templated habit" of Enabling these for the duration of shower.

	EntFire( g_UpdateName + "_jimmy_xtra_fire", "Enable" );
	EntFire( g_UpdateName + "_jimmy_xtra_fire", "Disable", null, 8 );
}

function tsu_c1m4_jimmy_05_gnomehero()
{
	// Gnome Chompsky emerges, breaking through the wooden map and kiosk, parks, lights darken,
	// then ForceFinaleStart a "standard" finale type. Use delays to synchronize disco / fireworks.

	make_particle( "_jimmy_gnome_materialize", "-4430 -2074 0", "0 0 0", "mini_fireworks" );
	make_particle( "_jimmy_gnome_materialize", "-4430 -2074 32", "0 0 0", "mini_fireworks" );
	make_particle( "_jimmy_gnome_materialize", "-4430 -2074 64", "0 0 0", "mini_fireworks" );
	EntFire( g_UpdateName + "_jimmy_gnome_materialize" + "_system", "Kill", null, 2 );

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_entities" );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_lightsoff" );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_discorays", 6 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_parenting", 6 );

	// After a short suspenseful delay, start Chompsky's entry song!

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_savesugar", 10 );

	// Chompsky needs a moment to test out his sparkshowers!

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_sparkstest", 15 );

	// After another short delay, he'll start riding in!

	EntFire( g_UpdateName + "_jimmy_moveline_main", "Open", null, 25 );

	// Punch up the "light_dynamic" brightness as Chompsky gets closer to entry!

	EntFire( g_UpdateName + "_jimmy_disco_*", "brightness", 2, 27 );

	// Angel wing sparks... he's our guardian!

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_sparksangel", 30 );

	// If the directory/map still exists, allow Gnome Chompsky to timely destroy it.

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_mapanimate", 28 );
	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_mapsoundfx", 33 );

	// Destroy Valve's massive, pesky "trigger_finale" (LEAVES BSP CLIP BEHIND, OH WELL).

	EntFire( "worldspawn", "CallScriptFunction", "tsu_c1m4_jimmy_05_kioskbreak", 38 );

	// All showmanship over with... hand off control to the actual gameplay.
	// Note that 7 second delay so "_05_parenting" has time to spawn stuff in.

	EntFire( g_UpdateName + "_jimmy_moveline_main", "AddOutput", "OnFullyOpen worldspawn:CallScriptFunction:tsu_c1m4_jimmy_06_theshow:0:-1", 7 );
}

// STAGE 06 :: THE SHOW
///////////////////////

// Standard finale takes it the rest of the way. Inject I/O to activate the trolley as escape platform.

function tsu_c1m4_jimmy_06_theshow()
{
	printl( ">>>>>> THE SHOW STARTS HERE <<<<<<" );

	EntFire( "alternative_finale", "ForceFinaleStart", null, 4.5 );

	// Delete the 4 "trigger_push" preventing boarding of the trolley -- it's OK now.

	EntFire( g_UpdateName + "_jimmy_xtra_push_*", "Kill" );

	// Gnome Chompsky is settled into position -- close up the path behind him with
	// the vertical speakers (also visually justifies the UNDELETABLE CLIP).

	EntFire( g_UpdateName + "_jimmy_moveline_speaker2", "Open" );

	// Delete the now-washed-out toycar and gateway lights and restore the discoball's
	// light_dynamics which were TurnOff'd at the start in order to fit within 18 limit.
	// I manually_confirmed that all 18 were indeed TurnOn'd again, just to eliminate
	// risk of some "lingering quirk" if done so immediately after a Kill... dynamic
	// lights are pretty damn good and innovative, and have good reactions unlike particles.

	EntFire( g_UpdateName + "_jimmy_lightomni_*", "Kill" );

	EntFire( g_UpdateName + "_jimmy_disco_16_spot", "TurnOn" );
	EntFire( g_UpdateName + "_jimmy_disco_17_spot", "TurnOn" );
	EntFire( g_UpdateName + "_jimmy_disco_18_spot", "TurnOn" );

	// LIGHT_DYNAMIC BUG ?!
	//
	//	Some lights, specifically "_jimmy_disco_17_spot" when tested, only illuminate
	//	entities and not the world -- this light, when tested arbitrarily, after it
	//	had its color changed to try and visually identify where it was it was really
	//	difficult to find until I ClearParent'd and ent_teleport'd it to various spots,
	//	where it did successfully illuminate if pointing at a prop_static but only lit
	//	that prop_static. THIS DOESN'T MAKE SENSE AS ALL LIGHTS ARE CREATED EQUALLY.
	//
	//	Also: THE QUIRK DIDN'T JUST START HAPPENING, IT HAPPENED BEFORE LIMIT WORKAROUND.
	//
	// When bugged, ent_dump doesn't show Spawnflags even if 0 (both), 1 (props) or 2 (world),
	// but while setting this specific light to 0 didn't fix it, and 1 was identical to 0,
	// setting to 2 did de-illuminate the prop_static and get the spotlight back!
	//
	// 18/18 light_dynamics are mine, so this TEST_ONLY'd all 18 as spotlights-only which do
	// not illuminate prop_statics. Result was that even the toycar wasn't illuminated at all
	// and it was F-UGLY, so this isn't an option.
	//
	// At the end of the day, constant or random light_dynamics (it doesn't really matter)
	// will have a hissy-fit and limit its illumination. Maybe this is CPU/GPU holding back
	// from things being intense, maybe it's a bug, but regardless I know all the lights are
	// identical, this is just an engine-level quirk that I simply need to accept... and can
	// not notice substantially, as at most it's 2-3 spotlights that are missing. There will
	// also be multiples of each color, so the problem only stands out when I'm seeking out
	// a random light of very specific unique coloring. I could work this out further, determine
	// if it's always the same light_dynamic for w/e reason, but CPU/GPU may be inconsistent!
	//
	// LAPTOP changed LOW/MED/LOW to VERYHIGH/HIGH/HIGH and my light_dynamics still don't have
	// shadows, but it was laggier, like the lights might've had smoother spots... but that's
	// it... I thought these used to have shadows? Maybe my INTEL INTEGRATED just doesn't support
	// them whatsoever? I WONDER IF OTHER'S COMPUTERS WILL LAG... GRANTED, 10 YEARS OF ADVANCEMENT.
	//
	// EntFire( "light_dynamic", "AddOutput", "spawnflags 2" );

	// Damn sparks are almost louder than the concert... time to delete it.

	EntFire( g_UpdateName + "_jimmy_elevator_sparks", "Kill" );

	// There have been a LOT of distracting noises up to this point, and the blades
	// still don't have a sound, which hasn't exactly left itself noticeable until
	// now... where the car is stationary... so, play this one indefinitely. Yes,
	// Volume of 0.5 is audible, but only barely, just enough for a low-effort sound.

	make_noise( "sound", "_jimmy_sound_blades", "-4430 -3529 25", 5000, "Chainsaw.FullThrottle", true );
	EntFire( g_UpdateName + "_jimmy_sound_blades", "Volume", 0.5 );

	// Play a *.VCD scene to immediately cancel out "Let's get this car gassed up!"
	// Map does 6 SpeakResponseConcepts, but none of them would disable this line.

	// TO_DO
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			break;
		}
	}
}



/*******************************************************************************************************************************
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Case by case look into:

	"body" "0"
	"disableshadows" "0"
	"glowbackfacemult" "1.0"
	"glowcolor" "0 0 0"
	"glowrange" "0"
	"glowrangemin" "0"
	"glowstate" "0"
	"rendercolor" "255 255 255"
	"skin" "0"
	"solid" "0"
	"solid" "6"

Rotate Valve's prop_dynamic "models/props_equipment/elevator_buttons.mdl" by:

	"angles" "0 180 -10"

Sample env_spark for crooked-made elevator button:

	"classname" "env_spark"
	"angles" "0 180 -10"
	"Magnitude" "1"
	"MaxDelay" "0"
	"targetname" "tsu_jimmy_reference_spark"
	"TrailLength" "1"
	"origin" "-3944 -3478 592.24"

Collection of ALL available GOOD particles to avoid having to use browser on LAPTOP:

	"classname" "info_particle_system"
	"angles" "0 0 0"
	"effect_name" "fireworks_02"
	"start_active" "0"
	"targetname" "tsu_jimmy_reference_particle"
	"origin" "-4375 -3465 21"

	"effect_name" "fireworks_explosion_01"
	"effect_name" "fireworks_explosion_02"
	"effect_name" "fireworks_explosion_03"
	"effect_name" "fireworks_explosion_04"
	"effect_name" "mini_firework_flare"
	"effect_name" "mini_fireworks"
	"effect_name" "fireworks_03"
	"effect_name" "string_lights_03_glow"

entity
{
	"classname" "info_particle_target"
	"angles" "-60 180 -180"
	"targetname" "tsu_jimmy_particle_top_3"
	"origin" "-4446 -3447 81"
}
entity
{
	"classname" "info_particle_system"
	"angles" "-90 0 0"
	"effect_name" "fireworks_sparkshower_01"
	"start_active" "0"
	"targetname" "tsu_jimmy_particle_top_2"
	"origin" "-4430 -3447 85"
}
entity
{
	"classname" "info_particle_target"
	"angles" "-60 0 0"
	"targetname" "tsu_jimmy_particle_top_1"
	"origin" "-4414 -3447 81"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 180 -4"
	"effect_name" "fireworks_01"
	"start_active" "0"
	"targetname" "tsu_jimmy_particle_back_3"
	"origin" "-4444 -3424 62"
}
entity
{
	"classname" "info_particle_system"
	"angles" "-7 180 -9"
	"effect_name" "fireworks_01"
	"start_active" "0"
	"targetname" "tsu_jimmy_particle_back_2"
	"origin" "-4430 -3424 62"
}
entity
{
	"classname" "info_particle_system"
	"angles" "-15 180 -4"
	"effect_name" "fireworks_01"
	"start_active" "0"
	"targetname" "tsu_jimmy_particle_back_1"
	"origin" "-4416 -3424 62"
}
entity
{
	"classname" "info_particle_target"
	"angles" "-60 90 0"
	"targetname" "tsu_jimmy_particle_left_3"
	"origin" "-4406 -3452 27"
}
entity
{
	"classname" "info_particle_system"
	"angles" "-90 90 0"
	"effect_name" "fireworks_sparkshower_01"
	"start_active" "0"
	"targetname" "tsu_jimmy_particle_left_2"
	"origin" "-4406 -3468 31"
}
entity
{
	"classname" "info_particle_target"
	"angles" "-60 270 -180"
	"targetname" "tsu_jimmy_particle_left_1"
	"origin" "-4406 -3484 27"
}
entity
{
	"classname" "info_particle_target"
	"angles" "-60 270 180"
	"targetname" "tsu_jimmy_particle_right_1"
	"origin" "-4454 -3484 27"
}
entity
{
	"classname" "info_particle_system"
	"angles" "-90 90 0"
	"effect_name" "fireworks_sparkshower_01"
	"start_active" "0"
	"targetname" "tsu_jimmy_particle_right_2"
	"origin" "-4454 -3468 31"
}
entity
{
	"classname" "info_particle_target"
	"angles" "-60 90 0"
	"targetname" "tsu_jimmy_particle_right_3"
	"origin" "-4454 -3452 27"
}
entity
{
	"classname" "info_target"
	"angles" "44.09 168.84 -15.79"
	"targetname" "tsu_jimmy_rotator_disco"
	"origin" "-4429.5 -3471.5 122"
}
entity
{
	"classname" "info_target"
	"angles" "44.09 168.84 -15.79"
	"targetname" "tsu_jimmy_rotator_blades"
	"origin" "-4430 -3529 24.5"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "45 180 180"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_16_beam"
	"origin" "-4440.23 -3471.9 111.375"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "45 0 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_18_beam"
	"origin" "-4418.92 -3471.9 111.301"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 90 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_01_beam"
	"origin" "-4429.57 -3456.85 122"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 180 -180"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_03_beam"
	"origin" "-4444.62 -3471.9 121.982"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 270 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_05_beam"
	"origin" "-4429.55 -3486.97 122"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 0 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_07_beam"
	"origin" "-4414.5 -3471.9 122"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 45 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_08_beam"
	"origin" "-4418.93 -3461.3 122"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 315 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_06_beam"
	"origin" "-4418.93 -3482.51 122"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 225 180"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_04_beam"
	"origin" "-4440.24 -3482.51 121.982"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "0 135 180"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_02_beam"
	"origin" "-4440.22 -3461.3 121.982"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "90 0 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_13_beam"
	"origin" "-4429.55 -3471.9 106.93"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "45 90 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_14_beam"
	"origin" "-4429.57 -3461.25 111.338"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "45 270 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_12_beam"
	"origin" "-4429.55 -3482.57 111.351"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "-90 0 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_10_beam"
	"origin" "-4429.57 -3471.9 137.053"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "-45 0 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_17_beam"
	"origin" "-4418.94 -3471.9 132.688"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "-45 90 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_09_beam"
	"origin" "-4429.57 -3461.27 132.651"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "-45 180 -180"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_15_beam"
	"origin" "-4440.23 -3471.9 132.589"
}
entity
{
	"classname" "beam_spotlight"
	"angles" "-45 270 0"
	"HDRColorScale" "0.7"
	"maxspeed" "100"
	"spawnflags" "1"
	"spotlightlength" "500"
	"spotlightwidth" "50"
	"targetname" "tsu_jimmy_disco_11_beam"
	"origin" "-4429.55 -3482.55 132.639"
}
entity
{
	"classname" "info_target"
	"angles" "0 270 0"
	"targetname" "tsu_jimmy_movelinear"
	"origin" "-4430 -3474 0"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 90 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_01_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.57 -3456.85 122"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 135 180"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_02_spot"
	"texturename" "effects/spotlight"
	"origin" "-4440.22 -3461.3 121.982"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 180 -180"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_03_spot"
	"texturename" "effects/spotlight"
	"origin" "-4444.62 -3471.9 121.982"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 225 180"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_04_spot"
	"texturename" "effects/spotlight"
	"origin" "-4440.24 -3482.51 121.982"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 270 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_05_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.55 -3486.97 122"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 315 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_06_spot"
	"texturename" "effects/spotlight"
	"origin" "-4418.93 -3482.51 122"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 0 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_07_spot"
	"texturename" "effects/spotlight"
	"origin" "-4414.5 -3471.9 122"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "0 45 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_08_spot"
	"texturename" "effects/spotlight"
	"origin" "-4418.93 -3461.3 122"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "-45 90 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_09_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.57 -3461.27 132.651"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "-90 0 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_10_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.57 -3471.9 137.053"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "-45 270 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_11_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.55 -3482.55 132.639"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "45 270 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_12_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.55 -3482.57 111.351"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "90 0 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_13_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.55 -3471.9 106.93"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "45 90 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_14_spot"
	"texturename" "effects/spotlight"
	"origin" "-4429.57 -3461.25 111.338"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "-45 180 -180"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_15_spot"
	"texturename" "effects/spotlight"
	"origin" "-4440.23 -3471.9 132.589"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "45 180 180"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_16_spot"
	"texturename" "effects/spotlight"
	"origin" "-4440.23 -3471.9 111.375"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "-45 0 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_17_spot"
	"texturename" "effects/spotlight"
	"origin" "-4418.94 -3471.9 132.688"
}
entity
{
	"classname" "env_projectedtexture"
	"angles" "45 0 0"
	"cameraspace" "0"
	"enableshadows" "0"
	"farz" "2100"
	"lightcolor" "255 255 255 200"
	"lightfov" "4"
	"lightonlytarget" "0"
	"lightworld" "1"
	"nearz" "4"
	"shadowquality" "1"
	"spawnflags" "1"
	"targetname" "tsu_jimmy_disco_18_spot"
	"texturename" "effects/spotlight"
	"origin" "-4418.92 -3471.9 111.301"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 270 0"
	"cpoint1" "tsu_jimmy_rope_left_target"
	"effect_name" "string_lights_03"
	"render_in_front" "0"
	"start_active" "0"
	"targetname" "tsu_jimmy_rope_left_system"
	"origin" "-4410.05 -3384.07 18"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 270 0"
	"cpoint1" "tsu_jimmy_rope_right_target"
	"effect_name" "string_lights_03"
	"render_in_front" "0"
	"start_active" "0"
	"targetname" "tsu_jimmy_rope_right_system"
	"origin" "-4450.05 -3384.07 18"
}
entity
{
	"classname" "info_particle_target"
	"angles" "0 90 0"
	"targetname" "tsu_jimmy_rope_right_target"
	"origin" "-4450.07 -3426.95 30"
}
entity
{
	"classname" "info_particle_target"
	"angles" "0 90 0"
	"targetname" "tsu_jimmy_rope_left_target"
	"origin" "-4410.07 -3426.95 30"
}
entity
{
	"classname" "info_particle_target"
	"angles" "0 270 0"
	"targetname" "tsu_jimmy_balloon_topleft_target"
	"origin" "-4410.05 -3384.07 18"
}
entity
{
	"classname" "info_particle_target"
	"angles" "0 270 0"
	"targetname" "tsu_jimmy_balloon_topright_target"
	"origin" "-4450.05 -3384.07 18"
}
entity
{
	"classname" "info_particle_target"
	"angles" "0 270 0"
	"targetname" "tsu_jimmy_balloon_botleft_target"
	"origin" "-4418.05 -3316.07 52"
}
entity
{
	"classname" "info_particle_target"
	"angles" "0 270 0"
	"targetname" "tsu_jimmy_balloon_botright_target"
	"origin" "-4442.05 -3316.07 52"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 270 0"
	"cpoint1" "tsu_jimmy_balloon_botleft_target"
	"effect_name" "balloon"
	"render_in_front" "0"
	"start_active" "0"
	"targetname" "tsu_jimmy_balloon_botleft_system"
	"origin" "-4418.05 -3316.07 100"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 270 0"
	"cpoint1" "tsu_jimmy_balloon_botright_target"
	"effect_name" "balloon"
	"render_in_front" "0"
	"start_active" "0"
	"targetname" "tsu_jimmy_balloon_botright_system"
	"origin" "-4442.05 -3316.07 100"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 270 0"
	"cpoint1" "tsu_jimmy_balloon_topleft_target"
	"effect_name" "balloon"
	"render_in_front" "0"
	"start_active" "0"
	"targetname" "tsu_jimmy_balloon_topleft_system"
	"origin" "-4410.05 -3384.07 66"
}
entity
{
	"classname" "info_particle_system"
	"angles" "0 270 0"
	"cpoint1" "tsu_jimmy_balloon_topright_target"
	"effect_name" "balloon"
	"render_in_front" "0"
	"start_active" "0"
	"targetname" "tsu_jimmy_balloon_topright_system"
	"origin" "-4450.05 -3384.07 66"
}


More particle effects:

	center of elevator for glass breakage		"effect_name" "window_glass"
	play for kiosk and map display wood puffs	"effect_name" "bridge_smokepuff"

Consider simply spawning and insta-Breaking this to create easy wood debris:

	"model" "models/props_junk/wood_crate002a.mdl"

Sound effect options:

	When elevator glass breaks:

		"message" "Breakable.MatGlass"
		"message" "Breakable.Glass"

	When Jimmy pounds the glass (too RNG if it's a real zombie, probably ignore this):

		"message" "Bounce.Glass"
		"message" "Glass.Break"

	Options for when kiosk and map display break:

		"message" "SmashCave.WoodRockCollapse"
		"message" "WoodenDoor.Break"
		"message" "Wood_Box.Break"

	Play lightly for the frontal fan blade:

		"message" "Chainsaw.FullThrottle"

	Don't forget these, they do need syncing with particles though:

		"message" "c2m5.fireworks_launch"
		"message" "c2m5.fireworks_burst"


NEEDS SPIN + PARTICLE EFFECT FOR EXPLOSION + BEEPING TIMER... BUT OVERALL, IT'S CLOSE, AND IT HAS EZ-BOUNCE

ent_create pipe_bomb_projectile
script Entities.FindByName( null, "hi" ).SetVelocity( Vector( 90, 90, 90 ) );



have the alligator come out and chomp and kill zombies

when it's Tank, have the atrium pitch-black (vin diesel / jeff) -- disco ball OFF -- but 1 beam
... 1 beam on the disco ball points to exactly where the Tank is at all times, as if Chompsky is HELPING
... then, 2nd Tank wave is of course 2 Tanks with 2 spotlights pointing out where they are at ALL times
... maybe need a trigger_look for this or something, so the beam/spot rotate to face it



trigger_finale ForceFinaleStart == gnome chompsky does this 5 seconds after pitchblack... does same 1 thing as relay I deleted





add and parent a "pimp mobile" light_dynamic **UNDERNEATH HIS CAR** that lights up the path but overall just looks stylish
++ it should be pink... then, depending on how the "frontal blades" go, maybe add a 2nd light_dynamic that's colored white
++ caution though: env_projectedtexture + light_dynamic == SIGNIFICANT PERF COSTS
... advantage is that 10 years ago my PC took a noticeable perf hit from it... modern PC's won't care at all.



when car comes in, fire break to the map, break to kiosk, kill to env_player_blocker on the map
maybe play wood-breaking particle effects and then, for just the kiosk, leave a pile of wood behind

thus need:

1. glass break sound and particle
2. wood break sound, particle and prop left behind



common_male01 was ditched quick for common_male_riot just b/c "why not?"



JIMMY GIBBS STEALS CAR

// Spawning "common_male_jimmy" directly will always chase Survivors NOT the goal, so create male01 and replace its model.
// But, when male01 and changed, it will T-pose, so I'm effectively back to "square one" 10 years ago.
// Using NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmygibbs" ), "m_nModelIndex" ) instead will
// still produce the T-pose Jimmy Gibbs... it won't animate... not sure, how to get it TO animate, in the past I thought
// it just "figured itself out" after sometime... but I need 100% reliability. The new SetSequence WILL brute-force it!!
// Where GetSequence() revealed that 99 is bashing something in front of it and 118 is bashing and kicking the ground.
// And 120 is more trying to bash through a wall so looks more approprirate for the elevator than 99.

SpawnEntityFromTable( "func_breakable", { targetname = g_UpdateName + "_breakable_glass", model = Entities.FindByClassnameNearest( "func_brush", Vector( -4043, -3408, 158 ), 1 ).GetModelName(), origin = Vector( -4043, -3408, 158 ) } );

kill_entity( Entities.FindByClassnameNearest( "func_brush", Vector( -4043, -3408, 158 ), 1 ) );

EntFire( g_UpdateName + "_breakable_glass", "Break" );



// gascan with skin 1 as "prop_physics_OVERRIDE" will prevent them from getting shot and thus appear "empty", so an EASY solution




gascans need to glow white not blue
gascans need to be indestructible from shooting hence appear empty
when top elevator button is pressed z_common_limit 0 and ent_fire infected ignite to there's no more

when jimmy gibbs breaks glass set z_common_limit back to 30

env_sparh and slightly angle top elevator button

c1m4_jimmygibbs_-prefixed functions for each "phase" where new info_goal_infected_chase will need to be spawned in



what about my scope? my round_start and player_connect_full in anv_mapfixes.nut are worldspawn scope

how do I get those same events done by my new tsu_ file?

answer: just use the same Game Events copy/paste game will use last-most made -- so, override it w/ Apply_Quad_Mode-etc BUT ADD my 2nd new function



lookup datamaps for "CScavengeProgressDisplay" to see if I can set it to 13/13... but single player would need to be customized







script SpawnEntityFromTable( "env_instructor_hint", { targetname = g_UpdateName + "_hint_waitwhat", origin = Vector( -4800, -3520, 168 ), hint_caption = "Wait what?", hint_color = "255 255 0", hint_timeout = 7 } );

{
	"classname" "env_instructor_hint"
	"targetname" "sky_instructor_cola_hint"
	"hint_target" "sky_instructor_cola_target"
	"hint_caption" "Find some coca-cola for Whitaker! (6 Boxes)"
	"hint_timeout" "7"
	"hint_range" "5000"
	"hint_auto_start" "0"
	"hint_icon_onscreen" "icon_alert_red"
	"hint_icon_offscreen" "icon_alert"
	"hint_allow_nodraw_target" "1"
	"hint_color" "255 255 255"
	"hint_static" "0"
	"hint_shakeoption" "0"
	"hint_pulseoption" "0"
	"hint_nooffscreen" "0"
	"hint_icon_offset" "0"
	"hint_forcecaption" "0"
	"hint_alphaoption" "0"
	"origin" "12243 14031 487"
}



{
"origin" "-4664 -3544 40"
"targetname" "relay_car_escape"
"spawnflags" "0"
"classname" "logic_relay"
"hammerid" "528456"
"OnTrigger" "trigger_finaleFinaleEscapeForceSurvivorPositions0.2-1"
"OnTrigger" "fade_outro_1Fade0-1"
"OnTrigger" "relay_endgameTrigger0-1"
"OnTrigger" "gas_nozzleKill0-1"
"OnTrigger" "rand_camera_pickerPickRandomShuffle0.2-1"
"OnTrigger" "escape_3Enable0-1"
"OnTrigger" "escape_4Enable0-1"
"OnTrigger" "escape_2Enable0-1"
"OnTrigger" "escape_6Enable0-1"
"OnTrigger" "escape_7Enable0-1"
"OnTrigger" "exitdoor_portalOpen0-1"
"OnTrigger" "escape_1Enable0-1"
"OnTrigger" "!activatorSpeakResponseConceptc1m4escape0-1"
}


{
"origin" "-4677.5 -3546.16 81.1573"
"targetname" "relay_endgame"
"spawnflags" "0"
"classname" "logic_relay"
"hammerid" "528434"
"OnTrigger" "trigger_finaleFinaleEscapeFinished7-1"
"OnTrigger" "gameinstructor_disableGenerateGameEvent0-1"
"OnTrigger" "progress_displayTurnOff0-1"
}

"OnTrigger" "escape_carSetAnimationcharger_escape_a0-1"

https://github.com/Stabbath/L4D2-Decompiled/blob/master/Stripper%20Dumps/Official/c1m4_atrium.0000.cfg



if common_male01 unavoidably dies too easily, then just re-model the riotcop:

	"OnTrigger" "riot_cop_spawnerSpawnZombiecommon_male_riot riotcop0-1"


info_goal_infected_chase can do a lot:

	"OnTrigger" "goal_infectedSetParentAttachmentpushtrigger_point0.1-1"
	"OnTrigger" "goal_infectedEnable0.3-1"
	"OnTrigger" "goal_infectedSetParentapc_prop_body0-1"


info_zombie_spawn can only spawn in by "population" and I don't want to distribute a modified populations.txt with my mod,
and either way Jimmy Gibbs doesn't follow info_goal_infected_chase anyway -- so the SetModel hack/workaround is mandatory


AS SURVIVORS DESCEND HAVE HIM KICKING THE CANS HE SUPPOSEDLY POURED, THEN ONCE REACH BOTTOM HAVE HIM AGGRO SURVIVORS

DEFINITELY DON'T USE THE SLOW-MOTION, AS PEOPLE ARE OVER-FAMILIAR

VASTLY SUPERIOR TO PROP_DYNAMIC BECAUSE SOUNDS / ANIMATIONS ARE ALREADY THERE -- I JUST CAN'T MAKE HIM "TRIP" ON WAY TO CAR

jimmy himself is immune to headshots, while male01 isn't, I guess merely changing the model gives him that ability

Z_COMMON_LIMIT 0 DURING THE EVENT, AND WHEN ELEVATOR STARTS KILL ALL "INFECTED", SET LIMIT 0, SPAWN JIMMY

HAVE JIMMY RUN INTO THE SCENE OUT FROM NOWHERE WHEN THE ELEVATOR STARTS, TO KICK CANS ON THE WAY DOWN
DROP CANS FROM AIR SO THEY LAND RANDOMLY, STARTGLOWING, DELETE SCAVENGE, ALTER TRIGGER_FINALE TO "STANDARD",
ENV_INSTRUCTOR_HINTS RE-ADD, LOGIC_RELAY FOR GLASS BREAK / OUTRO PLAY (IGNORE THE "ALTERNATIVE PIPE BOMB" SEQUENCE
FOR NOW, AS GLASS BREAK IS EASY), MORE SUBTLE ENV_SPARKS / ON FUNC_BUTTON ELEVATOR, NO SLOW-MOTION... IT BEING
A REAL JIMMY GIBBS SOLVES THE BLUE STRIPES, AND LUCKILY HE'S ALREADY 100% HEADSHOT-IMMUNE SO HEALTH CAN BE INFINITE.
HE'LL JUST BE SHOT BACK FROM HIS INFO_GOAL_INFECTED_CHASE AS SURVIVORS SHOOT AT HIM THROUGH THE GLASS, WHICH SIMPLY
MAKES HIM MORE INTERACTIVE THAN THE ORIGINAL... ****UAT HDD VERSION HAS MORE SOUL****.



on 4 second delay same time of StartGlowing:

	[i] You'll need to fill the car with... wait, what?!



{
	"classname" "env_instructor_hint"
	"targetname" "sky_instructor_hint"
	"hint_target" "sky_instructor_target"
	"hint_caption" "Refill the generator to restore electricity!"
	"hint_timeout" "0"
	"hint_range" "2500"
	"hint_auto_start" "0"
	"hint_icon_onscreen" "icon_alert_red"
	"hint_icon_offscreen" "icon_alert"
	"hint_allow_nodraw_target" "1"
	"hint_color" "255 255 255"
	"hint_static" "0"
	"hint_shakeoption" "0"
	"hint_pulseoption" "0"
	"hint_nooffscreen" "0"
	"hint_icon_offset" "0"
	"hint_forcecaption" "0"
	"hint_alphaoption" "0"
	"origin" "-8731 -7810 -333"
}

"instructor_server_hint_create" //create a hint using data supplied entirely by the server/map.
{
	"userid"					"short"		// user ID of the player that triggered the hint
	"hint_entindex"				"long"		// entity id of the env_instructor_hint that fired the event
	"hint_name"					"string"	// what to name the hint. For referencing it again later (e.g. a kill command for the hint instead of a timeout)
	"hint_target"				"long"		// entity id that the hint should display at
	"hint_timeout"				"short"	 	// how long in seconds until the hint automatically times out, 0 = never
	"hint_display_limit"		"short"	 	// how many times this hint can be displayed before it closes, 0 = unlimited
	"hint_icon_onscreen"		"string"	// the hint icon to use when the hint is onscreen. e.g. "icon_alert_red"
	"hint_icon_offscreen"		"string"	// the hint icon to use when the hint is offscreen. e.g. "icon_alert"
	"hint_caption"				"string"	// the hint caption. e.g. "Push this button!"
	"hint_color"				"string"	// the hint color in "r,g,b" format where each component is 0-255
	"hint_icon_offset"			"float"		// how far on the z axis to offset the hint from entity origin
	"hint_range"				"float"		// range before the hint is culled 130/300
	"hint_flags"				"long"		// hint flags
	"hint_binding"				"string"	// bindings to use when use_binding is the onscreen icon
	"hint_allow_nodraw_target"	"bool"		// if false, the hint will dissappear if the target entity is invisible
	"hint_nooffscreen"			"bool"		// if true, the hint will not show when outside the player view
	"hint_forcecaption"			"bool"		// if true, the hint caption will show even if the hint is occluded
	"hint_instance_type"		"long"		// lesson instance display type
	"hint_suppress_rest"		"bool"		// If true, icon will not appear in center of screen (rest) before moving to target
}

	hint_icon_offset = "0"
	hint_instance_type = "2"                // show multiple
	hint_nooffscreen = "0"                  // 0/1
	hint_pulseoption = "0"


"OnUser4" "!selfEndHint0-1"
"OnUser4" "!selfKill0.01-1"

local hint = ::VSLib.Utils.CreateEntity("env_instructor_hint", Vector(0, 0, 0), QAngle(0, 0, 0), hinttbl);
	
hint.Input("ShowHint", "", 0, this);


::tsu_lightdynamic_colorize <- function( user_strColor )
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

::tsu_lightdynamic_stylize <- function( user_strStyle )
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

::tsu_lightdynamic_omni_maker <- function ( user_strTargetname,
					    user_strOrigin,
					    user_strColor = "Purple",
					    user_strStyle = "Static",
					    user_intBrightness = -4,
					    user_flDistance = 2500,
					    user_intSpawnflags = 0 )
{
	SpawnEntityFromTable( "light_dynamic",
	{
		targetname		=	user_strTargetname,
		origin			=	StringToVector( user_strOrigin, " " ),
		_light			=	tsu_lightdynamic_colorize( user_strColor ),
		style			=	tsu_lightdynamic_stylize( user_strStyle ),
		brightness		=	user_intBrightness,
		distance		=	user_flDistance,
		spawnflags		=	user_intSpawnflags		// Niche but just-in-case
	} );
}

::tsu_lightdynamic_spot_maker <- function ( user_strTargetname,
					    user_strOrigin,
					    user_strColor = "Orange",
					    user_strStyle = "Static",
					    user_intBrightness = -3,
					    user_flDistance = 1000,
					    user_strAngles = "90 0 0",
					    user_flSpotRadius = 2000,
					    user_flOuterAngle = 120,
					    user_flInnerAngle = 120,
					    user_intPitch = 0,
					    user_intSpawnflags = 0 )
{
	SpawnEntityFromTable( "light_dynamic",
	{
		targetname		=	user_strTargetname,
		origin			=	StringToVector( user_strOrigin, " " ),
		_light			=	tsu_lightdynamic_colorize( user_strColor ),
		style			=	tsu_lightdynamic_stylize( user_strStyle ),
		brightness		=	user_intBrightness,
		distance		=	user_flDistance,
		angles			=	StringToVector( user_strAngles, " " ),	// Physically useless to all except SPOTLIGHT
		spotlight_radius	=	user_flSpotRadius,			// Only changes anything if SPOTLIGHT else 0
		_cone			=	user_flOuterAngle,			// Non-0 means it's a SPOTLIGHT
		_inner_cone		=	user_flInnerAngle,			// Non-0 means it's a SPOTLIGHT
		pitch			=	user_intPitch,				// SPOTLIGHT-only & ABSOLUTELY USELESS IGNORE
		spawnflags		=	user_intSpawnflags		// Niche but just-in-case
	} );
}

script tsu_lightdynamic_spot_maker( "wrongturn_lighthouse_spot", "-1062 1231 -15", "Yellow", "Static", -3, 9999, "0 90 0" );

script tsu_lightdynamic_omni_maker( "wrongturn_window_omni", "2035 2775 170", "Window", "Static", 3, 200 );

script tsu_lightdynamic_omni_maker( "wrongturn_planefire_omni", "2612 2233 101", "Fire", "Inferno", -1 );

::tsu_lightdynamic_maker <- function( user_strTargetname, user_strColor, user_strOrigin )
{
	local strColor = null;

	switch ( user_strColor )
	{
		case "Red":
			strColor = "255 0 0 0";
			break;
		case "Green":
			strColor = "0 255 0 0";
			break;
		case "Blue":
			strColor = "0 0 255 0";
			break;
		case "Yellow":
			strColor = "255 255 0 0";
			break;
		case "Purple":
			strColor = "255 0 255 0";
			break;
		case "Turquoise":
			strColor = "0 255 255 0";
			break;
		case "White":
			strColor = "255 255 255 0";
			break;
		case "Black":
			strColor = "0 0 0 0";
			break;
	}

	// Note that "brightness" here was originally "-4.5" but "brightness AKA m_Exponent  ====  -4" as per
	// my "_dumper" function and the NetProp being an "Int" and NOT a "Float", it was determined that it
	// actually does "round up" in which case is "-4", so the dumb-looking "-4.5" was changed to "-4".
	// It's noteworthy that "_dumper" otherwise reports ALL Keyvalues EXACTLY as they appear here post-spawn.
	// Furthermore, when SetParent'd and moving with it, "QAngle( static, varies, static )" is how it changes
	// noting that SetParenting has an "odd" behavior like that of visibly rotating the "func_simpleladder"
	// in all sorta of directions but finally "planting it back into the ground" disregarding the Z-tweaks.

	SpawnEntityFromTable( "light_dynamic",
	{
		targetname		=	user_strTargetname,
		_cone			=	320,
		_inner_cone		=	240,
		_light			=	strColor,
		brightness		=	-4,
		distance		=	0,
		pitch			=	0,
		spawnflags		=	0,
		spotlight_radius	=	3072,
		style			=	0,
		angles			=	Vector( 0, 0, 0 ),
		origin			=	StringToVector( user_strOrigin, " " )
	} );
}



JIMMY GIBBS STEALS CAR LOOSE ENDS JEFF'S PC

Pipe bomb sound effects:

	PipeBomb.TimerBeep
	PipeBomb.Bounce

Pipe bomb particles (top is the explosion btw):

	weapon_pipebomb
	weapon_pipebomb_blinking_light
	weapon_pipebomb_blinking_light_b
	weapon_pipebomb_blinking_light_c
	weapon_pipebomb_fuse

Light on sounds:

	c2m5.stage_light_on
	c2m5.turning_on_stage_lights

Functional ambient_generic "message"

	Jukebox.AllIWantForXmas			music\flu\jukebox\all_i_want_for_xmas.wav
	Jukebox.BadMan1				music\flu\jukebox\badman.wav
	Jukebox.Ridin1				music\flu\jukebox\midnightride.wav
	Jukebox.still_alive			music\flu\jukebox\portal_still_alive.wav
	Jukebox.re_your_brains			music\flu\jukebox\re_your_brains.wav
	Jukebox.SaveMeSomeSugar			music\flu\jukebox\save_me_some_sugar_mono.wav
	Jukebox.saints_will_never_come		music\flu\jukebox\thesaintswillnevercome.wav

"Tractor.Start" / Stop == possible alternative sound for blades (instead of chainsaw)

CPipeBombProjectile - pipe_bomb_projectile

	- m_hThrower (Save)(4 Bytes)
	- m_bIsLive (Save)(1 Bytes)
	- m_DmgRadius (Save)(4 Bytes)
	- m_flDetonateTime (Save)(4 Bytes)
	- m_flWarnAITime (Save)(4 Bytes)
	- m_flDamage (Save)(4 Bytes)
	- m_iszBounceSound (Save)(4 Bytes)
	- m_bHasWarnedAI (Save)(1 Bytes)
	- m_eHull (Save)(4 Bytes)
	- m_bloodColor (Save)(4 Bytes)
	- m_iDamageCount (Save)(4 Bytes)
	- m_flFieldOfView (Save)(4 Bytes)
	- m_HackedGunPos (Save)(12 Bytes)
	- m_flDamageAccumulator (Save)(4 Bytes)
	- m_impactEnergyScale (Save|Key|Input)(4 Bytes) - physdamagescale
	- m_viewtarget (Save)(12 Bytes)
	- m_flGroundSpeed (Save)(4 Bytes)
	- m_bSequenceFinished (Save)(1 Bytes)
	- m_bSequenceLoops (Save)(1 Bytes)
	- m_nHitboxSet (Save|Key)(4 Bytes) - hitboxset
	- m_nSequence (Save|Key)(4 Bytes) - sequence
	- m_flPlaybackRate (Save|Key)(4 Bytes) - playbackrate
	- m_flCycle (Save|Key)(4 Bytes) - cycle
	- m_flModelScale (Save)(4 Bytes)
	- m_flSpeed (Save|Key)(4 Bytes) - speed
	- m_lifeState (Save)(1 Bytes)
	- m_takedamage (Save)(1 Bytes)
	- m_iMaxHealth (Save|Key)(4 Bytes) - max_health
	- m_iHealth (Save|Key)(4 Bytes) - health
	- m_target (Save|Key)(4 Bytes) - target
	- m_hOwnerEntity (Save)(4 Bytes)
	- m_pPhysicsObject (Save)(0 Bytes)
	- m_flElasticity (Save)(4 Bytes)
	- m_bIsInStasis (Save)(1 Bytes)
	- m_hGroundEntity (Save)(4 Bytes)
	- m_AIAddOn (Save|Key)(4 Bytes) - addon
	- m_vecBaseVelocity (Save|Key)(12 Bytes) - basevelocity
	- m_vecAbsVelocity (Save)(12 Bytes)
	- m_vecAngVelocity (Save|Key)(12 Bytes) - avelocity
	- m_pBlocker (Save)(4 Bytes)
	- m_flGravity (Save|Key)(4 Bytes) - gravity
	- m_flFriction (Save|Key)(4 Bytes) - friction
	- m_flMoveDoneTime (Save)(4 Bytes)
	- m_vecAbsOrigin (Save)(12 Bytes)
	- m_vecVelocity (Save|Key)(12 Bytes) - velocity

CPipeBombProjectile (type DT_PipeBombProjectile)

	Member: m_vecForce (offset 1080) (type vector) (bits 0) (NoScale)
	Member: m_nSequence (offset 1152) (type integer) (bits 12) (Unsigned)
	Member: m_blinktoggle (offset 6020) (type integer) (bits 1) (Unsigned)
	Member: m_viewtarget (offset 6008) (type vector) (bits 0) (CoordMP)
	Member: m_flDamage (offset 6772) (type float) (bits 10) (RoundDown)
	Member: m_DmgRadius (offset 6760) (type float) (bits 10) (RoundDown)
	Member: m_bIsLive (offset 6757) (type integer) (bits 1) (Unsigned)
	Member: m_hThrower (offset 6780) (type integer) (bits 21) (Unsigned|NoScale)
	Member: m_vecVelocity (offset 728) (type vector) (bits 0) (NoScale)
	Member: m_fFlags (offset 316) (type integer) (bits 10) (Unsigned)
	Member: m_vInitialVelocity (offset 6792) (type vector) (bits 20) ()

CScavengeProgressDisplay - game_scavenge_progress_display

	- m_bActive (Save)(1 Bytes)
	- m_nTotalScavengeItems (Save|Key)(4 Bytes) - Max
	- InputSetTotalItems (Input)(0 Bytes) - SetTotalItems

CScavengeProgressDisplay (type DT_ScavengeProgressDisplay)

	Member: m_bActive (offset 1072) (type integer) (bits 1) (Unsigned)

Infected - infected

	- m_bloodColor (Save)(4 Bytes)

Infected (type DT_Infected)

	Member: m_gibbedLimbForce (offset 7424) (type vector) (bits 0) (NoScale)
	Member: m_originalBody (offset 7436) (type integer) (bits 32) ()
	Member: m_mobRush (offset 7393) (type integer) (bits 1) (Unsigned)
	Member: m_bIsBurning (offset 7416) (type integer) (bits 1) (Unsigned)
	Member: m_iRequestedWound1 (offset 7448) (type integer) (bits 32) ()
	Member: m_iRequestedWound2 (offset 7452) (type integer) (bits 32) ()
	Member: m_nFallenFlags (offset 7324) (type integer) (bits 32) ()

VCD SCENES

Entity format:

	"classname" "logic_choreographed_scene"
	"busyactor" "0"
	"onplayerdeath" "0"
	"SceneFile" "scenes/mechanic/worldc1m4b01.vcd"
	"targetname" "tsu_jimmy_reffinal_choreo"
	"origin" "-4253 -3382 9"

What each number does:

	If an Actor is talking "busyactor"

		Start immediately 0
		Wait for actor to finish 1
		Interrupt at next interrupt event 2
		Cancel at next interrupt event 3

	On player death "onplayerdeath"

		Do Nothing 0
		Cancel Script and return to AI 1

SUBTITLES_ENGLISH.TXT EXTRACTS

	"#commentary\com-dynamicpaths.wav"	"[Kim Swift] Something that was always sad for us to watch in Left 4 Dead was that players would always choose an optimized path through a level once they'd played the map a couple times. That meant the hard work we put into other areas of the map would never be seen. So, one thing we wanted to add in Left 4 Dead 2 was the ability for the AI Director to change the path of the survivors through a level, so they have to take a different path each time.  The cemetery contains one example of this new approach.  There are four different paths that the AI Director can create for the survivors.  It does this by spawning in and out particular crypts and gates."
	"#commentary\com-lasersights.wav"	"[Jay Pinkerton] The laser-sight weapon upgrade came from an experiment during the development of the first Left 4 Dead.  Though we didn’t end up shipping them at the time. While developing Left 4 Dead 2, when we were talking about interesting items that players could scavenge out of the levels, we remembered the visual impact of those red laser beams. The original intention of the item was to increase the accuracy of the guns, but the more valuable benefit was accidental:  you could now see where the other members of your team were aiming. We also liked the choices that confronted players when they had to decide whether or not to swap out their upgraded weapon for one of a different style."
	"#commentary\com-localmusic.wav"	"[Erik Wolpaw] When deciding what to do about the music for Left 4 Dead 2 we faced some interesting challenges. Some of the music in Left 4 Dead 1 plays an iconic and important role in game play, and we felt that it shouldn't really be changed. On the other hand, the game is set in the Southern United States, which is rich with musical identity, so we also felt that adding some local flavor to each campaign would really help set the tone for that campaign. The solution to bridging the gap between the new 'local' campaign music and the more traditional horror music from the first game was solved in several ways.  First, we kept all the original themes from Left 4 Dead 1 but arranged them in a style consistent with the local campaign's theme.  Second, we wrote an overarching set of cinematic \"southern goth\" pieces for entire game.   Finally, we wrote new pieces for the new characters in the style of Left 4 Dead 1.  By doing all this, we establish that these are new characters in new places but they are sharing the experience of everyone else in the Left 4 Dead universe."
	"#commentary\com-secretingredients.wav"	"[Bronwen Grimes] The infected textures are part hand-painted, part photographic reference.  One of our team members had a nightmare folder full of photographs of people suffering from bizarre diseases and injuries.  They were so hard to look at that the infected actually contain none of these.   Instead, the secret ingredients for infecting normal-looking human textures are photos of housing insulation and potato skins."
	"#commentary\com-story.wav"	"[Chet Faliszek] In Left 4 Dead 2 we wanted to give players who were looking for a narrative a little more.   To do this, we introduce the four Survivors to each other and the infection as we begin the game.   This let’s us see the world changing through their eyes.  And the world is changing, each new Campaign shows a different stage and reaction to the infection.  We start with CEDA’s naïve underwhelming response and end with the Military’s cold but needed resolve to save only those they can. We also connect each Campaign.  So while you know you escape Whispering Oaks in Dark Carnival, you also know that is just one escape of many on your journey to safety in New Orleans.  Time does pass between campaigns, but each campaign starts with the previous rescue vehicle.  We also continue to spread hints and clues to the infection.  There is more 'Story' in the dialogue this time around, but players should still search for and read graffiti and notes in the world.  Observant players of Left 4 Dead will notice some tie-ins to the story as both games are set in the same world."
	"#commentary\com-traditionalcrescendo.wav"	"[Kerry Davis] This is the only 'traditional' Crescendo Event in The Parish campaign.  In Left 4 Dead 1, every Crescendo Event was essentially a button press where players held out in one spot until the infected stopped coming.  While we added the onslaught and optional crescendo variations, we felt that the old-school Left 4 Dead style event still had some life in it."
	"#commentary\com-welcome.wav"	"[Gabe Newell] Hi, my name is Gabe Newell, and welcome to Left 4 Dead 2.  We love this style of zombie-driven cooperative gameplay.  Tom Leonard and the rest of the Left 4 Dead 2 team have had a great time building on the design and game mechanics of the original and we hope you have as much fun playing the game as we did making it. To listen to a commentary node, put your crosshair over the floating commentary symbol and press your use key. To stop a commentary node, put your crosshair over the rotating node and press the use key again. Some commentary nodes may take control of the game in order to show something to you. In these cases, simply press your use key again to stop the commentary.  Please let me know what you think after you have had a chance to play Left 4 Dead 2.  I can be reached at gaben@valvesoftware.com.  I get about 10,000 emails each time we release a game, and while I can't respond to all of them, I do read all of them.  Thanks, and have fun!"
	"Coach_GettingRevived03"	"<clr:112,75,125>Coach: Hell yeah it hurts."
	"Coach_GrabbedByJockey06"	"<clr:112,75,125>Coach: Ellis, is that you? What the hell!?"
	"Coach_Hurrah07"	"<clr:112,75,125>Coach: Oh hell yeah!"
	"Coach_Hurrah11"	"<clr:112,75,125>Coach: Oh hell yeah!"
	"Coach_MiscDirectional13"	"<clr:112,75,125>Coach: Through this window!"
	"Coach_MiscDirectional14"	"<clr:112,75,125>Coach: Through that window!"
	"Coach_ReactionNegative01"	"<clr:112,75,125>Coach: Shit."
	"Coach_ReactionNegative02"	"<clr:112,75,125>Coach: What the f-"
	"Coach_ReactionNegative03"	"<clr:112,75,125>Coach: Damn!"
	"Coach_ReactionNegative04"	"<clr:112,75,125>Coach: Man, this is about to get all Baghdad and shit.."
	"Coach_ReactionNegative05"	"<clr:112,75,125>Coach: Oh hell, this about to get bad."
	"Coach_ReactionNegative06"	"<clr:112,75,125>Coach: Hell no."
	"Coach_ReactionNegative07"	"<clr:112,75,125>Coach: Nhhhhhh."
	"Coach_ReactionNegative08"	"<clr:112,75,125>Coach: God damn it!"
	"Coach_ReactionNegative09"	"<clr:112,75,125>Coach: Shiiit."
	"Coach_ReactionNegative10"	"<clr:112,75,125>Coach: Shiiit."
	"Coach_ReactionNegative11"	"<clr:112,75,125>Coach: What the?"
	"Coach_ReactionNegative12"	"<clr:112,75,125>Coach: Bullshit."
	"Coach_ReactionNegative13"	"<clr:112,75,125>Coach: Well, I'll be a monkey's uncle."
	"Coach_ReactionNegative14"	"<clr:112,75,125>Coach: Bullshit."
	"Coach_ReactionNegative15"	"<clr:112,75,125>Coach: Goddamn!"
	"Coach_ReactionNegative16"	"<clr:112,75,125>Coach: Son of a bitch."
	"Coach_ReactionNegative17"	"<clr:112,75,125>Coach: Son of a bitch."
	"Coach_ReactionNegative18"	"<clr:112,75,125>Coach: Goddamn!"
	"Coach_ReactionNegative19"	"<clr:112,75,125>Coach: Well, I'll be a monkey's uncle."
	"Coach_ReactionNegative20"	"<clr:112,75,125>Coach: Bullshit."
	"Coach_TakeAutoShotgun03"	"<clr:112,75,125>Coach: Oh, hell yeah, I'm takin' an autoshotgun."
	"Coach_Taunt01"	"<clr:112,75,125>Coach: Hell yeah!"
	"Coach_Taunt05"	"<clr:112,75,125>Coach: Oh hell yeah!"
	"Coach_TransitionClose01"	"<clr:112,75,125>Coach: That shit was crazy."
	"Coach_TransitionClose02"	"<clr:112,75,125>Coach: That shit was crazy."
	"Coach_TransitionClose08"	"<clr:112,75,125>Coach: Touchdown!"
	"Coach_TransitionClose10"	"<clr:112,75,125>Coach: That was some epic shit right there."
	"Coach_WorldC1M1B137"	"<clr:112,75,125>Coach: Down this elevator shaft!"
	"Coach_WorldC1M1B61"	"<clr:112,75,125>Coach: Elevator's out!"
	"Coach_WorldC1M1B62"	"<clr:112,75,125>Coach: Oh, crumbs! Elevator's out."
	"Coach_WorldC1M3B21"	"<clr:112,75,125>Coach: Heyyy! Jimmy Gibbs!"
	"Coach_WorldC1M3B22"	"<clr:112,75,125>Coach: Ohh heyyy! Jimmy Gibbs!"
	"Coach_WorldC1M3B23"	"<clr:112,75,125>Coach: I heard of Jimmy Gibbs! That man's a stock car LEGEND."
	"Coach_WorldC1M4B01"	"<clr:112,75,125>Coach: Son, you got a DEAL."
	"Coach_WorldC1M4B02"	"<clr:112,75,125>Coach: Ha HA! All the way to New Orleans! Baby, that sounds like a PLAN."
	"Coach_WorldC1M4B03"	"<clr:112,75,125>Coach: All right, so...Getting' evac'd ain't happening. Anybody got an idea, now's the time."
	"Coach_WorldC1M4B04"	"<clr:112,75,125>Coach: Looks like we're gonna have to save ourselves. Anybody got an idea, speak up, we're listenin'."
	"Coach_WorldC1M4B05"	"<clr:112,75,125>Coach: Normally I wouldn't do this. But in these circumstances, I think Mr. Gibbs, Jr. ain't gonna mind."
	"Coach_WorldC1M4B06"	"<clr:112,75,125>Coach: Normally I wouldn't agree to do this. But in these circumstances, I think Mr. Gibbs, Jr. ain't gonna mind."
	"Coach_WorldC1M4B07"	"<clr:112,75,125>Coach: If we see a Jimmy Gibbs zombie, somebody else is gonna have to kill him."
	"Coach_WorldC1M4B08"	"<clr:112,75,125>Coach: Soon as them doors open? You run your ass off and find some GAS."
	"Coach_WorldC1M4B09"	"<clr:112,75,125>Coach: Soon as these doors open, get ready to MOVE."
	"Coach_WorldC1M4B10"	"<clr:112,75,125>Coach: Forgive us, Jimmy, but we need your car."
	"Coach_WorldC1M4B11"	"<clr:112,75,125>Coach: Haul ass and get gas!"
	"Coach_WorldC1M4B12"	"<clr:112,75,125>Coach: Oh, come on, baby, come on..."
	"Coach_WorldC1M4B13"	"<clr:112,75,125>Coach: Oh, come on, baby, come on..."
	"Coach_WorldC1M4B14"	"<clr:112,75,125>Coach: Please, baby, baby, please, please..."
	"Coach_WorldC1M4B15"	"<clr:112,75,125>Coach: Oh, come on, baby, come on..."
	"Coach_WorldC1M4B16"	"<clr:112,75,125>Coach: Hurry up, hurrrry upppp..."
	"Coach_WorldC1M4B17"	"<clr:112,75,125>Coach: Come onnnn, come onnnnnn..."
	"Coach_WorldC1M4B18"	"<clr:112,75,125>Coach: Fillin' it up here!"
	"Coach_WorldC1M4B19"	"<clr:112,75,125>Coach: I got this one!"
	"Coach_WorldC1M4B20"	"<clr:112,75,125>Coach: Let's go! Find a gas can!"
	"Coach_WorldC1M4B21"	"<clr:112,75,125>Coach: Let's get this car gassed up!"
	"Coach_WorldC1M4B22"	"<clr:112,75,125>Coach: We need more gas!"
	"Coach_WorldC1M4B23"	"<clr:112,75,125>Coach: We still need more gas!"
	"Coach_WorldC1M4B24"	"<clr:112,75,125>Coach: All right, halfway there!"
	"Coach_WorldC1M4B25"	"<clr:112,75,125>Coach: Almost there!"
	"Coach_WorldC1M4B26"	"<clr:112,75,125>Coach: We need twenty more!"
	"Coach_WorldC1M4B27"	"<clr:112,75,125>Coach: We still need ten more!"
	"Coach_WorldC1M4B28"	"<clr:112,75,125>Coach: We still need five more!"
	"Coach_WorldC1M4B29"	"<clr:112,75,125>Coach: Just three more!"
	"Coach_WorldC1M4B30"	"<clr:112,75,125>Coach: Just two more!"
	"Coach_WorldC1M4B31"	"<clr:112,75,125>Coach: One more can to go!"
	"Coach_WorldC1M4B32"	"<clr:112,75,125>Coach: We're all gassed up, get to the car!"
	"Coach_WorldC1M4B33"	"<clr:112,75,125>Coach: Here we come, New Orleans!"
	"Coach_WorldC1M4B34"	"<clr:112,75,125>Coach: GET TO THE CAR!"
	"Coach_WorldC1M4B35"	"<clr:112,75,125>Coach: GET TO THE CAR, PEOPLE!"
	"Coach_WorldC1M4B36"	"<clr:112,75,125>Coach: HIT IT!"
	"Coach_WorldC1M4B37"	"<clr:112,75,125>Coach: Sorry about this, Mr. Gibbs."
	"Coach_WorldC1M4B38"	"<clr:112,75,125>Coach: GO, ELLIS, GO!"
	"Coach_WorldC1M4B39"	"<clr:112,75,125>Coach: GO, ELLIS, GO!"
	"Coach_WorldC1M4B40"	"<clr:112,75,125>Coach: PUNCH IT, ELLIS!"
	"Coach_WorldC1M4B41"	"<clr:112,75,125>Coach: Woo! Thank you, Mr. Gibbs."
	"Coach_WorldC2M415"	"<clr:112,75,125>Coach: Rochelle, you gotta find another window, this here is the men's room."
	"Coach_WorldC2M5B16"	"<clr:112,75,125>Coach: Then we start the Midnight Rider finale. It's all kinds of fireworks, smokepots, and lights and shit. That chopper pilot can't miss it."
	"Coach_WorldC2M5B17"	"<clr:112,75,125>Coach: Then we start the Midnight Rider finale. It's all kinds of fireworks, smokepots, and lights and shit. That chopper pilot can't miss it."
	"Coach_WorldC2M5B47"	"<clr:112,75,125>Coach: Set off the fireworks!"
	"Coach_WorldC2M5B80"	"<clr:112,75,125>Coach: Set off the fireworks!"
	"Coach_WorldC3M122"	"<clr:112,75,125>Coach: I normally stay the hell away from swamps on principle.  You remember that movie with that golfer that got his hand ate by a gator?  That shit's real."
	"Coach_WorldC3M129"	"<clr:112,75,125>Coach: Do not feed the gators."
	"Commentary_Title_DYNAMIC_PATHS"	"DYNAMIC PATHS"
	"Commentary_Title_LASER_SIGHTS"	 "LASER-SIGHTS"
	"Commentary_Title_LOCAL_MUSIC"	 "LOCAL MUSIC"
	"Commentary_Title_SECRET_INGREDIENTS"	"SECRET INGREDIENTS"
	"Commentary_Title_STORY"	"STORY"
	"Commentary_Title_TRADITIONAL_CRESCENDO"	"TRADITIONAL CRESCENDO"
	"Commentary_Title_WELCOME"	"WELCOME TO LEFT 4 DEAD 2"
	"Gambler_BoomerReaction01"	"<clr:64,100,166>Nick: Oh God damn it!"
	"Gambler_GoingToDie04"	"<clr:64,100,166>Nick: God damn it! God damn it.  God damn it."
	"Gambler_GoingToDie14"	"<clr:64,100,166>Nick: God damn it, I can't believe this."
	"Gambler_GrabbedBySmokerC101"	"<clr:64,100,166>Nick: What the hell?"
	"Gambler_GrenadeLauncher02"	"<clr:64,100,166>Nick: Hell yeah. Grenade launcher."
	"Gambler_MiscDirectional07"	"<clr:64,100,166>Nick: Through this window!"
	"Gambler_MiscDirectional08"	"<clr:64,100,166>Nick: Through that window!"
	"Gambler_PositiveNoise07"	"<clr:64,100,166>Nick: Hell yeah."
	"Gambler_PositiveNoise14"	"<clr:64,100,166>Nick: Hell yeah."
	"Gambler_ReactionNegative01"	"<clr:64,100,166>Nick: This is all going to hell!"
	"Gambler_ReactionNegative02"	"<clr:64,100,166>Nick: Damn..."
	"Gambler_ReactionNegative03"	"<clr:64,100,166>Nick: Shit!"
	"Gambler_ReactionNegative04"	"<clr:64,100,166>Nick: God damn it."
	"Gambler_ReactionNegative05"	"<clr:64,100,166>Nick: Bullshit!"
	"Gambler_ReactionNegative06"	"<clr:64,100,166>Nick: Bastards!"
	"Gambler_ReactionNegative07"	"<clr:64,100,166>Nick: Holy Shit!"
	"Gambler_ReactionNegative08"	"<clr:64,100,166>Nick: Ah, tits!"
	"Gambler_ReactionNegative09"	"<clr:64,100,166>Nick: Son of a bitch."
	"Gambler_ReactionNegative10"	"<clr:64,100,166>Nick: Son of a bitch."
	"Gambler_ReactionNegative11"	"<clr:64,100,166>Nick: Oh bullshit!"
	"Gambler_ReactionNegative12"	"<clr:64,100,166>Nick: My ass."
	"Gambler_ReactionNegative13"	"<clr:64,100,166>Nick: This is all going to hell!"
	"Gambler_ReactionNegative14"	"<clr:64,100,166>Nick: Damn..."
	"Gambler_ReactionNegative15"	"<clr:64,100,166>Nick: Shit!"
	"Gambler_ReactionNegative16"	"<clr:64,100,166>Nick: God damn it."
	"Gambler_ReactionNegative17"	"<clr:64,100,166>Nick: Bullshit!"
	"Gambler_ReactionNegative18"	"<clr:64,100,166>Nick: Bastards!"
	"Gambler_ReactionNegative19"	"<clr:64,100,166>Nick: Shit!"
	"Gambler_ReactionNegative20"	"<clr:64,100,166>Nick: Tits!"
	"Gambler_ReactionNegative21"	"<clr:64,100,166>Nick: Son of a bitch."
	"Gambler_ReactionNegative22"	"<clr:64,100,166>Nick: Oh bullshit!"
	"Gambler_ReactionNegative23"	"<clr:64,100,166>Nick: My ass."
	"Gambler_ReactionNegative24"	"<clr:64,100,166>Nick: Is this some kind of sick joke?"
	"Gambler_ReactionNegative25"	"<clr:64,100,166>Nick: Is this some kind of sick joke?"
	"Gambler_ReactionNegative26"	"<clr:64,100,166>Nick: I call foul."
	"Gambler_ReactionNegative27"	"<clr:64,100,166>Nick: Kiss my ass."
	"Gambler_ReactionNegative28"	"<clr:64,100,166>Nick: Ass."
	"Gambler_ReactionNegative29"	"<clr:64,100,166>Nick: Asshat."
	"Gambler_ReactionNegative30"	"<clr:64,100,166>Nick: Bitch."
	"Gambler_ReactionNegative31"	"<clr:64,100,166>Nick: Asshole."
	"Gambler_ReactionNegative32"	"<clr:64,100,166>Nick: Assclown."
	"Gambler_ReactionNegative33"	"<clr:64,100,166>Nick: Dumbshit."
	"Gambler_ReactionNegative34"	"<clr:64,100,166>Nick: Screw this."
	"Gambler_ReactionNegative35"	"<clr:64,100,166>Nick: Kiss my ass."
	"Gambler_ReactionNegative36"	"<clr:64,100,166>Nick: Kiss my ass."
	"Gambler_ReactionNegative37"	"<clr:64,100,166>Nick: What an assclown."
	"Gambler_ReactionNegative38"	"<clr:64,100,166>Nick: Dumbshit."
	"Gambler_TakeMelee01"	"<clr:64,100,166>Nick: Hell yeah!"
	"Gambler_World318"	"<clr:64,100,166>Nick: This used to be a beautiful city."
	"Gambler_World415"	"<clr:64,100,166>Nick: Your mom's car."
	"Gambler_World421"	"<clr:64,100,166>Nick: Your mom's car."
	"Gambler_World422"	"<clr:64,100,166>Nick: No Ellis, I've never seen anything like this."
	"Gambler_WorldC1M1B17"	"<clr:64,100,166>Nick: Damn it! Elevator's out."
	"Gambler_WorldC1M1B82"	"<clr:64,100,166>Nick: Down this shaft!"
	"Gambler_WorldC1M1B83"	"<clr:64,100,166>Nick: We can jump down the elevator shaft!"
	"Gambler_WorldC1M3B08"	"<clr:64,100,166>Nick: Disco Pants and Haircuts? Man, lots of space in this mall."
	"Gambler_WorldC1M3B12"	"<clr:64,100,166>Nick: Who the hell is Jimmy Gibbs, Jr.?"
	"Gambler_WorldC1M4B01"	"<clr:64,100,166>Nick: I think the little guy's onto something. Let's give it a shot."
	"Gambler_WorldC1M4B02"	"<clr:64,100,166>Nick: CEDA's not gonna save us, any ideas?"
	"Gambler_WorldC1M4B03"	"<clr:64,100,166>Nick: I'll agree to the idea, but I'm driving."
	"Gambler_WorldC1M4B04"	"<clr:64,100,166>Nick: What a fun road trip this will be."
	"Gambler_WorldC1M4B05"	"<clr:64,100,166>Nick: Well, it beats my idea: staying here and dying in the mall."
	"Gambler_WorldC1M4B06"	"<clr:64,100,166>Nick: Okay. Let's gas up the car and get the hell out of this mall."
	"Gambler_WorldC1M4B07"	"<clr:64,100,166>Nick: Let's get some GAS!"
	"Gambler_WorldC1M4B08"	"<clr:64,100,166>Nick: Fill 'er up!"
	"Gambler_WorldC1M4B09"	"<clr:64,100,166>Nick: Come onnnn, come onnnnnn..."
	"Gambler_WorldC1M4B10"	"<clr:64,100,166>Nick: Come onnnn, come onnnnnn..."
	"Gambler_WorldC1M4B11"	"<clr:64,100,166>Nick: Come on..."
	"Gambler_WorldC1M4B12"	"<clr:64,100,166>Nick: Get in the tank, you stupid goddamn gas, get in the tank."
	"Gambler_WorldC1M4B13"	"<clr:64,100,166>Nick: Piece of shit gas, GET IN THE CAR!"
	"Gambler_WorldC1M4B14"	"<clr:64,100,166>Nick: Got another can in the tank!"
	"Gambler_WorldC1M4B15"	"<clr:64,100,166>Nick: One more for the gas tank!"
	"Gambler_WorldC1M4B16"	"<clr:64,100,166>Nick: How big is the tank in this thing?"
	"Gambler_WorldC1M4B17"	"<clr:64,100,166>Nick: Hurry up, hurrrry upppp..."
	"Gambler_WorldC1M4B18"	"<clr:64,100,166>Nick: Come comeoncomeoncomeoncomeon. Come on!"
	"Gambler_WorldC1M4B19"	"<clr:64,100,166>Nick: Get! In! The! Tank!"
	"Gambler_WorldC1M4B20"	"<clr:64,100,166>Nick: Get in there!"
	"Gambler_WorldC1M4B21"	"<clr:64,100,166>Nick: Let's go! Find a gas can!"
	"Gambler_WorldC1M4B22"	"<clr:64,100,166>Nick: Let's get this car gassed up!"
	"Gambler_WorldC1M4B23"	"<clr:64,100,166>Nick: We need more gas!"
	"Gambler_WorldC1M4B24"	"<clr:64,100,166>Nick: We still need more gas!"
	"Gambler_WorldC1M4B25"	"<clr:64,100,166>Nick: Halfway there!"
	"Gambler_WorldC1M4B26"	"<clr:64,100,166>Nick: Almost there!"
	"Gambler_WorldC1M4B27"	"<clr:64,100,166>Nick: We need twenty more!"
	"Gambler_WorldC1M4B28"	"<clr:64,100,166>Nick: We still need ten more!"
	"Gambler_WorldC1M4B29"	"<clr:64,100,166>Nick: We still need five more!"
	"Gambler_WorldC1M4B30"	"<clr:64,100,166>Nick: Just three more!"
	"Gambler_WorldC1M4B31"	"<clr:64,100,166>Nick: Just two more!"
	"Gambler_WorldC1M4B32"	"<clr:64,100,166>Nick: One more and we can go!"
	"Gambler_WorldC1M4B33"	"<clr:64,100,166>Nick: One more can to go!"
	"Gambler_WorldC1M4B34"	"<clr:64,100,166>Nick: She's all filled up, let's go, get to the car!"
	"Gambler_WorldC1M4B35"	"<clr:64,100,166>Nick: Thank YOU, Jimmy Gibbs, Jr."
	"Gambler_WorldC1M4B36"	"<clr:64,100,166>Nick: Get to the car!"
	"Gambler_WorldC1M4B37"	"<clr:64,100,166>Nick: Would you get to the goddamn car?"
	"Gambler_WorldC1M4B38"	"<clr:64,100,166>Nick: HELL YEAH! Next stop: New Orleans..."
	"Gambler_WorldC1M4B39"	"<clr:64,100,166>Nick: Everyone to the car!"
	"Gambler_WorldC1M4B40"	"<clr:64,100,166>Nick: I'm not waiting long, get to the car!"
	"Gambler_WorldC1M4B41"	"<clr:64,100,166>Nick: Time to leave people!"
	"Gambler_WorldC1M4B42"	"<clr:64,100,166>Nick: Time to go!"
	"Gambler_WorldC1M4B43"	"<clr:64,100,166>Nick: Let's go people, let's go!"
	"Gambler_WorldC1M4B44"	"<clr:64,100,166>Nick: Hit it, Ellis!"
	"Gambler_WorldC2M1B03"	"<clr:64,100,166>Nick: God DAMN you, Jimmy Gibbs, Jr."
	"Gambler_WorldC2M428"	"<clr:64,100,166>Nick: Into the window."
	"Gambler_WorldC2M5B22"	"<clr:64,100,166>Nick: Set off the fireworks!"
	"Gambler_WorldC2M5B23"	"<clr:64,100,166>Nick: Launch the fireworks!"
	"Gambler_WorldC3MGoingToDie02"	"<clr:64,100,166>Nick: I am not going to be gator food."
	"Gambler_WorldC5M3B07"	"<clr:64,100,166>Nick: What the hell was this guy doing?"
	"Mechanic_DeathScream01"	"<clr:223,200,143><norepeat:15>Ellis: <clr:246,5,5>[Death scream]"
	"Mechanic_DeathScream02"	"<clr:223,200,143><norepeat:15>Ellis: <clr:246,5,5>[Death scream]"
	"Mechanic_DeathScream03"	"<clr:223,200,143><norepeat:15>Ellis: <clr:246,5,5>[Death scream]"
	"Mechanic_DeathScream04"	"<clr:223,200,143><norepeat:15>Ellis: <clr:246,5,5>[Death scream]"
	"Mechanic_DeathScream05"	"<clr:223,200,143><norepeat:15>Ellis: <clr:246,5,5>[Death scream]"
	"Mechanic_DeathScream06"	"<clr:223,200,143><norepeat:15>Ellis: <clr:246,5,5>[Death scream]"
	"Mechanic_EllisStoriesB01"	"<clr:223,200,143>Ellis: Jimmy Gibbs, Jr. is the man. I mean I don't know anybody like that, man.  But there was this guy I knew, he raced dirt tracks, not stock cars but open wheeled cars you know, and he was racing once and a goat..."
	"Mechanic_EllisStoriesG01"	"<clr:223,200,143>Ellis: I ever tell you about the time Keith and I made fireworks? Now, I didn't know shit about chemistry, but Keith figured,  \"Gasoline burns, doesn't it?\" Third degree burns on ninety-five percent of his body. Man, people in the next city over were calling to complain about the smell of burning skin."
	"Mechanic_EllisStoriesI01"	"<clr:223,200,143>Ellis: I ever tell you about the time my buddy Keith drove his car off a cliff, broke both his legs? It's not a funny ha-ha story so much as a make-you-think story.  For instance: windshields look pretty durable, right? Not the case, according to Keith. Son of a bitch flew right through that sucker--"
	"Mechanic_EllisStoriesL01"	"<clr:223,200,143>Ellis: I ever tell you guys about the time my buddy Keith got rolled by a gator in a swamp? Man, he didn't agonize it or nothing, we were just trying to grab two so we could piss 'em off and get 'em into a fight. Anyway, the third time Keith went under, I realized something was wrong, so I--"
	"Mechanic_EllisStoriesQ01"	"<clr:223,200,143>Ellis: I ever tell you about the time me and Keith made a homemade bumper car ride with riding mowers in his back yard? Mower blade wounds over ninety percent of his body. I didn't run him over, either.  He somehow managed to fall under his own."
	"Mechanic_GrabbedBySmoker02b"	"<clr:223,200,143>Ellis: NOOOOOOO!!!!"
	"Mechanic_GrenadeLauncher05"	"<clr:223,200,143>Ellis: Oh hell yeah, I gotta take the Grenade Launcher!"
	"Mechanic_Hurrah08"	"<clr:223,200,143>Ellis: Ahh HELL YEAH!"
	"Mechanic_ImWithYou04"	"<clr:223,200,143>Ellis: Hell yeah, I'm with ya."
	"Mechanic_KillConfirmationEllisR05"	"<clr:223,200,143>Ellis: Hell yeah, that was mine!"
	"Mechanic_Laughter07"	"<clr:223,200,143>Ellis: Hell yeah!"
	"Mechanic_LeadOn02"	"<clr:223,200,143>Ellis: Hell yeah, where we going?"
	"Mechanic_LedgeHangFall02"	"<clr:223,200,143>Ellis: NOOOOOOOOOOOOOOOO!!!!"
	"Mechanic_MiscDirectional07"	"<clr:223,200,143>Ellis: Hey, through this window!"
	"Mechanic_MiscDirectional08"	"<clr:223,200,143>Ellis: Through that window!"
	"Mechanic_ReactionNegative01"	"<clr:223,200,143>Ellis: No!"
	"Mechanic_ReactionNegative02"	"<clr:223,200,143>Ellis: Ahh SHIT!"
	"Mechanic_ReactionNegative03"	"<clr:223,200,143>Ellis: God DAMN!"
	"Mechanic_ReactionNegative04"	"<clr:223,200,143>Ellis: Ah Lord!"
	"Mechanic_ReactionNegative05"	"<clr:223,200,143>Ellis: Jesus NO, man!"
	"Mechanic_ReactionNegative06"	"<clr:223,200,143>Ellis: That ain't right!"
	"Mechanic_ReactionNegative07"	"<clr:223,200,143>Ellis: Oh SHIT!"
	"Mechanic_ReactionNegative08"	"<clr:223,200,143>Ellis: God DAMN!"
	"Mechanic_ReactionNegative09"	"<clr:223,200,143>Ellis: Jesus NO!"
	"Mechanic_ReactionNegative10"	"<clr:223,200,143>Ellis: No thank you!"
	"Mechanic_ReactionNegative11"	"<clr:223,200,143>Ellis: Shit, that ain't right!"
	"Mechanic_ReactionNegative12"	"<clr:223,200,143>Ellis: BULLSHIT!"
	"Mechanic_ReactionNegative13"	"<clr:223,200,143>Ellis: Oh, hogwash, man!"
	"Mechanic_ReactionNegative14"	"<clr:223,200,143>Ellis: Well piss!"
	"Mechanic_ReactionNegative15"	"<clr:223,200,143>Ellis: Hogwash!"
	"Mechanic_ReactionNegative16"	"<clr:223,200,143>Ellis: Ain't that a load of shit."
	"Mechanic_ReactionNegative17"	"<clr:223,200,143>Ellis: That's bullshit!"
	"Mechanic_ReactionNegative18"	"<clr:223,200,143>Ellis: Hogwash!"
	"Mechanic_ReactionNegative19"	"<clr:223,200,143>Ellis: Well piss!"
	"Mechanic_ReactionNegative20"	"<clr:223,200,143>Ellis: Ain't that a load of shit."
	"Mechanic_TransitionClose12"	"<clr:223,200,143>Ellis: THAT... was a pretty poor display."
	"Mechanic_World427"	"<clr:223,200,143>Ellis: Hey Nick, what kind of car did you drive?"
	"Mechanic_WorldC1M1B105"	"<clr:223,200,143>Ellis: Down this elevator shaft!"
	"Mechanic_WorldC1M1B69"	"<clr:223,200,143>Ellis: Goddamn elevator's out!"
	"Mechanic_WorldC1M3B12"	"<clr:223,200,143>Ellis: Check it out, man! Jimmy Gibbs, Jr.!"
	"Mechanic_WorldC1M3B13"	"<clr:223,200,143>Ellis: Check it out, man! That's Jimmy Gibbs, Jr.!"
	"Mechanic_WorldC1M3B14"	"<clr:223,200,143>Ellis: Ugh, only the best stock car racer who ever lived, Nick. Guess you don't read much history."
	"Mechanic_WorldC1M3B15"	"<clr:223,200,143>Ellis: That right there, ladies and gentlemen, is Mr. Jimmy Gibbs, Jr.!"
	"Mechanic_WorldC1M3B16"	"<clr:223,200,143>Ellis: I'll be damned! That's Jimmy Gibbs, Jr.!"
	"Mechanic_WorldC1M3B17"	"<clr:223,200,143>Ellis: Just the best stock car racer of all time. Try reading a book sometime."
	"Mechanic_WorldC1M3B18"	"<clr:223,200,143>Ellis: Now hold on. You been makin' jokes about Savannah all day and I've held my tongue. But don't belittle Jimmy Gibbs, Jr. That man is the pride of Georgia.."
	"Mechanic_WorldC1M3B19"	"<clr:223,200,143>Ellis: Now hold on. You been makin' jokes about Savannah all day and I've held my tongue. But don't belittle Jimmy Gibbs, Jr. That man's a living legend."
	"Mechanic_WorldC1M3B25"	"<clr:223,200,143>Ellis: That's Jimmy Gibbs, Jr. The greatest driver ever to climb into a stock car."
	"Mechanic_WorldC1M3B28"	"<clr:223,200,143>Ellis: Aw, hell. I coulda got my picture taken with Jimmy Gibbs's stock car? I HATE this apocalypse."
	"Mechanic_WorldC1M3B29"	"<clr:223,200,143>Ellis: God damn it. I coulda got my picture taken with Jimmy Gibbs's stock car."
	"Mechanic_WorldC1M3B30"	"<clr:223,200,143>Ellis: Check it, y'all! Jimmy Gibbs, Jr.!"
	"Mechanic_WorldC1M3B31"	"<clr:223,200,143>Ellis: Jimmy Gibbs got my vote."
	"Mechanic_WorldC1M4B01"	"<clr:223,200,143>Ellis: Actually, I been thinking..."
	"Mechanic_WorldC1M4B02"	"<clr:223,200,143>Ellis: I might have an idea."
	"Mechanic_WorldC1M4B03"	"<clr:223,200,143>Ellis: I think I got one."
	"Mechanic_WorldC1M4B04"	"<clr:223,200,143>Ellis: If you're looking for ideas, look no further. Because I have a good one."
	"Mechanic_WorldC1M4B05"	"<clr:223,200,143>Ellis: Let's go find Jimmy Gibbs's stock car. We get that thing gassed up, we can drive out of here."
	"Mechanic_WorldC1M4B06"	"<clr:223,200,143>Ellis: So I been thinking. Jimmy Gibbs's stock car's around here somewhere. We just gotta find it, gas it up, and I'll drive that thing to New Orleans my damn self."
	"Mechanic_WorldC1M4B07"	"<clr:223,200,143>Ellis: I've got an idea. You know them posters we been seein? Get your picture taken with Jimmy Gibbs's stock car? That means it's HERE. We just need to appropriate it, and we got ourselves an escape vehicle."
	"Mechanic_WorldC1M4B08"	"<clr:223,200,143>Ellis: Listen up. See that poster! Says here you can get your picture taken with Jimmy Gibbs stock car. All we gotta do is find it, gas it up, and drive out of here ourselves!"
	"Mechanic_WorldC1M4B09"	"<clr:223,200,143>Ellis: I've got an idea. Jimmy Gibbs, Jr. ain't gonna mind if we borrow his stock car. He's a very generous man."
	"Mechanic_WorldC1M4B10"	"<clr:223,200,143>Ellis: Yeah, yeah, yeah. All we gotta do is find it and gas it up, and I'll drive us out of here my damn self."
	"Mechanic_WorldC1M4B11"	"<clr:223,200,143>Ellis: Y'all remember those ads we saw on the way in? I think I got an idea how to get us some wheels."
	"Mechanic_WorldC1M4B12"	"<clr:223,200,143>Ellis: That's Jimmy Gibbs, Jr., and yes. We find his stock car, get it gassed up? I'll drive us out of here myself."
	"Mechanic_WorldC1M4B13"	"<clr:223,200,143>Ellis: Only if I get kilt. Otherwise you better kill me, cause I'M driving."
	"Mechanic_WorldC1M4B14"	"<clr:223,200,143>Ellis: I actually think the guy who came up with the idea should get to drive the stock car."
	"Mechanic_WorldC1M4B15"	"<clr:223,200,143>Ellis: It was my idea!"
	"Mechanic_WorldC1M4B16"	"<clr:223,200,143>Ellis: I think the guy who came up with the idea should get to drive the stock car. And that was, I dunno, ME."
	"Mechanic_WorldC1M4B17"	"<clr:223,200,143>Ellis: Now remember: They don't fill up the tanks at car shows, so we'll have to find some gas."
	"Mechanic_WorldC1M4B18"	"<clr:223,200,143>Ellis: All right, I'm bettin' the gas tank'll probably be empty. We'll have to gas it up before we can haul ass."
	"Mechanic_WorldC1M4B19"	"<clr:223,200,143>Ellis: Now, this ain't the first time I've tried to peel out of a car show. Turns out they usually leave the tanks empty for just such an eventuality. We gonna have to gas it up."
	"Mechanic_WorldC1M4B20"	"<clr:223,200,143>Ellis: Wherever he is, Coach-he's proud of you."
	"Mechanic_WorldC1M4B21"	"<clr:223,200,143>Ellis: Hell. I never thought of that."
	"Mechanic_WorldC1M4B22"	"<clr:223,200,143>Ellis: Not me. That man's like a father to me."
	"Mechanic_WorldC1M4B23"	"<clr:223,200,143>Ellis: Remember the plan. Grab gas, fill up the tank, and let's get out of here."
	"Mechanic_WorldC1M4B24"	"<clr:223,200,143>Ellis: Soon as these doors open... get ready to run."
	"Mechanic_WorldC1M4B25"	"<clr:223,200,143>Ellis: Go! Go! Go! Find some gas!"
	"Mechanic_WorldC1M4B26"	"<clr:223,200,143>Ellis: Hey there's the car! Grab a gas can and fill 'er up!"
	"Mechanic_WorldC1M4B27"	"<clr:223,200,143>Ellis: There's she is!"
	"Mechanic_WorldC1M4B28"	"<clr:223,200,143>Ellis: Oh Man! There's she is!"
	"Mechanic_WorldC1M4B29"	"<clr:223,200,143>Ellis: Hey, there's the car!"
	"Mechanic_WorldC1M4B30"	"<clr:223,200,143>Ellis: Come comeoncomeoncomeon..."
	"Mechanic_WorldC1M4B31"	"<clr:223,200,143>Ellis: Please get in the tank, please please please..."
	"Mechanic_WorldC1M4B32"	"<clr:223,200,143>Ellis: C'mon, hurrrry up up up up up..."
	"Mechanic_WorldC1M4B33"	"<clr:223,200,143>Ellis: Man I feel like I'm gassin' up royalty."
	"Mechanic_WorldC1M4B34"	"<clr:223,200,143>Ellis: This is... such an honor."
	"Mechanic_WorldC1M4B35"	"<clr:223,200,143>Ellis: Man, never in my wildest dreams did I think I'd be gassin' up Jimmy Gibbs's car."
	"Mechanic_WorldC1M4B36"	"<clr:223,200,143>Ellis: Would you look at that automobile..."
	"Mechanic_WorldC1M4B37"	"<clr:223,200,143>Ellis: I'll be drivin' you REALLLL soon, girl."
	"Mechanic_WorldC1M4B38"	"<clr:223,200,143>Ellis: I can't wait to get behind your wheel, darlin'."
	"Mechanic_WorldC1M4B39"	"<clr:223,200,143>Ellis: Come onnnn, come onnnnnn...Fill it up here!"
	"Mechanic_WorldC1M4B40"	"<clr:223,200,143>Ellis: Grab a gas can and fill 'er up!"
	"Mechanic_WorldC1M4B41"	"<clr:223,200,143>Ellis: Find a gas can!"
	"Mechanic_WorldC1M4B42"	"<clr:223,200,143>Ellis: Find a gas can!"
	"Mechanic_WorldC1M4B43"	"<clr:223,200,143>Ellis: I got this one!"
	"Mechanic_WorldC1M4B44"	"<clr:223,200,143>Ellis: Let's go! Let's get this car gassed up!"
	"Mechanic_WorldC1M4B45"	"<clr:223,200,143>Ellis: Let's get this car gassed up!"
	"Mechanic_WorldC1M4B46"	"<clr:223,200,143>Ellis: We need more gas!"
	"Mechanic_WorldC1M4B47"	"<clr:223,200,143>Ellis: We still need more gas!"
	"Mechanic_WorldC1M4B48"	"<clr:223,200,143>Ellis: Halfway there!"
	"Mechanic_WorldC1M4B49"	"<clr:223,200,143>Ellis: Almost there!"
	"Mechanic_WorldC1M4B50"	"<clr:223,200,143>Ellis: Hey, we need twenty more, twenty more!"
	"Mechanic_WorldC1M4B51"	"<clr:223,200,143>Ellis: We still need ten more!"
	"Mechanic_WorldC1M4B52"	"<clr:223,200,143>Ellis: We still need five more!"
	"Mechanic_WorldC1M4B53"	"<clr:223,200,143>Ellis: we need five more!"
	"Mechanic_WorldC1M4B54"	"<clr:223,200,143>Ellis: All right, just three more!"
	"Mechanic_WorldC1M4B55"	"<clr:223,200,143>Ellis: Just two more!"
	"Mechanic_WorldC1M4B56"	"<clr:223,200,143>Ellis: One more can do it!"
	"Mechanic_WorldC1M4B57"	"<clr:223,200,143>Ellis: We're all filled up, let's go!"
	"Mechanic_WorldC1M4B58"	"<clr:223,200,143>Ellis: Let's get outta here!"
	"Mechanic_WorldC1M4B59"	"<clr:223,200,143>Ellis: Let's go! I'm driving! WOOO!"
	"Mechanic_WorldC1M4B60"	"<clr:223,200,143>Ellis: Everybody get in the damn car!"
	"Mechanic_WorldC1M4B61"	"<clr:223,200,143>Ellis: Get in the car! We're ready!"
	"Mechanic_WorldC1M4B62"	"<clr:223,200,143>Ellis: Come on, let's GO!"
	"Mechanic_WorldC1M4B63"	"<clr:223,200,143>Ellis: Woooohoooo!"
	"Mechanic_WorldC1M4B64"	"<clr:223,200,143>Ellis: Next stop: New Orleans!"
	"Mechanic_WorldC1M4B65"	"<clr:223,200,143>Ellis: Buckle up, folks! I aim to see what this car can DO!"
	"Mechanic_WorldC1M4B66"	"<clr:223,200,143>Ellis: Jimmy Gibbs, Jr. I will do this for you."
	"Mechanic_WorldC1M4B67"	"<clr:223,200,143>Ellis: Here we go folks! Buckle up, I aim to see what this car can DO!"
	"Mechanic_WorldC2M1B07"	"<clr:223,200,143>Ellis: You are the most beautiful thing I have ever sat between."
	"Mechanic_WorldC2M5B30"	"<clr:223,200,143>Ellis: Set off the fireworks!"
	"Mechanic_WorldC2M5B31"	"<clr:223,200,143>Ellis: Launch the fireworks!"
	"Mechanic_WorldC3M140"	"<clr:223,200,143>Ellis: Oh yeah, I know plenty about swamps. They're full of bugs and gators and snakes and, well, zombies now!"
	"Mechanic_WorldC3M146"	"<clr:223,200,143>Ellis: This one time, I was on a tour boat and they fed chickens to the gators."
	"Mechanic_WorldC3M147"	"<clr:223,200,143>Ellis: Yeah. I mean not so much thinking about the gators as I'm wishing we had some BBQ chicken right now."
	"Mechanic_WorldC3M182"	"<clr:223,200,143>Ellis: I had no plans on feeding the gators."
	"Mechanic_WorldC3M183"	"<clr:223,200,143>Ellis: I had no plans on feeding the gators, thank you very much."
	"Mechanic_WorldC3M1B07"	"<clr:223,200,143>Ellis: Swimming with gators? Why, no thank you."
	"Mechanic_WorldC3M336"	"<clr:223,200,143>Ellis: All right, let's get out of here!"
	"Mechanic_WorldC5M4B20"	"<clr:223,200,143>Ellis: Well, hell yeah, we fought zombies."
	"Mechanic_Yes02"	"<clr:223,200,143>Ellis: Hell yeah."
	"Producer_ChargerRunningWithPlayer01"	"<clr:168,71,96>Rochelle: WHAT THE HELL?"
	"Producer_GettingRevived21"	"<clr:168,71,96>Rochelle: Broke."
	"Producer_GoingToDie20"	"<clr:168,71,96>Rochelle: Something's got to break our way."
	"Producer_GoingToDie304"	"<clr:168,71,96>Rochelle: I am too young and too beautiful to die."
	"Producer_GrabbedBySmokerC101"	"<clr:168,71,96>Rochelle: What the hell?!"
	"Producer_GrabbedBySmokerC104"	"<clr:168,71,96>Rochelle: Oh shit! What the hell is going on?!"
	"Producer_HeardSpecialC104"	"<clr:168,71,96>Rochelle: Oh what the hell is that!?"
	"Producer_MeleeResponse02"	"<clr:168,71,96>Rochelle: HELL yeah!"
	"Producer_MiscDirectional07"	"<clr:168,71,96>Rochelle: Through this window!"
	"Producer_MiscDirectional08"	"<clr:168,71,96>Rochelle: Through that window!"
	"Producer_NiceJob12"	"<clr:168,71,96>Rochelle: Oh, Hell yeah."
	"Producer_ReactionNegative01"	"<clr:168,71,96>Rochelle: Nooooo oo ooo ohhhhh."
	"Producer_ReactionNegative02"	"<clr:168,71,96>Rochelle: Damnn..."
	"Producer_ReactionNegative03"	"<clr:168,71,96>Rochelle: Oh this is bad..."
	"Producer_ReactionNegative04"	"<clr:168,71,96>Rochelle: Oh shit!"
	"Producer_ReactionNegative05"	"<clr:168,71,96>Rochelle: Sweet Jesus!"
	"Producer_ReactionNegative06"	"<clr:168,71,96>Rochelle: Sweet Lincoln's mullet!"
	"Producer_ReactionNegative08"	"<clr:168,71,96>Rochelle: Mother of Mercy."
	"Producer_ReactionNegative09"	"<clr:168,71,96>Rochelle: Well, this just sucks."
	"Producer_ReactionNegative10"	"<clr:168,71,96>Rochelle: Blarg!"
	"Producer_ReactionNegative11"	"<clr:168,71,96>Rochelle: Can just one goddamn thing go right?"
	"Producer_ReactionNegative12"	"<clr:168,71,96>Rochelle: We are in some deep shit!"
	"Producer_ReactionNegative13"	"<clr:168,71,96>Rochelle: Holy shit!"
	"Producer_ReactionNegative14"	"<clr:168,71,96>Rochelle: We are in some deep shit!"
	"Producer_ReactionNegative15"	"<clr:168,71,96>Rochelle: Could this really get any worse?  I don't think so."
	"Producer_ReactionNegative16"	"<clr:168,71,96>Rochelle: We do not have time for this shit."
	"Producer_ReactionNegative17"	"<clr:168,71,96>Rochelle: We don't have time for this shit."
	"Producer_ReactionNegative18"	"<clr:168,71,96>Rochelle: Goddamnit!"
	"Producer_ReactionNegative19"	"<clr:168,71,96>Rochelle: Can just one more goddamn thing go wrong?"
	"Producer_ReactionNegative20"	"<clr:168,71,96>Rochelle: Argghh!"
	"Producer_ReactionNegative21"	"<clr:168,71,96>Rochelle: Jesus Christ!"
	"Producer_WorldC1M1B43"	"<clr:168,71,96>Rochelle: What the hell is this thing?"
	"Producer_WorldC1M3B14"	"<clr:168,71,96>Rochelle: Anybody know who the race car guy is?"
	"Producer_WorldC1M3B15"	"<clr:168,71,96>Rochelle: Jimmy… Gibbs… Jr. Man, Southerners make the weirdest people famous."
	"Producer_WorldC1M3B16"	"<clr:168,71,96>Rochelle: Jimmy Gibbs Jr…. Yay."
	"Producer_WorldC1M3B17"	"<clr:168,71,96>Rochelle: Take that, Jimmy Gibbs!"
	"Producer_WorldC1M3B18"	"<clr:168,71,96>Rochelle: Eat lead, Jimmy Gibbs."
	"Producer_WorldC1M4B01"	"<clr:168,71,96>Rochelle: Okay. Anybody got any ideas?"
	"Producer_WorldC1M4B02"	"<clr:168,71,96>Rochelle: All right, so… we're screwed. Anybody got any ideas?"
	"Producer_WorldC1M4B03"	"<clr:168,71,96>Rochelle: What's on your mind, Ellis?"
	"Producer_WorldC1M4B04"	"<clr:168,71,96>Rochelle: Are we talking about this Jimmy Gibbs guy? His car's here?"
	"Producer_WorldC1M4B05"	"<clr:168,71,96>Rochelle: Are we talking about Jimmy Gibbs, Jr.?"
	"Producer_WorldC1M4B06"	"<clr:168,71,96>Rochelle: Well, it's a plan. I don't know if it's a GOOD plan. But it IS a plan."
	"Producer_WorldC1M4B07"	"<clr:168,71,96>Rochelle: Okay. Out of all the plans we have, which is zero, that might be in the top ten."
	"Producer_WorldC1M4B08"	"<clr:168,71,96>Rochelle: Any other ideas?"
	"Producer_WorldC1M4B09"	"<clr:168,71,96>Rochelle: OK, so Plan A is we go find this car. Plan B is we… wait here in this mall and die."
	"Producer_WorldC1M4B10"	"<clr:168,71,96>Rochelle: I had that idea first."
	"Producer_WorldC1M4B11"	"<clr:168,71,96>Rochelle: Hell, I'll do it."
	"Producer_WorldC1M4B12"	"<clr:168,71,96>Rochelle: Dibs on Gibbs!"
	"Producer_WorldC1M4B13"	"<clr:168,71,96>Rochelle: Find some gas, guys!"
	"Producer_WorldC1M4B14"	"<clr:168,71,96>Rochelle: As soon as these doors open, get ready to run."
	"Producer_WorldC1M4B15"	"<clr:168,71,96>Rochelle: Comeoncomeoncomeon come on…"
	"Producer_WorldC1M4B16"	"<clr:168,71,96>Rochelle: Please get in the tank, please please please…"
	"Producer_WorldC1M4B17"	"<clr:168,71,96>Rochelle: Hurry up, hurrrry upppp…"
	"Producer_WorldC1M4B18"	"<clr:168,71,96>Rochelle: Go faster…go in the tank faster…"
	"Producer_WorldC1M4B19"	"<clr:168,71,96>Rochelle: Come onnnn, come onnnnnn…"
	"Producer_WorldC1M4B20"	"<clr:168,71,96>Rochelle: Filling it up here!"
	"Producer_WorldC1M4B21"	"<clr:168,71,96>Rochelle: Filling it up here!"
	"Producer_WorldC1M4B22"	"<clr:168,71,96>Rochelle: I got this one!"
	"Producer_WorldC1M4B23"	"<clr:168,71,96>Rochelle: Come on, let's go! Find a gas can!"
	"Producer_WorldC1M4B24"	"<clr:168,71,96>Rochelle: Let's get this car gassed up!"
	"Producer_WorldC1M4B25"	"<clr:168,71,96>Rochelle: We need more gas!"
	"Producer_WorldC1M4B26"	"<clr:168,71,96>Rochelle: We still need more gas!"
	"Producer_WorldC1M4B27"	"<clr:168,71,96>Rochelle: Halfway there!"
	"Producer_WorldC1M4B28"	"<clr:168,71,96>Rochelle: Almost there!"
	"Producer_WorldC1M4B29"	"<clr:168,71,96>Rochelle: We need twenty more!"
	"Producer_WorldC1M4B30"	"<clr:168,71,96>Rochelle: We still need ten more!"
	"Producer_WorldC1M4B31"	"<clr:168,71,96>Rochelle: We still need five more!"
	"Producer_WorldC1M4B32"	"<clr:168,71,96>Rochelle: Just three more!"
	"Producer_WorldC1M4B33"	"<clr:168,71,96>Rochelle: Just two more!"
	"Producer_WorldC1M4B34"	"<clr:168,71,96>Rochelle: One more can to go!"
	"Producer_WorldC1M4B35"	"<clr:168,71,96>Rochelle: We're all filled up, let's go!"
	"Producer_WorldC1M4B36"	"<clr:168,71,96>Rochelle: Car's full let's go!"
	"Producer_WorldC1M4B37"	"<clr:168,71,96>Rochelle: Hit it, Ellis!"
	"Producer_WorldC1M4B38"	"<clr:168,71,96>Rochelle: Woooo!"
	"Producer_WorldC1M4B39"	"<clr:168,71,96>Rochelle: Punch it! Punch it!"
	"Producer_WorldC2M118"	"<clr:168,71,96>Rochelle: Hey, use the window."
	"Producer_WorldC2M1B01"	"<clr:168,71,96>Rochelle: Stock cars can't drive over traffic, right?"
	"Producer_WorldC2M1B04"	"<clr:168,71,96>Rochelle: You do realize: If this Jimmy Gribs guy had driven a monster truck? We'd be home free right now."
	"Producer_WorldC2M203"	"<clr:168,71,96>Rochelle: Ellis, I bet you won all the girls teddy bears."
	"Producer_WorldC2M5B18"	"<clr:168,71,96>Rochelle: Set off the fireworks!"
	"Producer_WorldC2M5B19"	"<clr:168,71,96>Rochelle: Launch the fireworks!"
	"Producer_WorldC3M108"	"<clr:168,71,96>Rochelle: Earl's Gator Village?  This just keeps getting better."
	"Producer_WorldC3M109"	"<clr:168,71,96>Rochelle: Yeah, let's just cut through the gator park and visit the crazy militants in the swamp.  Sound good?"
	"Producer_WorldC3M131"	"<clr:168,71,96>Rochelle: So what do you think is going to kill us?  Zombies, gators, snakes, bugs or the swamp people?"
	"Producer_WorldC3M1B03"	"<clr:168,71,96>Rochelle: Based on the location of Whispering Oaks, our previous air speed and accounting for the wind speed, I would place us right at Earl's Gator Village."
	"Producer_WorldC3M1B06"	"<clr:168,71,96>Rochelle: They actually have to put a sign up to stop people from swimming in the gator park? All right..."
	"Producer_WorldC3M1B07"	"<clr:168,71,96>Rochelle: No swimming in the gator park. Fair enough."
	"Producer_WorldC3M210"	"<clr:168,71,96>Rochelle: Okay, this is creepy."
	"Producer_WorldGenericProducer14"	"<clr:168,71,96>Rochelle: Elevator's out!"
	"Producer_WorldGenericProducer39"	"<clr:168,71,96>Rochelle: LOOK at this big, beautiful gun."
	"Producer_WorldGenericProducer89"	"<clr:168,71,96>Rochelle: Down this elevator shaft!"
	"Soldier1_CHATTER01"	"<clr:148,148,148>Soldier 1: Rescue Seven, this is Papa Gator. Over."
	"Soldier1_MISC11"	"<clr:148,148,148>Soldier 1: Papa Gator, affirmative. Visual inspection in Five."
	"Soldier1_MISC12"	"<clr:148,148,148>Soldier 1: Papa Gator, roger out."
	"Soldier2_CHATTER05"	"<clr:148,130,130>Soldier 2: Roger, Papa Gator. Fifteen minutes. Ah, be advised we have seen flashes on the west bank. Ah, visually confirm west bank is clear. Over."
	"Soldier2_CHATTER09"	"<clr:148,130,130>Soldier 2: Papa Gator, we're not sure. We are seeing, ah, multiple personnel and small arms fire. What is our current ROE? Over."
	"Soldier2_CHATTER10"	"<clr:148,130,130>Soldier 2: Roger, Papa Gator. All personnel on floating LZ. Clear for last Buzzard run. Over."
	"Soldier2_NAGS01"	"<clr:148,130,130>Soldier 2: Copy that, Papa Gator. Over."
	"Soldier2_NAGS02"	"<clr:148,130,130>Soldier 2: Ah, negative, Papa Gator. You are not good to go. We will advise when ready. Over."
	"Soldier2_NAGS03"	"<clr:148,130,130>Soldier 2: Copy that, Papa Gator. Over."
	"Soldier2_SURVIVORTALK02"	"<clr:148,130,130>Soldier 2: Affirmative, Papa Gator."

PARTICLE / AMBIENT_GENERIC MAKE_ FUNCTION TEMPLATES

local tblKeyvalues =
{
	targetname	= g_updateName + "_tank_yellexplode",
	origin		= vecTeleportUpper,
	spawnflags	= 48,
	health		= 10,
	pitch		= 100,
	pitchstart	= 100
};

local randNum = ( rand() % 4.5 ).tointeger();

if ( randNum == 0 )	{	tblKeyvalues.message <- "HulkZombie.Yell";		}
if ( randNum == 1 )	{	tblKeyvalues.message <- "HulkZombie.Throw";		}
if ( randNum == 2 )	{	tblKeyvalues.message <- "HulkZombie.Attack";		}
if ( randNum == 3 )	{	tblKeyvalues.message <- "HulkZombie.Throw.Fail";	}
if ( randNum == 4 )	{	tblKeyvalues.message <- "HulkZombie.StartLedgeClimb";	}

printl( tblKeyvalues.message );

SpawnEntityFromTable( "ambient_generic", tblKeyvalues );

tblKeyvalues.message = "explode_1";

printl( tblKeyvalues.message );

SpawnEntityFromTable( "ambient_generic", tblKeyvalues );

SpawnEntityFromTable( "env_shake",
{
	targetname	= g_updateName + "_tank_shake",
	origin		= vecTeleportUpper,
	radius		= 1500,
	frequency	= 1.7,
	duration	= 2.1,
	amplitude	= 10
} );

SpawnEntityFromTable( "info_particle_system",
{
	targetname	= g_updateName + "_tank_burst",
	origin		= vecTeleportUpper + Vector( 0, 24, 10 ),
	start_active	= 1,
	effect_name	= "aircraft_destroy_smokepufflong"
} );

EntFire( g_updateName + "_tank_yellexplode",	"PlaySound"  );
EntFire( g_updateName + "_tank_shake",		"StartShake" );
EntFire( g_updateName + "_tank_burst",		"Stop",   "",	0.5 );
EntFire( g_updateName + "_tank_*",		"Kill",   "",	2.0 );

SpawnEntityFromTable( "filter_activator_model",
{
	targetname	= g_updateName + "_rockslide_trigpush_filter_rock01",
	Negated		= "Allow entities that match criteria",
	model		= "models/props/cs_militia/militiarock01.mdl"
} );

function c10m5_rockslide_fx_sound()
{
	SpawnEntityFromTable( "ambient_generic",
	{
		targetname	= g_updateName + "_rockslide_fx_sound",
		origin		= Vector( 5093, 202, 123 ),
		spawnflags	= 48,
		health		= 10,
		pitch		= 50,
		pitchstart	= 50,
		radius		= 22000,
		message		= "physics/destruction/smash_rockcollapse1.wav"
	} );

	EntFire( g_updateName + "_rockslide_fx_sound",	"PlaySound"  );
}

function c10m5_rockslide_fx_shake()
{
	SpawnEntityFromTable( "env_shake",
	{
		targetname	= g_updateName + "_rockslide_fx_shake",
		origin		= Vector( 5093, 202, 123 ),
		radius		= 2200,
		frequency	= 2,
		duration	= 12,
		amplitude	= 7
	} );

	EntFire( g_updateName + "_rockslide_fx_shake",	"StartShake" );
}

function c10m5_rockslide_fx_prtcl()
{
	SpawnEntityFromTable( "info_particle_system",
	{
		targetname	= g_updateName + "_rockslide_fx_prtcla",
		origin		= Vector( 5093, 202, 103 ),
		start_active	= 0,
		effect_name	= "burning_General"
	} );

	EntFire( g_updateName + "_rockslide_fx_prtcla",	"Start",  "",	0 );
	EntFire( g_updateName + "_rockslide_fx_prtcla",	"Stop",   "",	2 );

	SpawnEntityFromTable( "info_particle_system",
	{
		targetname	= g_updateName + "_rockslide_fx_prtclb",
		origin		= Vector( 4528, -32, -196 ),
		start_active	= 0,
		effect_name	= "burning_General"
	} );

	EntFire( g_updateName + "_rockslide_fx_prtclb",	"Start",  "",	8.3 );
	EntFire( g_updateName + "_rockslide_fx_prtclb",	"Stop",   "",	10 );
}

SpawnEntityFromTable( "trigger_multiple",
{
	targetname	= g_updateName + "_rockslide_entireteam_trigmult",
	StartDisabled	= 0,
	spawnflags	= 1,
	allowincap	= 0,
	entireteam	= 2,
	filtername	= "anv_globalfixes_filter_survivor",
	origin		= Vector( 5232, -1427, -44 )
} );

EntFire( g_updateName + "_rockslide_entireteam_trigmult", "AddOutput", "mins -3872 -3828 -365" );
EntFire( g_updateName + "_rockslide_entireteam_trigmult", "AddOutput", "maxs 1170 0 1337" );
EntFire( g_updateName + "_rockslide_entireteam_trigmult", "AddOutput", "solid 2" );

EntFire( g_updateName + "_rockslide_entireteam_trigmult", "AddOutput", "OnEntireTeamStartTouch anv_mapfixes_rockslide_entireteam_timer:Enable::0:-1" );
EntFire( g_updateName + "_rockslide_entireteam_trigmult", "AddOutput", "OnEntireTeamEndTouch anv_mapfixes_rockslide_entireteam_timer:Disable::0:-1" );
EntFire( g_updateName + "_rockslide_entireteam_trigmult", "AddOutput", "OnEntireTeamEndTouch anv_mapfixes_rockslide_entireteam_timer:ResetTimer::0:-1" );

PrecacheEntityFromTable( { classname = "env_shake" } );
PrecacheEntityFromTable( { classname = "info_particle_system", effect_name = "burning_General" } );

Entities.First().PrecacheModel( "models/props_foliage/trees_cluster01.mdl" );
Entities.First().PrecacheModel( "models/props/cs_militia/militiarock01.mdl" );
Entities.First().PrecacheModel( "models/props/cs_militia/militiarock02.mdl" );
Entities.First().PrecacheScriptSound( "physics/destruction/smash_rockcollapse1.wav" );



BEST OPTION TO STOP VALVE'S ELEVATOR CONVERSATION == INTERRUPT IT WITH ANOTHER ONE

Previously I had this code:

	// Nullify the !activator "c1m4startelevator" SpeakResponseConcept in order to avoid
	// the now-obsolete elevator chatter.

	//EntFire( "button_elev_3rdfloor", "AddOutput", "OnPressed player:CancelCurrentScene::2:-1" );
	EntFire( "button_elev_3rdfloor", "AddOutput", "OnPressed !activator:SpeakResponseConcept:c1m1_elevator_smoke:0.1:-1" );

	^^^
	I don't want to re-create the entire button and all its Outputs, and lack Stripper:Source to
	just extract the 1 undesirable Output... SO_CANCELLING_IT_OUT_AFTER_ITS_ALREADY_PLAYED_IS_ONLY_OPTION.

But following up one SpeakResponseConcept with another doesn't stop the first, and while CancelCurrentScene
will immediately cease the speaking character's line, their subtitles still persist on-screen AND the characters
to respond to that scene still play out... so, the best / ONLY option is to play another *.VCD file to overwrite
Valve's from running entirely.

This offers SOME_UNIQUE_OPPORTUNITY, to have Valve's line play... then abruptly cancel it with character's shock
that the objective (they've grown accustomed to for 10-11+ years) has already been completed !!

In short, playing another *.VCD file via logic_choreographed_scene at the right time to solve this problem automatically.

DONE_FOR_NOW



PIPE BOMB -- IMPOSSIBLE TO MAKE IT "LIVE" -- TESTS -- START

Faking it process:

	1. Spawn a pipe_bomb_projectile w/ fuse, blinking light, explosive particle,
	   beep and explosion sounds and func_rotator parented to it

	2. Give it a velocity toward the elevator to start bouncing in that direction

	3. At different timings, change its gravity to fake different heights in each of its bounces

	4. When it reaches near its end, gravity should be strong enough so it "lands",
	   cease fuse/light/blink/beep, and explode particle/sound

	5. Break the elevator glass as usual

TL;DR: It has been a whole 10 years later and I'm still doing the same exact shit... in 10 more of these
       my Mom and Dad may surely be dead, or I'll even be dead myself or dying from obesity / heart-related
       issues if I keep flip-flopping with my weight control. To even AtomicStryker a decade ago, "m_bIsLive"
       is purely useless and deceptive, and Thinks were required in L4D1 to get it to bounce which it does
       automatically in L4D2. Only workaround is to construct a pipebomb from scratch faking the entire thing.
       As to HOW to fake it, there's many ways... my need is 100% cosmetic and not functional / player-thrown.

] DJ_WEST FAKED THE WHOLE THING
] https://github.com/AtomicStryker/atomicstrykers-codedump/blob/master/customized/l4d_incapped_grenade.sp
] 10 YEARS AND NO ONE HAS SOLVED THIS WITHOUT JUST FAKING THE ROTATION AND VELOCITY AND BEEPING ETC
] L4D1 NEEDED TO ADD A THINK TO IT JUST TO GET IT TO BOUNCE, WHICH L4D2 STARTS OUT IN THAT STATE AUTOMATICALLY
] Need help Activating an Entity https://forums.alliedmods.net/showthread.php?t=102993
] 4 pages 1 year research back in 2009 AtomicStryker... 10 years later still doing same shit
] [L4D/L4D2] Incapped Grenade (Pipe/Molotov/Vomitjar) https://forums.alliedmods.net/showthread.php?t=122224
] DJ_WEST solved it there but w/ faking it
] **** THERE'S NO FLAGS / SPAWNFLAGS THAT TURNED OUT USEFUL ****

] script SpawnEntityFromTable( "pipe_bomb_projectile", { targetname = g_UpdateName + "_jimmy_pipebomb", origin = Vector( -4528, -3261, 22 ) } );
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_bIsLive" ) )
0
] script printl( NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_bIsLive", 1 ) )
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_bIsLive" ) )
1
] script printl( NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_bIsLive", true ) )
AN ERROR HAS OCCURED [parameter 3 has an invalid type 'bool' ; expected: 'integer|float']
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flDetonateTime" ) )
-1
] script printl( NetProps.GetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flDetonateTime" ) )
0
] script printl( NetProps.SetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flDetonateTime", 3 ) )
] script printl( NetProps.GetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flDetonateTime" ) )
3
] script printl( NetProps.GetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flGravity" ) )
0
] script printl( NetProps.SetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flGravity", 5 ) )
] script printl( NetProps.SetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flGravity", 0.1 ) )
] script printl( NetProps.GetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flGravity" ) )
0.1
] gravity is only thing that works so far
] but it always bounces at the same height each time regarldess
] script printl( NetProps.SetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flGravity", 0.5 ) )
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_blinktoggle" ) )
0
] script printl( NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_blinktoggle", 1 ) )
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_blinktoggle" ) )
1-6 all do nothing
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_fFlags" ) )
0
] script printl( NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_fFlags", 2 ) )
] script printl( NetProps.GetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_fFlags" ) )
2/4/8/16/32/64/128/256/512 all did nothing + 2048/4096 also did nothing
] script printl( NetProps.SetPropInt( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_fFlags", 1024 ) )
] at 1024 it suddenly floats in the air and only reverse direction if it hits something
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
-1
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
0
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
1
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
-1
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
0
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
0
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
1
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
0
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags" ) )
1
] it becomes 1 when it has fully landed thats all
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_bIsLive" ) )
-1
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_bIsLive" ) )
0
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_bIsLive" ) )
-1
] m_bIsLive is NEVER 1 it's always 0 with a live pipe bomb
] script printl( NetProps.SetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_fFlags", 1024 ) )
] 1024 would be an interesting "ping pong pipebomb" metagame tho
] ent_setname pipe; ent_dump pipe
Set the name of pipe_bomb_projectile to pipe
  physdamagescale: 1.00
  classname: pipe_bomb_projectile
  gravity: 0.40
  friction: 0.20
  glowbackfacemult: 1.00
  fadescale: 1.00
] it would seem Valve gave pipebombs 0.4 grav and 0.2 friction unlike other stuff
] script printl( NetProps.SetPropFloat( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_flDetonateTime", 100 ) )
] cannot elongate pipebomb timer maybe b/c its already spawned in
] script SpawnEntityFromTable( "pipe_bomb_projectile", { targetname = g_UpdateName + "_jimmy_pipebomb", origin = Vector( -4528, -3261, 22 ) } );
] ent_fire !picker enable
] ent_info pipe_bomb_projectile
Compressing fragments for Tsuey(loopback) (1425 -> 997 bytes)
  output: OnIgnite
  output: OnUser1
  output: OnUser2
  output: OnUser3
  output: OnUser4
  input: physdamagescale
  input: KilledNPC
  input: skin
  input: SetBodyGroup
  input: Ignite
  input: IgniteLifetime
  input: IgniteNumHitboxFires
  input: IgniteHitboxFireScale
  input: BecomeRagdoll
  input: SetLightingOrigin
  input: TeamNum
  input: SetTeam
  input: fademindist
  input: fademaxdist
  input: Kill
  input: KillHierarchy
  input: Use
  input: Alpha
  input: AlternativeSorting
  input: Color
  input: SetParent
  input: SetParentAttachment
  input: SetParentAttachmentMaintainOffset
  input: ClearParent
  input: SetDamageFilter
  input: EnableDamageForces
  input: DisableDamageForces
  input: DispatchResponse
  input: AddContext
  input: RemoveContext
  input: ClearContext
  input: DisableShadow
  input: EnableShadow
  input: AddOutput
  input: FireUser1
  input: FireUser2
  input: FireUser3
  input: FireUser4
  input: RunScriptFile
  input: RunScriptCode
  input: CallScriptFunction
] cl_pdump 1
] find_ent pipe_bomb_proj
Searching for entities with class/target name containing substring: 'pipe_bomb_proj'
   'pipe_bomb_projectile' : 'anv_mapfixes_jimmy_pipebomb' (entindex 225) 
Found 1 matches.
] cl_pdump 225
] m_iEFlags with cl_pdump is 317472 when in air, when on ground too brief
] host_timescale 0.001
] find_ent pipe_bomb_projectile
Searching for entities with class/target name containing substring: 'pipe_bomb_projectile'
   'pipe_bomb_projectile' : '' (entindex 258) 
] 0.01 timescale m_bIsLive is always false even on live pipebom, m_fFlags is 1 when landed, 282624 was a m_iEFlags seen
] 315424 == m_iEFlags every single time it beeps, on the beep
] script SpawnEntityFromTable( "pipe_bomb_projectile", { targetname = g_UpdateName + "_jimmy_pipebomb", origin = Vector( -4528, -3261, 22 ) } );
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_iEFlags" ) )
38010880
] script printl( NetProps.SetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_iEFlags", 315424 ) )
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_iEFlags" ) )
311328
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_iEFlags" ) )
33816576
] ^ thats the value same value over several seconds of a live thrown pipebomb, cl_pdump shows a different number sadly
] the 38010880 value is from a self-spawned stationary pipe
] what happens when i set it to same as a real thrown pipe?
] script SpawnEntityFromTable( "pipe_bomb_projectile", { targetname = g_UpdateName + "_jimmy_pipebomb", origin = Vector( -4528, -3261, 22 ) } );
] script printl( NetProps.SetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_iEFlags", 33816576 ) )
] script printl( NetProps.GetPropInt( Entities.FindByClassname( null, "pipe_bomb_projectile" ), "m_iEFlags" ) )
33816576

PIPE BOMB -- IMPOSSIBLE TO MAKE IT "LIVE" -- TESTS -- END



PARTI-COOLS SAMPLING BEGIN!

Using this as each System location "-4427 -3460 65" and Target1 "-4427 -3460 512" and Target2 "-4327 -3460 216",
applying each only when just a sole System or the 1st Target isn't enough, all of these were demonstrated to work
and be absolutely minimalistic to work:

	https://developer.valvesoftware.com/wiki/Talk:List_of_L4D2_Particles
	^^^
	There is no standalone "flare" or "trail" particle in the entire list that works
	(tested with just 1 System and 1 System with 1 Target), meaning "fireworks_explosion_01"
	is just the flare-less explosion while "fireworks_01" is the flare with explosion --
	the caveat is that using "fireworks_01" means that, regardless of the System/Target
	difference (and the oddity that a Target IS REQUIRED even though it really serves
	no observable purpose), the "fireworks_01" flare always shoots up to the same height
	and shoots far beyond a lower Target... the Target is where the explosion occurs, but
	not where the flare ends. Firing "Stop" to an active "fireworks_01" will only prevent
	the explosion but the flare will travel to its usual hard-coded height.

	This means that "fireworks_01"-4 are my best/only options, AND they need to be embedded
	into the ground to "fake" the flare traveling less height.

These don't have flares:

	script make_particle( "_fireexplo1", "-4427 -3460 65", "0 0 0", "fireworks_explosion_01", "-4427 -3460 512" );
	script make_particle( "_fireexplo2", "-4427 -3460 65", "0 0 0", "fireworks_explosion_02", "-4427 -3460 512" );
	script make_particle( "_fireexplo3", "-4427 -3460 65", "0 0 0", "fireworks_explosion_03", "-4427 -3460 512" );
	script make_particle( "_fireexplo4", "-4427 -3460 65", "0 0 0", "fireworks_explosion_04", "-4427 -3460 512" );

These do have flares and are embedded into the ground, with Targets changed so explosion occurs at end of flare,
and interestingly these don't even require a Target since the explosion will occur at the end of the flare line:

	script make_particle( "_fire1", "-4427 -3460 -700", "0 0 0", "fireworks_01" );
	script make_particle( "_fire2", "-4427 -3460 -700", "0 0 0", "fireworks_02" );
	script make_particle( "_fire3", "-4427 -3460 -700", "0 0 0", "fireworks_03" );
	script make_particle( "_fire4", "-4427 -3460 -700", "0 0 0", "fireworks_04" );

Flare doesn't work with or without Target 1, I even tried a Target 2 to be thorough... and the "mini_fireworks"
works identically with just the System or Target 1, so is best left just as the sole System:

	script make_particle( "_miniflare", "-4427 -3460 65", "0 0 0", "mini_firework_flare", "-4427 -3460 512", "-4427 -3460 1024" );
	script make_particle( "_mini", "-4427 -3460 65", "0 0 0", "mini_fireworks" );

This works by itself as a System or with a Target, it simply "clones" itself and plays a 2nd time for the Target:

	script make_particle( "_burning", "-4427 -3460 65", "0 0 0", "burning_General", "-4427 -3460 512" );

Exhibits no difference if a Target is used, so only use a System for it:

	script make_particle( "_puff", "-4427 -3460 65", "0 0 0", "bridge_smokepuff" );

Needs more testing -- it doesn't look like Particle Browser at all, as just a System or with 1/2 Targets, it's just
the smallest most useless spec of glass explosion:

	script make_particle( "_glass", "-4427 -3460 65", "0 0 0", "window_glass", "-4427 -3460 512", "-4327 -3460 216" );
	script make_particle( "_glass", "-4427 -3460 65", "0 0 0", "window_glass", "-4327 -3460 216" );

These are its sub-particles, "impact_glass" has its own subs but is worthless to me even in Particle Browser:

		window_glass
		window_glass_child_base
		window_glass_child_bits
		window_glass_child_smoke

These work 100%, just use these, IDK how to use Targets on this one, but using the subs works just fine, ignore
the "_base" sub-particle since I think that's where the glass actually is that breaks and mine isn't above players:

	script make_particle( "_glass", "-4084 -3404 155", "0 0 0", "window_glass_child_bits" );
	script make_particle( "_glass", "-4084 -3404 80", "0 0 0", "window_glass_child_smoke" );

This will create 1 sparkshower at System, then "clones" at Target 1 and Target 2 -- it's actually this case where
it was proven necessary for the Targets to also "inherit" the same Angles, which is 100% harmless for other particle
types that don't use Angles... but here, it saves from having to use 3 separate Systems:

		EDIT:
		^^^^
		Actually just use 3 separate make_particle() calls in this case -- I'm not going to add Angle
		parameters, requiring 2 extra parameters, just for this 1 particle, because the model that these
		sparks come out of is "flared outwards", so each of the Targets would actually need unique and
		separate Angles... so, K.I.S.S... even if it's not what Valve would do.

Thus, so while this is possible (if System Angles inherited to the Targets, which they don't any longer):

	script make_particle( "_sparks", "-4427 -3460 65", "-90 0 0", "fireworks_sparkshower_01", "-4427 -3460 512", "-4327 -3460 216" );

Do this instead for more control -- without having make_particle() cater to a roughly-once-off:

	script make_particle( "_sparksa", "-4427 -3460 65", "-90 0 0", "fireworks_sparkshower_01" );
	script make_particle( "_sparksb", "-4427 -3460 512", "-90 0 0", "fireworks_sparkshower_01" );
	script make_particle( "_sparksc", "-4327 -3460 216", "-90 0 0", "fireworks_sparkshower_01" );

String lights CANNOT_BE_DELETED once drawn, so for the **trolley** use move_rope/keyframe_rope instead...
also, BOTH_VARIANTS_PERSIST_ROUND_TRANSITION... they cannot be deleted AT_ALL, so I wonder if/how Valve
only spawns them in once for Dark Carnival... or maybe it's just the multi-colored lights with the issue?

		... they DO work, just they MUST be used in a way that they're PERMANENT for BOTH teams from the START

		... top has STRING, bottom is just floating glows, both persist round transition

		... STRINGING TOGETHER "env_sprite" TO MIMIC THESE **IS OUTSIDE THE SCOPE/EFFORT OF THIS ONCE-OFF USAGE** !!

	script make_particle( "_christmas", "-4427 -3460 65", "0 0 0", "string_lights_03", "-4427 -3460 512" );
	script make_particle( "_christmas", "-4427 -3460 65", "0 0 0", "string_lights_03_glow", "-4427 -3460 512" );

Balloons are an odd case but WORK_AS_DESIRED... deleting the System the balloon will still persist, but while
the System exists it can be SetParented to move even with the player! And they're washed away on round transition!
However, no Targets are computed at all here... Targets CANNOT be used to influence the "height" of the "string".

	script make_particle( "_balloon", "-4427 -3460 65", "0 0 0", "balloon" );

Pipebomb... top is the explosion, "_light" is burst+trail, "_b" is burst, "_c" is trail, "_fuse" is the fire
on top -- note that Targets in all these cases don't add or detract anything, thus just use Systems forever:

	script make_particle( "_pipe", "-4427 -3460 65", "0 0 0", "weapon_pipebomb" );
	script make_particle( "_pipeblink", "-4427 -3460 65", "0 0 0", "weapon_pipebomb_blinking_light" );
	script make_particle( "_pipeblinkb", "-4427 -3460 65", "0 0 0", "weapon_pipebomb_blinking_light_b" );
	script make_particle( "_pipeblinkc", "-4427 -3460 65", "0 0 0", "weapon_pipebomb_blinking_light_c" );
	script make_particle( "_pipefuse", "-4427 -3460 65", "0 0 0", "weapon_pipebomb_fuse" );

Wood breakage particles SUCK, tried all these, all particles with "wood" in the name:

	script make_particle( "burning_wood_01", "-4427 -3460 65", "0 0 0", "burning_wood_01" );
	script make_particle( "burning_wood_01_core", "-4427 -3460 65", "0 0 0", "burning_wood_01_core" );
	script make_particle( "burning_wood_01_core2", "-4427 -3460 65", "0 0 0", "burning_wood_01_core2" );
	script make_particle( "burning_wood_01_core_glow", "-4427 -3460 65", "0 0 0", "burning_wood_01_core_glow" );
	script make_particle( "burning_wood_01_embers", "-4427 -3460 65", "0 0 0", "burning_wood_01_embers" );
	script make_particle( "burning_wood_01_smoke", "-4427 -3460 65", "0 0 0", "burning_wood_01_smoke" );
	script make_particle( "burning_wood_01b", "-4427 -3460 65", "0 0 0", "burning_wood_01b" );
	script make_particle( "burning_wood_01c", "-4427 -3460 65", "0 0 0", "burning_wood_01c" );
	script make_particle( "burning_wood_02", "-4427 -3460 65", "0 0 0", "burning_wood_02" );
	script make_particle( "burning_wood_02c", "-4427 -3460 65", "0 0 0", "burning_wood_02c" );
	script make_particle( "embers_wood_01", "-4427 -3460 65", "0 0 0", "embers_wood_01" );
	script make_particle( "embers_wood_01_smoke", "-4427 -3460 65", "0 0 0", "embers_wood_01_smoke" );
	script make_particle( "embers_wood_02", "-4427 -3460 65", "0 0 0", "embers_wood_02" );
	script make_particle( "embers_wood_02_lingeringsmoke", "-4427 -3460 65", "0 0 0", "embers_wood_02_lingeringsmoke" );
	script make_particle( "embers_wood_02_smoke", "-4427 -3460 65", "0 0 0", "embers_wood_02_smoke" );
	script make_particle( "burning_wood_01", "-4427 -3460 65", "0 0 0", "burning_wood_01" );
	script make_particle( "burning_wood_01b", "-4427 -3460 65", "0 0 0", "burning_wood_01b" );
	script make_particle( "burning_wood_01c", "-4427 -3460 65", "0 0 0", "burning_wood_01c" );
	script make_particle( "burning_wood_02", "-4427 -3460 65", "0 0 0", "burning_wood_02" );
	script make_particle( "burning_wood_02_removed", "-4427 -3460 65", "0 0 0", "burning_wood_02_removed" );
	script make_particle( "burning_wood_02c", "-4427 -3460 65", "0 0 0", "burning_wood_02c" );
	script make_particle( "impact_wood", "-4427 -3460 65", "0 0 0", "impact_wood" );
	script make_particle( "impact_wood_cheap", "-4427 -3460 65", "0 0 0", "impact_wood_cheap" );
	script make_particle( "impact_wood_child_base", "-4427 -3460 65", "0 0 0", "impact_wood_child_base" );
	script make_particle( "impact_wood_child_burn", "-4427 -3460 65", "0 0 0", "impact_wood_child_burn" );
	script make_particle( "impact_wood_child_burst", "-4427 -3460 65", "0 0 0", "impact_wood_child_burst" );
	script make_particle( "impact_wood_child_chunks", "-4427 -3460 65", "0 0 0", "impact_wood_child_chunks" );
	script make_particle( "impact_wood_child_smoke", "-4427 -3460 65", "0 0 0", "impact_wood_child_smoke" );
	script make_particle( "infected_door_hit_wood", "-4427 -3460 65", "0 0 0", "infected_door_hit_wood" );
	script make_particle( "infected_door_slash_wood", "-4427 -3460 65", "0 0 0", "infected_door_slash_wood" );

These are the only 2 reasonable ones, but the debris still very tiny so would need SEVERAL:

	script make_particle( "infected_door_hit_wood", "-4427 -3460 65", "0 0 0", "infected_door_hit_wood" );
	script make_particle( "infected_door_slash_wood", "-4427 -3460 65", "0 0 0", "infected_door_slash_wood" );

Best solution == just spawn a crate and insta-break it, it'll look better than the above garbage.

Should function have entity cleanup?

	NO.

	While "fireworks_sparkshower_01" would suffice a System delete after 8-9 seconds, and particles
	like "string_lights_03" indeed persist even round transition, there'd still be the case with "balloon"
	where it can be SetParented and move with things, which is required to move it, even though its System
	can be deleted allowing the particle to exist... confusing situation, thus this stuff is too situational.

PARTI-COOLS DONE.



MAKE FUNCTION LOOSE ENDS

#1 - Need to create a "make_choreo" or "make_scene" function

	It shouldn't need an origin so ignore that parameter.

	Use these Keyvalues for "logic_choreographed_scene":

		"busyactor" "0"
		"onplayerdeath" "0"
		"SceneFile" "scenes/mechanic/worldc1m4b01.vcd"
		"targetname" "tsu_jimmy_reffinal_choreo"

	I need to interrupt the following lines with a substitute VCD:

		** Note that nullifying current scene w/ "CancelCurrentScene" or "SpeakResponseConcept" both FAIL.
		   It's because "SpeakResponseConcept" just works differently -- whereas the LCS entity is a full-on
		   interruption and ceases whatever was going on before... making it GOOD for my use, but also BAD
		   for retail/canonical gameplay since it interrupts active lines.

		1. Elevator chat, I want to abruptly cut them off... they're SHOCKED (to their systems...)

		2. "Get some gas" etc. lines after finale starts, even though turned to "Standard"

	What each number does:

		If an Actor is talking "busyactor"

			Start immediately 0
			Wait for actor to finish 1
			Interrupt at next interrupt event 2
			Cancel at next interrupt event 3

		On player death "onplayerdeath"

			Do Nothing 0
			Cancel Script and return to AI 1

	Test-case to confirm working:

		"Producer_WorldC1M3B16"	"<clr:168,71,96>Rochelle: Jimmy Gibbs Jr…. Yay."

#2 - Copy "make_sparks" for a "make_shake"... mostly just so my PRECACHING of it makes to full fruition / sense

	See "env_shake" example elsewhere in this *.TXT.

	It's not a priority or useful and "pro players" would just find it distracting.

	Note that Tanks chasing you DOES ALSO SHAKE, so it's sorta redundant anyway.

#3 - Pipebomb's bare-bones creation steps (100% ignoring ALL dead-ends, they're documented ELSEWHERE)

	"PipeBomb.Bounce" should be optional since the Vector'd entity should make the sounds.

	"PipeBomb.TimerBeep" is definitely necessary.

	SpawnEntityFromTable( "pipe_bomb_projectile", { targetname = g_UpdateName + "_jimmy_pipebomb", origin = Vector( -4528, -3261, 22 ) } );

	SetParent fuse / blinking light / explosion particle/sound / beep sound and make_rotator to it

	Give it a Velocity toward the elevator to start bouncing in that direction

	At different timings, change its Gravity to fake different heights in each of its bounces

		NetProps.SetPropFloat( Entities.FindByName( null, g_UpdateName + "_jimmy_pipebomb" ), "m_flGravity", 0.1 );

		0.4 grav and 0.2 friction may ODDLY be the defaults, idk how to change friction / won't need to anyway

	When it reaches near its end, Gravity should be strong enough to make it "land"

	Cease particles and explode sound... adjust glass break timings

I've come a long way... to have sounds/hints 100% done... to only have THE_ABOVE remain.



ADDITIONAL IDEAS TO ASSESS

cut microphone on the trolley, wanted to support vocalize spamming / singing along... too difficult to get a working base atm

	script SpawnEntityFromTable( "env_microphone", { targetname = g_UpdateName + "_jimmy_xtra_microphone", origin = Vector( -4420, -1981, 17 ), SpeakerName = g_UpdateName + "_jimmy_xtra_speaker", speaker_dsp_preset = 57, spawnflags = 63, SmoothFactor = 0, Sensitivity = 1, MaxRange = 100 } );
	script SpawnEntityFromTable( "info_target", { targetname = g_UpdateName + "_jimmy_xtra_speaker", origin = Vector( -4420, -1981, 17 ), spawnflags = 0 } );
	script SpawnEntityFromTable( "info_target", { targetname = g_UpdateName + "_jimmy_xtra_speaker", origin = Vector( -4420, -1981, 17 ), spawnflags = 0 } );

consider using a https://developer.valvesoftware.com/wiki/Point_spotlight / env_beam / env_laser to:
... Gnome Chompsky will help, with an Infected-only filtered beam/laser, kill zombies with his spinning disco ball

Gnome Chompsky bored now; hop aboard the trolley!

note I haven't yet included the "tunnel of love entrance archway" with lights... I want Gnome to be more "mobile"
than that... so I guess that, plus the subtitle "sing-a-long"", will be EXCLUDED this time around -- there's a thing as too much
--- put speakers on the archway

basketball spotlight entry w/ start of "save me some sugar" -> play that out -> "re your brains" -> "still alive" when escape is active

I spell Gnome Chompski's name wrong everywhere b/c of this
https://en.wikipedia.org/wiki/Noam_Chomsky#University_of_Arizona:_2017%E2%80%93present



JEFF'S PC "LIVE UNSUSPECTING VICTIM" TESTING ISSUES

#1 - Ensure there's no leading 0 in targetnames that can break this:

	local strGascanTarget = g_UpdateName + "_jimmy_empty_gascan_" + RandomInt( 1, 13 );

#2 - Jeff's PC has Jimmy spawn with a Riotcop Faceshield, whereas my Laptop does not, albeit same settings

#3 - The first round was only producing a Male01 and not even a Riotcop, resulting in permstuck elevator

	Riotcop's model is precached, IDK why it failed, and cannot reproduce it -- it's NOT
	due to loading into map 4 from map 3 (but would've made sense as I only prior tested
	straight loads into map 4). I STRONGLY_SUSPECT it's not a failure of the "changemodel"
	function given that all the other functions 100% work !!

	Recall that spawning a Jimmy directly w/o SetModel() workaround results in him never
	chasing the goal... so the Riotcop was used since it chases and has extra immunity,
	but then #2's Faceshield issue was observed, and the 1st round failure leading to no
	Jimmy model entering the Jimmy-filtered trigger, resulting in permstucking in elevator.

	Infected players can't headshot and func_brush block bullets, so this was instead changed
	to "common_male01" which solved both #1 and #2:

		EntFire( g_UpdateName + "_jimmygibbs_spawner", "SpawnZombie", "common_male_riot,anv_mapfixes_jimmygibbs" );
									    ^^ common_male01

#4 - Need to eliminate Commons since it's a distraction from Jimmy if lots of zombies are chasing the goal

	Prevent it starting when he spawns to run past:

		function tsu_c1m4_jimmy_02_runningpast()
		{
			Convars.SetValue( "z_common_limit", 0 );
			EntFire( "infected", "Kill" );

	And restore it exactly when the glass breaks:

		function tsu_c1m4_jimmy_04_glassbreak()
		{
			Convars.SetValue( "z_common_limit", 30 );

#5 - Help players survive the first song

	Fireworks and damage triggers will help... but maybe a "carrot on a stick bile jar" that coaxes
	Commons by default to run into the propeller blade?

#6 - I've long-missed deleting a trigger_push

	Optionally I can delete "_jimmy_speaker_push" once the speakers have risen.

	Infected players aren't blocked by the Survivor-only clip to prevent them from touching it, so
	they can get permstuck ramming into the front of the "love gate".

	Option #1 == Create a gate-sized "SI Player and AI" clip that doesn't extend to ceiling.

	Option #2 == Change the trigger_push to only push "Survivors"

	DECISION :: Option #2, will allow players to "ride the raising love gate" up as it ascends, and
	they can reasonably get on top of it, and won't get stuck because it is ascending. Would be very
	funny to see a Hunter "abuse" this for a cheesy semi-damage pounce.

#7 - Bots cannot leave elevator b/c there's no nav leading out

	Bots still inside will 100% ignore attacked/incapped players outside because they cannot exit.

	Need to run some sort of "logic_timer Think" (noting that "AddThinkToEnt" is bad since doing that
	on worldspawn will persist it running on round transition) to detect bots still inside then warp
	them out sometime after glass breaks. Need to use VScript to detect the bot... as spawnflags can
	only detect "Client" which includes any Survivors/Infected (as it's the "NPC" flag that's Commons).

	SUPERIOR HIGH-EFFORT SOLUTION:

		When elevator reaches bottom, have elevator doors slightly open, but angled, and
		make use of make_sparks() again to add more sparks, but smaller, more frequent.
		Adjust the function to tweak it more maybe... or just suffice a copy of the button's.

		Like 5 seconds after glass breaks after real players have exited, THEN it's time to
		open the elevator doors (let's say Jimmy's car-hit/pipebomb hit it back into function)
		which will let bots exit safely... and doubly not make it a finale exploit spot.

		Kinda obsoletes the "nav clip" I added, but not really since it'll still help, only less.

#8 - Retry firing Stop to strung-light particles to get them to cease... pretty sure I confirmed fail on this before tho

#9 - Scoring... either copy LAST STAND FINALE's solution/alternative Kerry did add, or run normal Scavenge and "fake" 13 can pours

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*******************************************************************************************************************************/