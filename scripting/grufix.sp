#include <sourcemod>

int g_Offset;
int g_PrevAbsFrameTime[MAXPLAYERS+1][2];

public void OnPluginStart()
{
	GameData gamedata = LoadGameConfigFile("tf2.grufix");
	if (!gamedata)
		SetFailState("Could not load tf2.grufix gamedata!");
	
	// Note that CTFPlayer.m_dLastAbsoluteFrameTime is just a label for the offset that i came up with
	g_Offset = gamedata.GetOffset("CTFPlayer.m_dLastAbsoluteFrameTime");
	if (!g_Offset)
		SetFailState("Could not get CTFPlayer.m_dLastAbsoluteFrameTime!");
	
	delete gamedata;
	
	CreateTimer(1.0, Timer_CheckAbsFrameTimes, _, TIMER_REPEAT);
}

public Action Timer_CheckAbsFrameTimes(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Address entaddr = GetEntityAddress(i);
			
			int current[2];
			current[0] = LoadFromAddress(entaddr+view_as<Address>(g_Offset+4), NumberType_Int32);
			current[1] = LoadFromAddress(entaddr+view_as<Address>(g_Offset), NumberType_Int32);
			
			// Check if CTFPlayer.m_dLastAbsoluteFrameTime is equal to -1.0
			if (current[0] != 0xBFF00000 && current[1] != 0x00000000)
			{
				// Check if CTFPlayer.m_dLastAbsoluteFrameTime is equal to the value it had 1 second ago
				// (Normally the value of CTFPlayer.m_dLastAbsoluteFrameTime is either -1.0 or different every frame)
				if (current[0] == g_PrevAbsFrameTime[i][0] && current[1] == g_PrevAbsFrameTime[i][1])
				{
					// If it is, set CTFPlayer.m_dLastAbsoluteFrameTime to -1.0 and prevent shit from hitting the fan
					StoreToAddress(entaddr+view_as<Address>(g_Offset+4), 0xBFF00000, NumberType_Int32);
					StoreToAddress(entaddr+view_as<Address>(g_Offset), 0x00000000, NumberType_Int32);
				}
			}
			
			g_PrevAbsFrameTime[i][0] = current[0];
			g_PrevAbsFrameTime[i][1] = current[1];
		}
	}
}