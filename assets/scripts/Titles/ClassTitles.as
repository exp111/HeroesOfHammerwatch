namespace Titles
{
	class ClassTitles
	{
		dictionary m_lists;

		void AddClassTitles(string charClass)
		{
			print("Adding class titles for " + charClass);

			auto list = TitleList("tweak/titles/classes/" + charClass + ".sval");
			m_lists.set(charClass, @list);
		}

		TitleList@ GetList(string charClass)
		{
			TitleList@ list = null;
			m_lists.get(charClass, @list);
			return list;
		}

		Title@ GetTitle(string charClass, int index)
		{
			TitleList@ list = GetList(charClass);
			if (list is null)
			{
				PrintError("Class titles list for \"" + charClass + "\" is not loaded!");
				return null;
			}
			return list.GetTitle(index);
		}

		void RefreshModifiers(SValueBuilder& builder)
		{
			builder.PushArray();

			auto record = GetLocalPlayerRecord();
			
			dictionary titles;

			record.modifiersTitles.Clear();
			auto characters = GetCharacters();
			for (uint i = 0; i < characters.length(); i++)
			{
				string charClass = GetParamString(UnitPtr(), characters[i], "class");
				int titleIndex = GetParamInt(UnitPtr(), characters[i], "title", false, 0);
				
				int64 best = titleIndex;
				if (titles.get(charClass, best))
					best = max(best, titleIndex);
					
				titles.set(charClass, best);
			}
			
			auto keys = titles.getKeys();
			for (uint i = 0; i < keys.length(); i++)
			{
				string charClass = keys[i];
				int64 titleIndex;
				titles.get(charClass, titleIndex);
				
				auto list = GetList(charClass);
				if (list is null)
				{
					PrintError("Class titles list for \"" + charClass + "\" is not loaded!");
					continue;
				}

				auto title = list.GetTitle(int(titleIndex));

				builder.PushArray();
				builder.PushString(charClass);
				builder.PushInteger(titleIndex);
				builder.PopArray();

				dictionary params = { { "title", Resources::GetString(title.m_name) } };
				title.m_modifiers.m_name = Resources::GetString(".modifier.list.classtitle", params);

				title.EnableModifiers(record);
			}

			builder.PopArray();
		}

		void NetRefreshModifiers(PlayerRecord@ record, SValue@ params)
		{
			record.modifiersTitles.Clear();

			auto arrTitles = params.GetArray();
			for (uint i = 0; i < arrTitles.length(); i++)
			{
				auto arrTitle = arrTitles[i].GetArray();

				string charClass = arrTitle[0].GetString();
				int titleIndex = arrTitle[1].GetInteger();

				auto list = GetList(charClass);
				if (list is null)
				{
					PrintError("Class titles list for \"" + charClass + "\" is not loaded!");
					continue;
				}

				auto title = list.GetTitle(titleIndex);
				title.EnableModifiers(record);
			}
		}
	}
}

Titles::ClassTitles g_classTitles;
