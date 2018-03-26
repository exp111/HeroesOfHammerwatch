array<WorldScript::MenuAnchorPoint@> g_menuAnchors;

[GameMode default]
class MainMenu : BaseGameMode
{
	MenuControlInputWidget@ m_expectingInput;

	MenuProvider@ m_mainMenu;
	MenuProvider@ m_ingameMenu;
	Menu::InGameChat@ m_ingameChat;
	Menu::InGameNotifier@ m_ingameNotifier;

	GameChatWidget@ m_wChat;

	MenuProvider@ m_gameMenu;
	MenuState m_state;

	SoundInstance@ m_musicInstance;

	bool m_testLevel;
	bool m_hostPrivate;
	string m_hostName;
	int m_hostMaxPlayers;
	int m_hostMaxLevel;
	int m_hostMinLevel;
	int m_hostNgp;
	uint64 m_inviteAcceptID;

	int m_frameCount;
	bool m_lostConnection;
	int m_joinFailed = -1;

	TownRecord@ m_town;

	Menu::JoiningLobbyMenu@ m_joiningMenu;

	MainMenu(Scene@ scene)
	{
		super(scene);

		if (!VarExists("g_intro_logos"))
			AddVar("g_intro_logos", true);
		if (!VarExists("g_intro_logos_shown"))
			AddVar("g_intro_logos_shown", false);
		if (!VarExists("g_debug_menu"))
			AddVar("g_debug_menu", false);
		if (!VarExists("g_multi_test"))
			AddVar("g_multi_test", false, null, cvar_flags::Cheat);

		@m_mainMenu = MenuProvider();
		@m_ingameMenu = MenuProvider();

		@m_ingameNotifier = Menu::InGameNotifier();
		m_ingameNotifier.Initialize(m_guiBuilder, "gui/ingame_menu/notifier.gui");

		m_guiBuilder.AddWidgetProducer("menu_control_input", LoadMenuControlInput);
		m_guiBuilder.AddWidgetProducer("game_chat", LoadGameChatWidget);
		m_guiBuilder.AddWidgetProducer("menu_savegame", LoadMenuSaveGameWidget);
		m_guiBuilder.AddWidgetProducer("menu_lobby_player", LoadMenuLobbyPlayer);
		m_guiBuilder.AddWidgetProducer("menu_serverlist_item", LoadMenuServerListItemWidget);
		LoadMenu();

		if (Platform::GetSessionCount() == 0)
		{
			auto cb = GetControlBindings();
			GetControlBindings().AssignControls(1);
		}

		InstantiateMice();
	}

	void InstantiateMice()
	{
		m_mice.removeRange(0, m_mice.length());
		int numInputs = Platform::GetInputCount();
		for (int i = 0; i < numInputs; i++) {
			GameInput@ gi = Platform::GetGameInput(i);
			MenuInput@ mi = Platform::GetMenuInput(i);
			m_mice.insertLast(MenuMouse(gi, mi, numInputs > 1));
		}
	}

	Menu::ServerlistMenu@ GetServerlistMenu()
	{
		for (uint i = 0; i < m_gameMenu.m_menus.length(); i++)
		{
			auto menu = cast<Menu::ServerlistMenu>(m_gameMenu.m_menus[i]);
			if (menu !is null)
				return menu;
		}
		return null;
	}

	void ShowMessage(MenuMessage message)
	{
		if (message == MenuMessage::Saved)
			m_ingameNotifier.ShowSaved(2000);
		else if (message == MenuMessage::LostConnection)
			m_lostConnection = true;
	}

