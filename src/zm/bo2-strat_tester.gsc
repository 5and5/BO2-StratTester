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
            level thread set_starting_round( 70 );
        }
    }
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