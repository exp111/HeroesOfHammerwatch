namespace Menu
{
	class FrontMenu : HwrMenu
	{
		Widget@ m_wPopupMultiplayer;
		Widget@ m_wPopupOptions;
		Widget@ m_wPopupConfirmRestart;
		Widget@ m_wPopupConfirmStop;

		array<Widget@> m_arrPopups;

		FrontMenu(MenuProvider@ provider)
		{
			super(provider);
		}

		void Initialize(GUIDef@ def) override
		{
			HwrMenu::Initialize(def);

			auto wMultiTest = m_widget.GetWidgetById("multi-test");
			if (wMultiTest !is null)
				wMultiTest.m_visible = GetVarBool("g_multi_test");

			m_arrPopups.insertLast(@m_wPopupMultiplayer = m_widget.GetWidgetById("popup-multiplayer"));
			m_arrPopups.insertLast(@m_wPopupOptions = m_widget.GetWidgetById("popup-options"));
			m_arrPopups.insertLast(@m_wPopupConfirmRestart = m_widget.GetWidgetById("popup-restart"));
			m_arrPopups.insertLast(@m_wPopupConfirmStop = m_widget.GetWidgetById("popup-stop"));
		}

		bool Close() override
		{
			return false;
		}

		void TogglePopupMenu(Widget@ w)
		{
			for (uint i = 0; i < m_arrPopups.length(); i++)
			{
				if (m_arrPopups[i] is null)
					continue;

				if (m_arrPopups[i] is w)
					m_arrPopups[i].m_visible = !m_arrPopups[i].m_visible;
				else
					m_arrPopups[i].m_visible = false;
			}
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "single")
				ShowCharacterSelection("");

			else if (name == "multi-test")
			{
				cast<MainMenu>(g_gameMode).m_testLevel = true;
				PickCharacter(0);
				Lobby::CreateLobby();
			}

			else if (name == "multi")
				TogglePopupMenu(m_wPopupMultiplayer);
			else if (name == "multi-host")
				ShowCharacterSelection("multi-host");
			else if (name == "multi-serverlist")
				ShowCharacterSelection("multi-serverlist");

			else if (name == "options")
				TogglePopupMenu(m_wPopupOptions);
			else if (name == "options-gameplay")
				OpenMenu(GameOptionsMenu(m_provider), "gui/main_menu/options_game.gui");
			else if (name == "options-graphics")
				OpenMenu(GraphicsMenu(m_provider), "gui/main_menu/options_graphics.gui");
			else if (name == "options-sound")
				OpenMenu(SoundMenu(m_provider), "gui/main_menu/options_sound.gui");
			else if (name == "options-controls")
				OpenMenu(ControlsMenu(m_provider), "gui/main_menu/options_controls.gui");
			else if (name == "options-credits")
				OpenMenu(CreditsMenu(m_provider), "gui/main_menu/credits.gui");

			else if (name == "resume")
				ResumeGame();

			else if (name == "restart" || name == "restart-no")
				TogglePopupMenu(m_wPopupConfirmRestart);
			else if (name == "restart-yes")
			{
				ResumeGame();
				GlobalCache::Set("main_restart", "1");
			}

			else if (name == "quit")
				QuitGame();

			else if (name == "stop" || name == "stop-no")
				TogglePopupMenu(m_wPopupConfirmStop);
			else if (name == "stop-yes")
				StopScenario();

			else
				HwrMenu::OnFunc(sender, name);
		}
	}
}
