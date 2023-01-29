#include maps\_utility;

init_loadout()
{
	// MikeD (7/30/2007): New method of precaching/giving weapons.
	// Set the level variables.
	if( !IsDefined( level.player_loadout ) )
	{
		level.player_loadout = [];
	}

	// CODER MOD
	// With the player joining later now we need to precache all weapons for the level
	init_models_and_variables_loadout();

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] give_loadout();
		players[i].pers["class"] = "closequarters";
	}
	level.loadoutComplete = true;
	level notify("loadout complete");

	// Precache Zombie Heroes
	mptype\nazi_zombie_heroes::precache();
}

init_models_and_variables_loadout()
{
	if( level.script == "credits" )
	{
		set_player_viewmodel( "viewmodel_usa_marine_arms");
		set_player_interactive_hands( "viewmodel_usa_marine_player");
		level.campaign = "american";
		return;
	}
	else
	{
		add_weapon( "zombie_colt" );
		PrecacheItem( "napalmblob" );
		PrecacheItem( "napalmbloblight" );
		set_switch_weapon( "zombie_colt" );

		set_laststand_pistol( "zombie_colt" );

		set_player_viewmodel( "viewmodel_usa_marine_arms");
		set_player_interactive_hands( "viewmodel_usa_marine_player");

		level.campaign = "american";
		return;
	}
}

// This will precache and set the loadout rather than duplicating work.
add_weapon( weapon_name )
{
	PrecacheItem( weapon_name );
	level.player_loadout[level.player_loadout.size] = weapon_name;
}

// This sets the secondary offhand type when the player spawns in
set_secondary_offhand( weapon_name )
{
	level.player_secondaryoffhand = weapon_name;
}

// This sets the the switchtoweapon when the player spawns in
set_switch_weapon( weapon_name )
{
	level.player_switchweapon = weapon_name;
}

// This sets the the action slot for when the player spawns in
set_action_slot( num, option1, option2 )
{

	if( num < 2 || num > 4)
	{
		if(level.script != "pby_fly")  // GLocke 11/15/2007 - The flying level uses all 4 dpad slots
		{
			// Not using 1, since it's defaulted to grenade launcher.
			assertmsg( "_loadout.gsc: set_action_slot must be set with a number greater than 1 and less than 5" );
		}
	}

	// Glocke 12/03/07 - added precaching of weapon type for action slot
	if(IsDefined(option1))
	{
		if(option1 == "weapon")
		{
			PrecacheItem(option2);
			level.player_loadout[level.player_loadout.size] = option2;
		}
	}

	if( !IsDefined( level.player_actionslots ) )
	{
		level.player_actionslots = [];
	}

	action_slot = SpawnStruct();
	action_slot.num = num;
	action_slot.option1 = option1;

	if( IsDefined( option2 ) )
	{
		action_slot.option2 = option2;
	}

	level.player_actionslots[level.player_actionslots.size] = action_slot;
}

// Sets the player's viewmodel
set_player_viewmodel( viewmodel )
{
	PrecacheModel( viewmodel );
	level.player_viewmodel = viewmodel;
}

// Sets the player's handmodel used for "interactive" hands and banzai attacks
set_player_interactive_hands( model )
{
	level.player_interactive_hands = model;
	PrecacheModel( level.player_interactive_hands ); 
}

// Sets the player's laststand pistol
set_laststand_pistol( weapon )
{
	level.laststandpistol = weapon;
}

give_loadout(wait_for_switch_weapon)
{
	if( !IsDefined( game["gaveweapons"] ) )
	{
		game["gaveweapons"] = 0;
	}

	if( !IsDefined( game["expectedlevel"] ) )
	{
		game["expectedlevel"] = "";
	}

	if( game["expectedlevel"] != level.script )
	{
		game["gaveweapons"] = 0;		
	}

	if( game["gaveweapons"] == 0 )
	{
		game["gaveweapons"] = 1;
	}

	// MikeD (4/18/2008): In order to be able to throw a grenade back, the player first needs to at
	// least have a grenade in his inventory before doing so. So let's try to find out and give it to him
	// then take it away.
	gave_grenade = false;

	// First check to see if we are giving him a grenade, if so, skip this process.
	for( i = 0; i < level.player_loadout.size; i++ )
	{
		if( WeaponType( level.player_loadout[i] ) == "grenade" )
		{
			gave_grenade = true;
			break;
		}
	}

	// If we do not have a grenade then try to automatically assign one
	// If we can't automatically do this, then the scripter needs to do by hand in the level
	if( !gave_grenade )
	{
		if( IsDefined( level.player_grenade ) )
		{
			grenade = level.player_grenade;
			self GiveWeapon( grenade );
			self SetWeaponAmmoStock( grenade, 0 );
			gave_grenade = true;
		}

		if( !gave_grenade )
		{
			// Get all of the AI and assign any grenade to the player
			ai = GetAiArray( "allies" );

			if( IsDefined( ai ) )
			{
				for( i = 0; i < ai.size; i++ )
				{
					if( IsDefined( ai[i].grenadeWeapon ) )
					{
						grenade = ai[i].grenadeWeapon;
						self GiveWeapon( grenade );
						self SetWeaponAmmoStock( grenade, 0 );
						break;
					}
				}
			}

			println( "^3LOADOUT ISSUE: Unable to give a grenade, the player need to be given a grenade and then take it away in order for the player to throw back grenades, but not have any grenades in his inventory." );
		}
	}

	for( i = 0; i < level.player_loadout.size; i++ )
	{
		self GiveWeapon( level.player_loadout[i] );
	}

	self SetActionSlot( 1, "" );
	self SetActionSlot( 2, "" );
	self SetActionSlot( 3, "altMode" );	// toggles between attached grenade launcher
	self SetActionSlot( 4, "" );

	if( IsDefined( level.player_actionslots ) )
	{
		for( i = 0; i < level.player_actionslots.size; i++ )
		{
			num = level.player_actionslots[i].num;
			option1 = level.player_actionslots[i].option1;

			if( IsDefined( level.player_actionslots[i].option2 ) )
			{
				option2 = level.player_actionslots[i].option2;
				self SetActionSlot( num, option1, option2 );
			}
			else
			{
				self SetActionSlot( num, option1 );
			}
		}
	}

	if( IsDefined( level.player_switchweapon ) )
	{
		// the wait was added to fix a revive issue with the host
		// for some reson the SwitchToWeapon message gets lost
		// this can be removed if that is ever resolved
		if ( isdefined(wait_for_switch_weapon) && wait_for_switch_weapon == true )
		{
			wait(0.5);
		}
		self SwitchToWeapon( level.player_switchweapon );
	}

	wait(0.5);

	self player_flag_set("loadout_given");
}

