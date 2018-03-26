namespace Menu
{
	class HwrMenu : Menu
	{
		bool m_closeAfterContext;
		
		Widget@ m_wMultiplayer;

		HwrMenu(MenuProvider@ provider)
		{
			super(provider);
		}
		
		void Initialize(GUIDef@ def) override
		{
			@m_wMultiplayer = m_widget.GetWidgetById("popup-multiplayer");
		}
		
		void Update(int dt) override
		{
			Menu::Update(dt);
		
			if (m_wMultiplayer is null)
				return;
		
			bool onlineAvailable = Platform::Service.IsMultiplayerAvailable();
			
			for (uint i = 0; i < m_wMultiplayer.m_children.length(); i++)
				cast<ScalableSpriteButtonWidget>(m_wMultiplayer.m_children[i]).m_enabled = onlineAvailable;
		}

		void ShowCharacterSelection(string context)
		{
			if (GetCharacters().length() == 0)
				OpenMenu(CharacterCreationMenu(m_provider, context), "gui/main_menu/character_creation.gui");
			else
				OpenMenu(CharacterSelectionMenu(m_provider, context), "gui/main_menu/character_selection.gui");
		}

		void FinishContext(string context)
		{
			if (context == "")
				cast<MainMenu>(g_gameMode).PlayGame(GetVarInt("g_start_sessions"));
			else if (context == "multi-host")
				OpenMenu(Menu::HostMenu(m_provider), "gui/main_menu/host.gui");
			else if (context == "multi-serverlist")
				OpenMenu(Menu::ServerlistMenu(m_provider), "gui/main_menu/serverlist.gui");
			else if (context == "multi-invite")
			{
				auto gm = cast<MainMenu>(g_gameMode);
				gm.JoiningLobby();
				Lobby::JoinLobby(gm.m_inviteAcceptID);
			}

			if (m_closeAfterContext)
				RemoveFromProvider();
		}
	}
}
