namespace Menu
{
	class SplitscreenOptionsMenu : Menu
	{
		SplitscreenSelectionMenu@ m_splitscreenMenu;

		SplitscreenOptionsMenu(MenuProvider@ provider, SplitscreenSelectionMenu@ splitscreenMenu)
		{
			super(provider);

			m_isPopup = true;

			@m_splitscreenMenu = splitscreenMenu;
		}

		void Initialize(GUIDef@ def) override
		{
			Menu::Initialize(def);

			UpdateDifficultyTexts();
		}

		void UpdateDifficultyTexts()
		{
			ButtonWidget@ wDiff = cast<ButtonWidget>(m_widget.GetWidgetById("host-set-difficulty"));
			if (wDiff !is null)
			{
				string diffName = m_splitscreenMenu.GetDifficultyName(m_splitscreenMenu.m_startDifficulty);
				wDiff.SetText(Resources::GetString(".menu.lobby.info.difficulty") + " " + utf8string(diffName).toUpper().plain());
				wDiff.SetEnabled(true);
			}

			TextWidget@ wDesc = cast<TextWidget>(m_widget.GetWidgetById("option-diff-desc"));
			if (wDesc !is null)
			{
				string diff;
				switch (m_splitscreenMenu.m_startDifficulty)
				{
					case GameDifficulty::Easy: diff = Resources::GetString(".menu.splayer.difficulty.easy.desc"); break;
					case GameDifficulty::Normal: diff = Resources::GetString(".menu.splayer.difficulty.normal.desc"); break;
					case GameDifficulty::Hard: diff = Resources::GetString(".menu.splayer.difficulty.hard.desc"); break;
					case GameDifficulty::Serious: diff = Resources::GetString(".menu.splayer.difficulty.serious.desc"); break;
				}
				wDesc.SetText(diff);
			}
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto parse = name.split(" ");
			if (parse[0] == "host-set-mods")
				OpenMenu(SwitchesMenu(m_provider, this, m_splitscreenMenu.m_startScenario, m_splitscreenMenu.m_startMods, true), "gui/main_menu/switches.gui");
			else if (parse[0] == "host-set-difficulty")
			{
				m_splitscreenMenu.OnFunc(sender, "change-difficulty");
				UpdateDifficultyTexts();
			}
			else if (parse[0] == "setcustom" || parse[0] == "set-mod")
				m_splitscreenMenu.OnFunc(sender, name);
			else
			{
				if (name == "back")
				{
					//TODO..?
					//m_splitscreenMenu.LobbyDataUpdate(true);
				}
				Menu::OnFunc(sender, name);
			}
		}
	}
}
