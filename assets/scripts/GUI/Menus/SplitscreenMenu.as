namespace Menu
{
	class SplitscreenMenu : Menu
	{
		SplitscreenMenu(MenuProvider@ provider)
		{
			super(provider);

			m_isPopup = true;
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "newgame")
				OpenMenu(SplitscreenSelectionMenu(m_provider), "gui/main_menu/splitscreenselection.gui");
			else if (name == "loadgame")
			{
				auto loadMenu = LoadGameMenu(m_provider, false);
				loadMenu.m_splitscreen = true;
				OpenMenu(loadMenu, "gui/main_menu/loadgame.gui");
			}

			else
				Menu::OnFunc(sender, name);
		}
	}
}
