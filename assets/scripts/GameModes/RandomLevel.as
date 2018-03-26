[GameMode]
class RandomLevel : Campaign
{
	EnemyPlacement@ m_enemyPlacer;

	RandomLevel(Scene@ scene)
	{
		super(scene);
	}
	
	void Generate(SValue@ save)
	{
		int shortcut = 0;
		int numPlrs = 1;
		if (save !is null)
		{
			m_levelCount = GetParamInt(UnitPtr(), save, "level-count", false, GetVarInt("g_start_level"));
			m_fountainEffects = FountainEffect(GetParamInt(UnitPtr(), save, "fountain-effects", false, 0));
			shortcut = GetParamInt(UnitPtr(), save, "shortcut", false, 0);
			numPlrs = GetParamInt(UnitPtr(), save, "num-plrs", false, 1);
			g_ngp = GetParamInt(UnitPtr(), save, "ngp", false, 0);
		}
		else
			m_levelCount = GetVarInt("g_start_level");
		
		auto townSave = LoadHostTown();
		auto arrFlags = GetParamArray(UnitPtr(), townSave, "flags", false);
		if (arrFlags !is null)
		{
			for (uint i = 0; i < arrFlags.length(); i++)
				g_flags.Set(arrFlags[i].GetString(), FlagState::Town);
		}
		
		print("NewGame+ " +g_ngp);
		GenerateDungeon(this, m_levelCount, shortcut, numPlrs);
	}
	
	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		if (sMode != StartMode::LoadGame)
			m_useSpawnLogic = false;
	
		Campaign::Start(peer, save, sMode);

		for (uint i = 0; i < g_prefabsToSpawn.length(); i++)
			g_prefabsToSpawn[i].m_pfb.Fabricate(g_scene, g_prefabsToSpawn[i].m_pos);
		
		g_prefabsToSpawn.removeRange(0, g_prefabsToSpawn.length());

		Campaign::PostStart();

		if (m_levelCount == 0)
		{
			auto record = GetLocalPlayerRecord();
			Stats::AddAvg("time-played-run", record);
			Stats::AddAvg("avg-exp-gained", record);
			Stats::AddAvg("avg-levels-gained", record);
			Stats::AddAvg("avg-items-picked", record);
			Stats::AddAvg("avg-gold-found", record);
			Stats::AddAvg("avg-ore-found", record);
			Stats::Add("total-runs", 1, record);
			
			record.hp = 1.0f;
			record.mana = 1.0f;
			record.potionChargesUsed = 0;
		}

		Stats::Add("floors-visited", 1);
	}
	
	/*
	void UpdateFrame(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		Campaign::UpdateFrame(ms, gameInput, menuInput);
	}
	*/
}