	void LoadMenu()
	{
		@m_gameMenu = m_mainMenu;

		if (GetVarBool("g_debug_menu"))
			m_mainMenu.Initialize(m_guiBuilder, Menu::TestMenu(m_mainMenu), "gui/test.gui", "gui/main_menu/backdrop.gui");
		else
		{
			if (GetVarBool("g_intro_logos") && !GetVarBool("g_intro_logos_shown"))
				m_mainMenu.Initialize(m_guiBuilder, Menu::IntroMenu(m_mainMenu), "gui/main_menu/intro.gui", "gui/main_menu/backdrop.gui");
			else
				m_mainMenu.Initialize(m_guiBuilder, Menu::FrontMenu(m_mainMenu), "gui/main_menu/main.gui", "gui/main_menu/backdrop.gui");
		}

		@m_gameMenu = m_ingameMenu;
		m_ingameMenu.Initialize(m_guiBuilder, Menu::FrontMenu(m_ingameMenu), "gui/ingame_menu/main.gui", "gui/ingame_menu/backdrop.gui");

		@m_ingameChat = Menu::InGameChat();
		m_ingameChat.Initialize(m_guiBuilder, "gui/ingame_menu/chat.gui");

		g_gameMode.ClearWidgetRoot();
	}

	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		@m_town = TownRecord();
		m_town.Load(LoadLocalTown());

		auto res = g_scene.FetchAllWorldScripts("SpawnTownBuilding");
		for (uint i = 0; i < res.length(); i++)
		{
			auto spawn = cast<WorldScript::SpawnTownBuilding>(res[i].GetUnit().GetScriptBehavior());
			auto building = m_town.GetBuilding(spawn.TypeName);

			auto prefab = building.GetPrefab();
			if (prefab is null)
				continue;

			prefab.Fabricate(g_scene, spawn.Position);
		}

