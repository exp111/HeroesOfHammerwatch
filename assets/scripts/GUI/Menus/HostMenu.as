namespace Menu
{
	class HostMenu : Menu
	{
		ScalableSpriteButtonWidget@ m_wButtonOK;
		TextInputWidget@ m_wName;

		HostMenu(MenuProvider@ provider)
		{
			super(provider);
		}

		void Initialize(GUIDef@ def) override
		{
			Menu::Initialize(def);

			@m_wButtonOK = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("ok"));
			@m_wName = cast<TextInputWidget>(m_widget.GetWidgetById("name"));
			
			if (m_wName !is null)
				m_wName.SetText(Resources::GetString(".mainmenu.host.name", { { "name", Lobby::GetPlayerName(0) } }));

			cast<MainMenu>(g_gameMode).m_hostPrivate = false;
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "privacy-changed")
			{
				auto group = cast<CheckBoxGroupWidget>(sender);
				cast<MainMenu>(g_gameMode).m_hostPrivate = (group.GetChecked().GetValue() == "private");
			}
			else if (name == "host")
			{
				cast<MainMenu>(g_gameMode).m_hostName = m_wName.m_text.plain();
			
				m_wButtonOK.m_enabled = false;
				Lobby::CreateLobby();
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
