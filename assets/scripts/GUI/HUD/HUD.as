class HUD : IWidgetHoster
{
	GUIDef@ m_guiDef;

	WorldScript::AnnounceText@ m_currAnnounce;

	WaypointMarkersWidget@ m_waypoints;

	SpeechBubbleManager@ m_speechBubbles;

	UsableIcon m_currentUseIcon;
	Sprite@ m_useIcon;
	Sprite@ m_useIconCross;
	Sprite@ m_useIconKey;
	Sprite@ m_useIconShop;
	Sprite@ m_useIconSpeech;
	Sprite@ m_useIconExit;
	Sprite@ m_useIconQuestion;
	Sprite@ m_useIconRevive;

	// This is only for overhead boss bars?
	Sprite@ m_spriteBossbarOn;
	Sprite@ m_spriteBossbarOff;
	Sprite@ m_spriteBossbarInvuln;
	Sprite@ m_spriteBossbarCheckpoint;
	array<OverheadBossBar@> m_arrBosses;

	Widget@ m_wTopbar;
	Widget@ m_wHealthGui;
	Widget@ m_wSkillGui;
	Widget@ m_wBossBars;
	bool m_showOverheadBossBars;

	uint m_tutorialData;
	TextWidget@ m_wTutorial;
	TextWidget@ m_wDeadMessage;
	TextWidget@ m_wDeadMessage2;

	int m_barStatsTimeC;

	SpriteBarWidget@ m_wBarHealth;
	TextWidget@ m_wHealth; //TODO: Move this into SpriteBarWidget

	SpriteBarWidget@ m_wBarMana;
	TextWidget@ m_wMana; //TODO: Move this into SpriteBarWidget

	TextWidget@ m_wCombo;
	SpriteBarWidget@ m_wBarCombo;
	SpriteBarWidget@ m_wBarComboTimer;
	SpriteBarWidget@ m_wBarExperience;

	TextWidget@ m_wCurrencyGold;
	SpriteWidget@ m_wCurrencyGoldIcon;

	TextWidget@ m_wCurrencyOre;
	SpriteWidget@ m_wCurrencyOreIcon;

	Widget@ m_wCurrencySkillPointsContainer;
	TextWidget@ m_wCurrencySkillPoints;

	RectWidget@ m_wKeyTemplate;
	Widget@ m_wKeyList;

	SpriteWidget@ m_wPotion;
	DotbarWidget@ m_wPotionBar;

	array<SkillWidget@> m_arrSkillWidgets;

	PlayerRecord@ m_lastRecord;

	Tooltip@ m_tooltipItems;

	TextWidget@ m_wDebugHandicap;
	

	HUD(GUIBuilder@ b)
	{
		b.AddWidgetProducer("skill", LoadSkillWidget);
		b.AddWidgetProducer("bossbar", LoadBossBarWidget);
		b.AddWidgetProducer("waypoints", LoadWaypointMarkersWidget);

		@m_speechBubbles = SpeechBubbleManager();

		GUIDef@ def = LoadWidget(b, "gui/hud.gui");
		@m_guiDef = def;

		@m_useIcon = def.GetSprite("use-icon");
		@m_useIconCross = def.GetSprite("use-icon-cross");
		@m_useIconKey = def.GetSprite("use-icon-key");
		@m_useIconShop = def.GetSprite("use-icon-shop");
		@m_useIconSpeech = def.GetSprite("use-icon-speech");
		@m_useIconExit = def.GetSprite("use-icon-exit");
		@m_useIconQuestion = def.GetSprite("use-icon-question");
		@m_useIconRevive = def.GetSprite("use-icon-revive");

		@m_wTopbar = m_widget.GetWidgetById("topbar");
		@m_wHealthGui = m_widget.GetWidgetById("health-gui");
		@m_wSkillGui = m_widget.GetWidgetById("skill-gui");
		@m_wBossBars = m_widget.GetWidgetById("boss-bars");

		@m_waypoints = cast<WaypointMarkersWidget>(m_widget.GetWidgetById("waypoints"));

		Tutorial::AssignHUD(cast<TextWidget>(m_widget.GetWidgetById("tutorial")));
		
		@m_wDeadMessage = cast<TextWidget>(m_widget.GetWidgetById("deadmessage"));
		@m_wDeadMessage2 = cast<TextWidget>(m_widget.GetWidgetById("deadmessage2"));

		@m_wBarHealth = cast<SpriteBarWidget>(m_widget.GetWidgetById("health-bar"));
		@m_wHealth = cast<TextWidget>(m_widget.GetWidgetById("health"));

		@m_wBarMana = cast<SpriteBarWidget>(m_widget.GetWidgetById("mana-bar"));
		@m_wMana = cast<TextWidget>(m_widget.GetWidgetById("mana"));

		@m_wCombo = cast<TextWidget>(m_widget.GetWidgetById("combo"));
		@m_wBarCombo = cast<SpriteBarWidget>(m_widget.GetWidgetById("combo-bar"));
		@m_wBarComboTimer = cast<SpriteBarWidget>(m_widget.GetWidgetById("combo-bar-timer"));
		@m_wBarExperience = cast<SpriteBarWidget>(m_widget.GetWidgetById("exp-bar"));

		@m_wCurrencyGold = cast<TextWidget>(m_widget.GetWidgetById("gold"));
		@m_wCurrencyGoldIcon = cast<SpriteWidget>(m_widget.GetWidgetById("gold-icon"));

		@m_wCurrencyOre = cast<TextWidget>(m_widget.GetWidgetById("ore"));
		@m_wCurrencyOreIcon = cast<SpriteWidget>(m_widget.GetWidgetById("ore-icon"));

		@m_wCurrencySkillPointsContainer = m_widget.GetWidgetById("skill-points-container");
		@m_wCurrencySkillPoints = cast<TextWidget>(m_widget.GetWidgetById("skill-points"));

		@m_wKeyTemplate = cast<RectWidget>(m_widget.GetWidgetById("topbar-key-template"));
		@m_wKeyList = m_widget.GetWidgetById("topbar-key-list");

		@m_wPotion = cast<SpriteWidget>(m_widget.GetWidgetById("potion"));
		@m_wPotionBar = cast<DotbarWidget>(m_widget.GetWidgetById("potion-bar"));

		for (uint i = 0; ; i++)
		{
			auto wSkill = cast<SkillWidget>(m_widget.GetWidgetById("skill-" + (i + 1)));
			if (wSkill is null)
				break;
			m_arrSkillWidgets.insertLast(wSkill);
		}

		@m_tooltipItems = Tooltip(Resources::GetSValue("gui/tooltip.sval"));

		@m_wDebugHandicap = cast<TextWidget>(m_widget.GetWidgetById("debug-handicap"));
	}

	void Start()
	{
		if (cast<Town>(g_gameMode) !is null)
		{
			m_wCurrencyGoldIcon.SetSprite("topbar-icon-gold-town");
			m_wCurrencyOreIcon.SetSprite("topbar-icon-ore-town");
		}

		m_wDebugHandicap.m_visible = GetVarBool("ui_debug_handicap");
	}

	void OnDeath()
	{
		// ?
	}

	void InitializeKeys(PlayerRecord@ record)
	{
		m_wKeyList.ClearChildren();

		for (uint i = 0; i < record.keys.length(); i++)
		{
			int num = record.keys[i];

			auto wNewKey = cast<RectWidget>(m_wKeyTemplate.Clone());
			wNewKey.m_visible = true;
			wNewKey.SetID("");
			wNewKey.m_visible = (num > 0);

			auto wSprite = cast<SpriteWidget>(wNewKey.GetWidgetById("icon"));
			wSprite.SetSprite("topbar-icon-key-" + i);

			auto wText = cast<TextWidget>(wNewKey.GetWidgetById("value"));
			wText.m_visible = GetVarBool("ui_key_count");
			wText.SetText("" + num);

			m_wKeyList.AddChild(wNewKey);
		}
	}

	void Update(int dt) override
	{
		BaseGameMode@ gm = cast<BaseGameMode>(g_gameMode);
		if (gm is null)
			return;

		PlayerRecord@ record = null;
		if (gm.m_spectating)
			@record = g_players[gm.m_spectatingPlayer];
		else
			@record = GetLocalPlayerRecord();

		Update(dt, record);
	}

	void Update(int dt, PlayerRecord@ record)
	{
		if (record is null)
			return;

		m_speechBubbles.Update(dt);

		m_wHealthGui.m_visible = GetVarBool("ui_hud_stats");
		m_wSkillGui.m_visible = GetVarBool("ui_hud_skills");
		m_wBossBars.m_visible = (m_wBossBars.m_children.length() > 2 && GetVarBool("ui_hud_bossbar"));
		m_showOverheadBossBars = GetVarBool("ui_hud_bossbar_actors");
		m_wTopbar.m_visible = GetVarBool("ui_hud_topbar");

		m_wBossBars.m_width = g_gameMode.m_wndWidth;
		m_wBossBars.m_offset.x = 15;
		if (m_wHealthGui.m_visible)
		{
			int statsWidth = m_wHealthGui.m_width - 7;
			m_wBossBars.m_offset.x = statsWidth;
			m_wBossBars.m_width -= statsWidth;
		}
		else
			m_wBossBars.m_width -= 15;
		if (m_wSkillGui.m_visible)
			m_wBossBars.m_width -= m_wSkillGui.m_width - 7;
		else
			m_wBossBars.m_width -= 15;
		
		Tutorial::Update(dt);
		
		if (m_lastRecord !is record)
		{
			if (m_lastRecord is null)
				InitializeKeys(record);

			@m_lastRecord = record;
		}

		if (record.hp < 1.0f || record.mana < 1.0f)
			m_barStatsTimeC = 1500;
		else if (m_barStatsTimeC > 0)
			m_barStatsTimeC -= dt;

		auto player = cast<PlayerBase>(record.actor);
		if (player !is null)
		{
			for (int i = 0; i < min(m_arrSkillWidgets.length(), player.m_skills.length()); i++)
				m_arrSkillWidgets[i].SetSkill(player.m_skills[i]);

			auto localPlayer = cast<Player>(player);
			if (localPlayer !is null)
			{
				vec2 comboBars = localPlayer.GetComboBars();
				comboBars.x = clamp(comboBars.x, 0.0f, 1.0f);
				m_wBarCombo.SetValue(comboBars.x);
				m_wBarComboTimer.SetValue(comboBars.x * comboBars.y);
				m_wCombo.m_visible = comboBars.x >= 1.0f;
				m_wCombo.SetText("" + localPlayer.m_comboCount);
			}
			else
			{
				m_wBarCombo.SetValue(0);
				m_wBarComboTimer.SetValue(0);
				m_wCombo.m_visible = false;
			}

			int charges = 1 + g_allModifiers.PotionCharges();

			float potionSpriteStep = (4.0f / float(charges));
			int potionSprite = (4 - int(round(potionSpriteStep * record.potionChargesUsed)));

			if (potionSprite < 0 || record.potionChargesUsed == charges) potionSprite = 0;
			else if (potionSprite > 4) potionSprite = 4;

			//NOTE: This has to be in Update() since this unlocks when you find a well in dungeon
			m_wPotion.m_visible = g_flags.IsSet("unlock_apothecary");
			if (m_wPotion.m_visible)
			{
				m_wPotion.SetSprite("potion-" + potionSprite);
				m_wPotionBar.m_value = (charges - record.potionChargesUsed);
				m_wPotionBar.m_max = charges;
			}

			//TODO: use Player instead of localPlayer so we can spectate player's proper stats
			ivec2 extraStats;
			if (localPlayer !is null)
				extraStats = g_allModifiers.StatsAdd(localPlayer);

			float maxHealth = record.MaxHealth() + extraStats.x;
			float maxMana = record.MaxMana() + extraStats.y;

			m_wBarHealth.SetValue(record.hp);
			m_wHealth.SetText("" + int(ceil(record.hp * maxHealth)));

			m_wBarMana.SetValue(record.mana);
			m_wMana.SetText("" + int(floor(record.mana * maxMana)));
		}
		else
		{
			for (uint i = 0; i < m_arrSkillWidgets.length(); i++)
				m_arrSkillWidgets[i].SetSkill(null);

			m_wBarHealth.SetValue(0);
			m_wHealth.SetText("0");

			m_wBarMana.SetValue(0);
			m_wMana.SetText("0");

			m_wBarCombo.SetValue(0);
			m_wBarComboTimer.SetValue(0);
			m_wPotion.SetSprite("potion-0");
		}

		int xpStart = record.LevelExperience(record.level - 1);
		int xpEnd = record.LevelExperience(record.level) - xpStart;
		int xpNow = record.experience - xpStart;

		m_wBarExperience.SetValue(xpNow / float(xpEnd));

		auto gm = cast<Campaign>(g_gameMode);
		if (gm !is null && gm.m_townLocal !is null)
		{
			auto town = gm.m_townLocal;

			int currGold = town.m_gold;
			int currOre = town.m_ore;

			auto gmTown = cast<Town>(g_gameMode);

			if (gmTown is null)
			{
				currGold = record.runGold;
				currOre = record.runOre;
			}
			else
			{
				m_wCurrencySkillPointsContainer.m_visible = GetVarBool("ui_hud_topbar");
				m_wCurrencySkillPoints.SetText("" + record.skillPoints);
			}

			m_wCurrencyGold.SetText(formatThousands(currGold));
			m_wCurrencyOre.SetText(formatThousands(currOre));
		}

		bool showKeyCount = GetVarBool("ui_key_count");
		for (uint i = 0; i < record.keys.length(); i++)
		{
			int num = record.keys[i];
			m_wKeyList.m_children[i].m_visible = (num > 0);

			auto wTextValue = cast<TextWidget>(m_wKeyList.m_children[i].GetWidgetById("value"));
			wTextValue.m_visible = showKeyCount;
			if (wTextValue.m_visible)
				wTextValue.SetText("" + num);
		}

		if (m_wDebugHandicap.m_visible)
			m_wDebugHandicap.SetText("Handicap: " + record.handicap);

%PROFILE_START HUD UpdateWidgets
		IWidgetHoster::Update(dt);
%PROFILE_STOP
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		bool drawnPlayerBars = DrawPlayerBars(sb);
		DrawHoverItem(sb);
		DrawUseIcon(sb, drawnPlayerBars ? 22 : 14);

		m_speechBubbles.Draw(sb, idt);

		if (m_showOverheadBossBars)
		{
			for (int i = 0; i < int(m_arrBosses.length()); i++)
			{
				if (!m_arrBosses[i].Draw(sb, idt))
					m_arrBosses.removeAt(i--);
			}
		}

		IWidgetHoster::Draw(sb, idt);
	}

	bool DrawPlayerBars(SpriteBatch& sb)
	{
		if (cast<Town>(g_gameMode) !is null)
			return false;

		auto plr = GetLocalPlayerRecord();

		auto localPlayer = cast<Player>(plr.actor);
		if (localPlayer is null)
			return false;
		
		int yPos = g_gameMode.m_wndHeight / 2 - 10 - 10 - 1;
		int width = 16;

		vec2 comboBars = localPlayer.GetComboBars();

		int barsVisibility = GetVarInt("ui_bars_visibility");
		if (barsVisibility == -1)
			return false;

		bool alwaysShowBars = (barsVisibility == 1);
		bool showBarStats = (alwaysShowBars || m_barStatsTimeC > 0);
		bool showBarCombo = (alwaysShowBars || comboBars.x > 0.0f);

		int height = 1;
		if (showBarStats) height += 4;
		if (showBarCombo) height += 2;

		if (height == 1)
			return false;

		vec4 p = vec4((g_gameMode.m_wndWidth - width) / 2, yPos, width, height);
		sb.DrawSprite(null, p, p, vec4(0, 0, 0, 1));

		yPos--;

		if (showBarStats)
		{
			DrawPlayerBar(sb, width -2, yPos += 2, plr.hp, vec4(1,0,0,1), vec4(0.16,0.06,0.06,1));
			DrawPlayerBar(sb, width -2, yPos += 2, plr.mana, vec4(0,0.71,1,1), vec4(0.06,0.08,0.12,1));
		}

		if (showBarCombo)
		{
			yPos += 2;
		
			DrawPlayerBar(sb, width -2, yPos, comboBars.x, vec4(.3,0,.3,1), vec4(0.03,0,0.03,1));
			DrawPlayerBar(sb, width -2, yPos, comboBars.x * comboBars.y, vec4(1,0,1,1), vec4(0,0,0,0));
		}

		return true;
	}

	void DrawPlayerBar(SpriteBatch& sb, int width, int ypos, float fill, vec4 colorFilled, vec4 colorEmpty)
	{
		int w = int(width * clamp(fill, 0.0, 1.0));

		vec4 p = vec4((g_gameMode.m_wndWidth - width) / 2, ypos, w, 1);
		sb.DrawSprite(null, p, p, colorFilled);

		p.x += w;
		p.z = width - w;
		sb.DrawSprite(null, p, p, colorEmpty);
	}

	void DrawHoverItem(SpriteBatch& sb)
	{
		auto localPlayer = GetLocalPlayer();
		if (localPlayer is null)
			return;

		auto usable = localPlayer.GetTopUsable();
		if (usable is null || !usable.CanUse(localPlayer))
			return;

		auto hoverItem = cast<Item>(usable);
		if (hoverItem is null)
			return;

		auto gm = cast<BaseGameMode>(g_gameMode);
		if (gm is null)
			return;

		m_tooltipItems.SetTitle("\\c" + GetItemQualityColorString(hoverItem.m_item.quality) + utf8string(Resources::GetString(hoverItem.m_item.name)).toUpper().plain());
		m_tooltipItems.SetText(Resources::GetString(hoverItem.m_item.desc) + (hoverItem.m_item.set !is null ? ("\n\\c" + SetItemColorString + Resources::GetString(hoverItem.m_item.set.name) + "\\d") : ""));
		
		vec2 tooltipSize = m_tooltipItems.GetSize();
		m_tooltipItems.Draw(sb, vec2(
			gm.m_wndWidth / 2 - tooltipSize.x / 2,
			gm.m_wndHeight / 2 - tooltipSize.y - 30
		));
	}

	void DrawUseIcon(SpriteBatch& sb, int y)
	{
		auto localPlayer = GetLocalPlayer();
		if (localPlayer is null)
			return;

		IUsable@ usable = localPlayer.GetTopUsable();
		if (usable is null)
			return;

		vec2 pos = vec2(g_gameMode.m_wndWidth / 2, g_gameMode.m_wndHeight / 2);

		auto icon = usable.GetIcon(localPlayer);
		if (icon == UsableIcon::None)
			return;

		if (icon == UsableIcon::Cross)
			sb.DrawSprite(pos - vec2(m_useIconCross.GetWidth() / 2, y + m_useIconCross.GetHeight()), m_useIconCross, g_menuTime);
		else if (icon == UsableIcon::Shop)
			sb.DrawSprite(pos - vec2(m_useIconShop.GetWidth() / 2, y + m_useIconShop.GetHeight()), m_useIconShop, g_menuTime);
		else if (icon == UsableIcon::Speech)
			sb.DrawSprite(pos - vec2(m_useIconSpeech.GetWidth() / 2, y + m_useIconSpeech.GetHeight()), m_useIconSpeech, g_menuTime);
		else if (icon == UsableIcon::Exit)
			sb.DrawSprite(pos - vec2(m_useIconExit.GetWidth() / 2, y + m_useIconExit.GetHeight()), m_useIconExit, g_menuTime);
		else if (icon == UsableIcon::Question)
			sb.DrawSprite(pos - vec2(m_useIconQuestion.GetWidth() / 2, y + m_useIconQuestion.GetHeight()), m_useIconQuestion, g_menuTime);
		else if (icon == UsableIcon::Revive)
			sb.DrawSprite(pos - vec2(m_useIconRevive.GetWidth() / 2, y + m_useIconRevive.GetHeight()), m_useIconRevive, g_menuTime);
		else
		{
			sb.DrawSprite(pos - vec2(m_useIcon.GetWidth() / 2, y + m_useIcon.GetHeight()), m_useIcon, g_menuTime);

			if (icon == UsableIcon::Key)
				sb.DrawSprite(pos - vec2(m_useIconKey.GetWidth() / 2, y + m_useIcon.GetHeight() + 2 + m_useIconKey.GetHeight()), m_useIconKey, g_menuTime);
		}
	}

	bool Announce(const AnnounceParams &in params)
	{
		auto w = cast<TextWidget>(m_widget.GetWidgetById("announce"));
		if (w is null)
		{
			PrintError("TextWidget \"announce\" not found!");
			return false;
		}

		if (w.m_visible && !params.m_override)
			return false;

		if (params.m_align == -1) w.m_alignment = TextAlignment::Left;
		else if (params.m_align == 0) w.m_alignment = TextAlignment::Center;
		else if (params.m_align == 1) w.m_alignment = TextAlignment::Right;

		w.SetFont(params.m_font);
		w.SetText(params.m_text);
		w.m_anchor = params.m_anchor;
		w.m_visible = true;

		auto col = tocolor(params.m_color);
		auto colTransparent = vec4(col.r, col.g, col.b, 0);

		w.CancelAnimations();
		w.Animate(WidgetVec4Animation("color", colTransparent, col, params.m_fadeTime));
		if (params.m_time != -1)
		{
			w.Animate(WidgetVec4Animation("color", col, colTransparent, params.m_fadeTime, params.m_fadeTime + params.m_time));
			w.Animate(WidgetBoolAnimation("visible", false, params.m_fadeTime + params.m_time + params.m_fadeTime));
		}

		return true;
	}

	TextWidget@ GetCountDown()
	{
		return cast<TextWidget>(m_widget.GetWidgetById("countdown"));
	}

	void SetExtraLife()
	{
		// ?
	}

	OverheadBossBar@ AddBossBarActor(Actor@ actor, int barCount, int barOffset, string name)
	{
		if (!m_showOverheadBossBars)
			return null;

		OverheadBossBar@ b = OverheadBossBar(this);
		b.Set(actor, barCount, barOffset, name);
		m_arrBosses.insertLast(b);
		return b;
	}

	OverheadBossBar@ GetBossBarActor(Actor@ actor)
	{
		for (uint i = 0; i < m_arrBosses.length(); i++)
		{
			OverheadBossBar@ bar = m_arrBosses[i];
			if (bar.m_actor is actor)
				return bar;
		}
		return null;
	}

	void AddBossBar(Actor@ actor, string name)
	{
		auto wTemplate = cast<BossBarWidget>(m_widget.GetWidgetById("boss-template"));
		if (wTemplate is null)
			return;

		if (m_wBossBars is null)
			return;

		auto wBossBar = cast<BossBarWidget>(wTemplate.Clone());
		wBossBar.m_visible = true;
		wBossBar.SetID("");
		@wBossBar.m_actor = actor;
		wBossBar.SetText(Resources::GetString(name));
		m_wBossBars.AddChild(wBossBar);

		for (uint i = 0; i < m_wBossBars.m_children.length(); i++)
		{
			auto wBar = cast<BossBarWidget>(m_wBossBars.m_children[i]);
			if (wBar is null)
				continue;
			wBar.UpdateAppearance();
		}
	}

	BossBarWidget@ GetBossBar(Actor@ actor)
	{
		if (m_wBossBars is null)
			return null;

		for (uint i = 0; i < m_wBossBars.m_children.length(); i++)
		{
			BossBarWidget@ bar = cast<BossBarWidget>(m_wBossBars.m_children[i]);
			if (bar is null)
				continue;

			if (bar.m_actor is actor)
				return bar;
		}

		return null;
	}

	void PlayPickup()
	{
		// ?
	}

	Widget@ ShowBuffIcon(string id, int duration)
	{
		// ?
		return null;
	}
}
