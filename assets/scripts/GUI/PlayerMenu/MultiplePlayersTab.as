class MultiplePlayersTab : PlayerMenuTab
{
	int m_currentPlayerIndex;

	void OnShow() override
	{
		PlayerMenuTab::OnShow();

		UpdateFromLocal();

		int connectedPlayers = NumConnectedPlayers();

		auto wPlayerButtonLeft = cast<SpriteButtonWidget>(m_widget.GetWidgetById("player-button-left"));
		if (wPlayerButtonLeft !is null)
			wPlayerButtonLeft.m_enabled = (connectedPlayers > 1);

		auto wPlayerButtonRight = cast<SpriteButtonWidget>(m_widget.GetWidgetById("player-button-right"));
		if (wPlayerButtonRight !is null)
			wPlayerButtonRight.m_enabled = (connectedPlayers > 1);
	}

	void UpdateFromLocal()
	{
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].local)
			{
				m_currentPlayerIndex = i;
				break;
			}
		}
		UpdateNow(g_players[m_currentPlayerIndex]);
	}

	void UpdateNow()
	{
		int curIndex = 0;
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;

			if (curIndex == m_currentPlayerIndex)
			{
				UpdateNow(g_players[i]);
				return;
			}
			curIndex++;
		}

		PrintError("Couldn't find player with active index " + m_currentPlayerIndex);
		UpdateFromLocal();
	}

	void UpdateNow(PlayerRecord@ record)
	{
		// Player face
		auto wFace = cast<SpriteWidget>(m_widget.GetWidgetById("playerface"));
		if (wFace !is null)
			wFace.SetSprite(GetFaceSprite(record.charClass, record.face));

		// Player header
		vec4 playerColor = ParseColorRGBA("#" + GetPlayerColor(record.peer) + "ff");

		auto wPlayerName = cast<TextWidget>(m_widget.GetWidgetById("playername"));
		if (wPlayerName !is null)
		{
			wPlayerName.SetText(Lobby::GetPlayerName(record.peer));
			wPlayerName.SetColor(playerColor);
		}

		auto wPlayerTitle = cast<TextWidget>(m_widget.GetWidgetById("playertitle"));
		if (wPlayerTitle !is null)
		{
			dictionary titleParams = {
				{ "name", record.GetName() },
				{ "title", Resources::GetString(record.GetTitle().m_name) },
				{ "lvl", "" + record.level },
				{ "class", Resources::GetString(".class." + record.charClass) }
			};
			wPlayerTitle.SetText(Resources::GetString(".hud.character.title", titleParams));
		}

		auto wPlayerHeader = cast<RectWidget>(m_widget.GetWidgetById("playerheader"));
		if (wPlayerHeader !is null)
		{
			if (record.local)
				wPlayerHeader.m_color = ParseColorRGBA("#202A26FF");
			else
			{
				ColorHSV hsv(playerColor);
				hsv.m_saturation *= 0.5f;
				hsv.m_value *= 0.35f;
				wPlayerHeader.m_color = tocolor(hsv.ToColorRGBA());
			}
		}
	}

	bool OnFunc(Widget@ sender, string name) override
	{
		if (name == "char-prev")
		{
			if (--m_currentPlayerIndex < 0)
				m_currentPlayerIndex = NumConnectedPlayers() - 1;
			UpdateNow();
			return true;
		}
		else if (name == "char-next")
		{
			if (++m_currentPlayerIndex >= NumConnectedPlayers())
				m_currentPlayerIndex = 0;
			UpdateNow();
			return true;
		}
		return false;
	}
}
