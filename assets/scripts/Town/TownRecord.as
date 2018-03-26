class BestiaryEntry
{
	uint m_type;
	int m_kills;
	int m_killer;
	UnitProducer@ m_producer;
	
	BestiaryEntry(UnitProducer@ producer, int kills, int killer)
	{
		@m_producer = producer;
		m_kills = kills;
		m_killer = killer;
		
		auto params = m_producer.GetBehaviorParams();
		m_type = HashString(GetParamString(UnitPtr(), params, "type", false));
	}
}

class ItemiaryEntry
{
	int m_count;
	ActorItem@ m_item;
	
	ItemiaryEntry(ActorItem@ item, int count)
	{
		@m_item = item;
		m_count = count;
	}
}

class TownRecord
{
	bool m_local;

	array<TownBuilding@> m_buildings;

	array<TownStatue@> m_statues;
	array<string> m_statuePlacements;
	array<BestiaryEntry@> m_bestiary;
	array<ItemiaryEntry@> m_itemiary;

	Stats::StatList@ m_statistics;

	pint m_gold;
	pint m_ore;

	pint m_reputationPresented;

	array<uint> m_bossesKilled;

	array<string> m_townFlags;

	TownRecord(bool local = false)
	{
		m_local = local;

		m_buildings.insertLast(TownBuilding(this, "townhall", 1));
		m_buildings.insertLast(TownBuilding(this, "guildhall", 1));
		m_buildings.insertLast(TownBuilding(this, "generalstore", 1));
		m_buildings.insertLast(TownBuilding(this, "blacksmith", 0));
		m_buildings.insertLast(TownBuilding(this, "oretrader", 0));
		m_buildings.insertLast(TownBuilding(this, "apothecary", 0));
		m_buildings.insertLast(TownBuilding(this, "fountain", 0));
		m_buildings.insertLast(TownBuilding(this, "magicshop", 0));
		m_buildings.insertLast(TownBuilding(this, "chapel", 0));
		m_buildings.insertLast(TownBuilding(this, "tavern", 0));
		m_buildings.insertLast(TownBuilding(this, "treasury", 1));
		m_buildings.insertLast(TownBuilding(this, "sculptor", 0));

		@m_statistics = Stats::LoadList("tweak/stats.sval");

		m_bossesKilled.insertLast(0);
		m_bossesKilled.insertLast(0);
		m_bossesKilled.insertLast(0);
		m_bossesKilled.insertLast(0);
		m_bossesKilled.insertLast(0);
	}

	void FoundItem(ActorItem@ item)
	{
		for (uint i = 0; i < m_itemiary.length(); i++)
		{
			if (m_itemiary[i].m_item !is item)
				continue;
			
			m_itemiary[i].m_count++;
			return;
		}
		
		m_itemiary.insertLast(ItemiaryEntry(item, 1));
	}
	
	void KilledEnemy(UnitProducer@ prod)
	{
		for (uint i = 0; i < m_bestiary.length(); i++)
		{
			if (m_bestiary[i].m_producer !is prod)
				continue;
			
			m_bestiary[i].m_kills++;
			return;
		}
		
		m_bestiary.insertLast(BestiaryEntry(prod, 1, 0));
	}

	void EnemyKilledPlayer(UnitProducer@ prod)
	{
		for (uint i = 0; i < m_bestiary.length(); i++)
		{
			if (m_bestiary[i].m_producer !is prod)
				continue;
			
			m_bestiary[i].m_killer++;
			return;
		}
		
		m_bestiary.insertLast(BestiaryEntry(prod, 0, 1));
	}
	
	array<BestiaryEntry@>@ GetBestiary(string type)
	{
		uint filter = HashString(type);
		array<BestiaryEntry@> ret;
		
		for (uint i = 0; i < m_bestiary.length(); i++)
		{
			if (m_bestiary[i].m_type != filter)
				continue;

			ret.insertLast(m_bestiary[i]);
		}
		
		return ret;
	}

	int GetReputation()
	{
		return m_statistics.GetReputationPoints();
	}

	int GetReputationPresented()
	{
		return m_reputationPresented;
	}

