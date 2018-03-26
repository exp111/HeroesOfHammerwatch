namespace Menu
{
	enum ServerlistSortColumn
	{
		None,
		Name,
		Players,
	}

	class ServerlistMenu : Menu
	{
		TextInputWidget@ m_wFilter;
		MenuServerListItem@ m_listTemplate;
		FilteredListWidget@ m_list;

		ServerlistSortColumn m_sortColumn = ServerlistSortColumn::Players;
		int m_sortDir = 1;

		Sprite@ m_spriteButton;
		Sprite@ m_spriteButtonHover;
		Sprite@ m_spriteButtonDown;

		int m_charLevel;

		ServerlistMenu(MenuProvider@ provider)
		{
			super(provider);
		}

		void Initialize(GUIDef@ def) override
		{
			@m_wFilter = cast<TextInputWidget>(m_widget.GetWidgetById("filter"));
			@m_listTemplate = cast<MenuServerListItem>(m_widget.GetWidgetById("serverlist-template"));
			@m_list = cast<FilteredListWidget>(m_widget.GetWidgetById("serverlist"));

			@m_spriteButton = def.GetSprite("listitem");
			@m_spriteButtonHover = def.GetSprite("listitem-hover");
			@m_spriteButtonDown = def.GetSprite("listitem-down");

			Lobby::ListLobbies();

			auto svChar = LoadCharacter();
			if (svChar !is null)
			{
				m_charLevel = GetParamInt(UnitPtr(), svChar, "level", false, 1);

				string name = GetParamString(UnitPtr(), svChar, "name");
				string charClass = GetParamString(UnitPtr(), svChar, "class");

				auto classColors = CharacterColors::GetClass(charClass);

				int colorSkin = GetParamInt(UnitPtr(), svChar, "color-skin");
				int color1 = GetParamInt(UnitPtr(), svChar, "color-1");
				int color2 = GetParamInt(UnitPtr(), svChar, "color-2");
				int color3 = GetParamInt(UnitPtr(), svChar, "color-3");

				auto wCharUnit = cast<UnitWidget>(m_widget.GetWidgetById("char-unit"));
				wCharUnit.AddUnit("players/" + charClass + ".unit", "idle-3");
				wCharUnit.m_multiColors.insertLast(classColors.m_skin[colorSkin % classColors.m_skin.length()]);
				wCharUnit.m_multiColors.insertLast(classColors.m_1[color1 % classColors.m_1.length()]);
				wCharUnit.m_multiColors.insertLast(classColors.m_2[color2 % classColors.m_2.length()]);
				wCharUnit.m_multiColors.insertLast(classColors.m_3[color3 % classColors.m_3.length()]);

				string charClassName = Resources::GetString(".class." + charClass);
				auto wName = cast<TextWidget>(m_widget.GetWidgetById("char-name"));
				wName.SetText(Resources::GetString(".mainmenu.serverlist.charname", {
					{ "name", name },
					{ "lvl", m_charLevel },
					{ "class", charClassName }
				}));
			}
		}

		void Show() override
		{
			Menu::Show();

			Lobby::ListLobbies();
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto parse = name.split(" ");
			if (parse[0] == "join")
			{
				if (parse.length() > 1)
				{
					MainMenu@ menu = cast<MainMenu>(g_gameMode);
					menu.JoiningLobby();
					Lobby::JoinLobby(parseUInt(parse[1]));
				}
			}
			else if (parse[0] == "refresh")
			{
				//m_list.ClearChildren();
				Lobby::ListLobbies();
			}
			else if (parse[0] == "filterlist")
				m_list.SetFilter(m_wFilter.m_text.plain());
			else if (parse[0] == "filterlist-clear")
			{
				m_wFilter.ClearText();
				m_list.ShowAll();
			}
			else if (parse[0] == "sort")
			{
				ServerlistSortColumn setCol = ServerlistSortColumn::None;
				if (parse[1] == "name")
					setCol = ServerlistSortColumn::Name;
				else if (parse[1] == "players")
					setCol = ServerlistSortColumn::Players;
				else
					setCol = ServerlistSortColumn::None;

				if (m_sortColumn == setCol)
				{
					if (m_sortDir == 0 || m_sortDir == -1)
						m_sortDir = 1;
					else if (m_sortDir == 1)
						m_sortDir = -1;
				}
				else
					m_sortDir = 1;
				m_sortColumn = setCol;

				m_list.m_children.sortAsc();
			}
			else
				Menu::OnFunc(sender, name);
		}

		void OnLobbyList(array<uint64>@ lobbies)
		{
			m_list.ClearChildren();
			for (uint i = 0; i < lobbies.length(); i++)
			{
				string lobbyName = Lobby::GetLobbyData(lobbies[i], "name");
				int lobbyPlayerCount = Lobby::GetLobbyPlayerCount(lobbies[i]);
				int lobbyPlayerCountMax = Lobby::GetLobbyPlayerCountMax(lobbies[i]);
				int lobbyPing = Lobby::GetLobbyPing(lobbies[i]);

				int maxLevel = parseInt(Lobby::GetLobbyData(lobbies[i], "max-level"));
				int minLevel = parseInt(Lobby::GetLobbyData(lobbies[i], "min-level"));
				int ngp = parseInt(Lobby::GetLobbyData(lobbies[i], "ngp"));

				MenuServerListItem@ wLobbyItem = cast<MenuServerListItem>(m_listTemplate.Clone());
				wLobbyItem.m_visible = true;
				wLobbyItem.m_func = "join " + lobbies[i];
				wLobbyItem.Set(this, lobbyName, lobbyPlayerCount, lobbyPlayerCountMax, lobbyPing);

				if (lobbyPlayerCount >= lobbyPlayerCountMax)
					wLobbyItem.m_enabled = false;
				else if (m_charLevel < minLevel || m_charLevel > maxLevel)
					wLobbyItem.m_enabled = false;

				if (minLevel > 1 && maxLevel < 60)
				{
					string strMinLevel = "" + minLevel;
					string strMaxLevel = "" + maxLevel;
					if (m_charLevel < minLevel)
						strMinLevel = "\\cff0000" + minLevel;
					if (m_charLevel > maxLevel)
						strMaxLevel = "\\cff0000" + maxLevel;
					wLobbyItem.m_tooltipText = Resources::GetString(".mainmenu.serverlist.level-restriction.both", {
						{ "min", strMinLevel },
						{ "max", strMaxLevel }
					});
				}
				else if (minLevel > 1)
				{
					string strMinLevel = "" + minLevel;
					if (m_charLevel < minLevel)
						strMinLevel = "\\cff0000" + minLevel + "\\d";
					wLobbyItem.m_tooltipText = Resources::GetString(".mainmenu.serverlist.level-restriction.min", {
						{ "min", strMinLevel }
					});
				}
				else if (maxLevel < 60)
				{
					string strMaxLevel = "" + maxLevel;
					if (m_charLevel > maxLevel)
						strMaxLevel = "\\cff0000" + maxLevel + "\\d";
					wLobbyItem.m_tooltipText = Resources::GetString(".mainmenu.serverlist.level-restriction.max", {
						{ "max", strMaxLevel }
					});
				}

				if (ngp > 0)
				{
					if (wLobbyItem.m_tooltipText != "")
						wLobbyItem.m_tooltipText += "\n\\d";
					wLobbyItem.m_tooltipText += Resources::GetString(".mainmenu.serverlist.ngp", {
						{ "ngp", ngp }
					});
				}

				m_list.AddChild(wLobbyItem);
			}

			m_list.m_children.sortAsc();
		}
	}
}
