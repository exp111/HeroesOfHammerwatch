namespace Menu
{
	class GameOptionsMenu : SubOptionsMenu
	{
		GameOptionsMenu(MenuProvider@ provider)
		{
			super(provider);

			m_isPopup = true;
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "cfg-language")
				OpenMenu(Menu::GameLanguagesMenu(m_provider), "gui/main_menu/options_game_languages.gui");
			else if (name == "cfg-skin")
				OpenMenu(Menu::PlayerSkinMenu(m_provider), "gui/main_menu/options_player_skin.gui");
			else
				SubOptionsMenu::OnFunc(sender, name);
		}
	}
}
