class TownBuilding
{
	TownRecord@ m_town;

	string m_typeName;
	int m_level;

	array<Modifiers::ModifierList@> m_levelModifiers;

	TownBuilding(TownRecord@ town, string typeName, int level = 0)
	{
		@m_town = town;

		m_typeName = typeName;
		m_level = level;

		LoadTweakData();
	}

	Modifiers::ModifierList@ GetModifiers()
	{
		if (m_level < int(m_levelModifiers.length()))
			return m_levelModifiers[m_level];
		return null;
	}

	void RefreshModifiers()
	{
		// Only host town should apply building modifiers
		if (m_town.m_local)
			return;

		for (uint i = 0; i < m_levelModifiers.length(); i++)
			g_allModifiers.Remove(m_levelModifiers[i]);

		auto mods = GetModifiers();
		if (mods !is null)
			g_allModifiers.Add(mods);
	}

	void LoadTweakData()
	{
		SValue@ sval = Resources::GetSValue("tweak/buildings/" + m_typeName + ".sval");
		if (sval is null)
			return;

		auto arrLevels = GetParamArray(UnitPtr(), sval, "levels");
		if (arrLevels is null)
			return;

		for (uint i = 0; i < arrLevels.length(); i++)
		{
			auto modList = Modifiers::LoadModifiersList(UnitPtr(), arrLevels[i]);

			dictionary params = { { "building", Resources::GetString(".town.building." + m_typeName) }, { "level", i + 1 } };
			modList.m_name = Resources::GetString(".modifier.list.building", params);

			m_levelModifiers.insertLast(modList);
		}

		RefreshModifiers();
	}

	Prefab@ GetPrefab()
	{
		return Resources::GetPrefab("prefabs/town/building_" + m_typeName + "_" + m_level + ".pfb");
	}

	void Upgrade(int level)
	{
		m_level = level;

		RefreshModifiers();
	}

	void Save(SValueBuilder& builder)
	{
		builder.PushInteger(m_typeName, m_level);
	}

	void Load(SValue@ sv)
	{
		if (sv.GetType() == SValueType::Integer)
			m_level = sv.GetInteger();

		RefreshModifiers();
	}
}
