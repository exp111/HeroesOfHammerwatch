namespace Upgrades
{
	class ChapelShop : UpgradeShop
	{
		array<array<ScriptSprite@>> m_icons;
		array<array<Upgrade@>> m_rows;

		ChapelShop(SValue& params)
		{
			super(params);

			auto icons = GetParamArray(UnitPtr(), params, "icons");
			for (uint i = 0; i < icons.length(); i++)
			{
				m_icons.insertLast(array<ScriptSprite@>());

				auto row = icons[i].GetArray();
				for (uint j = 0; j < row.length(); j++)
				{
					auto iconParams = row[j].GetArray();
					auto newSprite = ScriptSprite(iconParams);
					m_icons[i].insertLast(newSprite);
				}
			}

			auto rows = GetParamArray(UnitPtr(), params, "rows");
			for (uint i = 0; i < rows.length(); i++)
			{
				m_rows.insertLast(array<Upgrade@>());

				auto row = rows[i].GetArray();
				for (uint j = 0; j < row.length(); j++)
				{
					auto upgrData = cast<SValue>(row[j]);
					string upgrClassName = GetParamString(UnitPtr(), upgrData, "class");

					auto upgr = cast<Upgrades::Upgrade>(InstantiateClass(upgrClassName, upgrData));
					if (upgr is null)
					{
						PrintError("Class \"" + upgrClassName + "\" is not of type Upgrades::Upgrade");
						continue;
					}

					m_upgrades.insertLast(upgr); // so that the iterator can find it (for remembered upgrades)
					m_rows[i].insertLast(upgr);
				}
			}
		}

		int GetIconIndex(int index, int x)
		{
			return index * 2 + x;
		}

		ScriptSprite@ GetIcon(int y, int index)
		{
			if (y < 0 || y >= int(m_icons.length()))
			{
				PrintError("Y out of range! (Max: " + m_icons.length() + ")");
				return null;
			}

			if (index < 0 || index >= int(m_icons[y].length()))
			{
				PrintError("Index out of range! (Max: " + m_icons[y].length() + ")");
				return null;
			}

			return m_icons[y][index];
		}
	}
}
