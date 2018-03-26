// Usage:
//   if (Statues::GetPlacedLevel("armor-statue") == 1)

namespace Statues
{
	class StatueDef
	{
		string m_id;
		array<StatueLevelDef@> m_levels;

		StatueDef(string id, SValue@ sval)
		{
			m_id = id;

			auto arrLevels = sval.GetArray();
			for (uint j = 0; j < arrLevels.length(); j++)
				m_levels.insertLast(StatueLevelDef(arrLevels[j]));
		}

		StatueLevelDef@ GetLevel(int level)
		{
			if (level == 0)
				return null;
			return m_levels[level - 1];
		}
	}

	class StatueLevelDef
	{
		string m_name;
		string m_desc;

		int m_sculptCost;

		UnitScene@ m_scene;
		array<vec4> m_colors;

		Modifiers::ModifierList@ m_modifiers;

		StatueLevelDef(SValue@ sval)
		{
			m_name = GetParamString(UnitPtr(), sval, "name");
			m_desc = GetParamString(UnitPtr(), sval, "desc");

			m_sculptCost = GetParamInt(UnitPtr(), sval, "sculpt-cost");

			auto prod = Resources::GetUnitProducer(GetParamString(UnitPtr(), sval, "unit"));
			@m_scene = prod.GetUnitScene(GetParamString(UnitPtr(), sval, "scene"));

			auto colors = GetParamArray(UnitPtr(), sval, "colors");
			for (uint i = 0; i < colors.length(); i++)
				m_colors.insertLast(colors[i].GetVector4());

			auto arrModifiers = Modifiers::LoadModifiers(UnitPtr(), sval);
			if (arrModifiers.length() > 0)
			{
				@m_modifiers = Modifiers::ModifierList(arrModifiers);

				dictionary params = { { "statue", Resources::GetString(m_name) } };
				m_modifiers.m_name = Resources::GetString(".modifier.list.statue", params);
			}
		}

		void EnableModifiers()
		{
			if (m_modifiers !is null)
				g_allModifiers.Add(m_modifiers);
		}

		void DisableModifiers()
		{
			if (m_modifiers !is null)
				g_allModifiers.Remove(m_modifiers);
		}
	}

	void DisableModifiers()
	{
		for (uint i = 0; i < g_statues.length(); i++)
		{
			for (uint j = 0; j < g_statues[i].m_levels.length(); j++)
				g_statues[i].m_levels[j].DisableModifiers();
		}
	}

	int GetPlacedLevel(string id)
	{
		auto gm = cast<Campaign>(g_gameMode);

		int placement = gm.m_town.GetStatuePlacement(id);
		if (placement == -1)
			return 0;

		auto statue = gm.m_town.GetStatue(id);
		if (statue is null)
		{
			PrintError("Coulnd't find statue with ID \"" + id + "\"");
			return 0;
		}

		return statue.m_level;
	}

	StatueDef@ GetStatue(string id)
	{
		for (uint i = 0; i < g_statues.length(); i++)
		{
			if (g_statues[i].m_id == id)
				return g_statues[i];
		}
		return null;
	}

	StatueLevelDef@ GetStatue(string id, int level)
	{
		auto def = GetStatue(id);
		if (def is null)
		{
			PrintError("Couldn't find statue with ID \"" + id + "\"");
			return null;
		}
		return def.GetLevel(level);
	}

	void LoadStatues()
	{
		auto sv = Resources::GetSValue("tweak/statues.sval");
		auto keys = sv.GetDictionary().getKeys();
		for (uint i = 0; i < keys.length(); i++)
			g_statues.insertLast(StatueDef(keys[i], sv.GetDictionaryEntry(keys[i])));
	}
}

array<Statues::StatueDef@> g_statues;
