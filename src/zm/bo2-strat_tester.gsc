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
	level.start_round = 100; // what round the game starts at
	level.power_on = 1; // turns power on
	level.perks_on_revive = 1 // give perks back on revive
	level.perks_on_spawn = 1 // give perks on spawn

	// HUD
	level.hud_timer = 1; // total game timer
	level.hud_round_timer = 1; // round timer
}

main()
{
	// Pluto only
    // replaceFunc( maps/mp/zombies/_zm_powerups::powerup_drop, ::powerup_drop_override );
}

init()
{
	level.STRAT_TESTER_VERSION = "0.2";
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
                self give_perk("specialty_longersprint", 0);
                wait 0.15;
                self give_perk("specialty_rof", 0);
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