	void OnNewTitle(Titles::Title@ title)
	{
		print("New guild title: \"" + title.m_name + "\"");

		m_gold += title.m_unlockGold;
		m_ore += title.m_unlockOre;

		auto localPlayer = GetLocalPlayerRecord();
		localPlayer.skillPoints += title.m_skillPoints;
		localPlayer.townTitleSync = title.m_points;

		auto gm = cast<Campaign>(g_gameMode);
		gm.RefreshTownModifiers();
		gm.SaveLocalTown();

		dictionary paramsTitle = { { "title", Resources::GetString(title.m_name) } };
		auto notif = gm.m_notifications.Add(
			Resources::GetString(".hud.newtitle.guild", paramsTitle),
			ParseColorRGBA("#" + Tweak::NotificationColors_NewTitle + "FF")
		);

		if (title.m_unlockGold > 0)
			notif.AddSubtext("icon-gold", formatThousands(title.m_unlockGold));
		if (title.m_unlockOre > 0)
			notif.AddSubtext("icon-ore", formatThousands(title.m_unlockOre));
		if (title.m_skillPoints > 0)
			notif.AddSubtext("icon-star", formatThousands(title.m_skillPoints));
	}

	Titles::Title@ GetTitle()
	{
		auto gm = cast<Campaign>(g_gameMode);
		return gm.m_titlesGuild.GetTitleFromPoints(GetReputationPresented());
	}

	Titles::Title@ GetNextTitle()
	{
		auto gm = cast<Campaign>(g_gameMode);
		return gm.m_titlesGuild.GetNextTitleFromPoints(GetReputationPresented());
	}

	void GiveStatue(string id, int level)
	{
		TownStatue@ statue = GetStatue(id);
		if (statue is null)
		{
			@statue = TownStatue();
			statue.m_id = id;
			m_statues.insertLast(statue);
		}
		print("Received statue \"" + id + "\" level " + level);
		statue.m_level = max(statue.m_level, level);
	}

	TownStatue@ GetStatue(string id)
	{
		for (uint i = 0; i < m_statues.length(); i++)
		{
			if (m_statues[i].m_id == id)
				return m_statues[i];
		}
		return null;
	}

	array<TownStatue@> GetPlacedStatues()
	{
		array<TownStatue@> ret;
		for (uint i = 0; i < m_statuePlacements.length(); i++)
		{
			auto statue = GetStatue(m_statuePlacements[i]);
			if (statue !is null)
				ret.insertLast(statue);
		}
		return ret;
	}

	int GetStatuePlacement(string id)
	{
		for (uint i = 0; i < m_statuePlacements.length(); i++)
		{
			if (m_statuePlacements[i] == id)
				return i;
		}
		return -1;
	}

	TownBuilding@ GetBuilding(string typeName)
	{
		for (uint i = 0; i < m_buildings.length(); i++)
		{
			if (m_buildings[i].m_typeName == typeName)
				return m_buildings[i];
		}
		return null;
	}

	void Save(SValueBuilder& builder, bool saveFlags)
	{
		builder.PushInteger("gold", m_gold);
		builder.PushInteger("ore", m_ore);

		builder.PushInteger("reputation-presented", m_reputationPresented);

		builder.PushDictionary("buildings");
		for (uint i = 0; i < m_buildings.length(); i++)
			m_buildings[i].Save(builder);
		builder.PopDictionary();

		builder.PushDictionary("statistics");
		m_statistics.Save(builder);
		builder.PopDictionary();

		builder.PushDictionary("statues");
		for (uint i = 0; i < m_statues.length(); i++)
		{
			auto statue = m_statues[i];
			if (statue.m_sculpted)
				statue.Save(builder);
		}
		builder.PopDictionary();

		builder.PushArray("statue-placements");
		for (uint i = 0; i < m_statuePlacements.length(); i++)
			builder.PushString(m_statuePlacements[i]);
		builder.PopArray();
		
		builder.PushArray("bestiary");
		for (uint i = 0; i < m_bestiary.length(); i++)
		{
			builder.PushInteger(m_bestiary[i].m_producer.GetResourceHash());
			builder.PushInteger(m_bestiary[i].m_kills);
			builder.PushInteger(m_bestiary[i].m_killer);
		}
		builder.PopArray();
		
		builder.PushArray("itemiary");
		for (uint i = 0; i < m_itemiary.length(); i++)
		{
			builder.PushInteger(m_itemiary[i].m_item.idHash);
			builder.PushInteger(m_itemiary[i].m_count);
		}
		builder.PopArray();
		
		builder.PushArray("flags");
		//if (saveFlags)
		{
			for (uint i = 0; i < m_townFlags.length(); i++)
				builder.PushString(m_townFlags[i]);
		
			auto flagKeys = g_flags.m_flags.getKeys();
			for (uint i = 0; i < flagKeys.length(); i++)
			{
				int64 state;
				g_flags.m_flags.get(flagKeys[i], state);
				
				FlagState flag = FlagState(state);
				if (flag == FlagState::Town /* || flag == FlagState::TownAll || flag == FlagState::HostTown */)
					builder.PushString(flagKeys[i]);
			}
		}
		builder.PopArray();

		builder.PushArray("random");
		for (int i = 0; i < int(RandomContext::NumContexts); i++)
			builder.PushInteger(RandomBank::GetSeed(RandomContext(i)));
		builder.PopArray();

		builder.PushArray("bosses-killed");
		for (uint i = 0; i < m_bossesKilled.length(); i++)
			builder.PushInteger(int(m_bossesKilled[i]));
		builder.PopArray();
	}

