bool g_isTown = false;

[GameMode]
class Town : Campaign
{
	int m_usedFountain;

	string m_upgradedBuildingName;

	array<StatueBehavior@> m_statueUnits;

	UserWindow@ m_introWindow;

	Town(Scene@ scene)
	{
		super(scene);

		m_userWindows.insertLast(@m_introWindow = UserWindow(m_guiBuilder, "gui/intro.gui"));
	}
	
	// TODO: Delete this (USE_MULTIPLAYER)
	void Generate(SValue@ save) {}

	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		g_isTown = true;

		Campaign::Start(peer, save, sMode);
		Campaign::PostStart();

		m_timePlayedDungeonPrev = m_timePlayedDungeon;
		m_timePlayedDungeon = 0;
		
		m_levelCount = GetVarInt("g_start_level");

		int reputation = m_townLocal.GetReputation();
		int reputationRun = reputation - m_townLocal.m_reputationPresented;
		while (reputationRun > 0)
		{
			auto title = m_townLocal.GetTitle();
			auto titleNext = m_townLocal.GetNextTitle();
			int giveRep = titleNext.m_points - title.m_points;
			if (reputationRun < giveRep)
				break;

			m_townLocal.OnNewTitle(titleNext);
			m_townLocal.m_reputationPresented += giveRep;
			reputationRun -= giveRep;
		}
		m_townLocal.m_reputationPresented = reputation;

		SpawnBuildings();
		SpawnStatues();

		if (save !is null)
		{
			auto arrPlayerPos = GetParamArray(UnitPtr(), save, "town-player-pos", false);
			if (arrPlayerPos !is null)
			{
				for (uint i = 0; i < arrPlayerPos.length(); i += 2)
				{
					int posPeer = arrPlayerPos[i].GetInteger();
					vec3 pos = arrPlayerPos[i + 1].GetVector3();

					auto record = GetPlayerRecordByPeer(posPeer);
					if (record !is null && record.actor !is null)
						record.actor.m_unit.SetPosition(pos);
				}
			}
		}

		auto localRecord = GetLocalPlayerRecord();
		if (!g_flags.IsSet("unlock_apothecary"))
			localRecord.potionChargesUsed = 1;

		if (GetVarBool("ui_show_intro"))
		{
			SetVar("ui_show_intro", false);
			Config::SaveVar("ui_show_intro", "0");
			m_introWindow.Show();
		}

