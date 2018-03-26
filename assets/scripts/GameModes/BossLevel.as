[GameMode]
class BossLevel : Campaign
{
	BossLevel(Scene@ scene)
	{
		super(scene);
	}

	// TODO: Delete this (USE_MULTIPLAYER)
	void Generate(SValue@ save) {}

	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		Campaign::Start(peer, save, sMode);
		SetLevelFlags(m_levelCount);
		Campaign::PostStart();
		Stats::Add("floors-visited", 1);
		
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;
				
			if (g_players[i].hp > 0)
			{
				g_players[i].hp = 1;
				g_players[i].mana = 1;
			}
		}
	}
}
