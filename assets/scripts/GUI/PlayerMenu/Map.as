class PlayerMenuMapTab : PlayerMenuTab
{
	vec2 m_mapDragLast;
	vec2 m_camPos;
	vec4 m_mapColor;

	Widget@ m_wMap;
	TextWidget@ m_wInfo;

	bool m_showFog = true;

	PlayerMenuMapTab()
	{
		m_id = "map";

		m_mapColor = ParseColorRGBA("#" + Tweak::PlayerMenuMapColor + "FF");
	}

	void OnCreated() override
	{
		@m_wMap = m_widget.GetWidgetById("map");
		@m_wInfo = cast<TextWidget>(m_widget.GetWidgetById("info"));
	}

	int GetMapScale() { return 4; }
	int GetMapWidth() { return m_wMap.m_width + 64; }
	int GetMapHeight() { return m_wMap.m_height + 64; }

	void OnShow() override
	{
		auto localPlayer = GetLocalPlayer();
		if (localPlayer is null)
			return;

		m_camPos = xy(localPlayer.m_unit.GetPosition());

		auto gm = cast<Campaign>(g_gameMode);
		ivec3 level = CalcLevel(gm.m_levelCount);

		if (cast<Town>(gm) !is null)
			m_wInfo.SetText(Resources::GetString(".world.town"));
		else
		{
			string info = "";

			if (level.x == 0)
				info += Resources::GetString(".world.mines");
			else
				info += Resources::GetString(".world.tower");

			info += ", ";

			info += Resources::GetString(".world.acts." + level.x);
			info += " - ";

			dictionary params = { { "num", level.z + 1 } };
			info += Resources::GetString(".world.floor", params);

			m_wInfo.SetText(info);
		}
	}

	void Update(int dt) override
	{
		auto gm = cast<BaseGameMode>(g_gameMode);
		vec2 mousePos = (gm.m_mice[0].GetPos(0) / gm.m_wndScale);

		MenuInput@ mi = GetMenuInput();
		if (m_wMap.GetRectangle().Contains(mousePos))
		{
			if (!mi.Forward.Pressed && mi.Forward.Down)
				m_camPos += (m_mapDragLast - mousePos) * GetMapScale();
			m_mapDragLast = mousePos;
		}
	}

	void AfterUpdate() override
	{
		auto gm = cast<Campaign>(g_gameMode);

		int scale = GetMapScale();
		int width = GetMapWidth() * scale;
		int height = GetMapHeight() * scale;

		gm.m_minimap.Prepare(g_scene, m_camPos, width, height, ~0);
	}

	vec4 GetMapColor()
	{
		if (!m_showFog)
			return vec4();
		return m_mapColor;
	}

	bool ShouldShowFog()
	{
		if (GetVarBool("ui_hide_fog"))
			return false;

		auto plr = GetLocalPlayerRecord();
		if (plr !is null && plr.items.find("old-map") != -1)
			return false;

		return true;
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		auto gm = cast<Campaign>(g_gameMode);

		vec2 pos = m_wMap.m_origin;
		int width = GetMapWidth();
		int height = GetMapHeight();

		sb.PushClipping(vec4(
			pos.x, pos.y,
			m_wMap.m_width, m_wMap.m_height
		));

		vec2 mapPos = pos - vec2(width - m_wMap.m_width, height - m_wMap.m_height) / 2.0f;
		sb.DrawMinimap(mapPos, gm.m_minimap, width, height, GetMapColor());
		//sb.DrawMinimap(pos - vec2(0, 32), gm.m_minimap, width, height, GetMapColor());

		sb.PopClipping();
	}
}
