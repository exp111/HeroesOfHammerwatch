namespace Titles
{
	class TitleList
	{
		array<Title@> m_titles;

		TitleList(string filename)
		{
			auto sval = Resources::GetSValue(filename);
			if (sval is null)
			{
				PrintError("Couldn't find titles list file \"" + filename + "\"");
				return;
			}

			auto arr = sval.GetArray();
			for (uint i = 0; i < arr.length(); i++)
				m_titles.insertLast(Title(arr[i]));
		}

		void ClearModifiers(Modifiers::ModifierList@ modifiers)
		{
			for (uint i = 0; i < m_titles.length(); i++)
				modifiers.Remove(m_titles[i].m_modifiers);
		}

		void EnableTitleModifiers(PlayerRecord@ record, int index)
		{
			record.modifiersTitles.Clear();
			GetTitle(index).EnableModifiers(record);
		}

		Title@ GetTitle(int index)
		{
			if (index >= int(m_titles.length()))
				return m_titles[m_titles.length() - 1];
			return m_titles[index];
		}

		Title@ GetTitleFromPoints(int points)
		{
			for (int i = m_titles.length() - 1; i >= 0; i--)
			{
				if (points >= m_titles[i].m_points)
					return m_titles[i];
			}
			return null;
		}

		Title@ GetNextTitleFromPoints(int points)
		{
			for (int i = m_titles.length() - 1; i >= 0; i--)
			{
				if (points >= m_titles[i].m_points)
				{
					if (i == int(m_titles.length()) - 1)
						break;
					return m_titles[i + 1];
				}
			}
			return null;
		}
	}
}
