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
				//bool lobbyPlaying = (Lobby::GetLobbyData(lobbies[i], "playing") == "1");
				int lobbyPlayerCount = Lobby::GetLobbyPlayerCount(lobbies[i]);
				int lobbyPlayerCountMax = Lobby::GetLobbyPlayerCountMax(lobbies[i]);
				int lobbyPing = Lobby::GetLobbyPing(lobbies[i]);
				//GameDifficulty difficulty = GameDifficulty(parseInt(Lobby::GetLobbyData(lobbies[i], "difficulty")));

				MenuServerListItem@ wLobbyItem = cast<MenuServerListItem>(m_listTemplate.Clone());
				wLobbyItem.m_visible = true;
				wLobbyItem.m_func = "join " + lobbies[i];
				wLobbyItem.Set(this, lobbyName, lobbyPlayerCount, lobbyPlayerCountMax, lobbyPing);

				/*
				auto wDiff = cast<TextWidget>(wLobbyItem.GetWidgetById("difficulty"));
				if (wDiff !is null)
				{
					switch (difficulty)
					{
						case GameDifficulty::Easy: wDiff.SetText(Resources::GetString(".difficulty.easy")); break;
						case GameDifficulty::Normal: wDiff.SetText(Resources::GetString(".difficulty.normal")); break;
						case GameDifficulty::Hard: wDiff.SetText(Resources::GetString(".difficulty.hard")); break;
						case GameDifficulty::Serious: wDiff.SetText(Resources::GetString(".difficulty.serious")); break;
					}
				}

				auto wPing = cast<TextWidget>(wLobbyItem.GetWidgetById("ping"));
				if (wPing !is null)
					wPing.SetText((ping < 0) ? "?" : ("" + ping));
				*/

				m_list.AddChild(wLobbyItem);
			}

			m_list.m_children.sortAsc();
		}
	}
}
