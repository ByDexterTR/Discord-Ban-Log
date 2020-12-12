#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

ConVar webhook = null;

public Plugin myinfo = 
{
	name = "Discord Ban LOG", 
	author = "phiso - ByDexter", 
	description = "Banlanan oyuncuları ve banlayan yetkiliyi discorda aktarır.", 
	version = "1.1", 
	url = "phiso#3331"
};

public void OnPluginStart()
{
	webhook = CreateConVar("sm_banlog_webhook", "WEBHOOK", "Discord Kanal Webhooku");
	AutoExecConfig(true, "Discord-BanLog");
}

public Action OnBanClient(int client, int time, int flags, const char[] reason, const char[] kick_message, const char[] command, any source)
{
	char clientsteamid[64], yetkilisteamid[64], mesaj[2048];
	GetClientAuthId(source, AuthId_Steam2, yetkilisteamid, sizeof(yetkilisteamid));
	GetClientAuthId(client, AuthId_Steam2, clientsteamid, sizeof(clientsteamid));

	if (time > 0)
		Format(mesaj, sizeof(mesaj), "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n> **:star: Yeni Bir Yasaklama :star:**\n> ```ini\n> [ Yetkili ] : %N - %s\n> [ Oyuncu ] : %N - %s\n> [ Süre ] : %d Dakika\n> [ Sebep ] : %s```", source, yetkilisteamid, client, clientsteamid, time, reason);
	else if (time <= 0)
		Format(mesaj, sizeof(mesaj), "▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n> **:star: Yeni Bir Yasaklama :star:**\n> ```ini\n> [ Yetkili ] : %N - %s\n> [ Oyuncu ] : %N - %s\n> [ Süre ] : Kalıcı\n> [ Sebep ] : %s```", source, yetkilisteamid, client, clientsteamid, reason);
	
	SendToDiscord(mesaj);
}
public void SendToDiscord(const char[] message)
{
	char Api[256];
	GetConVarString(webhook, Api, sizeof(Api));
	
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, Api);
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "content", message);
	SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/x-www-form-urlencoded");
	
	if (request == null || !SteamWorks_SetHTTPCallbacks(request, Callback_SendToDiscord) || !SteamWorks_SendHTTPRequest(request))
	{
		PrintToServer("[ban_log] ! HATA !");
		delete request;
	}
	else
		PrintToServer("[ban_log] Ban bilgisi discorda aktarma basarili!");
}

public int Callback_SendToDiscord(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if (!bFailure && bRequestSuccessful)
	{
		if (eStatusCode != k_EHTTPStatusCode200OK && eStatusCode != k_EHTTPStatusCode204NoContent)
		{
			LogError("[ban_log] HATA BULUNDU - Kod: [%i]", eStatusCode);
			SteamWorks_GetHTTPResponseBodyCallback(hRequest, Callback_Response);
		}
	}
	delete hRequest;
}

public int Callback_Response(const char[] sData)
{
	PrintToServer("[ban_log] %s", sData);
}