give_model( class )
{
	switch( self.entity_num )
	{
	case 0:
		character\char_zomb_player_0::main();
		break;
	case 1:
		character\char_zomb_player_1::main();
		break;
	case 2:
		character\char_zomb_player_2::main();
		break;
	case 3:
		character\char_zomb_player_3::main();
		break;
	}

	// MikeD (3/28/2008): If specified, give the player his hands
	if( IsDefined( level.player_viewmodel ) )
	{
		self SetViewModel( level.player_viewmodel );
	}
}

///////////////////////////////////////////////
// SavePlayerWeaponStatePersistent
// 
// Saves the player's weapons and ammo state persistently( in the game variable )
// so that it can be restored in a different map.
// You can use strings for the slot:
// 
// SavePlayerWeaponStatePersistent( "russianCampaign" );
// 
// Or you can just use numbers:
// 
// SavePlayerWeaponStatePersistent( 0 );
// SavePlayerWeaponStatePersistent( 1 ); etc.
// 
// In a different map, you can restore using RestorePlayerWeaponStatePersistent( slot );
// Make sure that you always persist the data between map changes.

SavePlayerWeaponStatePersistent( slot )
{
	current = level.player getCurrentWeapon();
	if ( ( !isdefined( current ) ) || ( current == "none" ) )
		assertmsg( "Player's current weapon is 'none' or undefined. Make sure 'disableWeapons()' has not been called on the player when trying to save weapon states." );
	game[ "weaponstates" ][ slot ][ "current" ] = current;

	offhand = level.player getcurrentoffhand();
	game[ "weaponstates" ][ slot ][ "offhand" ] = offhand;

	game[ "weaponstates" ][ slot ][ "list" ] = [];
	weapList = level.player GetWeaponsList();
	for ( weapIdx = 0; weapIdx < weapList.size; weapIdx++ )
	{
		game[ "weaponstates" ][ slot ][ "list" ][ weapIdx ][ "name" ] = weapList[ weapIdx ];

		// below is only used if we want to NOT give max ammo
		// game[ "weaponstates" ][ slot ][ "list" ][ weapIdx ][ "clip" ] = level.player GetWeaponAmmoClip( weapList[ weapIdx ] );
		// game[ "weaponstates" ][ slot ][ "list" ][ weapIdx ][ "stock" ] = level.player GetWeaponAmmoStock( weapList[ weapIdx ] );
	}
}

RestorePlayerWeaponStatePersistent( slot )
{
	if ( !isDefined( game[ "weaponstates" ] ) )
		return false;
	if ( !isDefined( game[ "weaponstates" ][ slot ] ) )
		return false;

	level.player takeallweapons();

	for ( weapIdx = 0; weapIdx < game[ "weaponstates" ][ slot ][ "list" ].size; weapIdx++ )
	{
		weapName = game[ "weaponstates" ][ slot ][ "list" ][ weapIdx ][ "name" ];

		if ( isdefined( level.legit_weapons ) )
		{
			// weapon doesn't exist in this level
			if ( !isdefined( level.legit_weapons[ weapName ] ) )
				continue;
		}

		// don't carry over C4 or claymores
		if ( weapName == "c4" )
			continue;
		if ( weapName == "claymore" )
			continue;
		level.player GiveWeapon( weapName );
		level.player GiveMaxAmmo( weapName );

		// below is only used if we want to NOT give max ammo
		// level.player SetWeaponAmmoClip( weapName, game[ "weaponstates" ][ slot ][ "list" ][ weapIdx ][ "clip" ] );
		// level.player SetWeaponAmmoStock( weapName, game[ "weaponstates" ][ slot ][ "list" ][ weapIdx ][ "stock" ] );
	}

	if ( isdefined( level.legit_weapons ) )
	{
		weapname = game[ "weaponstates" ][ slot ][ "offhand" ];
		if ( isdefined( level.legit_weapons[ weapName ] ) )
			level.player switchtooffhand( weapname );

		weapname = game[ "weaponstates" ][ slot ][ "current" ];
		if ( isdefined( level.legit_weapons[ weapName ] ) )
			level.player SwitchToWeapon( weapname );
	}
	else
	{
		level.player switchtooffhand( game[ "weaponstates" ][ slot ][ "offhand" ] );
		level.player SwitchToWeapon( game[ "weaponstates" ][ slot ][ "current" ] );
	}

	return true;
}