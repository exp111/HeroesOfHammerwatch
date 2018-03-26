namespace Stats
{
	class Accomplishment
	{
		Stat@ m_stat;
		int m_level;

		int m_value;
		int m_reputation;

		string m_statueID;
		int m_statueLevel;

		bool m_finished;

		Accomplishment(Stat@ stat, SValue@ sval, int level)
		{
			@m_stat = stat;
			m_level = level;

			m_value = GetParamInt(UnitPtr(), sval, "value");

			m_reputation = GetParamInt(UnitPtr(), sval, "reputation", false);

			m_statueID = GetParamString(UnitPtr(), sval, "statue-id", false);
			m_statueLevel = GetParamInt(UnitPtr(), sval, "statue-level", false);
		}

		string GetName()
		{
			return Resources::GetString(".accomplishment." + m_stat.m_name + ".name", {
				{ "lvl", toRoman(m_level) }
			});
		}

		string GetDescription()
		{
			return Resources::GetString(".accomplishment." + m_stat.m_name + ".desc", {
				{ "lvl", toRoman(m_level) },
				{ "requirement", formatThousands(m_value) }
			});
		}

		bool IsValueGood(int value)
		{
			return value >= m_value;
		}

		void OnUpdated()
		{
			// If already finished, or the stat value isn't reached yet
			if (m_finished || !IsValueGood(m_stat.ValueInt()))
				return;

			m_finished = true;

			auto gm = cast<Campaign>(g_gameMode);

			dictionary params = { { "name", GetName() } };
			auto notif = gm.m_notifications.Add(
				Resources::GetString(".hud.accomplishment.done", params),
				ParseColorRGBA("#" + Tweak::NotificationColors_Accomplishment + "FF")
			);
			notif.AddSubtext("icon-reputation", formatThousands(m_reputation));

			OnLoadFinished();
		}

		void OnLoadFinished()
		{
			// Called from:
			// * OnUpdated if the value is good
			// * Town load if the value is good

			auto gm = cast<Campaign>(g_gameMode);
			if (gm is null)
				return;

			if (m_statueID != "")
			{
				print("  * Statue: \"" + m_statueID + "\", level: " + m_statueLevel);
				gm.m_town.GiveStatue(m_statueID, m_statueLevel);
			}
		}
	}
}