		Lobby::SetJoinable(true);
		CheckForAchievements();
	}
	
	void CheckForAchievements()
	{
		if (m_townLocal.GetBuilding("tavern").m_level >= 1)
			Platform::Service.UnlockAchievement("class_thief");
		if (m_townLocal.GetBuilding("chapel").m_level >= 1)
			Platform::Service.UnlockAchievement("class_priest");
		if (m_townLocal.GetBuilding("magicshop").m_level >= 1)
			Platform::Service.UnlockAchievement("class_wizard");

		if (m_townLocal.m_bossesKilled[0] != 0)
			Platform::Service.UnlockAchievement("beat_stone_guardian");
		if (m_townLocal.m_bossesKilled[1] != 0)
			Platform::Service.UnlockAchievement("beat_warden");
		if (m_townLocal.m_bossesKilled[2] != 0)
			Platform::Service.UnlockAchievement("beat_three_councilors");
		if (m_townLocal.m_bossesKilled[3] != 0)
			Platform::Service.UnlockAchievement("beat_watcher");
		if (m_townLocal.m_bossesKilled[4] != 0)
		{
			Platform::Service.UnlockAchievement("beat_thundersnow");
			Platform::Service.UnlockAchievement("beat_forsaken_tower");
		}
		
		if (g_flags.Get("unlock_combo") == FlagState::Town)
			Platform::Service.UnlockAchievement("combo");
		
		auto arrCharacters = GetCharacters();
		for (uint i = 0; i < arrCharacters.length(); i++)
		{
			auto svChar = arrCharacters[i];

			int level = GetParamInt(UnitPtr(), svChar, "level");
			string charClass = GetParamString(UnitPtr(), svChar, "class");
			int ngp = GetParamInt(UnitPtr(), svChar, "new-game-plus", false);
			
			if (level >= 20)
				Platform::Service.UnlockAchievement("level20_" + charClass);
			if (level >= 40)
				Platform::Service.UnlockAchievement("level40_" + charClass);
			if (ngp > 1)
				Platform::Service.UnlockAchievement("beat_forsaken_tower_ng");
			if (ngp > 2)
				Platform::Service.UnlockAchievement("beat_forsaken_tower_ng2");
			if (ngp > 3)
				Platform::Service.UnlockAchievement("beat_forsaken_tower_ng3");
			if (ngp > 4)
				Platform::Service.UnlockAchievement("beat_forsaken_tower_ng4");
			if (ngp > 5)
				Platform::Service.UnlockAchievement("beat_forsaken_tower_ng5");
		}
		
		if (m_townLocal.GetBuilding("townhall").m_level >= 5 &&
			m_townLocal.GetBuilding("treasury").m_level >= 4 &&
			m_townLocal.GetBuilding("guildhall").m_level >= 5 &&
			m_townLocal.GetBuilding("generalstore").m_level >= 5 &&
			m_townLocal.GetBuilding("blacksmith").m_level >= 5 &&
			m_townLocal.GetBuilding("oretrader").m_level >= 3 &&
			m_townLocal.GetBuilding("apothecary").m_level >= 3 &&
			m_townLocal.GetBuilding("fountain").m_level >= 2 &&
			m_townLocal.GetBuilding("chapel").m_level >= 3 &&
			m_townLocal.GetBuilding("tavern").m_level >= 1 &&
			m_townLocal.GetBuilding("magicshop").m_level >= 3)
			Platform::Service.UnlockAchievement("town_restored");
	}
	
	void Save(SValueBuilder& builder) override
	{
		Campaign::Save(builder);

		builder.PushArray("town-player-pos");
		for (uint i = 0; i < g_players.length(); i++)
		{
			auto player = g_players[i];
			if (player.actor is null || player.peer == 255)
				continue;

			builder.PushInteger(player.peer);
			builder.PushVector3(player.actor.m_unit.GetPosition());
		}
		builder.PopArray();
	}

	void OnExitGame() override
	{
		SaveLocalTown();
		auto record = GetLocalPlayerRecord();
		SavePlayer(record, false);
	}
	
	void SpawnBuildings()
	{
		if (!Network::IsServer())
			return;

		auto res = g_scene.FetchAllWorldScripts("SpawnTownBuilding");
		for (uint i = 0; i < res.length(); i++)
		{
			auto spawn = cast<WorldScript::SpawnTownBuilding>(res[i].GetUnit().GetScriptBehavior());
			auto building = m_town.GetBuilding(spawn.TypeName);

			auto prefab = building.GetPrefab();
			if (prefab is null)
			{
				PrintError("Couldn't find prefab for '" + building.m_typeName + "' for level " + building.m_level);
				continue;
			}

			prefab.Fabricate(g_scene, spawn.Position);
		}
	}

	void SpawnStatues()
	{
		if (Network::IsServer())
		{
			auto res = g_scene.FetchAllWorldScripts("SpawnTownStatue");
			for (uint i = 0; i < res.length(); i++)
			{
				auto scriptUnit = res[i].GetUnit();
				auto prod = Resources::GetUnitProducer("doodads/statue.unit");

				UnitPtr unit = prod.Produce(g_scene, scriptUnit.GetPosition());

				m_statueUnits.insertLast(cast<StatueBehavior>(unit.GetScriptBehavior()));
			}
		}

		SetStatues();
	}

	void SetStatues()
	{
		for (int i = 0; i < min(m_statueUnits.length(), m_town.m_statuePlacements.length()); i++)
		{
			TownStatue@ statue = m_town.GetStatue(m_town.m_statuePlacements[i]);
			//TODO: Properly netsync this
			m_statueUnits[i].SetStatue(statue);
		}
	}
	
	void SavePlayer(SValueBuilder& builder, PlayerRecord& player) override
	{
		Campaign::SavePlayer(builder, player);
		builder.PushBoolean("in-town", true);
	}

	void LoadPlayer(SValue& data, PlayerRecord& player) override
	{
		Campaign::LoadPlayer(data, player);

		player.statisticsSession.Clear();
		
		if (player.local && !GetParamBool(UnitPtr(), data, "in-town", false, false))
			OnRunEnd(true);

		player.hp = 1;
		player.mana = 1;
		player.potionChargesUsed = 0;
		player.runGold = 0;
		player.runOre = 0;
	}

	string GetPlayerDisplayName(PlayerRecord@ record) override
	{
		return Resources::GetString(record.GetTitle().m_name) + "\n" + Campaign::GetPlayerDisplayName(record);
	}
}
