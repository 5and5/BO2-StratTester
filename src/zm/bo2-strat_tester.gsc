#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/gametypes_zm/_hud_message;
#include maps/mp/gametypes_zm/_globallogic;
#include maps/mp/gametypes_zm/_weapons;
#include maps/mp/zombies/_zm_buildables;
#include maps/mp/zombies/_zm_equipment;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm_melee_weapon;
#include maps/mp/zombies/_zm_audio;

settings()
{
	// Settings
	level.start_round = 100; 			// what round the game starts at
	level.power_on = 1; 				// turns power on
	level.perks_on_revive = 1; 			// give perks back on revive
	level.perks_on_spawn = 1; 			// give perks on spawn
	level.weapons_on_spawn = 1;			// give weapons on spawn

	// HUD
	level.hud_timer = 1; 				// total game timer
	level.hud_round_timer = 1; 			// round timer
	level.hud_zombie_counter = 1;		// zombie remaining counter
	level.hud_zone_names = 1;			// spawn zone hud
	level.hud_health_bar = 0;			// not added yet
}

main()
{
	// Pluto only
    // replaceFunc( maps/mp/zombies/_zm_powerups::powerup_drop, ::powerup_drop_override );
}

init()
{
	level.STRAT_TESTER_VERSION = "0.3 beta";
    level.init = 0;
	settings();
    level thread onConnect();
}

onConnect()
{
    for (;;)
    {
        level waittill( "connected" , player);
        player thread connected();
    }
}

connected()
{
    self endon( "disconnect" );
    self.init = 0;

    for(;;)
    {
        self waittill( "spawned_player" );

        if( !self.init )
        {
            self.init = 1;

            self.score = 500000;
			self welcome_message();
            self thread timer_hud();
			self thread zone_hud();
			self thread zombie_remaining_hud();
            self thread give_weapons_on_spawn();
            self thread give_perks_on_spawn();
            self thread give_perks_on_revive();
        }

        if( !level.init )
        {
            level.init = 1;

            enable_cheats();

            level thread turn_on_power();
            level thread set_starting_round();
        }
    }
}

welcome_message()
{
	self iprintln( "Welcome to Strat Tester v" + level.STRAT_TESTER_VERSION );
	self iprintln( "Made by 5and5" );
}

enable_cheats()
{
    setDvar( "sv_cheats", 1 );
	setDvar( "cg_ufo_scaler", 0.7 );

    if( level.player_out_of_playable_area_monitor && IsDefined( level.player_out_of_playable_area_monitor ) )
	{
		self notify( "stop_player_out_of_playable_area_monitor" );
	}
	level.player_out_of_playable_area_monitor = 0;
}

turn_on_power() //by xepixtvx
{	
	if( !level.power_on )
		return;

	flag_wait( "initial_blackscreen_passed" );
	wait 5;
	trig = getEnt( "use_elec_switch", "targetname" );
	powerSwitch = getEnt( "elec_switch", "targetname" );
	powerSwitch notSolid();
	trig setHintString( &"ZOMBIE_ELECTRIC_SWITCH" );
	trig setVisibleToAll();
	trig notify( "trigger", self );
	trig setInvisibleToAll();
	powerSwitch rotateRoll( -90, 0, 3 );
	level thread maps/mp/zombies/_zm_perks::perk_unpause_all_perks();
	powerSwitch waittill( "rotatedone" );
	flag_set( "power_on" );
	level setClientField( "zombie_power_on", 1 ); 
}

set_starting_round()
{
	level.first_round = false;
    level.zombie_move_speed = 130;
	level.zombie_vars[ "zombie_spawn_delay" ] = 0.08;
	level.round_number = level.start_round;
}


/*
* *****************************************************
*	
* ****************** Weapons/Perks ********************
*
* *****************************************************
*/

give_perks_on_revive()
{
	if( !level.perks_on_revive )
		return;

	level endon("end_game");
	self endon( "disconnect" );

	while( 1 )
	{
		self waittill( "player_revived", reviver );

        self give_perks_by_map();
	}
}

give_perks_on_spawn()
{
	if( !level.perks_on_spawn )
		return;

    level waittill("initial_blackscreen_passed");
    wait 0.5;
    self give_perks_by_map();
}

give_perks_by_map()
{
    switch( level.script )
    {
        case "zm_transit":
        	location = level.scr_zm_map_start_location;
            if ( location == "farm" )
            {
                self give_perk("specialty_armorvest", 0);
                wait 0.15;
                self give_perk("specialty_fastreload", 0);
                wait 0.15;
                self give_perk("specialty_rof", 0);
                wait 0.15;
                self give_perk("specialty_quickrevive", 0);
            }
            else if ( location == "town" )
            {
                self give_perk("specialty_armorvest", 0);
                wait 0.15;
                self give_perk("specialty_rof", 0);
                wait 0.15;
                self give_perk("specialty_longersprint", 0);
                wait 0.15;
                self give_perk("specialty_quickrevive", 0);
            }
            else if ( location == "transit" && !is_classic() ) //depot
            {
  
            }
            else if ( location == "transit" )
            {
                self give_perk("specialty_armorvest", 0);
                wait 0.15;
                self give_perk("specialty_longersprint", 0);
                wait 0.15;
                self give_perk("specialty_fastreload", 0);
                wait 0.15;
                self give_perk("specialty_quickrevive", 0);
            }
            break;
        case "zm_nuked":
            self give_perk("specialty_armorvest", 0);
            wait 0.15;
            self give_perk("specialty_fastreload", 0);
            wait 0.15;
            self give_perk("specialty_rof", 0);
            wait 0.15;
            self give_perk("specialty_quickrevive", 0);
            break;
        case "zm_highrise":
            self give_perk("specialty_armorvest", 0);
            wait 0.15;
            self give_perk("specialty_fastreload", 0);
            wait 0.15;
            self give_perk("specialty_rof", 0);
            wait 0.15;
            self give_perk("specialty_quickrevive", 0);
            break;
        case "zm_prison":
            flag_wait( "afterlife_start_over" );
            self give_perk("specialty_armorvest", 0);
            wait 0.15;
            self give_perk("specialty_fastreload", 0);
            wait 0.15;
            self give_perk("specialty_rof", 0);
            wait 0.15;
            self give_perk("specialty_grenadepulldeath", 0);
            break;
        case "zm_buried":
            self give_perk("specialty_quickrevive", 0);
            wait 0.15;
            self give_perk("specialty_armorvest", 0);
            wait 0.15;
            self give_perk("specialty_additionalprimaryweapon", 0);
            wait 0.15;
            self give_perk("specialty_fastreload", 0);
            wait 0.15;
            self give_perk("specialty_longersprint", 0);
            wait 0.15;
            self give_perk("specialty_rof", 0);
            break;
        case "zm_tomb":
            self give_perk("specialty_armorvest", 0);
            wait 0.15;
            self give_perk("specialty_additionalprimaryweapon", 0);
            wait 0.15;
            self give_perk("specialty_fastreload", 0);
            wait 0.15;
            self give_perk("specialty_longersprint", 0);
            wait 0.15;
            self give_perk("specialty_flakjacket", 0);
            wait 0.15;
            self give_perk("specialty_quickrevive", 0);
            break;
    }
}

