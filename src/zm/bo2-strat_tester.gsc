#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;

main()
{
    // replaceFunc( maps/mp/zombies/_zm_powerups::powerup_drop, ::powerup_drop_override );
}

init()
{
    level.init = 0;
    level thread onConnect();
}

onConnect()
{
    for (;;)
    {
        level waittill("connected", player);
        player thread connected();
    }
}

connected()
{
    self endon("disconnect");
    self.init = 0;

    for(;;)
    {
        self waittill("spawned_player");

        if(!self.init)
        {
            self.init = 1;
        }

        if(!level.init)
        {
            level.init = 1;

            enable_cheats();

            level thread turnOnPower();
            level thread set_starting_round( 70 );
        }
    }
}

enable_cheats()
{
    setDvar( "sv_cheats", 1 );
	setDvar( "cg_ufo_scaler", 0.7 );
	level.player_out_of_playable_area_monitor = 0;
}

turnOnPower() //by xepixtvx
{	
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

set_starting_round( round )
{
	flag_wait( "start_zombie_round_logic" );
	wait 0.05;

	if( getDvar( "start_round" ) == "")
		setDvar( "start_round", round );

	level.first_round = false;
	level.zombie_vars[ "zombie_spawn_delay" ] = 0.08;
	level.round_number = getDvarInt( "start_round" );
}