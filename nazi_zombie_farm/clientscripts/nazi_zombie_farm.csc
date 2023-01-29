#include clientscripts\_utility;
#include clientscripts\_music;
#include clientscripts\_fx;

main()
{
	level.DLC3_Client = spawnStruct(); // Leave This Line Or Else It Breaks Everything

	// Must Change These For Your Map
	level.DLC3_Client.createFX = clientscripts\createfx\nazi_zombie_farm_fx::main;
	level.DLC3_Client.myFX = ::preCacheMyFX; 

	clientscripts\_load::main();

	println("Registering zombify");
	clientscripts\_utility::registerSystem("zombify", clientscripts\dlc3_code::zombifyHandler);

	clientscripts\dlc3_teleporter::main();
	
	clientscripts\dlc3_code::DLC3_FX();
	
	clientscripts\_zombiemode_tesla::init();

	thread clientscripts\_audio::audio_init(0);

	// Change For Your Map!
	thread clientscripts\nazi_zombie_farm_amb::main();

	level._zombieCBFunc = clientscripts\_zombie_mode::zombie_eyes;
	
	thread waitforclient(0);

	println("*** Client : zombie running...or is it chasing? Muhahahaha");	
}

preCacheMyFX()
{
	// LEVEL SPECIFIC - FEEL FREE TO REMOVE/EDIT
	
	level._effect["snow_thick"]	= LoadFx( "env/weather/fx_snow_blizzard_intense" );
}