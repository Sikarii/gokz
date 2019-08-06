#include <sourcemod>

#include <geoip>

#include <gokz/core>
#include <gokz/localdb>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <updater>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "GOKZ Local DB", 
	author = "DanZay", 
	description = "Provides database for players, maps, courses and times", 
	version = GOKZ_VERSION, 
	url = "https://bitbucket.org/kztimerglobalteam/gokz"
};

#define UPDATER_URL GOKZ_UPDATER_BASE_URL..."gokz-localdb.txt"

Database gH_DB = null;
DatabaseType g_DBType = DatabaseType_None;
bool gB_ClientSetUp[MAXPLAYERS + 1];
bool gB_Cheater[MAXPLAYERS + 1];
bool gB_MapSetUp;
int gI_DBCurrentMapID;

#include "gokz-localdb/api.sp"
#include "gokz-localdb/commands.sp"

#include "gokz-localdb/db/sql.sp"
#include "gokz-localdb/db/helpers.sp"
#include "gokz-localdb/db/create_tables.sp"
#include "gokz-localdb/db/save_time.sp"
#include "gokz-localdb/db/set_cheater.sp"
#include "gokz-localdb/db/setup_client.sp"
#include "gokz-localdb/db/setup_database.sp"
#include "gokz-localdb/db/setup_map.sp"
#include "gokz-localdb/db/setup_map_courses.sp"



// =====[ PLUGIN EVENTS ]=====

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNatives();
	RegPluginLibrary("gokz-localdb");
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateGlobalForwards();
	RegisterCommands();
}

public void OnAllPluginsLoaded()
{
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
	
	DB_SetupDatabase();
	
	char auth[32];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientAuthorized(client) && GetClientAuthId(client, AuthId_Engine, auth, sizeof(auth)))
		{
			OnClientAuthorized(client, auth);
		}
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATER_URL);
	}
}



// =====[ OTHER EVENTS ]=====

public void OnConfigsExecuted()
{
	DB_SetupMap();
}

public void GOKZ_DB_OnMapSetup(int mapID)
{
	DB_SetupMapCourses();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	DB_SetupClient(client);
}

public void OnClientDisconnect(int client)
{
	gB_ClientSetUp[client] = false;
}

public void GOKZ_OnCourseRegistered(int course)
{
	if (gB_MapSetUp)
	{
		DB_SetupMapCourse(course);
	}
}

public void GOKZ_OnTimerEnd_Post(int client, int course, float time, int teleportsUsed)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int style = GOKZ_GetCoreOption(client, Option_Style);
	DB_SaveTime(client, course, mode, style, time, teleportsUsed);
} 