give_weapons_on_spawn()
{
	if( !level.weapons_on_spawn )
		return;
	
    level waittill("initial_blackscreen_passed");

    switch( level.script )
    {
        case "zm_transit":
        	location = level.scr_zm_map_start_location;
            if ( location == "farm" )
            {
                self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
                self giveweapon_nzv( "cymbal_monkey_zm" );
                self giveweapon_nzv( "qcw05_zm" );
                self switchToWeapon( "raygun_mark2_upgraded_zm" );
            }
            else if ( location == "town" )
            {
                self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
                self giveweapon_nzv( "m1911_upgraded_zm" );
                self giveweapon_nzv( "cymbal_monkey_zm" );
                self switchToWeapon( "raygun_mark2_upgraded_zm" );
            }
            else if ( location == "transit" && !is_classic() ) //depot
            {
                self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
                self giveweapon_nzv( "qcw05_zm" );
                self giveweapon_nzv( "cymbal_monkey_zm" );
                self giveweapon_nzv( "tazer_knuckles_zm" );
                self switchToWeapon( "raygun_mark2_upgraded_zm" );
            }
            else if ( location == "transit" )
            {
                self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
                self giveweapon_nzv( "m1911_upgraded_zm" );
                self giveweapon_nzv( "jetgun_zm" );
                self giveweapon_nzv( "cymbal_monkey_zm" );
                self giveweapon_nzv( "tazer_knuckles_zm" );
                self switchToWeapon( "raygun_mark2_upgraded_zm" );
            }
            break;
        case "zm_nuked":
            self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
            self giveweapon_nzv( "m1911_upgraded_zm" );
            self giveweapon_nzv( "cymbal_monkey_zm" );
            self switchToWeapon( "raygun_mark2_upgraded_zm" );
            break;
        case "zm_highrise":
            self giveweapon_nzv( "slipgun_zm" );
            self giveweapon_nzv( "qcw05_zm" );
            self giveweapon_nzv( "cymbal_monkey_zm" );
            self switchToWeapon( "slipgun_zm" );
            break;
        case "zm_prison":
            flag_wait( "afterlife_start_over" );
            self giveweapon_nzv( "blundersplat_upgraded_zm" );
            self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
			self giveweapon_nzv( "claymore_zm" );
            self giveweapon_nzv( "upgraded_tomahawk_zm" );
            self.current_tactical_grenade = "upgraded_tomahawk_zm";
            self.current_tomahawk_weapon = "upgraded_tomahawk_zm";
            self setclientfieldtoplayer( "upgraded_tomahawk_in_use", 1 );
            break;
        case "zm_buried":
            wait 0.5;
            self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
            self giveweapon_nzv( "m1911_upgraded_zm" );
            self giveweapon_nzv( "slowgun_upgraded_zm" );
            self giveweapon_nzv( "cymbal_monkey_zm" );
			self giveweapon_nzv( "claymore_zm" );
            self switchToWeapon( "slowgun_upgraded_zm" );
            break;
        case "zm_tomb":
            self giveweapon_nzv( "raygun_mark2_upgraded_zm" );
            self giveweapon_nzv( "staff_air_upgraded_zm" );
            self giveweapon_nzv( "cymbal_monkey_zm" );
			self giveweapon_nzv( "claymore_zm" );
            self switchToWeapon( "staff_air_upgraded_zm" );
            break;
    }
}

