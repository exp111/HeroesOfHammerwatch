namespace Stats
{
	enum StatType
	{
		Number,
		Average
	}

	enum StatDisplay
	{
		None,
		Number,
		Time,
		Distance
	}

	enum StatScope
	{
		Town,
		Character,
		Global
	}

	class Stat
	{
		string m_name;
		string m_category;
		uint m_nameHash;

		bool m_town;
		StatType m_type;
		StatDisplay m_display;
		StatScope m_scope;

		array<Accomplishment@> m_accomplishments;

		pint m_valueInt;
		pint m_valueCount;
		
		string m_achievement;
		int m_achievementLimit;
		

		Stat(SValue@ params)
		{
			m_name = GetParamString(UnitPtr(), params, "name");
			m_category = GetParamString(UnitPtr(), params, "category", false, "");
			m_nameHash = HashString(m_name);

			m_town = GetParamBool(UnitPtr(), params, "town", false);

			string statTypeString = GetParamString(UnitPtr(), params, "type", false, "number");
			     if (statTypeString == "number") m_type = StatType::Number;
			else if (statTypeString == "average") m_type = StatType::Average;
			else PrintError("Unknown stat type \"" + statTypeString + "\"");

			string statDisplayString = GetParamString(UnitPtr(), params, "display", false, "number");
			     if (statDisplayString == "none") m_display = StatDisplay::None;
			else if (statDisplayString == "number") m_display = StatDisplay::Number;
			else if (statDisplayString == "time") m_display = StatDisplay::Time;
			else if (statDisplayString == "distance") m_display = StatDisplay::Distance;
			else PrintError("Unknown stat display type \"" + statDisplayString + "\"");

			string statScopeString = GetParamString(UnitPtr(), params, "scope", false, "global");
			     if (statScopeString == "town") m_scope = StatScope::Town;
			else if (statScopeString == "character") m_scope = StatScope::Character;
			else if (statScopeString == "global") m_scope = StatScope::Global;

			auto arrAccomplishments =  GetParamArray(UnitPtr(), params, "rewards", false);
			if (arrAccomplishments !is null)
			{
				for (uint i = 0; i < arrAccomplishments.length(); i++)
					m_accomplishments.insertLast(Accomplishment(this, arrAccomplishments[i], i + 1));
			}
			
			m_achievement = GetParamString(UnitPtr(), params, "achievement", false);
			m_achievementLimit = GetParamInt(UnitPtr(), params, "achievement-limit", false, 0);
		}

		int opCmp(const Stat &in other) const
		{
			return m_category.opCmp(other.m_category);
		}

		string ToString()
		{
			if (m_display == StatDisplay::None)
				return "";

			int value = m_valueInt;
			if (m_type == StatType::Average)
			{
				value /= m_valueCount;

				// Special case: If avg result is < 100 and it's a regular number,
				// we can show the average as a float
				if (value < 100 && m_display == StatDisplay::Number)
					return "" + round(float(m_valueInt) / float(m_valueCount), 2);
			}

			if (m_display == StatDisplay::Distance)
				return formatMeters(value);

			switch (m_display)
			{
				case StatDisplay::Number: return "" + formatThousands(value);
				case StatDisplay::Time: return formatTime(value, false, true);
			}

			return "" + value;
		}

		int ValueInt()
		{
			return m_valueInt;
		}

		void Add(int value, bool checkAwards)
		{
			if (g_isTown && !m_town)
				return;

			m_valueInt += value;

			if (checkAwards)
			{
				for (uint i = 0; i < m_accomplishments.length(); i++)
					m_accomplishments[i].OnUpdated();
					
				if (m_achievementLimit > 0 && m_valueInt >= m_achievementLimit)
				{
					Platform::Service.UnlockAchievement(m_achievement);
					m_achievementLimit = 0;
				}
			}
		}

		void AddAvg()
		{
			if (g_isTown && !m_town)
				return;

			if (m_type != StatType::Average)
			{
				PrintError("Tried adding average count to non-average stat \"" + m_name + "\"!");
				return;
			}
			m_valueCount++;
		}

		void Max(int value, bool checkAwards)
		{
			if (g_isTown && !m_town)
				return;

			if (value <= m_valueInt)
				return;
			m_valueInt = value;

			if (checkAwards)
			{
				for (uint i = 0; i < m_accomplishments.length(); i++)
					m_accomplishments[i].OnUpdated();
					
				if (m_achievementLimit > 0 && m_valueInt >= m_achievementLimit)
				{
					Platform::Service.UnlockAchievement(m_achievement);
					m_achievementLimit = 0;
				}
			}
		}

		int GetNumRewarded()
		{
			int ret = 0;
			for (uint i = 0; i < m_accomplishments.length(); i++)
			{
				if (m_accomplishments[i].m_finished)
					ret++;
			}
			return ret;
		}

		void Load(SValue@ svStat, bool checkAwards)
		{
			if (m_type == StatType::Number && svStat.GetType() == SValueType::Integer)
				m_valueInt = svStat.GetInteger();
			else if (m_type == StatType::Average && svStat.GetType() == SValueType::Array)
			{
				auto arr = svStat.GetArray();
				m_valueInt = arr[0].GetInteger();
				m_valueCount = arr[1].GetInteger();
			}

			for (uint i = 0; i < m_accomplishments.length(); i++)
			{
				auto reward = m_accomplishments[i];
				if (reward.IsValueGood(m_valueInt))
				{
					reward.m_finished = true;
					reward.OnLoadFinished();
				}
			}

			if (checkAwards)
			{
				if (m_achievementLimit > 0 && m_valueInt >= m_achievementLimit)
				{
					Platform::Service.UnlockAchievement(m_achievement);
					m_achievementLimit = 0;
				}
			}
		}

		void Save(SValueBuilder& builder)
		{
			if (m_type == StatType::Number)
				builder.PushInteger(m_name, m_valueInt);
			else if (m_type == StatType::Average)
			{
				builder.PushArray(m_name);
				builder.PushInteger(m_valueInt);
				builder.PushInteger(m_valueCount);
				builder.PopArray();
			}
		}

		void Clear()
		{
			m_valueInt = 0;
			m_valueCount = 0;
		}
	}
}
