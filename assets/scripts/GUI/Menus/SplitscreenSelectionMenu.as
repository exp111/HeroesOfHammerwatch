namespace Menu
{
	class SplitscreenPlayer
	{
		int m_index;

		GameInput@ m_inputGame;
		MenuInput@ m_inputMenu;

		ControlMap@ m_map;

		RectWidget@ m_widget;

		string m_skin = "serious_sam";

		SplitscreenPlayer(int index)
		{
			m_index = index;

			@m_inputGame = Platform::GetGameInput(index);
			@m_inputMenu = Platform::GetMenuInput(index);

			auto maps = m_inputGame.GetControlMaps();
			if (maps.length() == 1)
				@m_map = maps[0];
			else
				PrintError("There are " + maps.length() + " maps assigned to index " + index);
		}

		void DisplayName(int playerIndex)
		{
			auto gm = cast<BaseGameMode>(g_gameMode);
			if (playerIndex == 0)
			{
				if (!m_map.UseMouseLook)
				{
					@gm.m_mice[0].m_hackSecondGame = m_inputGame;
					@gm.m_mice[0].m_hackSecondMenu = m_inputMenu;
				}
				else
				{
					@gm.m_mice[0].m_hackSecondGame = null;
					@gm.m_mice[0].m_hackSecondMenu = null;
				}
			}

			m_widget.m_color = ParseColorRGBA("#" + GetPlayerColor(playerIndex) + "7f");

			TextWidget@ wPlayerName = cast<TextWidget>(m_widget.GetWidgetById("name"));
			if (wPlayerName !is null)
			{
				dictionary params = { { "num", playerIndex + 1 } };
				wPlayerName.SetText(Resources::GetString(".player.num", params));
			}

			Widget@ wPrompt = m_widget.GetWidgetById("prompt");
			if (wPrompt !is null)
				wPrompt.m_visible = !m_map.UseMouseLook;

			Widget@ wKbmButtonLeft = m_widget.GetWidgetById("kbm-skin-left");
			if (wKbmButtonLeft !is null)
				wKbmButtonLeft.m_visible = m_map.UseMouseLook;

			Widget@ wKbmButtonRight = m_widget.GetWidgetById("kbm-skin-right");
			if (wKbmButtonRight !is null)
				wKbmButtonRight.m_visible = m_map.UseMouseLook;

			Widget@ wGpSkinLeft = m_widget.GetWidgetById("gp-skin-left");
			if (wGpSkinLeft !is null)
				wGpSkinLeft.m_visible = !m_map.UseMouseLook;

			Widget@ wGpSkinRight = m_widget.GetWidgetById("gp-skin-right");
			if (wGpSkinRight !is null)
				wGpSkinRight.m_visible = !m_map.UseMouseLook;

			SetSkin(m_skin);
		}

		void SetSkin(string skin)
		{
			m_skin = skin;

			SpriteWidget@ wSkin = cast<SpriteWidget>(m_widget.GetWidgetById("skin-preview"));
			if (wSkin is null)
				return;

			Texture2D@ tex = Resources::GetTexture2D("actors/players/skins/" + skin + "/hud.png");
			wSkin.SetSprite(ScriptSprite(tex, vec4(96, 0, 32, 32)));
		}
	}

	class SplitscreenSelectionMenu : Menu
	{
		array<SplitscreenPlayer@> m_players;

		array<string> m_skins = {
			"serious_sam",
			"bogus_beret",
			"canned_cain",
			"hilarious_harry",
			"marty_mcparty",
			"minotaur_mike",
			"ninja_nobody",
			"pirate_pete",
			"rocking_ryan",
			"wild_wyatt"
		};

		Widget@ m_wPlayerTemplate;
		Widget@ m_wPlayerList;

		Sprite@ m_spriteLogosDefault;

		ScenarioInfo@ m_startScenario;
		string m_startLevel;
		array<string> m_startMods;
		GameDifficulty m_startDifficulty = GameDifficulty::Normal;

		string m_saveGame;

		SplitscreenSelectionMenu(MenuProvider@ provider)
		{
			super(provider);

			// Some high number will cause sequential automatic assignments which is what we want for this menu
			GetControlBindings().AssignControls(16);
		}

		void Initialize(GUIDef@ def) override
		{
			@m_spriteLogosDefault = def.GetSprite("logos-default-small");

			@m_wPlayerTemplate = m_widget.GetWidgetById("playertemplate");
			@m_wPlayerList = m_widget.GetWidgetById("playerlist");

			if (m_saveGame != "")
			{
				auto wButtonOptions = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("change-options"));
				if (wButtonOptions !is null)
					wButtonOptions.m_enabled = false;

				GameSaveInfo gsi = Saves::ReadInfo(m_saveGame);

				if (gsi.Scenario !is null)
					SetStartScenario(gsi.Scenario);

				ScenarioStartLevel@ level = null;
				auto levels = m_startScenario.GetStartLevels();
				for (uint i = 0; i < levels.length(); i++)
				{
					if (levels[i].GetLevel() == gsi.LevelFilename)
					{
						@level = levels[i];
						break;
					}
				}
				if (level !is null)
					SetStartLevel(level);

				m_startDifficulty = gsi.Difficulty;
				SetCurrentDifficulty();
			}
			else
			{
				SetCurrentDifficulty();
			}
		}

		bool Close() override
		{
			if (Menu::Close())
			{
				auto gm = cast<BaseGameMode>(g_gameMode);
				@gm.m_mice[0].m_hackSecondGame = null;
				@gm.m_mice[0].m_hackSecondMenu = null;

				GetControlBindings().AssignControls(1);
				return true;
			}
			return false;
		}

		SplitscreenPlayer@ GetKbmPlayer()
		{
			for (uint i = 0; i < m_players.length(); i++)
			{
				if (m_players[i].m_map.UseMouseLook)
					return m_players[i];
			}
			return null;
		}

		SplitscreenPlayer@ GetInput(int index)
		{
			for (uint i = 0; i < m_players.length(); i++)
			{
				if (m_players[i].m_index == index)
					return m_players[i];
			}
			return null;
		}

		bool HasJoined(int index)
		{
			return (GetInput(index) !is null);
		}

		void RemoveInput(int index)
		{
			for (uint i = 0; i < m_players.length(); i++)
			{
				if (m_players[i].m_index == index)
				{
					m_players[i].m_widget.RemoveFromParent();
					m_players.removeAt(i);
					for (uint j = i; j < m_players.length(); j++)
						m_players[j].DisplayName(j);
					break;
				}
			}
		}

		void JoinInput(int index)
		{
			int playerIndex = m_players.length();
			SplitscreenPlayer@ player = SplitscreenPlayer(index);

			if (player.m_map.UseMouseLook)
				playerIndex = 0;

			RectWidget@ wPlayer = cast<RectWidget>(m_wPlayerTemplate.Clone());
			wPlayer.SetID("");
			wPlayer.m_visible = true;

			m_wPlayerList.AddChild(wPlayer, playerIndex);
			@player.m_widget = wPlayer;

			player.DisplayName(playerIndex);
			m_players.insertAt(playerIndex, player);

			for (uint i = playerIndex + 1; i < m_players.length(); i++)
				m_players[i].DisplayName(i);
		}

		void SkinInput(int index, int dir)
		{
			SplitscreenPlayer@ ply = GetInput(index);
			if (ply is null)
				return;

			string newSkin = ply.m_skin;

			int skinIndex = m_skins.find(ply.m_skin);
			if (skinIndex != -1)
			{
				skinIndex += dir;
				if (skinIndex < 0)
					skinIndex = m_skins.length() - 1;
				else if (skinIndex >= int(m_skins.length()))
					skinIndex = 0;
				newSkin = m_skins[skinIndex];
			}

			int playerIndex = m_players.findByRef(ply);
			GlobalCache::Set("skin_" + playerIndex, newSkin);

			ply.SetSkin(newSkin);
		}

		bool GoBack() override
		{
			if (m_players.length() == 0)
				return Close();
			return true;
		}

		void Update(int dt) override
		{
			if (m_players.length() > 0 && !m_players[0].m_map.UseMouseLook)
			{
				auto mouse = cast<BaseGameMode>(g_gameMode).m_mice[0];
				auto mi = mouse.UsingSecondaryMenuInput();
				if (mi !is null)
					mouse.m_inputMenu.Forward = mi.Forward;
			}

			int numInputs = Platform::GetInputCount();
			for (int i = 0; i < numInputs; i++)
			{
				auto gi = Platform::GetGameInput(i);
				auto mi = Platform::GetMenuInput(i);

				if (i == 0 && mi.Toggle.Pressed)
				{
					Close();
					return;
				}

				if (HasJoined(i))
				{
					if (mi.Back.Pressed)
						RemoveInput(i);
					else if (mi.Left.Pressed)
						SkinInput(i, -1);
					else if (mi.Right.Pressed)
						SkinInput(i, 1);
					continue;
				}

				if (gi.UsingMouseLook && gi.Use.Pressed)
					JoinInput(i);
				else if (!gi.UsingMouseLook && AnyPressed(gi, mi))
					JoinInput(i);
			}

			Menu::Update(dt);
		}

		void SetStartScenario(ScenarioInfo@ scenario)
		{
			// Clear start mods if we switch scenario
			if (m_startScenario !is scenario)
			{
				m_startMods.removeRange(0, m_startMods.length());

				// Set default-on switches
				array<ScenarioModification@>@ arrMods = scenario.GetModifications();
				for (uint i = 0; i < arrMods.length(); i++)
				{
					if (arrMods[i].GetDefaultOn())
						m_startMods.insertLast(arrMods[i].GetID());
				}
			}

			@m_startScenario = scenario;

			TextWidget@ wScenarioName = cast<TextWidget>(m_widget.GetWidgetById("scenario-name"));
			if (wScenarioName !is null)
				wScenarioName.SetText(Resources::GetString(m_startScenario.GetName()));

			SpriteWidget@ wLogo = cast<SpriteWidget>(m_widget.GetWidgetById("logo"));
			if (wLogo !is null)
			{
				TempTexture2D@ logoTexture = null;
				if (m_startScenario !is null)
					@logoTexture = m_startScenario.LoadLogos();

				if (logoTexture !is null)
				{
					ScriptSprite@ logoSprite = ScriptSprite(logoTexture, Tweak::ScenarioLogoSmall);
					wLogo.SetSprite(logoSprite);
				}
				else
					wLogo.SetSprite(m_spriteLogosDefault);
			}

			auto startLevels = m_startScenario.GetStartLevels();
			if (startLevels.length() > 0)
				SetStartLevel(startLevels[0]);
			else
				PrintError("No start levels for scenario '" + m_startScenario.GetID() + "'");
		}

		void SetStartLevel(ScenarioStartLevel@ level)
		{
			m_startLevel = level.GetLevel();

			TextWidget@ wLevelName = cast<TextWidget>(m_widget.GetWidgetById("scenario-level"));
			if (wLevelName !is null)
				wLevelName.SetText(Resources::GetString(level.GetName()));
		}

		void SetCurrentDifficulty()
		{
			ScalableSpriteButtonWidget@ wDiff = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("difficulty"));
			if (wDiff !is null)
				wDiff.SetText(utf8string(GetDifficultyName(m_startDifficulty)).toUpper().plain());
		}

		string GetDifficultyName(GameDifficulty diff)
		{
			switch (diff)
			{
				case GameDifficulty::Easy: return Resources::GetString(".difficulty.easy");
				case GameDifficulty::Normal: return Resources::GetString(".difficulty.normal");
				case GameDifficulty::Hard: return Resources::GetString(".difficulty.hard");
				case GameDifficulty::Serious: return Resources::GetString(".difficulty.serious");
			}
			return Resources::GetString(".difficulty.normal");
		}

		GameDifficulty ToDifficulty(int diff)
		{
			switch (diff)
			{
				case 0: return GameDifficulty::Easy;
				case 1: return GameDifficulty::Normal;
				case 2: return GameDifficulty::Hard;
				case 3: return GameDifficulty::Serious;
			}
			return GameDifficulty::Normal;
		}

		void ShowLoadFailedDialog()
		{
			print("Failed to load savegame!");
			g_gameMode.ShowDialog(
				"",
				Resources::GetString(".menu.loadgame.failed"),
				Resources::GetString(".menu.ok"),
				this
			);
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto parse = name.split(" ");
			if (parse[0] == "kbm-skin")
			{
				SplitscreenPlayer@ kbmPlayer = GetKbmPlayer();
				if (kbmPlayer !is null)
					SkinInput(kbmPlayer.m_index, (parse[1] == "left" ? -1 : 1));
			}
			else if (parse[0] == "change-options")
			{
				OpenMenu(SplitscreenOptionsMenu(m_provider, this), "gui/main_menu/splitscreenoptions.gui");
			}
			else if (parse[0] == "change-switches")
			{
				OpenMenu(SwitchesMenu(m_provider, this, m_startScenario, m_startMods, true), "gui/main_menu/switches.gui");
			}
			else if (parse[0] == "set-mod")
			{
				int existingIndex = m_startMods.find(parse[1]);
				if (parse[2] == "on")
				{
					if (existingIndex == -1)
						m_startMods.insertLast(parse[1]);
				}
				else
				{
					if (existingIndex != -1)
						m_startMods.removeAt(existingIndex);
				}
			}
			else if (parse[0] == "change-difficulty")
			{
				switch (m_startDifficulty)
				{
					case GameDifficulty::Easy: m_startDifficulty = GameDifficulty::Normal; break;
					case GameDifficulty::Normal: m_startDifficulty = GameDifficulty::Hard; break;
					case GameDifficulty::Hard: m_startDifficulty = GameDifficulty::Serious; break;
					case GameDifficulty::Serious: m_startDifficulty = GameDifficulty::Easy; break;
				}

				SetCurrentDifficulty();
			}
			else if (parse[0] == "start")
			{
				if (m_players.length() == 0)
					g_gameMode.ShowDialog("", Resources::GetString(".menu.splitscreen.noplayers"), Resources::GetString(".menu.ok"), this);
				else
				{
					auto cb = GetControlBindings();
					cb.UnassignAll();
					for (uint i = 0; i < m_players.length(); i++)
						cb.Assign(i, m_players[i].m_map);

					if (m_saveGame == "")
						cast<MainMenu>(g_gameMode).PlayGame(m_players.length());
					else
					{
						SetVar("g_start_sessions", m_players.length());
						if (!Saves::Load(m_saveGame))
							ShowLoadFailedDialog();
					}
				}
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
