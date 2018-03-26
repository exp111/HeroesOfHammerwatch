class MenuSaveGameWidget : RectWidget
{
	Menu::LoadGameMenu@ m_owner;

	GameSaveInfo m_gsi;
	string m_filename;
	string m_label;

	SpriteWidget@ m_wSprite;

	MenuSaveGameWidget()
	{
		super();
	}

	Widget@ Clone() override
	{
		MenuSaveGameWidget@ w = MenuSaveGameWidget();
		CloneInto(w);
		return w;
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		RectWidget::Load(ctx);

		m_canFocus = true;
	}

	bool OnMouseDown(vec2 mousePos) override
	{
		m_wSprite.SetSprite(m_owner.m_spriteSaveGameFrameDown);
		return true;
	}

	bool OnMouseUp(vec2 mousePos) override
	{
		m_wSprite.SetSprite(m_owner.m_spriteSaveGameFrameHover);
		return true;
	}

	void OnMouseLeave(vec2 mousePos) override
	{
		m_wSprite.SetSprite(m_owner.m_spriteSaveGameFrame);
	}

	void OnMouseEnter(vec2 mousePos, bool forced) override
	{
		m_wSprite.SetSprite(m_owner.m_spriteSaveGameFrameHover);

		Widget@ wBox = m_host.m_widget.GetWidgetById("box-info");
		if (wBox is null)
			return;

		SpriteWidget@ wLogo = cast<SpriteWidget>(m_host.m_widget.GetWidgetById("logo"));
		if (wLogo !is null)
		{
			if (m_gsi.Scenario !is null)
			{
				TempTexture2D@ logoTexture = m_gsi.Scenario.LoadLogos();
				if (logoTexture !is null)
				{
					ScriptSprite@ logoSprite = ScriptSprite(logoTexture, Tweak::ScenarioLogoSmall);
					wLogo.SetSprite(logoSprite);
					wLogo.m_visible = true;
				}
				else
				{
					//TODO: Change to a default image
					@wLogo.m_ssprite = null;
					wLogo.m_visible = false;
				}
			}
			else
			{
				//TODO: Change to a default image
				@wLogo.m_ssprite = null;
				wLogo.m_visible = false;
			}
		}

		TextWidget@ wName = cast<TextWidget>(wBox.GetWidgetById("name"));
		if (wName !is null)
			wName.SetText(m_label);

		TextWidget@ wScenario = cast<TextWidget>(wBox.GetWidgetById("scenario"));
		if (wScenario !is null)
		{
			if (m_gsi.Scenario !is null)
				wScenario.SetText(Resources::GetString(m_gsi.Scenario.GetName()));
			else
				wScenario.SetText(Resources::GetString(".misc.unknown"));
		}

		TextWidget@ wLevel = cast<TextWidget>(wBox.GetWidgetById("level"));
		if (wLevel !is null)
		{
			bool found = false;

			if (m_gsi.Scenario !is null)
			{
				array<ScenarioStartLevel@>@ startLevels = m_gsi.Scenario.GetStartLevels();
				for (uint j = 0; j < startLevels.length(); j++)
				{
					ScenarioStartLevel@ ssl = startLevels[j];
					if (ssl.GetLevel() == m_gsi.LevelFilename)
					{
						found = true;
						wLevel.SetText(Resources::GetString(ssl.GetName()));
						break;
					}
				}
			}

			if (!found)
				wLevel.SetText(m_gsi.LevelFilename);
		}

		ctime tm = gmtime(m_gsi.Timestamp);
		string saveTime =
			formatInt(tm.year + 1900) + "-"
			+ formatInt(tm.mon + 1, "0", 2) + "-"
			+ formatInt(tm.mday, "0", 2) + " "
			+ formatInt(tm.hour, "0", 2) + ":"
			+ formatInt(tm.min, "0", 2) + ":"
			+ formatInt(tm.sec, "0", 2);

		TextWidget@ wLastSaved = cast<TextWidget>(wBox.GetWidgetById("last-saved"));
		if (wLastSaved !is null)
			wLastSaved.SetText(saveTime);

		TextWidget@ wPlayed = cast<TextWidget>(wBox.GetWidgetById("played"));
		if (wPlayed !is null)
			wPlayed.SetText(formatTime(m_gsi.PlaytimeTotal / 1000.0, false, false, false, true));
	}

	void Set(Menu::LoadGameMenu@ owner, GameSaveInfo &in gsi, string fnm)
	{
		@m_owner = owner;

		m_gsi = gsi;

		m_filename = fnm;
		m_label = fnm.substr(0, fnm.length() - 4);

		ButtonWidget@ wLoad = cast<ButtonWidget>(GetWidgetById("load"));
		if (wLoad !is null)
		{
			wLoad.SetText(m_label);
			wLoad.m_func = "load " + fnm;
		}

		@m_wSprite = cast<SpriteWidget>(GetWidgetById("sprite"));
	}

	bool PassesFilter(string str) override
	{
		return (m_label.toLower().findFirst(str) != -1);
	}
}

ref@ LoadMenuSaveGameWidget(WidgetLoadingContext &ctx)
{
	MenuSaveGameWidget@ w = MenuSaveGameWidget();
	w.Load(ctx);
	return w;
}
