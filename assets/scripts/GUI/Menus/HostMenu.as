namespace Menu
{
	class HostMenu : Menu
	{
		ScalableSpriteButtonWidget@ m_wButtonOK;
		TextInputWidget@ m_wName;

		SliderWidget@ m_wMaxPlayers;
		SliderWidget@ m_wMaxLevel;
		SliderWidget@ m_wMinLevel;

		TextWidget@ m_wNgp;
		SpriteButtonWidget@ m_wNgpLeft;
		SpriteButtonWidget@ m_wNgpRight;

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

			@m_wMaxPlayers = cast<SliderWidget>(m_widget.GetWidgetById("max-players"));
			if (m_wMaxPlayers !is null)
			{
				int maxLimit = GetVarInt("g_multiplayer_limit");
				if (maxLimit < 4)
					maxLimit = 4;
				m_wMaxPlayers.m_max = float(maxLimit);
				m_wMaxPlayers.m_default = float(maxLimit);
				m_wMaxPlayers.Reset();
			}

			@m_wMaxLevel = cast<SliderWidget>(m_widget.GetWidgetById("max-level"));
			@m_wMinLevel = cast<SliderWidget>(m_widget.GetWidgetById("min-level"));

			@m_wNgp = cast<TextWidget>(m_widget.GetWidgetById("ngp"));
			@m_wNgpLeft = cast<SpriteButtonWidget>(m_widget.GetWidgetById("ngp-left"));
			@m_wNgpRight = cast<SpriteButtonWidget>(m_widget.GetWidgetById("ngp-right"));

			UpdateNgp();

			cast<MainMenu>(g_gameMode).m_hostPrivate = false;
		}

		void UpdateNgp()
		{
			auto gm = cast<MainMenu>(g_gameMode);

			m_wNgp.SetText("+" + gm.m_hostNgp);
			m_wNgpLeft.m_enabled = (gm.m_hostNgp > 0);
			m_wNgpRight.m_enabled = (gm.m_hostNgp < gm.m_town.m_highestNgp);
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "privacy-changed")
			{
				auto checkable = cast<ICheckableWidget>(sender);
				cast<MainMenu>(g_gameMode).m_hostPrivate = (checkable.IsChecked());
			}
			else if (name == "host")
			{
				auto gm = cast<MainMenu>(g_gameMode);

				gm.m_hostName = m_wName.m_text.plain();
				gm.m_hostMaxPlayers = m_wMaxPlayers.GetValueInt();
				gm.m_hostMaxLevel = m_wMaxLevel.GetValueInt();
				gm.m_hostMinLevel = m_wMinLevel.GetValueInt();

				m_wButtonOK.m_enabled = false;
				Lobby::CreateLobby();
			}
			else if (name == "levels-changed")
			{
				float maxLevel = m_wMaxLevel.m_value;
				float minLevel = m_wMinLevel.m_value;

				if (minLevel > maxLevel)
					m_wMinLevel.SetValue(maxLevel);
			}
			else if (name == "ngp-prev")
			{
				auto gm = cast<MainMenu>(g_gameMode);

				gm.m_hostNgp--;
				if (gm.m_hostNgp < 0)
					gm.m_hostNgp = 0;

				UpdateNgp();
			}
			else if (name == "ngp-next")
			{
				auto gm = cast<MainMenu>(g_gameMode);

				gm.m_hostNgp++;
				if (gm.m_hostNgp > gm.m_town.m_highestNgp)
					gm.m_hostNgp = gm.m_town.m_highestNgp;

				UpdateNgp();
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
