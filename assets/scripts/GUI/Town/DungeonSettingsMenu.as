class DungeonSettingsMenu : ScriptWidgetHost
{
	TextWidget@ m_wNgp;
	SpriteButtonWidget@ m_wNgpLeft;
	SpriteButtonWidget@ m_wNgpRight;

	DungeonSettingsMenu(SValue& sval)
	{
		super();
	}

	void Initialize() override
	{
		@m_wNgp = cast<TextWidget>(m_widget.GetWidgetById("ngp"));
		@m_wNgpLeft = cast<SpriteButtonWidget>(m_widget.GetWidgetById("ngp-left"));
		@m_wNgpRight = cast<SpriteButtonWidget>(m_widget.GetWidgetById("ngp-right"));

		UpdateNgp();
	}

	void UpdateNgp()
	{
		bool isHost = Network::IsServer();

		auto gm = cast<Campaign>(g_gameMode);
		auto town = gm.m_townLocal;

		m_wNgp.SetText("+" + g_ngp);
		m_wNgpLeft.m_enabled = (isHost && g_ngp > 0);
		m_wNgpRight.m_enabled = (isHost && g_ngp < town.m_highestNgp);
	}

	bool ShouldFreezeControls() override { return true; }
	bool ShouldDisplayCursor() override { return true; }

	void Update(int dt) override
	{
		UpdateNgp();

		ScriptWidgetHost::Update(dt);
	}

	void OnNgpChanged()
	{
		(Network::Message("SetNgp") << g_ngp).SendToAll();

		if (Network::IsServer() && Lobby::IsInLobby())
		{
			SValueBuilder builder;
			builder.PushInteger(g_ngp);
			SendSystemMessage("SetNGP", builder.Build());
		}
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "close")
			Stop();
		else if (name == "ngp-prev" && Network::IsServer())
		{
			g_ngp--;
			if (g_ngp < 0)
				g_ngp = 0;

			OnNgpChanged();
		}
		else if (name == "ngp-next" && Network::IsServer())
		{
			g_ngp++;

			auto gm = cast<Campaign>(g_gameMode);
			auto town = gm.m_townLocal;
			if (g_ngp > town.m_highestNgp)
				g_ngp = town.m_highestNgp;

			OnNgpChanged();
		}
		else
			ScriptWidgetHost::OnFunc(sender, name);
	}
}
