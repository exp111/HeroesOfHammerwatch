class MenuServerListItem : ScalableSpriteButtonWidget
{
	Menu::ServerlistMenu@ m_owner;

	string m_serverName;
	int m_serverPlayers;
	int m_serverPlayersMax;

	BitmapString@ m_textPlayers;
	BitmapString@ m_textPing;

	MenuServerListItem()
	{
		super();
	}

	int opCmp(const Widget@ w) override
	{
		if (m_owner is null)
			return 0;

		const MenuServerListItem@ wServer = cast<MenuServerListItem>(w);
		if (wServer is null)
			return 0;

		if (m_owner.m_sortColumn == Menu::ServerlistSortColumn::None)
			return 0;
		else if (m_owner.m_sortColumn == Menu::ServerlistSortColumn::Name)
			return m_serverName.opCmp(wServer.m_serverName) * m_owner.m_sortDir;
		else if (m_owner.m_sortColumn == Menu::ServerlistSortColumn::Players)
		{
			if (m_serverPlayers < wServer.m_serverPlayers)
				return 1 * m_owner.m_sortDir;
			else if (m_serverPlayers > wServer.m_serverPlayers)
				return -1 * m_owner.m_sortDir;
			return 0;
		}

		return 0;
	}

	Widget@ Clone() override
	{
		MenuServerListItem@ w = MenuServerListItem();
		CloneInto(w);
		return w;
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		ScalableSpriteButtonWidget::Load(ctx);

		m_textOffset.x = 10;
	}

	void Set(Menu::ServerlistMenu@ owner, string name, int players, int playersMax, int lobbyPing)
	{
		@m_owner = owner;

		m_serverName = name;
		m_serverPlayers = players;
		m_serverPlayersMax = playersMax;

		SetText(name);

		@m_textPlayers = m_font.BuildText(players + " / " + playersMax);
		m_textPlayers.SetColor(m_colorText);

		string ping;
		
		if (lobbyPing < 0)
			ping = "?";
		else if (lobbyPing > 999)
			ping = "999";
		else
			ping = "" + lobbyPing;
			
		@m_textPing = m_font.BuildText(ping);
		m_textPing.SetColor(m_colorText);
	}

	bool PassesFilter(string str) override
	{
		if (m_serverName.toLower().findFirst(str) != -1)
			return true;
		return false;
	}

	void DoDraw(SpriteBatch& sb, vec2 pos) override
	{
		ScalableSpriteButtonWidget::DoDraw(sb, pos);

		if (m_textPlayers !is null)
		{
			sb.DrawString(pos + vec2(
				m_width - m_textPlayers.GetWidth() - 10 /* - 24 */,
				m_height / 2.0f - m_textPlayers.GetHeight() / 2.0f
			), m_textPlayers);
		}
		/*
		if (m_textPing !is null)
		{
			sb.DrawString(pos + vec2(
				m_width - m_textPing.GetWidth() - 10,
				m_height / 2.0f - m_textPing.GetHeight() / 2.0f
			), m_textPing);
		}
		*/
	}
}

ref@ LoadMenuServerListItemWidget(WidgetLoadingContext &ctx)
{
	MenuServerListItem@ w = MenuServerListItem();
	w.Load(ctx);
	return w;
}