giveweapon_nzv( weapon )
{
	if( issubstr( weapon, "tomahawk_zm" ) && level.script == "zm_prison" )
	{
		self play_sound_on_ent( "purchase" );
		self notify( "tomahawk_picked_up" );
		level notify( "bouncing_tomahawk_zm_aquired" );
		self notify( "player_obtained_tomahawk" );
		if( weapon == "bouncing_tomahawk_zm" )
		{
			self.tomahawk_upgrade_kills = 0;
			self.killed_with_only_tomahawk = 1;
			self.killed_something_thq = 0;
		}
		else
		{
			self.tomahawk_upgrade_kills = 99;
			self.killed_with_only_tomahawk = 1;
			self.killed_something_thq = 1;
			self notify( "tomahawk_upgraded_swap" );
		}
		old_tactical = self get_player_tactical_grenade();
		if( old_tactical != "none" && IsDefined( old_tactical ) )
		{
			self takeweapon( old_tactical );
		}
		self set_player_tactical_grenade( weapon );
		self.current_tomahawk_weapon = weapon;
		gun = self getcurrentweapon();
		self disable_player_move_states( 1 );
		self giveweapon( "zombie_tomahawk_flourish" );
		self switchtoweapon( "zombie_tomahawk_flourish" );
		self waittill_any( "player_downed", "weapon_change_complete" );
		self switchtoweapon( gun );
		self enable_player_move_states();
		self takeweapon( "zombie_tomahawk_flourish" );
		self giveweapon( weapon );
		self givemaxammo( weapon );
		if( !(is_equipment( gun ))is_equipment( gun ) && !(is_placeable_mine( gun )) )
		{
			self switchtoweapon( gun );
			self waittill( "weapon_change_complete" );
		}
		else
		{
			primaryweapons = self getweaponslistprimaries();
			if( primaryweapons.size > 0 && IsDefined( primaryweapons ) )
			{
				self switchtoweapon( primaryweapons[ 0] );
				self waittill( "weapon_change_complete" );
			}
		}
		self play_weapon_vo( weapon );
	}
	else
	{
		if( weapon == "willy_pete_zm" && level.script == "zm_prison" )
		{
			self play_sound_on_ent( "purchase" );
			gun = self getcurrentweapon();
			old_tactical = self get_player_tactical_grenade();
			if( old_tactical != "none" && IsDefined( old_tactical ) )
			{
				self takeweapon( old_tactical );
			}
			self set_player_tactical_grenade( weapon );
			self giveweapon( weapon );
			self givemaxammo( weapon );
			if( !(is_equipment( gun ))is_equipment( gun ) && !(is_placeable_mine( gun )) )
			{
				self switchtoweapon( gun );
				self waittill( "weapon_change_complete" );
			}
			else
			{
				primaryweapons = self getweaponslistprimaries();
				if( primaryweapons.size > 0 && IsDefined( primaryweapons ) )
				{
					self switchtoweapon( primaryweapons[ 0] );
					self waittill( "weapon_change_complete" );
				}
			}
			self play_weapon_vo( weapon );
		}
		else
		{
			if( weapon == "time_bomb_zm" && level.script == "zm_buried" )
			{
				self weapon_give( weapon, undefined, undefined, 0 );
			}
			else
			{
				if( issubstr( weapon, "one_inch_punch" ) && level.script == "zm_tomb" )
				{
					self play_sound_on_ent( "purchase" );
					gun = self getcurrentweapon();
					self disable_player_move_states( 1 );
					if( weapon == "one_inch_punch_zm" )
					{
						self.b_punch_upgraded = 0;
						self giveweapon( "zombie_one_inch_punch_flourish" );
						self switchtoweapon( "zombie_one_inch_punch_flourish" );
					}
					else
					{
						self.b_punch_upgraded = 1;
						if( weapon == "one_inch_punch_air_zm" )
						{
							self.str_punch_element = "air";
						}
						else
						{
							if( weapon == "one_inch_punch_fire_zm" )
							{
								self.str_punch_element = "fire";
							}
							else
							{
								if( weapon == "one_inch_punch_ice_zm" )
								{
									self.str_punch_element = "ice";
								}
								else
								{
									if( weapon == "one_inch_punch_lightning_zm" )
									{
										self.str_punch_element = "lightning";
									}
									else
									{
										if( weapon == "one_inch_punch_upgraded_zm" )
										{
											self.str_punch_element = "upgraded";
										}
									}
								}
							}
						}
						self giveweapon( "zombie_one_inch_punch_upgrade_flourish" );
						self switchtoweapon( "zombie_one_inch_punch_upgrade_flourish" );
					}
					self waittill_any( "player_downed", "weapon_change_complete" );
					self enable_player_move_states();
					if( weapon == "one_inch_punch_zm" )
					{
						self takeweapon( "zombie_one_inch_punch_flourish" );
					}
					else
					{
						self takeweapon( "zombie_one_inch_punch_upgrade_flourish" );
					}
					gun = self change_melee_weapon( weapon, gun );
					self giveweapon( weapon );
					if( !(is_equipment( gun ))is_equipment( gun ) && !(is_placeable_mine( gun )) )
					{
						self switchtoweapon( gun );
						self waittill( "weapon_change_complete" );
					}
					else
					{
						primaryweapons = self getweaponslistprimaries();
						if( primaryweapons.size > 0 && IsDefined( primaryweapons ) )
						{
							self switchtoweapon( primaryweapons[ 0] );
							self waittill( "weapon_change_complete" );
						}
					}
					self thread create_and_play_dialog( "perk", "one_inch" );
				}
				else
				{
					if( issubstr( weapon, "_melee_zm" ) && issubstr( weapon, "staff_" ) && level.script == "zm_tomb" )
					{
						self play_sound_on_ent( "purchase" );
						gun = self getcurrentweapon();
						gun = self change_melee_weapon( weapon, gun );
						self giveweapon( weapon );
						if( !(is_equipment( gun ))is_equipment( gun ) && !(is_placeable_mine( gun )) )
						{
							self switchtoweapon( gun );
							self waittill( "weapon_change_complete" );
						}
						else
						{
							primaryweapons = self getweaponslistprimaries();
							if( primaryweapons.size > 0 && IsDefined( primaryweapons ) )
							{
								self switchtoweapon( primaryweapons[ 0] );
								self waittill( "weapon_change_complete" );
							}
						}
						self play_weapon_vo( weapon );
					}
					else
					{
						if( issubstr( weapon, "staff_" ) && level.script == "zm_tomb" )
						{
							if( issubstr( weapon, "_upgraded_zm" ) )
							{
								if( !(self hasweapon( "staff_revive_zm" )) )
								{
									self setactionslot( 3, "weapon", "staff_revive_zm" );
									self giveweapon( "staff_revive_zm" );
								}
								self givemaxammo( "staff_revive_zm" );
							}
							else
							{
								if( self hasweapon( "staff_revive_zm" ) )
								{
									self takeweapon( "staff_revive_zm" );
									self setactionslot( 3, "altmode" );
								}
							}
							self weapon_give( weapon, undefined, undefined, 0 );
						}
						else
						{
							if( issubstr( weapon, "equip_dieseldrone_zm" ) && level.script == "zm_tomb" )
							{
								if( IsDefined( level.zombie_custom_equipment_setup ) )
								{
									players = getplayers();
									i = 0;
									while( i < players.size )
									{
										if( players[ i] hasweapon( weapon ) )
										{
											self stealth_iprintln( "^1ERROR: ^7Diesel Drone is already equiped by one player" );
										}
										i++;
									}
									quadrotor = getentarray( "quadrotor_ai", "targetname" );
									if( quadrotor.size >= 1 )
									{
										self stealth_iprintln( "^1ERROR: ^7Diesel Drone is already active, can't spawn another yet" );
									}
									// customequipgiver = spawn( "script_model", self normalisedtrace( "position" ) );
									// customequipgiver setmodel( "veh_t6_dlc_zm_quadrotor" );
									// customequipgiver.stub = spawnstruct();
									// customequipgiver.stub.weaponname = "equip_dieseldrone_zm";
									// customequipgiver.stub.craftablestub = spawnstruct();
									// customequipgiver.stub.craftablestub.use_actionslot = 2;
									// customequipgiver [[  ]]( self );
									// customequipgiver delete();
								}
							}
							else
							{
								if( self is_melee_weapon( weapon ) )
								{
									if( weapon == "bowie_knife_zm" || weapon == "tazer_knuckles_zm" )
									{
										// self give_melee_weapon_by_name( weapon );
                                        self give_melee_weapon_instant( weapon );
									}
									else
									{
										self play_sound_on_ent( "purchase" );
										gun = self getcurrentweapon();
										gun = self change_melee_weapon( weapon, gun );
										self giveweapon( weapon );
										if( !(is_equipment( gun ))is_equipment( gun ) && !(is_placeable_mine( gun )) )
										{
											self switchtoweapon( gun );
											self waittill( "weapon_change_complete" );
										}
										else
										{
											primaryweapons = self getweaponslistprimaries();
											if( primaryweapons.size > 0 && IsDefined( primaryweapons ) )
											{
												self switchtoweapon( primaryweapons[ 0] );
												self waittill( "weapon_change_complete" );
											}
										}
										self play_weapon_vo( weapon );
									}
								}
								else
								{
									if( self is_equipment( weapon ) )
									{
										self play_sound_on_ent( "purchase" );
										if( level.destructible_equipment.size > 0 && IsDefined( level.destructible_equipment ) )
										{
											i = 0;
											while( i < level.destructible_equipment.size )
											{
												equip = level.destructible_equipment[ i];
												if( equip.name == weapon && IsDefined( equip.name ) && equip.owner == self && IsDefined( equip.owner ) )
												{
													equip item_damage( 9999 );
													break;
												}
												else
												{
													if( equip.name == weapon && IsDefined( equip.name ) && weapon == "jetgun_zm" )
													{
														equip item_damage( 9999 );
														break;
													}
													else
													{
														i++;
													}
												}
												i++;
											}
										}
										self equipment_take( weapon );
										self equipment_buy( weapon );
										self play_weapon_vo( weapon );
									}
									else
									{
										if( self is_weapon_upgraded( weapon ) )
										{
											self weapon_give( weapon, 1, undefined, 0 );
										}
										else
										{
											self weapon_give( weapon, undefined, undefined, 0 );
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	self stealth_iprintln( "Weapon: " + ( weapon + " ^2Given" ) );

}

stealth_iprintln( message )
{
    // self iprintln( message );
}

give_melee_weapon_instant( weapon_name )
{
	self giveweapon( weapon_name );
	gun = change_melee_weapon( weapon_name, "knife_zm" );
	if ( self hasweapon( "knife_zm" ) )
	{
		self takeweapon( "knife_zm" );
	}
    gun = self getcurrentweapon();
	if ( gun != "none" && !is_placeable_mine( gun ) && !is_equipment( gun ) )
	{
		self switchtoweapon( gun );
	}
}


/*
* *****************************************************
*	
* *********************** HUD *************************
*
* *****************************************************
*/

timer_hud()
{	
	self endon("disconnect");

	self.timer_hud = newClientHudElem(self);
	self.timer_hud.alignx = "left";
	self.timer_hud.aligny = "top";
	self.timer_hud.horzalign = "user_left";
	self.timer_hud.vertalign = "user_top";
	self.timer_hud.x += 4;
	self.timer_hud.y += 2;
	self.timer_hud.fontscale = 1.4;
	self.timer_hud.alpha = 0;
	self.timer_hud.color = ( 1, 1, 1 );
	self.timer_hud.hidewheninmenu = 1;

	self set_hud_offset();
	self thread timer_hud_watcher();
	self thread round_timer_hud();

	flag_wait( "initial_blackscreen_passed" );
	self.timer_hud setTimerUp(0);

	level waittill( "end_game" );

	level.total_time -= .1; // need to set it below the number or it shows the next number
	while( 1 )
	{	
		self.timer_hud setTimer(level.total_time);
		self.timer_hud.alpha = 1;
		self.round_timer_hud.alpha = 0;
		wait 0.1;
	}
}

set_hud_offset()
{
	self.timer_hud_offset = 0;
	self.zone_hud_offset = 15;
}

timer_hud_watcher()
{	
	self endon("disconnect");
	level endon( "end_game" );

	while(1)
	{	
		while( !level.hud_timer )
		{
			wait 0.1;
		}
		self.timer_hud.y = (2 + self.timer_hud_offset);
		self.timer_hud.alpha = 1;

		while( level.hud_timer )
		{
			wait 0.1;
		}
		self.timer_hud.alpha = 0;
	}
}

round_timer_hud()
{
	self endon("disconnect");

	self.round_timer_hud = newClientHudElem(self);
	self.round_timer_hud.alignx = "left";
	self.round_timer_hud.aligny = "top";
	self.round_timer_hud.horzalign = "user_left";
	self.round_timer_hud.vertalign = "user_top";
	self.round_timer_hud.x += 4;
	self.round_timer_hud.y += (2 + (15 * level.hud_timer ) + self.timer_hud_offset );
	self.round_timer_hud.fontscale = 1.4;
	self.round_timer_hud.alpha = 0;
	self.round_timer_hud.color = ( 1, 1, 1 );
	self.round_timer_hud.hidewheninmenu = 1;

	flag_wait( "initial_blackscreen_passed" );

	self thread round_timer_hud_watcher();

	level.FADE_TIME = 0.2;

	while( 1 )
	{
		zombies_this_round = level.zombie_total + get_round_enemy_array().size;
		hordes = zombies_this_round / 24;
		dog_round = flag( "dog_round" );
		leaper_round = flag( "leaper_round" );

		self.round_timer_hud setTimerUp(0);
		start_time = int(getTime() / 1000);

		level waittill( "end_of_round" );

		end_time = int(getTime() / 1000);
		time = end_time - start_time;

		self display_round_time(time, hordes, dog_round, leaper_round);

		level waittill( "start_of_round" );

		if( level.hud_round_timer )
		{
			self.round_timer_hud FadeOverTime(level.FADE_TIME);
			self.round_timer_hud.alpha = 1;
		}
	}
}

display_round_time(time, hordes, dog_round, leaper_round)
{
	timer_for_hud = time - 0.05;

	sph_off = 1;
	if(level.round_number > 50 && !dog_round && !leaper_round)
	{
		sph_off = 0;
	}

	self.round_timer_hud FadeOverTime(level.FADE_TIME);
	self.round_timer_hud.alpha = 0;
	wait level.FADE_TIME * 2;

	self.round_timer_hud.label = &"Round Time: ";
	self.round_timer_hud FadeOverTime(level.FADE_TIME);
	self.round_timer_hud.alpha = 1;

	for ( i = 0; i < 20 + (20 * sph_off); i++ ) // wait 10s or 5s
	{
		self.round_timer_hud setTimer(timer_for_hud);
		wait 0.25;
	}

	self.round_timer_hud FadeOverTime(level.FADE_TIME);
	self.round_timer_hud.alpha = 0;
	wait level.FADE_TIME * 2;

	if(sph_off == 0)
	{
		self display_sph(time, hordes);
	}

	self.round_timer_hud.label = &"";
}

display_sph( time, hordes )
{
	sph = time / hordes;

	self.round_timer_hud FadeOverTime(level.FADE_TIME);
	self.round_timer_hud.alpha = 1;
	self.round_timer_hud.label = &"SPH: ";
	self.round_timer_hud setValue(sph);

	for ( i = 0; i < 5; i++ )
	{
		wait 1;
	}

	self.round_timer_hud FadeOverTime(level.FADE_TIME);
	self.round_timer_hud.alpha = 0;

	wait level.FADE_TIME;
}

round_timer_hud_watcher()
{	
	self endon("disconnect");
	level endon( "end_game" );

	while( 1 )
	{
		while( !level.hud_round_timer )
		{
			wait 0.1;
		}
		self.round_timer_hud.y = (2 + (15 * level.hud_timer ) + self.timer_hud_offset );
		self.round_timer_hud.alpha = 1;

		while( level.hud_round_timer )
		{
			wait 0.1;
		}
		self.round_timer_hud.alpha = 0;

	}
}

zombie_remaining_hud()
{
	self endon( "disconnect" );
	level endon( "end_game" );

	level waittill( "start_of_round" );

    self.zombie_counter_hud = maps/mp/gametypes_zm/_hud_util::createFontString( "hudsmall" , 1.4 );
    self.zombie_counter_hud maps/mp/gametypes_zm/_hud_util::setPoint( "CENTER", "CENTER", "CENTER", 190 );
    self.zombie_counter_hud.alpha = 0;
    self.zombie_counter_hud.label = &"Zombies: ^1";
	self thread zombie_remaining_hud_watcher();

    while( 1 )
    {
        self.zombie_counter_hud setValue( ( maps/mp/zombies/_zm_utility::get_round_enemy_array().size + level.zombie_total ) );
        
        wait 0.05; 
    }
}

zombie_remaining_hud_watcher()
{	
	self endon("disconnect");
	level endon( "end_game" );

	while(1)
	{
		while( !level.hud_zombie_counter )
		{
			wait 0.1;
		}
		self.zombie_counter_hud.alpha = 1;

		while( level.hud_zombie_counter )
		{
			wait 0.1;
		}
		self.zombie_counter_hud.alpha = 0;
	}
}

zone_hud()
{
	if( !level.hud_zone_names )
		return;

	self endon("disconnect");

	x = 8;
	y = -111;
	if (level.script == "zm_buried")
	{
		y -= 25;
	}
	else if (level.script == "zm_tomb")
	{
		y -= 60;
	}

	self.zone_hud = newClientHudElem(self);
	self.zone_hud.alignx = "left";
	self.zone_hud.aligny = "bottom";
	self.zone_hud.horzalign = "user_left";
	self.zone_hud.vertalign = "user_bottom";
	self.zone_hud.x += x;
	self.zone_hud.y += y;
	self.zone_hud.fontscale = 1.3;
	self.zone_hud.alpha = 0;
	self.zone_hud.color = ( 1, 1, 1 );
	self.zone_hud.hidewheninmenu = 1;

	flag_wait( "initial_blackscreen_passed" );

	self thread zone_hud_watcher(x, y);
}

zone_hud_watcher( x, y )
{	
	self endon("disconnect");
	level endon( "end_game" );

	prev_zone = "";
	while(1)
	{
		while( !level.hud_zone_names )
		{
			wait 0.1;
		}

		while( level.hud_zone_names )
		{
			self.zone_hud.y = (y + (self.zone_hud_offset * !level.hud_health_bar ) );

			zone = self get_zone_name();
			if(prev_zone != zone)
			{
				prev_zone = zone;

				self.zone_hud fadeovertime(0.2);
				self.zone_hud.alpha = 0;
				wait 0.2;

				self.zone_hud settext(zone);

				self.zone_hud fadeovertime(0.2);
				self.zone_hud.alpha = 1;
				wait 0.2;

				continue;
			}

			wait 0.05;
		}
		self.zone_hud.alpha = 0;
	}
}

get_zone_name()
{
	zone = self get_current_zone();
	if (!isDefined(zone))
	{
		return "";
	}

	name = zone;

	if (level.script == "zm_transit")
	{
		if (zone == "zone_pri")
		{
			name = "Bus Depot";
		}
		else if (zone == "zone_pri2")
		{
			name = "Bus Depot Hallway";
		}
		else if (zone == "zone_station_ext")
		{
			name = "Outside Bus Depot";
		}
		else if (zone == "zone_trans_2b")
		{
			name = "Fog After Bus Depot";
		}
		else if (zone == "zone_trans_2")
		{
			name = "Tunnel Entrance";
		}
		else if (zone == "zone_amb_tunnel")
		{
			name = "Tunnel";
		}
		else if (zone == "zone_trans_3")
		{
			name = "Tunnel Exit";
		}
		else if (zone == "zone_roadside_west")
		{
			name = "Outside Diner";
		}
		else if (zone == "zone_gas")
		{
			name = "Gas Station";
		}
		else if (zone == "zone_roadside_east")
		{
			name = "Outside Garage";
		}
		else if (zone == "zone_trans_diner")
		{
			name = "Fog Outside Diner";
		}
		else if (zone == "zone_trans_diner2")
		{
			name = "Fog Outside Garage";
		}
		else if (zone == "zone_gar")
		{
			name = "Garage";
		}
		else if (zone == "zone_din")
		{
			name = "Diner";
		}
		else if (zone == "zone_diner_roof")
		{
			name = "Diner Roof";
		}
		else if (zone == "zone_trans_4")
		{
			name = "Fog After Diner";
		}
		else if (zone == "zone_amb_forest")
		{
			name = "Forest";
		}
		else if (zone == "zone_trans_10")
		{
			name = "Outside Church";
		}
		else if (zone == "zone_town_church")
		{
			name = "Church";
		}
		else if (zone == "zone_trans_5")
		{
			name = "Fog Before Farm";
		}
		else if (zone == "zone_far")
		{
			name = "Outside Farm";
		}
		else if (zone == "zone_far_ext")
		{
			name = "Farm";
		}
		else if (zone == "zone_brn")
		{
			name = "Barn";
		}
		else if (zone == "zone_farm_house")
		{
			name = "Farmhouse";
		}
		else if (zone == "zone_trans_6")
		{
			name = "Fog After Farm";
		}
		else if (zone == "zone_amb_cornfield")
		{
			name = "Cornfield";
		}
		else if (zone == "zone_cornfield_prototype")
		{
			name = "Nacht";
		}
		else if (zone == "zone_trans_7")
		{
			name = "Upper Fog Before Power";
		}
		else if (zone == "zone_trans_pow_ext1")
		{
			name = "Fog Before Power";
		}
		else if (zone == "zone_pow")
		{
			name = "Outside Power Station";
		}
		else if (zone == "zone_prr")
		{
			name = "Power Station";
		}
		else if (zone == "zone_pcr")
		{
			name = "Power Control Room";
		}
		else if (zone == "zone_pow_warehouse")
		{
			name = "Warehouse";
		}
		else if (zone == "zone_trans_8")
		{
			name = "Fog After Power";
		}
		else if (zone == "zone_amb_power2town")
		{
			name = "Cabin";
		}
		else if (zone == "zone_trans_9")
		{
			name = "Fog Before Town";
		}
		else if (zone == "zone_town_north")
		{
			name = "North Town";
		}
		else if (zone == "zone_tow")
		{
			name = "Center Town";
		}
		else if (zone == "zone_town_east")
		{
			name = "East Town";
		}
		else if (zone == "zone_town_west")
		{
			name = "West Town";
		}
		else if (zone == "zone_town_south")
		{
			name = "South Town";
		}
		else if (zone == "zone_bar")
		{
			name = "Bar";
		}
		else if (zone == "zone_town_barber")
		{
			name = "Bookstore";
		}
		else if (zone == "zone_ban")
		{
			name = "Bank";
		}
		else if (zone == "zone_ban_vault")
		{
			name = "Bank Vault";
		}
		else if (zone == "zone_tbu")
		{
			name = "Below Bank";
		}
		else if (zone == "zone_trans_11")
		{
			name = "Fog After Town";
		}
		else if (zone == "zone_amb_bridge")
		{
			name = "Bridge";
		}
		else if (zone == "zone_trans_1")
		{
			name = "Fog Before Bus Depot";
		}
	}
	else if (level.script == "zm_nuked")
	{
		if (zone == "culdesac_yellow_zone")
		{
			name = "Yellow House Middle";
		}
		else if (zone == "culdesac_green_zone")
		{
			name = "Green House Middle";
		}
		else if (zone == "truck_zone")
		{
			name = "Truck";
		}
		else if (zone == "openhouse1_f1_zone")
		{
			name = "Green House Downstairs";
		}
		else if (zone == "openhouse1_f2_zone")
		{
			name = "Green House Upstairs";
		}
		else if (zone == "openhouse1_backyard_zone")
		{
			name = "Green House Backyard";
		}
		else if (zone == "openhouse2_f1_zone")
		{
			name = "Yellow House Downstairs";
		}
		else if (zone == "openhouse2_f2_zone")
		{
			name = "Yellow House Upstairs";
		}
		else if (zone == "openhouse2_backyard_zone")
		{
			name = "Yellow House Backyard";
		}
		else if (zone == "ammo_door_zone")
		{
			name = "Yellow House Backyard Door";
		}
	}
	else if (level.script == "zm_highrise")
	{
		if (zone == "zone_green_start")
		{
			name = "Green Highrise Level 3b";
		}
		else if (zone == "zone_green_escape_pod")
		{
			name = "Escape Pod";
		}
		else if (zone == "zone_green_escape_pod_ground")
		{
			name = "Escape Pod Shaft";
		}
		else if (zone == "zone_green_level1")
		{
			name = "Green Highrise Level 3a";
		}
		else if (zone == "zone_green_level2a")
		{
			name = "Green Highrise Level 2a";
		}
		else if (zone == "zone_green_level2b")
		{
			name = "Green Highrise Level 2b";
		}
		else if (zone == "zone_green_level3a")
		{
			name = "Green Highrise Restaurant";
		}
		else if (zone == "zone_green_level3b")
		{
			name = "Green Highrise Level 1a";
		}
		else if (zone == "zone_green_level3c")
		{
			name = "Green Highrise Level 1b";
		}
		else if (zone == "zone_green_level3d")
		{
			name = "Green Highrise Behind Restaurant";
		}
		else if (zone == "zone_orange_level1")
		{
			name = "Upper Orange Highrise Level 2";
		}
		else if (zone == "zone_orange_level2")
		{
			name = "Upper Orange Highrise Level 1";
		}
		else if (zone == "zone_orange_elevator_shaft_top")
		{
			name = "Elevator Shaft Level 3";
		}
		else if (zone == "zone_orange_elevator_shaft_middle_1")
		{
			name = "Elevator Shaft Level 2";
		}
		else if (zone == "zone_orange_elevator_shaft_middle_2")
		{
			name = "Elevator Shaft Level 1";
		}
		else if (zone == "zone_orange_elevator_shaft_bottom")
		{
			name = "Elevator Shaft Bottom";
		}
		else if (zone == "zone_orange_level3a")
		{
			name = "Lower Orange Highrise Level 1a";
		}
		else if (zone == "zone_orange_level3b")
		{
			name = "Lower Orange Highrise Level 1b";
		}
		else if (zone == "zone_blue_level5")
		{
			name = "Lower Blue Highrise Level 1";
		}
		else if (zone == "zone_blue_level4a")
		{
			name = "Lower Blue Highrise Level 2a";
		}
		else if (zone == "zone_blue_level4b")
		{
			name = "Lower Blue Highrise Level 2b";
		}
		else if (zone == "zone_blue_level4c")
		{
			name = "Lower Blue Highrise Level 2c";
		}
		else if (zone == "zone_blue_level2a")
		{
			name = "Upper Blue Highrise Level 1a";
		}
		else if (zone == "zone_blue_level2b")
		{
			name = "Upper Blue Highrise Level 1b";
		}
		else if (zone == "zone_blue_level2c")
		{
			name = "Upper Blue Highrise Level 1c";
		}
		else if (zone == "zone_blue_level2d")
		{
			name = "Upper Blue Highrise Level 1d";
		}
		else if (zone == "zone_blue_level1a")
		{
			name = "Upper Blue Highrise Level 2a";
		}
		else if (zone == "zone_blue_level1b")
		{
			name = "Upper Blue Highrise Level 2b";
		}
		else if (zone == "zone_blue_level1c")
		{
			name = "Upper Blue Highrise Level 2c";
		}
	}
	else if (level.script == "zm_prison")
	{
		if (zone == "zone_start")
		{
			name = "D-Block";
		}
		else if (zone == "zone_library")
		{
			name = "Library";
		}
		else if (zone == "zone_cellblock_west")
		{
			name = "Cellblock 2nd Floor";
		}
		else if (zone == "zone_cellblock_west_gondola")
		{
			name = "Cellblock 3rd Floor";
		}
		else if (zone == "zone_cellblock_west_gondola_dock")
		{
			name = "Cellblock Gondola";
		}
		else if (zone == "zone_cellblock_west_barber")
		{
			name = "Michigan Avenue";
		}
		else if (zone == "zone_cellblock_east")
		{
			name = "Times Square";
		}
		else if (zone == "zone_cafeteria")
		{
			name = "Cafeteria";
		}
		else if (zone == "zone_cafeteria_end")
		{
			name = "Cafeteria End";
		}
		else if (zone == "zone_infirmary")
		{
			name = "Infirmary 1";
		}
		else if (zone == "zone_infirmary_roof")
		{
			name = "Infirmary 2";
		}
		else if (zone == "zone_roof_infirmary")
		{
			name = "Roof 1";
		}
		else if (zone == "zone_roof")
		{
			name = "Roof 2";
		}
		else if (zone == "zone_cellblock_west_warden")
		{
			name = "Sally Port";
		}
		else if (zone == "zone_warden_office")
		{
			name = "Warden's Office";
		}
		else if (zone == "cellblock_shower")
		{
			name = "Showers";
		}
		else if (zone == "zone_citadel_shower")
		{
			name = "Citadel To Showers";
		}
		else if (zone == "zone_citadel")
		{
			name = "Citadel";
		}
		else if (zone == "zone_citadel_warden")
		{
			name = "Citadel To Warden's Office";
		}
		else if (zone == "zone_citadel_stairs")
		{
			name = "Citadel Tunnels";
		}
		else if (zone == "zone_citadel_basement")
		{
			name = "Citadel Basement";
		}
		else if (zone == "zone_citadel_basement_building")
		{
			name = "China Alley";
		}
		else if (zone == "zone_studio")
		{
			name = "Building 64";
		}
		else if (zone == "zone_dock")
		{
			name = "Docks";
		}
		else if (zone == "zone_dock_puzzle")
		{
			name = "Docks Gates";
		}
		else if (zone == "zone_dock_gondola")
		{
			name = "Upper Docks";
		}
		else if (zone == "zone_golden_gate_bridge")
		{
			name = "Golden Gate Bridge";
		}
		else if (zone == "zone_gondola_ride")
		{
			name = "Gondola";
		}
	}
	else if (level.script == "zm_buried")
	{
		if (zone == "zone_start")
		{
			name = "Processing";
		}
		else if (zone == "zone_start_lower")
		{
			name = "Lower Processing";
		}
		else if (zone == "zone_tunnels_center")
		{
			name = "Center Tunnels";
		}
		else if (zone == "zone_tunnels_north")
		{
			name = "Courthouse Tunnels 2";
		}
		else if (zone == "zone_tunnels_north2")
		{
			name = "Courthouse Tunnels 1";
		}
		else if (zone == "zone_tunnels_south")
		{
			name = "Saloon Tunnels 3";
		}
		else if (zone == "zone_tunnels_south2")
		{
			name = "Saloon Tunnels 2";
		}
		else if (zone == "zone_tunnels_south3")
		{
			name = "Saloon Tunnels 1";
		}
		else if (zone == "zone_street_lightwest")
		{
			name = "Outside General Store & Bank";
		}
		else if (zone == "zone_street_lightwest_alley")
		{
			name = "Outside General Store & Bank Alley";
		}
		else if (zone == "zone_morgue_upstairs")
		{
			name = "Morgue";
		}
		else if (zone == "zone_underground_jail")
		{
			name = "Jail Downstairs";
		}
		else if (zone == "zone_underground_jail2")
		{
			name = "Jail Upstairs";
		}
		else if (zone == "zone_general_store")
		{
			name = "General Store";
		}
		else if (zone == "zone_stables")
		{
			name = "Stables";
		}
		else if (zone == "zone_street_darkwest")
		{
			name = "Outside Gunsmith";
		}
		else if (zone == "zone_street_darkwest_nook")
		{
			name = "Outside Gunsmith Nook";
		}
		else if (zone == "zone_gun_store")
		{
			name = "Gunsmith";
		}
		else if (zone == "zone_bank")
		{
			name = "Bank";
		}
		else if (zone == "zone_tunnel_gun2stables")
		{
			name = "Stables To Gunsmith Tunnel 2";
		}
		else if (zone == "zone_tunnel_gun2stables2")
		{
			name = "Stables To Gunsmith Tunnel";
		}
		else if (zone == "zone_street_darkeast")
		{
			name = "Outside Saloon & Toy Store";
		}
		else if (zone == "zone_street_darkeast_nook")
		{
			name = "Outside Saloon & Toy Store Nook";
		}
		else if (zone == "zone_underground_bar")
		{
			name = "Saloon";
		}
		else if (zone == "zone_tunnel_gun2saloon")
		{
			name = "Saloon To Gunsmith Tunnel";
		}
		else if (zone == "zone_toy_store")
		{
			name = "Toy Store Downstairs";
		}
		else if (zone == "zone_toy_store_floor2")
		{
			name = "Toy Store Upstairs";
		}
		else if (zone == "zone_toy_store_tunnel")
		{
			name = "Toy Store Tunnel";
		}
		else if (zone == "zone_candy_store")
		{
			name = "Candy Store Downstairs";
		}
		else if (zone == "zone_candy_store_floor2")
		{
			name = "Candy Store Upstairs";
		}
		else if (zone == "zone_street_lighteast")
		{
			name = "Outside Courthouse & Candy Store";
		}
		else if (zone == "zone_underground_courthouse")
		{
			name = "Courthouse Downstairs";
		}
		else if (zone == "zone_underground_courthouse2")
		{
			name = "Courthouse Upstairs";
		}
		else if (zone == "zone_street_fountain")
		{
			name = "Fountain";
		}
		else if (zone == "zone_church_graveyard")
		{
			name = "Graveyard";
		}
		else if (zone == "zone_church_main")
		{
			name = "Church Downstairs";
		}
		else if (zone == "zone_church_upstairs")
		{
			name = "Church Upstairs";
		}
		else if (zone == "zone_mansion_lawn")
		{
			name = "Mansion Lawn";
		}
		else if (zone == "zone_mansion")
		{
			name = "Mansion";
		}
		else if (zone == "zone_mansion_backyard")
		{
			name = "Mansion Backyard";
		}
		else if (zone == "zone_maze")
		{
			name = "Maze";
		}
		else if (zone == "zone_maze_staircase")
		{
			name = "Maze Staircase";
		}
	}
	else if (level.script == "zm_tomb")
	{
		if (isDefined(self.teleporting) && self.teleporting)
		{
			return "";
		}

		if (zone == "zone_start")
		{
			name = "Lower Laboratory";
		}
		else if (zone == "zone_start_a")
		{
			name = "Upper Laboratory";
		}
		else if (zone == "zone_start_b")
		{
			name = "Generator 1";
		}
		else if (zone == "zone_bunker_1a")
		{
			name = "Generator 3 Bunker 1";
		}
		else if (zone == "zone_fire_stairs")
		{
			name = "Fire Tunnel";
		}
		else if (zone == "zone_bunker_1")
		{
			name = "Generator 3 Bunker 2";
		}
		else if (zone == "zone_bunker_3a")
		{
			name = "Generator 3";
		}
		else if (zone == "zone_bunker_3b")
		{
			name = "Generator 3 Bunker 3";
		}
		else if (zone == "zone_bunker_2a")
		{
			name = "Generator 2 Bunker 1";
		}
		else if (zone == "zone_bunker_2")
		{
			name = "Generator 2 Bunker 2";
		}
		else if (zone == "zone_bunker_4a")
		{
			name = "Generator 2";
		}
		else if (zone == "zone_bunker_4b")
		{
			name = "Generator 2 Bunker 3";
		}
		else if (zone == "zone_bunker_4c")
		{
			name = "Tank Station";
		}
		else if (zone == "zone_bunker_4d")
		{
			name = "Above Tank Station";
		}
		else if (zone == "zone_bunker_tank_c")
		{
			name = "Generator 2 Tank Route 1";
		}
		else if (zone == "zone_bunker_tank_c1")
		{
			name = "Generator 2 Tank Route 2";
		}
		else if (zone == "zone_bunker_4e")
		{
			name = "Generator 2 Tank Route 3";
		}
		else if (zone == "zone_bunker_tank_d")
		{
			name = "Generator 2 Tank Route 4";
		}
		else if (zone == "zone_bunker_tank_d1")
		{
			name = "Generator 2 Tank Route 5";
		}
		else if (zone == "zone_bunker_4f")
		{
			name = "zone_bunker_4f";
		}
		else if (zone == "zone_bunker_5a")
		{
			name = "Workshop Downstairs";
		}
		else if (zone == "zone_bunker_5b")
		{
			name = "Workshop Upstairs";
		}
		else if (zone == "zone_nml_2a")
		{
			name = "No Man's Land Walkway";
		}
		else if (zone == "zone_nml_2")
		{
			name = "No Man's Land Entrance";
		}
		else if (zone == "zone_bunker_tank_e")
		{
			name = "Generator 5 Tank Route 1";
		}
		else if (zone == "zone_bunker_tank_e1")
		{
			name = "Generator 5 Tank Route 2";
		}
		else if (zone == "zone_bunker_tank_e2")
		{
			name = "zone_bunker_tank_e2";
		}
		else if (zone == "zone_bunker_tank_f")
		{
			name = "Generator 5 Tank Route 3";
		}
		else if (zone == "zone_nml_1")
		{
			name = "Generator 5 Tank Route 4";
		}
		else if (zone == "zone_nml_4")
		{
			name = "Generator 5 Tank Route 5";
		}
		else if (zone == "zone_nml_0")
		{
			name = "Generator 5 Left Footstep";
		}
		else if (zone == "zone_nml_5")
		{
			name = "Generator 5 Right Footstep Walkway";
		}
		else if (zone == "zone_nml_farm")
		{
			name = "Generator 5";
		}
		else if (zone == "zone_nml_celllar")
		{
			name = "Generator 5 Cellar";
		}
		else if (zone == "zone_bolt_stairs")
		{
			name = "Lightning Tunnel";
		}
		else if (zone == "zone_nml_3")
		{
			name = "No Man's Land 1st Right Footstep";
		}
		else if (zone == "zone_nml_2b")
		{
			name = "No Man's Land Stairs";
		}
		else if (zone == "zone_nml_6")
		{
			name = "No Man's Land Left Footstep";
		}
		else if (zone == "zone_nml_8")
		{
			name = "No Man's Land 2nd Right Footstep";
		}
		else if (zone == "zone_nml_10a")
		{
			name = "Generator 4 Tank Route 1";
		}
		else if (zone == "zone_nml_10")
		{
			name = "Generator 4 Tank Route 2";
		}
		else if (zone == "zone_nml_7")
		{
			name = "Generator 4 Tank Route 3";
		}
		else if (zone == "zone_bunker_tank_a")
		{
			name = "Generator 4 Tank Route 4";
		}
		else if (zone == "zone_bunker_tank_a1")
		{
			name = "Generator 4 Tank Route 5";
		}
		else if (zone == "zone_bunker_tank_a2")
		{
			name = "zone_bunker_tank_a2";
		}
		else if (zone == "zone_bunker_tank_b")
		{
			name = "Generator 4 Tank Route 6";
		}
		else if (zone == "zone_nml_9")
		{
			name = "Generator 4 Left Footstep";
		}
		else if (zone == "zone_air_stairs")
		{
			name = "Wind Tunnel";
		}
		else if (zone == "zone_nml_11")
		{
			name = "Generator 4";
		}
		else if (zone == "zone_nml_12")
		{
			name = "Generator 4 Right Footstep";
		}
		else if (zone == "zone_nml_16")
		{
			name = "Excavation Site Front Path";
		}
		else if (zone == "zone_nml_17")
		{
			name = "Excavation Site Back Path";
		}
		else if (zone == "zone_nml_18")
		{
			name = "Excavation Site Level 3";
		}
		else if (zone == "zone_nml_19")
		{
			name = "Excavation Site Level 2";
		}
		else if (zone == "ug_bottom_zone")
		{
			name = "Excavation Site Level 1";
		}
		else if (zone == "zone_nml_13")
		{
			name = "Generator 5 To Generator 6 Path";
		}
		else if (zone == "zone_nml_14")
		{
			name = "Generator 4 To Generator 6 Path";
		}
		else if (zone == "zone_nml_15")
		{
			name = "Generator 6 Entrance";
		}
		else if (zone == "zone_village_0")
		{
			name = "Generator 6 Left Footstep";
		}
		else if (zone == "zone_village_5")
		{
			name = "Generator 6 Tank Route 1";
		}
		else if (zone == "zone_village_5a")
		{
			name = "Generator 6 Tank Route 2";
		}
		else if (zone == "zone_village_5b")
		{
			name = "Generator 6 Tank Route 3";
		}
		else if (zone == "zone_village_1")
		{
			name = "Generator 6 Tank Route 4";
		}
		else if (zone == "zone_village_4b")
		{
			name = "Generator 6 Tank Route 5";
		}
		else if (zone == "zone_village_4a")
		{
			name = "Generator 6 Tank Route 6";
		}
		else if (zone == "zone_village_4")
		{
			name = "Generator 6 Tank Route 7";
		}
		else if (zone == "zone_village_2")
		{
			name = "Church";
		}
		else if (zone == "zone_village_3")
		{
			name = "Generator 6 Right Footstep";
		}
		else if (zone == "zone_village_3a")
		{
			name = "Generator 6";
		}
		else if (zone == "zone_ice_stairs")
		{
			name = "Ice Tunnel";
		}
		else if (zone == "zone_bunker_6")
		{
			name = "Above Generator 3 Bunker";
		}
		else if (zone == "zone_nml_20")
		{
			name = "Above No Man's Land";
		}
		else if (zone == "zone_village_6")
		{
			name = "Behind Church";
		}
		else if (zone == "zone_chamber_0")
		{
			name = "The Crazy Place Lightning Chamber";
		}
		else if (zone == "zone_chamber_1")
		{
			name = "The Crazy Place Lightning & Ice";
		}
		else if (zone == "zone_chamber_2")
		{
			name = "The Crazy Place Ice Chamber";
		}
		else if (zone == "zone_chamber_3")
		{
			name = "The Crazy Place Fire & Lightning";
		}
		else if (zone == "zone_chamber_4")
		{
			name = "The Crazy Place Center";
		}
		else if (zone == "zone_chamber_5")
		{
			name = "The Crazy Place Ice & Wind";
		}
		else if (zone == "zone_chamber_6")
		{
			name = "The Crazy Place Fire Chamber";
		}
		else if (zone == "zone_chamber_7")
		{
			name = "The Crazy Place Wind & Fire";
		}
		else if (zone == "zone_chamber_8")
		{
			name = "The Crazy Place Wind Chamber";
		}
		else if (zone == "zone_robot_head")
		{
			name = "Robot's Head";
		}
	}

	return name;
}