		m_hostNgp = m_town.m_currentNgp;
	}

	void SpawnPlayers() override
	{
	}

	bool ShouldDisplayCursor() override
	{
		return (m_state != MenuState::Hidden) || (m_dialogWindow !is null);
	}

	void SetMenuState(MenuState state)
	{
		m_ingameChat.StopInput();

		g_gameMode.ClearWidgetRoot();

		m_state = state;

		if (m_state == MenuState::InGameMenu)
			@m_gameMenu = m_ingameMenu;
		else if (m_state == MenuState::MainMenu)
			@m_gameMenu = m_mainMenu;
		else if (m_state == MenuState::Hidden)
		{
			if (m_musicInstance !is null && m_musicInstance.IsPlaying())
				m_musicInstance.Stop();
			return;
		}

		g_gameMode.AddWidgetRoot(m_gameMenu.GetCurrentMenu());
		m_gameMenu.GetCurrentMenu().SetActive();

		if (m_state == MenuState::MainMenu)
		{
			if (m_musicInstance is null)
			{
				auto music = Resources::GetSoundEvent("event:/music/menu");
				if (music !is null)
				{
					@m_musicInstance = music.PlayTracked();
					m_musicInstance.SetLooped(true);
					m_musicInstance.SetPaused(false);
				}
			}
		}
		else if (m_musicInstance !is null)
			m_musicInstance.Stop();
	}

	bool MenuBack() override
	{
		if (m_state == MenuState::Hidden)
			return false;

		if (!BaseGameMode::MenuBack())
		{
			if (m_gameMenu is m_ingameMenu)
				return m_gameMenu.GoBack();
			else
				m_gameMenu.GoBack();
		}

		return true;
	}

	void UpdateFrame(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		BaseGameMode::UpdateFrame(ms, gameInput, menuInput);

		Platform::Service.InMenus(true);

		if (m_state == MenuState::Hidden)
		{
			m_ingameNotifier.Update(ms);
			m_ingameChat.Update(ms, menuInput);
			return;
		}
		
%PROFILE_START GameMenu Update
		m_gameMenu.Update(ms, gameInput, menuInput);
%PROFILE_STOP

		if (m_lostConnection)
		{
			m_lostConnection = false;
			ShowDialog("connectionlost", Resources::GetString(".menu.notifier.lostconnection"), Resources::GetString(".menu.ok"), m_gameMenu.GetCurrentMenu());
		}

		if (m_joinFailed != -1)
		{
			string prompt = "join";
			if (m_joinFailed == 1)
				prompt = "host";
			ShowDialog("joinfailed", Resources::GetString(".menu.notifier.joinfailed." + prompt), Resources::GetString(".menu.ok"), m_gameMenu.GetCurrentMenu());
			m_joinFailed = -1;
		}

		m_frameCount++;
	}

	vec2 GetCameraPos(int idt) override
	{
		float scalar = (m_frameCount + idt / 33.0f);
		vec2 camOffset = vec2(sin(scalar / 40.0f) * 8.0f, cos(scalar / 60.0f) * 4.0f);
		return m_camPos + camOffset;
	}
	
	void PreRenderFrame(int idt) override
	{
	}
	
	void RenderFrame(int idt, SpriteBatch& sb) override
	{
		sb.PushTransformation(mat::scale(mat4(), GetVarFloat("ui_scale")));
	
		int w = g_gameMode.m_wndWidth;
		int h = g_gameMode.m_wndHeight;

		if (m_state == MenuState::Hidden)
		{
			m_ingameChat.Draw(sb, idt);
			m_ingameNotifier.Draw(sb, idt);

			if (m_dialogWindow !is null && m_dialogWindow.m_visible)
			{
				m_dialogWindow.Draw(sb, idt);
				DrawMouse(idt, sb);
			}
			
			sb.PopTransformation();
			return;
		}

		m_gameMenu.Render(idt, sb);

		RenderWidgets(null, idt, sb);

		if (m_gameMenu.GetCurrentMenu().ShouldDisplayCursor())
			DrawMouse(idt, sb);
			
		sb.PopTransformation();
	}
	
	void RenderFrameLoading(int idt, SpriteBatch& sb)
	{
		BitmapFont@ loadFont = Resources::GetBitmapFont("gui/fonts/code2003_20_bold.fnt");
		if (loadFont is null)
			return;
		
		auto loadText = loadFont.BuildText(Resources::GetString(".menu.loading"), -1, TextAlignment::Center);
	
		sb.Begin(m_wndWidth, m_wndHeight, m_wndScale);
		sb.DrawSprite(null, vec4(-5, -5, m_wndWidth + 10, m_wndHeight + 10), vec4(), vec4(0, 0, 0, 1));
		sb.DrawString(vec2((m_wndWidth - loadText.GetWidth()) / 2, (m_wndHeight - loadText.GetHeight()) / 2), loadText);
		
		auto loadStates = Lobby::GetPlayerLoadStates();
		if (loadStates !is null)
		{
			BitmapFont@ plrFont = Resources::GetBitmapFont("gui/fonts/arial11.fnt");
			if (plrFont is null)
				return;
		
			for (uint i = 0; i < loadStates.length(); i++)
			{
				auto name = Lobby::GetPlayerName(loadStates[i].Peer);
				
				string text;
				
				switch(loadStates[i].Progress)
				{
				case 0:
					text = "\\c000000...\\d " + name;
					break;
				case 1:
					text = ".\\c000000..\\d " + name;
					break;
				case 2:
					text = "..\\c000000.\\d " + name;
					break;
				case 3:
					text = "... " + name;
					break;
				}
				
				auto plrText = plrFont.BuildText(text, -1, TextAlignment::Left);
				sb.DrawString(vec2(4, 2 + i * plrText.GetHeight()), plrText);
			}		
		}
		
		sb.End();
	}
	
	void ChatMessage(uint8 peer, string msg)
	{
		if (Lobby::IsPlayerLocal(peer))
			return;

		if (m_wChat !is null)
			m_wChat.PlayerChat(peer, msg);
	}

	void LobbyDataUpdate()
	{
		//NOTE: Steam seems to trigger a data update for the lobby right after it triggers
		//      a data update for a lobby member. Not sure why, but this means that you should
		//      be careful when setting lobby member data in this callback, as it could result
		//      in never-ending events. (I suppose the same counts for regular lobby data too)
	}

	void LobbyMemberDataUpdate(uint8 peer)
	{
		//NOTE: See note above in LobbyDataUpdate.
	}

	void HandleChatMessage(string message)
	{
		/*
		if (message.length() >= 1 && message.length() <= 2)
		{
			int num = parseInt(message);
			if (num < 1 || num > 42)
				return;

			if (!GetVarBool("ui_chat_dialog"))
				return;

			PlaySound2D(Resources::GetSoundEvent("event:/dialog/chat/chat_" + num));
		}
		*/
	}

	void LobbyCreated(bool loadingSave)
	{
		print("LobbyCreated()");
		Lobby::SetPrivate(m_hostPrivate);
		Lobby::SetLobbyData("name", m_hostName);
		Lobby::SetPlayerLimit(m_hostMaxPlayers);
		Lobby::SetLobbyData("max-level", m_hostMaxLevel);
		Lobby::SetLobbyData("min-level", m_hostMinLevel);

		GlobalCache::Set("start_host_ngp", "" + m_hostNgp);

		if (m_testLevel)
			Lobby::SetLevel("levels/test_multi.lvl");
		else
			Lobby::SetLevel("levels/town_outlook.lvl");
		Lobby::StartGame();
		//Lobby::SetJoinable(true);
	}

	void JoiningLobby()
	{
		@m_joiningMenu = Menu::JoiningLobbyMenu(m_gameMenu);
		m_gameMenu.GetCurrentMenu().OpenMenu(m_joiningMenu, "gui/main_menu/joininglobby.gui");
	}

	void LobbyInviteAccepted(uint64 id)
	{
		if (!Platform::Service.IsMultiplayerAvailable())
		{
			ShowDialog("", Resources::GetString(".menu.notifier.joinfailed.join"), Resources::GetString(".menu.ok"), null);
			return;
		}
	
		m_inviteAcceptID = id;
		auto menu = cast<Menu::HwrMenu>(m_gameMenu.m_menus[0]);
		if (menu is null)
		{
			PrintError("First menu is not HwrMenu!");
			return;
		}

		menu.ShowCharacterSelection("multi-invite");
	}

	void LobbyEntered()
	{
	}

	void LobbyFailedJoin(bool host)
	{
		m_joinFailed = host ? 1 : 0;

		if (m_joiningMenu !is null)
		{
			m_joiningMenu.Close();
			@m_joiningMenu = null;
		}

		ShowDialog("", Resources::GetString(".menu.notifier.joinfailed.join"), Resources::GetString(".menu.ok"), null);
	}

	void AddPlayer(uint8 peer) override
	{
		if (m_wChat !is null)
			m_wChat.PlayerSystem(peer, ".menu.lobby.chat.isjoined");
	}

	void RemovePlayer(uint8 peer, bool kicked) override
	{
		if (m_wChat !is null)
		{
			if (kicked)
				m_wChat.PlayerSystem(peer, ".menu.lobby.chat.iskicked");
			else
				m_wChat.PlayerSystem(peer, ".menu.lobby.chat.isleft");
		}
	}
	
	void SystemMessage(string name, SValue@ data)
	{
		if (name == "AddChat")
		{
			if (m_wChat !is null)
				m_wChat.AddChat(data.GetString());
		}
		else if (name == "SetNGP" && Network::IsServer())
			Lobby::SetLobbyData("ngp", data.GetInteger());
	}

	void PlayGame(int numPlrs)
	{
		// Singleplayer
		StartGame(numPlrs, "levels/town_outlook.lvl");
	}

	void OnBindingInput(ControllerType type, int key)
	{
		if (m_expectingInput !is null)
			m_expectingInput.ExpectedInput(type, key);
	}

	void LobbyList(array<uint64>@ lobbies)
	{
		auto listMenu = GetServerlistMenu();
		if (listMenu !is null)
			listMenu.OnLobbyList(lobbies);
	}
}
