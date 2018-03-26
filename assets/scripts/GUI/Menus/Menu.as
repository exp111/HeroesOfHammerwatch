namespace Menu
{
	class Menu : IWidgetHoster
	{
		MenuProvider@ m_provider;

		bool m_isPopup;
		bool m_closing;

		Menu(MenuProvider@ provider)
		{
			@m_provider = provider;

			m_isPopup = false;
			m_closing = false;
		}

		void Initialize(GUIDef@ def) {}

		void SetActive()
		{
			g_gameMode.ReplaceTopWidgetRoot(this);
		}

		void OpenMenu(string path)
		{
			Menu::SimpleMenu@ menu = Menu::SimpleMenu(m_provider);
			m_provider.m_menus.insertLast(menu);
			GUIDef@ def = menu.LoadWidget(g_gameMode.m_guiBuilder, path);
			menu.Initialize(def);
			menu.SetActive();
		}

		void OpenMenu(Menu::Menu@ menu, string path, int index = -1)
		{
			if (index == -1)
				m_provider.m_menus.insertLast(menu);
			else
				m_provider.m_menus.insertAt(index, menu);
			GUIDef@ def = menu.LoadWidget(g_gameMode.m_guiBuilder, path);
			menu.Initialize(def);
			menu.SetActive();
		}

		bool GoBack()
		{
			return Close();
		}

		bool ShouldDisplayCursor() { return true; }

		bool Close()
		{
			if (m_closing)
				return true;

			BaseGameMode@ gm = cast<BaseGameMode>(g_gameMode);
			if (gm !is null)
				gm.m_tooltip.Hide();

			m_provider.m_menus[m_provider.m_menus.length() - 2].Show();
			m_closing = true;

			return true;
		}

		bool RemoveFromProvider()
		{
			int index = m_provider.m_menus.findByRef(this);
			if (index != -1)
			{
				m_provider.m_menus.removeAt(index);
				return true;
			}
			return false;
		}

		void Show()
		{
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "connectionlost")
				StopScenario();
			else if (name == "back")
				Close();
		}
	}
}
