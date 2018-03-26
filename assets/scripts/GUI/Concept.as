class Concept : IWidgetHoster
{
	bool m_visible;

	ConceptBackground@ m_background;
	array<UnitPtr>@ m_onClosed;

	Concept(GUIBuilder@ b)
	{
		@m_background = ConceptBackground(b);

		LoadWidget(b, "gui/concept.gui");
	}

	bool BlocksLower() override
	{
		return true;
	}

	bool IsVisible()
	{
		return m_visible;
	}

	void Show(string background, string displayText, string buttonText, array<UnitPtr>@ onClosed, string plattImage = "")
	{
		@m_onClosed = onClosed;

		if (plattImage == "")
			m_background.Load(background);
		else
			m_background.LoadPlatt(plattImage, background);

		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;
			g_players[i].readyState = false;
		}
		UpdateReadyText();

		m_visible = true;

		auto wDisplayText = cast<TextWidget>(m_widget.GetWidgetById("displaytext"));
		if (wDisplayText !is null)
			wDisplayText.SetText(Resources::GetString(displayText), wDisplayText.m_textWidth, TextAlignment::Center);

		if (buttonText != "")
		{
			auto wButtonText = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("continue"));
			if (wButtonText !is null)
				wButtonText.SetText(Resources::GetString(buttonText));
		}

		if (g_players.length() == 1 || Platform::GetSessionCount() > 1)
		{
			Widget@ wContinueBox = m_widget.GetWidgetById("continuebox");
			if (wContinueBox !is null)
				wContinueBox.m_width = 188;
		}

		g_gameMode.AddWidgetRoot(this);
	}

	void Hide()
	{
		if (!m_visible)
			return;

		m_visible = false;

		if (m_onClosed !is null)
		{
			for (uint i = 0; i < m_onClosed.length(); i++)
			{
				auto script = WorldScript::GetWorldScript(g_scene, m_onClosed[i].GetScriptBehavior());
				if (script !is null)
					script.Execute();
			}
		}

		g_gameMode.RemoveWidgetRoot(this);
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

		int readyPlayers = 0;
		int totalPlayers = 0;

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

	void ReadyChanged()
	{
		if (AllReady() || Platform::GetSessionCount() > 1)
		{
			if (Network::IsServer())
				(Network::Message("LevelConceptClose")).SendToAll();
			Hide();
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

	void Continue()
	{
		PlayerRecord@ player = GetLocalPlayerRecord();
		if (player !is null)
			player.readyState = true;

		(Network::Message("LevelConceptContinue")).SendToAll();

		if (Platform::GetSessionCount() == 1)
		{
			auto wButtonText = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("continue"));
			if (wButtonText !is null)
				wButtonText.SetText(Resources::GetString(".levelend.wait"));
		}

		ReadyChanged();
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "continue")
			Continue();
	}

	void Update(int dt) override
	{
		if (!m_visible)
			return;

		m_background.Update(dt);
		IWidgetHoster::Update(dt);
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		if (!m_visible)
			return;

		m_background.Draw(sb, idt);
		IWidgetHoster::Draw(sb, idt);
	}

	void DoLayout() override
	{
		m_background.DoLayout();
		IWidgetHoster::DoLayout();
	}
}





class ConceptBackground : IWidgetHoster
{
	GUIBuilder@ m_builder;
	PlattBackground@ m_platt;
	bool m_showPlatt;
	
	ConceptBackground(GUIBuilder@ b)
	{
		@m_builder = b;
		@m_platt = PlattBackground(b);
	}

	void Load(string path)
	{
		LoadWidget(m_builder, path);
		if (m_widget is null)
			LoadWidget(m_builder, "gui/concepts/empty.gui");
			
		m_showPlatt = false;
	}
	
	void LoadPlatt(string plattPath, string bgPath)
	{
		LoadWidget(m_builder, plattPath);
		if (m_widget is null)
			LoadWidget(m_builder, "gui/concepts/empty.gui");
		else
			m_platt.Load(bgPath);
			
		m_showPlatt = true;
	}
	
	void Update(int dt) override
	{
		if (m_showPlatt)
			m_platt.Update(dt);
			
		IWidgetHoster::Update(dt);
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		if (m_showPlatt)
		{
			vec2 center = vec2(g_gameMode.m_wndWidth * 0.5, g_gameMode.m_wndHeight * 0.5);
			
			mat4 tform = mat::translate(mat4(), xyz(center));
			tform *= mat4(mat::shearX(mat3(), 0.095));
			tform = mat::scale(tform, vec3(0.55, 0.60, 1));
			tform = mat::translate(tform, xyz(center * -1.0));
			tform = mat::translate(tform, vec3(280, -60, 0));

			sb.PushTransformation(tform);
			
			m_platt.Draw(sb, idt);
			
			sb.PopTransformation();
		}
		
		IWidgetHoster::Draw(sb, idt);
	}
	
	void DoLayout() override
	{
		if (m_showPlatt)
			m_platt.DoLayout();
			
		IWidgetHoster::DoLayout();
	}
}

class PlattBackground : IWidgetHoster
{
	GUIBuilder@ m_builder;
	
	PlattBackground(GUIBuilder@ b)
	{
		@m_builder = b;
	}

	void Load(string path)
	{
		LoadWidget(m_builder, path);
		if (m_widget is null)
			LoadWidget(m_builder, "gui/concepts/empty.gui");
	}
}