	void Load(SValue@ sv)
	{
		if (sv is null)
			return;
	
		m_gold = GetParamInt(UnitPtr(), sv, "gold");
		m_ore = GetParamInt(UnitPtr(), sv, "ore");

		m_reputationPresented = GetParamInt(UnitPtr(), sv, "reputation-presented", false);

		auto dictBuildings = GetParamDictionary(UnitPtr(), sv, "buildings", false);
		if (dictBuildings !is null)
		{
			auto keys = dictBuildings.GetDictionary().getKeys();
			for (uint i = 0; i < keys.length(); i++)
			{
				TownBuilding@ building = GetBuilding(keys[i]);
				if (building is null)
				{
					PrintError("Couldn't load building type \"" + keys[i] + "\"");
					continue;
				}
				building.Load(dictBuildings.GetDictionaryEntry(keys[i]));
			}
		}

		auto dictStatistics = GetParamDictionary(UnitPtr(), sv, "statistics", false);
		if (dictStatistics !is null)
			m_statistics.Load(dictStatistics);

		auto dictStatues = GetParamDictionary(UnitPtr(), sv, "statues", false);
		if (dictStatues !is null)
		{
			auto keys = dictStatues.GetDictionary().getKeys();
			for (uint i = 0; i < keys.length(); i++)
			{
				TownStatue@ statue = GetStatue(keys[i]);
				if (statue !is null)
					statue.Load(dictStatues.GetDictionaryEntry(keys[i]));
			}
		}

		auto arrPlacements = GetParamArray(UnitPtr(), sv, "statue-placements", false);
		if (arrPlacements !is null)
		{
			for (uint i = 0; i < arrPlacements.length(); i++)
			{
				TownStatue@ statue = GetStatue(arrPlacements[i].GetString());
				if (statue !is null)
					m_statuePlacements.insertLast(statue.m_id);
			}
		}
		
		auto arrBestiary = GetParamArray(UnitPtr(), sv, "bestiary", false);
		if (arrBestiary !is null)
		{
			for (uint i = 0; i < arrBestiary.length(); i += 3)
			{
				auto prod = Resources::GetUnitProducer(arrBestiary[i].GetInteger());
				if (prod is null)
					continue;
			
				m_bestiary.insertLast(BestiaryEntry(prod, arrBestiary[i + 1].GetInteger(), arrBestiary[i + 2].GetInteger()));
			}
		}
		
		auto arrItemiary = GetParamArray(UnitPtr(), sv, "itemiary", false);
		if (arrItemiary !is null)
		{
			for (uint i = 0; i < arrItemiary.length(); i += 2)
			{
				auto item = g_items.GetItem(arrItemiary[i].GetInteger());
				if (item is null)
					continue;
			
				m_itemiary.insertLast(ItemiaryEntry(item, arrItemiary[i + 1].GetInteger()));
			}
		}
		
		auto arrFlags = GetParamArray(UnitPtr(), sv, "flags", false);
		if (arrFlags !is null)
		{
			/*
			for (uint i = 0; i < arrFlags.length(); i++)
				m_townFlags.insertLast(arrFlags[i].GetString());
			*/
			auto flag = m_local ? FlagState::Town : FlagState::HostTown;
			for (uint i = 0; i < arrFlags.length(); i++)
				g_flags.Set(arrFlags[i].GetString(), flag);
		}

		auto arrRandom = GetParamArray(UnitPtr(), sv, "random", false);
		if (arrRandom !is null)
		{
			for (int i = 0; i < min(int(arrRandom.length()), int(RandomContext::NumContexts)); i++)
				RandomBank::SetSeed(RandomContext(i), arrRandom[i].GetInteger());
		}

		auto arrBossesKilled = GetParamArray(UnitPtr(), sv, "bosses-killed", false);
		if (arrBossesKilled !is null)
		{
			for (int i = 0; i < min(m_bossesKilled.length(), arrBossesKilled.length()); i++)
				m_bossesKilled[i] = uint(arrBossesKilled[i].GetInteger());
		}
	}
}
