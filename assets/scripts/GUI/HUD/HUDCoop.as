class CoopPlayerWidget : RectWidget
{
	HUDCoop@ m_hudCoop;

	PlayerRecord@ m_record;

	SpriteWidget@ m_wPortrait;
	BarWidget@ m_wHealth;
	Widget@ m_wIconDead;
	SpriteWidget@ m_wIconSoulLink;
	SpriteWidget@ m_wTriangle;

	int m_lastSoulLink = -1;

	CoopPlayerWidget()
	{
		super();
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		RectWidget::Load(ctx);
	}

	void SetPeer(PlayerRecord@ record)
	{
		@m_record = record;

		vec4 color = ParseColorRGBA("#" + GetPlayerColor(m_record.peer) + "ff");

		@m_wPortrait = cast<SpriteWidget>(GetWidgetById("portrait"));
		@m_wHealth = cast<BarWidget>(GetWidgetById("health"));
		@m_wIconDead = GetWidgetById("dead");
		@m_wIconSoulLink = cast<SpriteWidget>(GetWidgetById("soullink"));
		@m_wTriangle = cast<SpriteWidget>(GetWidgetById("triangle"));

		m_wPortrait.SetSprite(GetFaceSprite(record.charClass, record.face));

		m_wTriangle.m_color = color;
	}

	void Update(int dt) override
	{
		RectWidget::Update(dt);

		if (m_record is null || m_record.peer == 255)
		{
			bool haveToLayout = false;
			if (m_visible)
				haveToLayout = true;
			m_visible = false;
			if (haveToLayout)
				m_host.DoLayout();
			return;
		}
		else if (m_record !is null && m_record.peer != 255)
			m_visible = true;

		bool isDead = m_record.IsDead();

		m_wIconDead.m_visible = isDead;
		m_wIconSoulLink.m_visible = (!isDead && m_record.soulLinkedBy != -1);
		if (!isDead && m_lastSoulLink != m_record.soulLinkedBy)
		{
			m_lastSoulLink = m_record.soulLinkedBy;
			m_wIconSoulLink.m_color = ParseColorRGBA("#" + GetPlayerColor(m_record.soulLinkedBy) + "ff");
		}
		m_wPortrait.m_colorize = isDead;

		if (isDead)
		{
			m_wHealth.SetScale(0.0f);
			return;
		}

		if (m_wHealth !is null)
			m_wHealth.SetScale(m_record.hp);
	}

	Widget@ Clone() override
	{
		CoopPlayerWidget@ w = CoopPlayerWidget();
		CloneInto(w);
		return w;
	}
}

ref@ LoadCoopPlayerWidget(WidgetLoadingContext &ctx)
{
	CoopPlayerWidget@ w = CoopPlayerWidget();
	w.Load(ctx);
	return w;
}

class HUDCoop : IWidgetHoster
{
	Widget@ m_wPlayerList;
	Widget@ m_wPlayerTemplate;
	Widget@ m_wSeparatorTemplate;

	array<CoopPlayerWidget@> m_players;

	bool m_localPlayerAdded;

	HUDCoop(GUIBuilder@ b)
	{
		b.AddWidgetProducer("coop-player", LoadCoopPlayerWidget);

		LoadWidget(b, "gui/hud/coop.gui");

		@m_wPlayerList = m_widget.GetWidgetById("playerlist");
		@m_wPlayerTemplate = m_widget.GetWidgetById("playerlist-template");
		@m_wSeparatorTemplate = m_widget.GetWidgetById("separator-template");
	}

	bool ShouldShow()
	{
		if (!Lobby::IsInLobby())
			return false;

		if (g_players.length() > 4)
			return false;

		return true;
	}

	void Update(int dt) override
	{
		if (!ShouldShow())
			return;

		IWidgetHoster::Update(dt);

		if (!m_localPlayerAdded)
		{
			auto localPlayer = GetLocalPlayerRecord();
			if (localPlayer !is null)
			{
				m_localPlayerAdded = true;

				// Add local player
				CoopPlayerWidget@ wNewLocalPlayer = cast<CoopPlayerWidget>(m_wPlayerTemplate.Clone());
				wNewLocalPlayer.SetID("");
				wNewLocalPlayer.m_visible = true;
				@wNewLocalPlayer.m_hudCoop = this;
				wNewLocalPlayer.SetPeer(GetLocalPlayerRecord());
				m_wPlayerList.AddChild(wNewLocalPlayer);

				// Add separator
				auto wNewSeparator = m_wSeparatorTemplate.Clone();
				wNewSeparator.SetID("");
				wNewSeparator.m_visible = true;
				m_wPlayerList.AddChild(wNewSeparator);

				DoLayout();
				DoLayout(); // avoid flickering.. (I hate layout issues)
			}
			else
				return;
		}

		// Check for new players
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (i >= m_players.length())
			{
				CoopPlayerWidget@ wNewPlayer = cast<CoopPlayerWidget>(m_wPlayerTemplate.Clone());
				wNewPlayer.SetID("");
				wNewPlayer.m_visible = true;
				@wNewPlayer.m_hudCoop = this;
				wNewPlayer.SetPeer(g_players[i]);
				if (!g_players[i].local)
				{
					m_wPlayerList.AddChild(wNewPlayer);
					DoLayout();
				}
				m_players.insertLast(wNewPlayer);
			}
			else if (m_players[i].m_record !is g_players[i])
				m_players[i].SetPeer(g_players[i]);
		}
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		if (!ShouldShow())
			return;

		IWidgetHoster::Draw(sb, idt);
	}
}
