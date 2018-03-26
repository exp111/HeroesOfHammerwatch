class Campaign : BaseGameMode
{
	float StartingHealth = 1.0;

	HUD@ m_hud;
	//HUDCoop@ m_hudCoop;
	Concept@ m_concept;
	MinimapQuery@ m_minimap;

	PlayerMenu@ m_playerMenu;
	GuildHallMenu@ m_guildHallMenu;
	ShopMenu@ m_shopMenu;

	NotificationManager@ m_notifications;

	bool m_allDead;
	uint m_allDeadTime;

	bool m_showMapOverlay;

	int m_prevIdt;

	int m_timePlayedC;
	int m_timePlayedDungeon;
	int m_timePlayedDungeonPrev;

	int m_darknessTimePrev;
	int m_darknessTime;

	TownRecord@ m_town;
	TownRecord@ m_townLocal;

	Titles::TitleList@ m_titlesGuild;

	FountainEffect m_fountainEffects;

	Campaign(Scene@ scene)
	{
		super(scene);

		@m_minimap = MinimapQuery();

		g_classTitles.AddClassTitles("paladin");
		g_classTitles.AddClassTitles("ranger");
		g_classTitles.AddClassTitles("thief");
		g_classTitles.AddClassTitles("sorcerer");
		g_classTitles.AddClassTitles("priest");
		g_classTitles.AddClassTitles("warlock");
		g_classTitles.AddClassTitles("wizard");

		AddItemFiles();
		Upgrades::LoadShops();
		Statues::LoadStatues();

		@m_titlesGuild = Titles::TitleList("tweak/titles/guild.sval");

		m_guiBuilder.AddWidgetProducer("inventory", LoadInventoryWidget);
		m_guiBuilder.AddWidgetProducer("inventoryitem", LoadInventoryItemWidget);
		m_guiBuilder.AddWidgetProducer("shopitem", LoadShopButtonWidget);
		m_guiBuilder.AddWidgetProducer("upgradeshopitem", LoadUpgradeShopButtonWidget);

		@m_hud = HUD(m_guiBuilder);
		//@m_hudCoop = HUDCoop(m_guiBuilder);
		@m_concept = Concept(m_guiBuilder);

		m_userWindows.insertLast(@m_gameOver = HWRGameOver(m_guiBuilder));
		m_userWindows.insertLast(@m_playerMenu = PlayerMenu(m_guiBuilder));
		m_userWindows.insertLast(@m_guildHallMenu = GuildHallMenu(m_guiBuilder));
		m_userWindows.insertLast(@m_shopMenu = ShopMenu(m_guiBuilder));

		@m_notifications = NotificationManager(m_guiBuilder);

		// This is here for development reasons (test from editor, run from command line)
		if (!VarExists("g_start_character"))
			AddVar("g_start_character", 0);

		if (LoadCharacter() is null)
			PickCharacter(GetVarInt("g_start_character"));
	}

	bool ShouldFreezeControls() override
	{
		return m_concept.IsVisible()
		    || BaseGameMode::ShouldFreezeControls();
	}

	bool ShouldDisplayCursor() override
	{
		return m_concept.IsVisible()
		    || BaseGameMode::ShouldDisplayCursor();
	}

	bool MenuBack() override
	{
		if (m_concept.IsVisible())
		{
			m_concept.Continue();
			return true;
		}

		return BaseGameMode::MenuBack();
	}

	HUD@ GetHUD() override { return m_hud; }

	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		@m_town = TownRecord();
		if (Network::IsServer())
			m_town.m_statistics.m_checkRewards = true;
		m_town.Load(LoadHostTown());

		@m_townLocal = TownRecord(true);
		m_townLocal.m_statistics.m_checkRewards = true;
		m_townLocal.Load(LoadLocalTown());

		RefreshTownModifiers();

		if (save !is null)
		{
			m_timePlayedDungeon = GetParamInt(UnitPtr(), save, "dungeon-time", false);
			m_timePlayedDungeonPrev = GetParamInt(UnitPtr(), save, "dungeon-time-prev", false);
			m_levelCount = GetParamInt(UnitPtr(), save, "level-count", false, GetVarInt("g_start_level"));
			m_fountainEffects = FountainEffect(GetParamInt(UnitPtr(), save, "fountain-effects", false, 0));
			g_ngp = GetParamInt(UnitPtr(), save, "ngp", false, 0);

			if (sMode == StartMode::LoadGame)
			{
				SValue@ minimapData = save.GetDictionaryEntry("minimap");
				if (minimapData !is null && minimapData.GetType() == SValueType::ByteArray)
					m_minimap.Read(g_scene, minimapData);
			}
		}
		else
			m_levelCount = GetVarInt("g_start_level");

		BaseGameMode::Start(peer, save, sMode);

		auto localRecord = GetLocalPlayerRecord();

		auto townTitle = m_townLocal.GetTitle();
		if (localRecord.townTitleSync < townTitle.m_points)
		{
			for (uint i = 0; i < m_titlesGuild.m_titles.length(); i++)
			{
				auto title = m_titlesGuild.m_titles[i];
				if (title.m_points > localRecord.townTitleSync)
					localRecord.skillPoints += title.m_skillPoints;

				if (title is townTitle)
					break;
			}
			localRecord.townTitleSync = townTitle.m_points;
		}

		if (cast<Town>(this) is null)
		{
			ivec3 level = CalcLevel(m_levelCount);
			if (level.y == 0)
			{
				Stats::AddAvg("avg-items-picked-act-" + (level.x + 1), localRecord);
				Stats::AddAvg("avg-gold-found-act-" + (level.x + 1), localRecord);
				Stats::AddAvg("avg-ore-found-act-" + (level.x + 1), localRecord);
			}
		}

		m_hud.Start();

		m_started = true;
		print("NewGame+ " +g_ngp);
	}

	void RefreshTownModifiers()
	{
		// Titles (TODO: Sync?)
		m_titlesGuild.ClearModifiers(g_allModifiers);
		m_town.GetTitle().EnableModifiers(g_allModifiers);

		// Statues (TODO: Sync?)
		Statues::DisableModifiers();

		auto statues = m_town.GetPlacedStatues();
		for (uint i = 0; i < statues.length(); i++)
		{
			auto def = statues[i].GetDef();
			def.EnableModifiers();
		}
	}

	void Save(SValueBuilder& builder) override
	{
		BaseGameMode::Save(builder);

		builder.PushInteger("fountain-effects", int(m_fountainEffects));
		builder.PushInteger("dungeon-time", m_timePlayedDungeon);
		builder.PushInteger("dungeon-time-prev", m_timePlayedDungeonPrev);

		if (cast<Town>(this) is null)
			builder.PushSimple("minimap", m_minimap.Write());

		SaveLocalTown();
	}
	
	void SaveLocalTown()
	{
		SValueBuilder twnBuilder;

		twnBuilder.PushDictionary("town");
		m_townLocal.Save(twnBuilder, Network::IsServer());
		twnBuilder.PopDictionary();

		SaveTown(twnBuilder.Build());
	}
	
	void OnExitGame()
	{
		SaveLocalTown();
		
		auto record = GetLocalPlayerRecord();
		SavePlayer(record, true);
		//SavePlayer(record, false);
	}
	

	void RemovePlayer(uint8 peer, bool kicked) override
	{
		BaseGameMode::RemovePlayer(peer, kicked);

		if (m_concept.m_visible)
			m_concept.IsVisible();

		CheckGameOver();
	}

	void PlayerDied(PlayerRecord@ player, PlayerRecord@ killer, DamageInfo di) override
	{
		if (player.local)
			@m_gameOver.m_killingActor = di.Attacker;
	
		CheckGameOver();
	}

	void CheckGameOver()
	{
		int freeLives = 0;
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;
			freeLives += g_players[i].GetFreeLives();
		}

		if (GetPlayersAlive() == 0 && freeLives == 0)
		{
			m_allDead = true;
			m_allDeadTime = g_scene.GetTime();
		}
	}

	void UpdatePausedFrame(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		Platform::Service.InMenus(ShouldDisplayCursor());

		BaseGameMode::UpdatePausedFrame(ms, gameInput, menuInput);
	}

	void UpdateFrame(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		Platform::Service.InMenus(ShouldDisplayCursor());

		if (gameInput.MapOverlay.Pressed)
		{
			m_showMapOverlay = !m_showMapOverlay;
			Tutorial::RegisterAction("map_overlay");
		}

		for (uint i = 0; i < g_players.length(); i++)
		{
			Actor@ a = g_players[i].actor;
			if (a !is null)
				m_minimap.Explore(g_scene, xy(a.m_unit.GetPosition()), 200);
		}

		BaseGameMode::UpdateFrame(ms, gameInput, menuInput);

		if (GlobalCache::Get("main_restart") == "1")
		{
			GlobalCache::Set("main_restart", "");

			auto ply = GetLocalPlayer();
			if (ply !is null)
			{
				if (cast<Town>(this) is null)
					ply.Kill(null, 0);
				else
					ply.m_unit.SetPosition(xyz(g_spawnPos));
			}
		}

		if (cast<Town>(g_gameMode) is null)
		{
			m_timePlayedC += ms;
			if (m_timePlayedC >= 1000)
			{
				m_timePlayedC -= 1000;
				m_timePlayedDungeon++;
				Stats::Add("time-played", 1, GetLocalPlayerRecord());
				Stats::Add("time-played-run", 1, GetLocalPlayerRecord());
			}
		}
	}

	void UpdateWidgets(int ms, GameInput& gameInput, MenuInput& menuInput) override
	{
		BaseGameMode::UpdateWidgets(ms, gameInput, menuInput);

		m_notifications.Update(ms);

		if (!m_gameOver.m_visible)
		{
			if (gameInput.PlayerMenu.Pressed)
			{
				ToggleUserWindow(m_playerMenu);
				Tutorial::RegisterAction("player_menu");
			}
			else if (gameInput.GuildMenu.Pressed)
			{
				ToggleUserWindow(m_guildHallMenu);
				Tutorial::RegisterAction("guild_menu");
			}
		}

		m_playerMenu.m_tabMap.m_showFog = m_playerMenu.m_tabMap.ShouldShowFog();

		auto player = GetLocalPlayerRecord();
		if (player !is null && player.HasBeenDeadFor(1000))
		{
			if (player.GetFreeLives() > 0)
			{
				m_hud.m_wDeadMessage.SetText(Resources::GetString(".dead.respawn"));
				m_hud.m_wDeadMessage2.SetText("");
			}
			else
			{
				if (m_allDead && g_scene.GetTime() > m_allDeadTime + 2000)
				{
					m_hud.m_wDeadMessage.SetText("");
					m_hud.m_wDeadMessage2.SetText("");

					if (Network::IsServer() && !m_gameOver.IsVisible())
					{
						SValue@ sv = m_gameOver.m_score.BuildData();
						m_gameOver.Show(sv);
						(Network::Message("GameOver") << sv).SendToAll();
						PauseGame(true, false);

						OnRunEnd(true);
					}
				}
				else
				{
					m_hud.m_wDeadMessage.SetText(Resources::GetString(".dead.gameover"));
					if (m_allDead)
						m_hud.m_wDeadMessage2.SetText("");
					else
						m_hud.m_wDeadMessage2.SetText(Resources::GetString(".dead.gameover.spectate"));
				}
			}

			if (Lobby::IsInLobby())
			{
				m_hud.m_wDeadMessage.m_visible = !m_spectating;
				m_hud.m_wDeadMessage2.m_visible = !m_spectating;
			}

			if (gameInput.Use.Pressed && !ShouldFreezeControls())
			{
				if (m_extraLives > 0 || player.GetFreeLives() > 0)
				{
					if (Network::IsServer())
						AttemptRespawn(player.peer);
					else
						Network::Message("AttemptRespawn").SendToHost();
				}
				else if (g_players.length() > 1)
					ToggleSpectating();
			}
		}
		else
		{
			m_hud.m_wDeadMessage.m_visible = false;
			m_hud.m_wDeadMessage2.m_visible = false;
		}

		PlayerRecord@ record = null;
		if (m_spectating)
			@record = g_players[m_spectatingPlayer];
		else
			@record = GetLocalPlayerRecord();

		if (record !is null)
		{
			auto plr = cast<PlayerBase>(record.actor);
			if (plr !is null)
			{
				m_darknessTimePrev = m_darknessTime;
				if (plr.m_buffs.Darkness())
				{
					if (m_darknessTime < Tweak::DarknessFadeTime)
						m_darknessTime += ms;
					if (m_darknessTime > Tweak::DarknessFadeTime)
						m_darknessTime = Tweak::DarknessFadeTime;
				}
				else
				{
					if (m_darknessTime > 0)
						m_darknessTime -= ms;
					if (m_darknessTime < 0)
						m_darknessTime = 0;
				}
			}
		}

		m_hud.Update(ms, record);
		//m_hudCoop.Update(ms);

		m_concept.Update(ms);
	}

	void RenderWidgets(PlayerRecord@ player, int idt, SpriteBatch& sb) override
	{
		DrawFloatingTexts(idt, sb);

		if (m_gameOver.m_visible)
		{
			for (uint i = 0; i < m_userWindows.length(); i++)
			{
				if (m_userWindows[i] !is m_gameOver && m_userWindows[i].m_visible)
					m_userWindows[i].Close();
			}
		}

		if (!m_playerMenu.m_visible && m_currInput !is null && m_showMapOverlay)
			sb.DrawMinimap(vec2(-32, -32), m_minimap, m_wndWidth + 64, m_wndHeight + 64, m_playerMenu.m_tabMap.GetMapColor(), vec4(1, 1, 1, GetVarFloat("ui_minimap_alpha")));

		auto plr = cast<PlayerBase>(player.actor);
		if (plr !is null)
		{
			if (m_darknessTime > 0)
			{
				float alphaTime = lerp(float(m_darknessTimePrev), float(m_darknessTime), idt / 33.0f);
				float alpha = easeQuad(alphaTime / float(Tweak::DarknessFadeTime));
				vec4 color = vec4(0, 0, 0, alpha);

				vec4 spriteRectSource;
				spriteRectSource.z = 128;
				spriteRectSource.w = 128;
				vec4 spriteRect = spriteRectSource;
				spriteRect.x = m_wndWidth / 2 - spriteRect.z / 2;
				spriteRect.y = m_wndHeight / 2 - spriteRect.w / 2;

				sb.DrawSprite(Resources::GetTexture2D("gui/darkness.png"), spriteRect, spriteRectSource, color);
				sb.FillRectangle(vec4(0, 0, spriteRect.x, m_wndHeight + 1), color);
				sb.FillRectangle(vec4(spriteRect.x, 0, spriteRect.z, spriteRect.y), color);
				sb.FillRectangle(vec4(spriteRect.x, spriteRect.y + spriteRect.w, spriteRect.z, spriteRect.y), color);
				sb.FillRectangle(vec4(spriteRect.x + spriteRect.z, 0, spriteRect.x, m_wndHeight + 1), color);
			}
		}

		m_hud.Draw(sb, idt);
		//m_hudCoop.Draw(sb, idt);

		m_concept.Draw(sb, idt);

		BaseGameMode::RenderWidgets(player, idt, sb);

		m_notifications.Draw(sb, idt);
	}

	void PreRenderFrame(int idt) override
	{
		if (idt == 0 || idt < m_prevIdt)
		{
			if (m_playerMenu.m_visible)
				m_playerMenu.AfterUpdate();
			else if (m_currInput !is null && m_showMapOverlay)
			{
				float scale = m_playerMenu.m_tabMap.GetMapScale();
				m_minimap.Prepare(g_scene, m_camPos, int((m_wndWidth + 64) * scale), int((m_wndHeight + 64) * scale), ~0);
			}
		}
		m_prevIdt = idt;

		BaseGameMode::PreRenderFrame(idt);
	}

	// Called as soon as game over
	// Called as soon as EndOfBeta is triggered
	void OnRunEnd(bool died)
	{
		auto record = GetLocalPlayerRecord();

		// Remove items & keys
		record.items.removeRange(0, record.items.length());
		for (uint i = 0; i < record.keys.length(); i++)
			record.keys[i] = 0;
		
		// Remove flags
		auto flagKeys = g_flags.m_flags.getKeys();
		for (uint i = 0; i < flagKeys.length(); i++)
		{
			int64 state;
			g_flags.m_flags.get(flagKeys[i], state);

			if (FlagState(state) == FlagState::Run)
				g_flags.m_flags.delete(flagKeys[i]);
		}

		// Deposit gold & ore to town
		DepositRun(record, died);

		// Calculate new handicap
		HandicapCalculate(record);

		// Reset some values
		record.hp = 1;
		record.mana = 1;
		record.potionChargesUsed = 0;
		record.runGold = 0;
		record.runOre = 0;
		record.runEnded = true;
		record.randomBuffNegative = 0;
		record.randomBuffPositive = 0;
		record.soulLinks.removeRange(0, record.soulLinks.length());
		record.soulLinkedBy = -1;
		record.generalStoreItemsSaved = -1;
		record.generalStoreItems.removeRange(0, record.generalStoreItems.length());
		record.generalStoreItemsPlume = 0;

		m_fountainEffects = FountainEffect::None;

		// Done, save player and local town now
		SavePlayer(record);
		SaveLocalTown();
	}

	void HandicapCalculate(PlayerRecord& record)
	{
		// Check against the previous run
		int runDiff = m_levelCount - record.previousRun;

		if (runDiff > 0)
			record.handicap *= 0.5f;
		else if (runDiff == 0)
			record.handicap *= 0.75f;
		else
			record.handicap = min(1.0f, record.handicap + 1.0f / record.statistics.GetStatInt("total-runs"));

		print("Level diff " + runDiff + " calls for new handicap: " + record.handicap);

		// Remember this run as the previous run
		record.previousRun = m_levelCount;
	}

	void DepositRun(PlayerRecord& record, bool died)
	{
		auto player = cast<Player>(record.actor);
		
		if (!died)
		{
			int takeGold = ApplyTaxRate(m_townLocal.m_gold, record.runGold);
			Stats::Add("gold-stored", takeGold, record);
			m_townLocal.m_gold += takeGold;

			int takeOre = record.runOre;
			Stats::Add("ores-stored", takeOre, record);
			m_townLocal.m_ore += takeOre;
		}

		record.runGold = 0;
		record.runOre = 0;
		
		if (died)
		{
			int xpDiff = (record.experience - record.LevelExperience(record.level - 1));
			record.experience -= int(xpDiff * Tweak::DeathExperienceLoss);
		}
	}

	void InitializePlayer(PlayerRecord& player) override
	{
		BaseGameMode::InitializePlayer(player);
		player.hp = StartingHealth;

		if (player.charClass == "")
		{
			array<string> classes = { "ranger", "paladin", "thief", "sorcerer", "warlock" };
			//array<string> classes = { "thief" };

			player.charClass = classes[randi(classes.length())];
			player.skinColor = randi(1000);
			player.color1 = randi(1000);
			player.color2 = randi(1000);
			player.color3 = randi(1000);
		}
	}

	void SavePlayer(SValueBuilder& builder, PlayerRecord& player) override
	{
		BaseGameMode::SavePlayer(builder, player);

		builder.PushString("name", player.name);

		builder.PushString("class", player.charClass);
		builder.PushInteger("color-skin", player.skinColor);
		builder.PushInteger("color-1", player.color1);
		builder.PushInteger("color-2", player.color2);
		builder.PushInteger("color-3", player.color3);
		builder.PushInteger("face", player.face);
		builder.PushFloat("voice", player.voice);

		builder.PushFloat("handicap", player.handicap);
		builder.PushInteger("previous-run", player.previousRun);

		builder.PushInteger("new-game-plus", player.newGamePlus);
		builder.PushInteger("title", player.titleIndex);
		builder.PushInteger("shortcut", player.shortcut);
		builder.PushInteger("random-buff-negative", player.randomBuffNegative);
		builder.PushInteger("random-buff-positive", player.randomBuffPositive);

		builder.PushInteger("run-gold", player.runGold);
		builder.PushInteger("run-ore", player.runOre);
		builder.PushInteger("skill-points", player.skillPoints);

		builder.PushInteger("town-title-sync", player.townTitleSync);

		builder.PushInteger("potion-charges-used", player.potionChargesUsed);

		builder.PushDictionary("upgrades");
		for (uint i = 0; i < player.upgrades.length(); i++)
			builder.PushInteger(player.upgrades[i].m_id, player.upgrades[i].m_level);
		builder.PopDictionary();
		
		builder.PushArray("items");
		for (uint i = 0; i < player.items.length(); i++)
			builder.PushString(player.items[i]);
		builder.PopArray();
		
		builder.PushArray("keys");
		for (uint i = 0; i < player.keys.length(); i++)
			builder.PushInteger(player.keys[i]);
		builder.PopArray();
		
		builder.PushArray("soul-links");
		for (uint i = 0; i < player.soulLinks.length(); i++)
			builder.PushInteger(player.soulLinks[i]);
		builder.PopArray();

		builder.PushInteger("soul-linked-by", player.soulLinkedBy);

		builder.PushDictionary("statistics");
		player.statistics.Save(builder);
		builder.PopDictionary();

		builder.PushDictionary("statistics-session");
		player.statisticsSession.Save(builder);
		builder.PopDictionary();

		builder.PushArray("generalstore");
		builder.PushInteger(player.generalStoreItemsSaved);
		for (uint i = 0; i < player.generalStoreItems.length(); i++)
			builder.PushInteger(player.generalStoreItems[i]);
		builder.PopArray();

		if (player.generalStoreItemsPlume > 0)
			builder.PushInteger("generalstore-plume", player.generalStoreItemsPlume);
	}

	void LoadPlayer(SValue& data, PlayerRecord& player) override
	{
		BaseGameMode::LoadPlayer(data, player);

		// Load main stats
		player.name = GetParamString(UnitPtr(), data, "name", false, player.name);

		player.charClass = GetParamString(UnitPtr(), data, "class", false, player.charClass);
		player.skinColor = GetParamInt(UnitPtr(), data, "color-skin", false, player.skinColor);
		player.color1 = GetParamInt(UnitPtr(), data, "color-1", false, player.color1);
		player.color2 = GetParamInt(UnitPtr(), data, "color-2", false, player.color2);
		player.color3 = GetParamInt(UnitPtr(), data, "color-3", false, player.color3);
		player.face = GetParamInt(UnitPtr(), data, "face", false, player.face);
		player.voice = GetParamFloat(UnitPtr(), data, "voice", false, player.voice);

		player.handicap = GetParamFloat(UnitPtr(), data, "handicap", false, player.handicap);
		player.previousRun = GetParamInt(UnitPtr(), data, "previous-run", false, 0);

		player.newGamePlus = GetParamInt(UnitPtr(), data, "new-game-plus", false, 0);
		player.titleIndex = GetParamInt(UnitPtr(), data, "title", false, player.titleIndex);
		player.shortcut = GetParamInt(UnitPtr(), data, "shortcut", false, 0);
		player.randomBuffNegative = GetParamInt(UnitPtr(), data, "random-buff-negative", false, 0);
		player.randomBuffPositive = GetParamInt(UnitPtr(), data, "random-buff-positive", false, 0);

		player.runGold = GetParamInt(UnitPtr(), data, "run-gold", false, 0);
		player.runOre = GetParamInt(UnitPtr(), data, "run-ore", false, 0);
		player.skillPoints = GetParamInt(UnitPtr(), data, "skill-points", false, 0);

		player.townTitleSync = GetParamInt(UnitPtr(), data, "town-title-sync", false, 0);

		player.potionChargesUsed = GetParamInt(UnitPtr(), data, "potion-charges-used", false, 0);

		// Clear upgrades
		player.upgrades.removeRange(0, player.upgrades.length());

		// Load upgrades
		auto dicUpgrades = GetParamDictionary(UnitPtr(), data, "upgrades", false);
		if (dicUpgrades !is null)
		{
			auto arrKeys = dicUpgrades.GetDictionary().getKeys();

			print("Upgrades: " + arrKeys.length());
			for (uint i = 0; i < arrKeys.length(); i++)
			{
				string id = arrKeys[i];
				int level = GetParamInt(UnitPtr(), dicUpgrades, arrKeys[i]);

				OwnedUpgrade ownedUpgrade;
				ownedUpgrade.m_id = id;
				ownedUpgrade.m_level = level;

				auto upgrade = Upgrades::GetShopUpgrade(ownedUpgrade.m_id, player);
				if (upgrade is null)
				{
					PrintError("Upgrade is null for \"" + ownedUpgrade.m_id + "\"");
					continue;
				}
				@ownedUpgrade.m_step = upgrade.GetStep(ownedUpgrade.m_level);

				player.upgrades.insertLast(ownedUpgrade);
			}

			print("Applying " + player.upgrades.length() + " upgrades to \"" + player.GetName() + "\":");
			for (uint i = 0; i < player.upgrades.length(); i++)
			{
				auto upgr = player.upgrades[i];
				string upgrInfo = Resources::GetString(upgr.m_step.m_name) + " (upgrade id \"" + upgr.m_id + "\", level " + upgr.m_level + ")";
				if (upgr.m_step.ApplyNow(player))
					print("+ " + upgrInfo);
				else
					print("  " + upgrInfo);
			}
		}

		// Clear keys
		for (uint i = 0; i < player.keys.length(); i++)
			player.keys[i] = 0;

		// Load keys
		auto keyData = data.GetDictionaryEntry("keys");
		if (keyData !is null)
		{
			auto arr = keyData.GetArray();
			for (uint i = 0; i < arr.length() && i < player.keys.length(); i++)
				player.keys[i] = arr[i].GetInteger();
		}

		// Clear soul links
		player.soulLinks.removeRange(0, player.soulLinks.length());

		// Load soul links
		auto soulLinkData = data.GetDictionaryEntry("soul-links");
		if (soulLinkData !is null)
		{
			auto arr = soulLinkData.GetArray();
			for (uint i = 0; i < arr.length() && i < player.keys.length(); i++)
				player.soulLinks.insertLast(arr[i].GetInteger());
		}

		// Load soul linked by
		auto soulLinkedBy = data.GetDictionaryEntry("soul-linked-by");
		if (soulLinkedBy !is null)
			player.soulLinkedBy = soulLinkedBy.GetInteger();

		// Clear items
		player.items.removeRange(0, player.items.length());

		// Load items
		auto itData = data.GetDictionaryEntry("items");
		if (itData !is null)
		{
			auto arr = itData.GetArray();
			for (uint i = 0; i < arr.length(); i++)
			{
				string itemId = arr[i].GetString();
				if (g_items.GetItem(itemId) !is null)
					player.items.insertLast(itemId);
			}
		}

		if (player.local)
		{
			// Make sure that all the items we own as the local player are "taken"
			for (uint i = 0; i < player.items.length(); i++)
				g_items.TakeItem(player.items[i]);
		}

		// Load character statistics
		auto dictStatistics = GetParamDictionary(UnitPtr(), data, "statistics", false);
		if (dictStatistics !is null)
			player.statistics.Load(dictStatistics);

		// Load session statistics
		auto dictStatisticsSession = GetParamDictionary(UnitPtr(), data, "statistics-session", false);
		if (dictStatisticsSession !is null)
			player.statisticsSession.Load(dictStatisticsSession);

		// Load general store items
		auto arrGeneralStore = GetParamArray(UnitPtr(), data, "generalstore", false);
		if (arrGeneralStore !is null && arrGeneralStore.length() > 0)
		{
			player.generalStoreItemsSaved = arrGeneralStore[0].GetInteger();
			for (uint i = 1; i < arrGeneralStore.length(); i++)
				player.generalStoreItems.insertLast(arrGeneralStore[i].GetInteger());
		}
		else
			player.generalStoreItemsSaved = -1;

		// Load general store plume state
		player.generalStoreItemsPlume = GetParamInt(UnitPtr(), data, "generalstore-plume", false);

		if (player.actor !is null)
			cast<PlayerBase>(player.actor).Refresh();
	}
}
