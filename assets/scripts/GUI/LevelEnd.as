LevelEndScreen@ g_levelEndScreen;

class LevelEndScreen : IWidgetHoster
{
	bool m_visible;

	string m_level;
	string m_startID;
	bool m_endGame;
	ConceptBackground@ m_background;

	Widget@ m_wEndButtons;
	ScalableSpriteButtonWidget@ m_wContinueButton;

	ScoreDialog@ m_score;

	LevelEndScreen(GUIBuilder@ b)
	{
		b.AddWidgetProducer("counter", LoadCounterWidget);

		LoadWidget(b, "gui/levelend.gui");
		@m_background = ConceptBackground(b);
		@m_score = ScoreDialog(b, this);

		@m_wEndButtons = m_widget.GetWidgetById("endbuttons");
		@m_wContinueButton = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("ok"));
	}

	/**
	 * Compatibility layer due to revision 8988
	 */
	void _Deprecation8988() { if (_Deprecation8988Printed) return; _Deprecation8988Printed = true; PrintError("Warning: LevelEndScreens's BuildData is deprecated, use m_score.BuildData() instead."); } bool _Deprecation8988Printed;
	SValue@ BuildData() { _Deprecation8988(); return m_score.BuildData(); }

	void Show(SValue@ sv, string level, string startId, string background, bool endGame)
	{
		if (Network::IsServer())
			PauseGame(true, false);

		m_level = level;
		m_startID = startId;
		m_endGame = endGame;
		m_background.Load(background);

		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;
			g_players[i].readyState = false;
		}
		UpdateReadyText();

		if (m_endGame)
			m_wContinueButton.SetText(utf8string(Resources::GetString(".levelend.quit")).toUpper().plain());

		if (g_players.length() == 1 || Platform::GetSessionCount() > 1)
		{
			Widget@ wContinueBox = m_widget.GetWidgetById("continuebox");
			if (wContinueBox !is null)
				wContinueBox.m_width = 100;
		}

		@g_levelEndScreen = this;

		m_visible = true;
		g_gameMode.ReplaceTopWidgetRoot(this);

		string diffName = GetCurrentDifficultyName();
		dictionary params = { { "diff", utf8string(diffName).toUpper().plain() } };
		m_score.Set(sv, Resources::GetString(".levelend.header", params));
		m_score.Show();
	}

	bool IsVisible()
	{
		return m_visible;
	}

	void Update(int dt) override
	{
		if (!m_visible)
			return;

		m_background.Update(dt);
		m_score.Update(dt);
		IWidgetHoster::Update(dt);
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		if (!m_visible)
			return;

		m_background.Draw(sb, idt);
		m_score.Draw(sb, idt);
		IWidgetHoster::Draw(sb, idt);
	}

	void DoLayout() override
	{
		m_background.DoLayout();
		IWidgetHoster::DoLayout();
	}
	
	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "ok" && !m_score.IsVisible())
		{
			if (m_wContinueButton !is null)
				m_wContinueButton.SetText(Resources::GetString(".levelend.wait"));

			OnContinuePressed();

			if (!Network::IsServer())
				(Network::Message("LevelEndContinue")).SendToAll();
		}
		else if (name == "scoreclose")
			m_wEndButtons.m_visible = true;
		else if (name == "score")
		{
			m_wEndButtons.m_visible = false;
			m_score.Show();
		}
	}

	void UpdateReadyText()
	{
		TextWidget@ wReady = cast<TextWidget>(m_widget.GetWidgetById("ready"));
		if (wReady is null)
			return;

		if (g_players.length() == 1 || Platform::GetSessionCount() > 1)
		{
			wReady.m_visible = false;
			return;
		}

		wReady.m_visible = true;

		int totalPlayers = 0;
		int readyPlayers = 0;

		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;

			if (g_players[i].readyState)
				readyPlayers++;
			totalPlayers++;
		}

		dictionary params = { { "ready", readyPlayers }, { "total", totalPlayers } };
		wReady.SetText(Resources::GetString(".interface.playersready", params));
	}

	bool AllReady()
	{
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;

			if (!g_players[i].readyState)
				return false;
		}
		return true;
	}

	void ReadyChanged()
	{
		if (AllReady() || Platform::GetSessionCount() > 1)
		{
			if (Network::IsServer())
			{
				PauseGame(false, false);
				g_startId = m_startID;
				ChangeLevel(m_level);
			}
		}
		else
			UpdateReadyText();
	}

	void PeerReady(uint8 peer)
	{
		PlayerRecord@ player = GetPlayerRecordByPeer(peer);
		if (player is null)
			return;

		player.readyState = true;

		ReadyChanged();
	}

	void OnContinuePressed()
	{
		if (m_endGame)
		{
			PauseGame(false, false);
			StopScenario();
			return;
		}

		PlayerRecord@ player = GetLocalPlayerRecord();
		if (player !is null)
			player.readyState = true;

		ReadyChanged();
	}
}
