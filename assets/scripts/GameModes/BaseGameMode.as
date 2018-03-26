void SetTileEffectsCvar(bool v)
{
	CVars::UseTileEffects = v;
}

void ListFlagsCFunc()
{
	string level = ":";
	string run = ":";
	string town = ":";
	string host = ":";
	
	auto flagKeys = g_flags.m_flags.getKeys();
	for (uint i = 0; i < flagKeys.length(); i++)
	{
		int64 state;
		g_flags.m_flags.get(flagKeys[i], state);

		switch(FlagState(state))
		{
		case FlagState::Level:
			level = level + "  " + flagKeys[i];
			break;
		case FlagState::Run:
			run = run + "  " + flagKeys[i];
			break;
		case FlagState::Town:
			town = town + "  " + flagKeys[i];
			break;
		case FlagState::TownAll:
		case FlagState::HostTown:
			host = host + "  " + flagKeys[i];
			break;
		}
	}

	print("Level:");
	print(level);
	print("Run:");
	print(run);
	print("Town:");
	print(town);
	print("Host:");
	print(host);
}

void SetUIScaleCVar(float val)
{
	auto res = GetVarIvec2("v_resolution");
	auto gm = cast<BaseGameMode>(g_gameMode);
	if (gm !is null)
		gm.ResizeWindow(res.x, res.y, GetVarFloat("g_scale"));
}


array<WorldScript::PrepareCamera@> g_prepareCameras;
int g_prepareCameraIndex = -1;

int g_doubleClickTime = -1;

void CvarDebugHandicap(bool value)
{
	auto gm = cast<Campaign>(g_gameMode);
	if (gm !is null)
	{
		if (gm.m_hud !is null)
			gm.m_hud.m_wDebugHandicap.m_visible = value;
	}
}

void CvarDebugWidgets(bool value)
{
	g_debugWidgets = value;
}

void CvarInspectWidget(bool value)
{
	g_inspectWidget = value;
}

void CvarPlayerNamesChanged(bool value)
{
	for (uint i = 0; i < g_players.length(); i++)
	{
		auto husk = cast<PlayerHusk>(g_players[i].actor);
		if (husk !is null)
			@husk.m_textName = null;
	}

	auto gm = cast<Campaign>(g_gameMode);
	if (gm !is null && gm.m_hud !is null && gm.m_hud.m_waypoints !is null)
	{
		for (uint i = 0; i < gm.m_hud.m_waypoints.m_waypoints.length(); i++)
		{
			auto wp = cast<PlayerWaypoint>(gm.m_hud.m_waypoints.m_waypoints[i]);
			if (wp is null)
				continue;

			@wp.m_textName = null;
		}
	}
}

void CvarHardwareCursor(bool value)
{
	auto gm = cast<BaseGameMode>(g_gameMode);
	if (gm.m_widgetRoots.length() == 0)
		return;

	if (value)
		Platform::ShowCursor();
	else
		Platform::HideCursor();
}

class BaseGameMode : AGameMode
{
	vec2 m_camPos;
	vec2 m_camPosLastLocal;
	bool m_camPosLastLocalSet;

	bool m_started;

	bool m_spawnedInitial;
	bool m_useSpawnLogic = true;
	
	array<IWidgetHoster@> m_widgetRoots;
	array<ScriptWidgetHost@> m_widgetScriptHosts;
	array<UserWindow@> m_userWindows;

	WidgetInspector@ m_widgetInspector;

	LevelEndScreen@ m_levelEndScreen;

	HUDSpectate@ m_hudSpectate;
	GameOver@ m_gameOver;

	bool m_switchingWidgetHoster;

	bool m_spectating;
	int m_spectatingPlayer;

	BitmapFont@ m_fntPlayerName;

	array<ScreenShake@> m_screenShake;

	int m_extraLives;
	int m_levelCount;

	Tooltip@ m_tooltip;
	array<MouseBase@> m_mice;

	bool m_usingUICursor;

	bool m_paused;
	
	BaseGameMode(Scene@ scene)
	{
		@g_scene = scene;
		@g_gameMode = this;

		Platform::Initialize();
		@m_currCursor = Platform::CursorNormal;

		g_doubleClickTime = Platform::GetDoubleClickTime();

		CharacterColors::LoadColors();

	//	m_guiBuilder.AddWidgetProducer("gui", PrintWidget);
		m_guiBuilder.AddWidgetProducer("group", LoadGroupWidget);
		m_guiBuilder.AddWidgetProducer("grouprect", LoadGroupRectWidget);
		m_guiBuilder.AddWidgetProducer("text", LoadTextWidget);
		m_guiBuilder.AddWidgetProducer("systext", LoadSysTextWidget);
		m_guiBuilder.AddWidgetProducer("sprite", LoadSpriteWidget);
		m_guiBuilder.AddWidgetProducer("rect", LoadRectWidget);
		m_guiBuilder.AddWidgetProducer("clip", LoadClipWidget);
		m_guiBuilder.AddWidgetProducer("scrollrect", LoadScrollableRectWidget);
		m_guiBuilder.AddWidgetProducer("flag", LoadFlagWidget);
		m_guiBuilder.AddWidgetProducer("transform", LoadTransformWidget);
		m_guiBuilder.AddWidgetProducer("button", LoadButtonWidget);
		m_guiBuilder.AddWidgetProducer("spritebutton", LoadSpriteButtonWidget);
		m_guiBuilder.AddWidgetProducer("scalebutton", LoadScalableSpriteButtonWidget);
		m_guiBuilder.AddWidgetProducer("scaleiconbutton", LoadScalableSpriteIconButtonWidget);
		m_guiBuilder.AddWidgetProducer("slider", LoadSliderWidget);
		m_guiBuilder.AddWidgetProducer("unit", LoadUnitWidget);
		m_guiBuilder.AddWidgetProducer("textinput", LoadTextInputWidget);
		m_guiBuilder.AddWidgetProducer("bar", LoadBarWidget);
		m_guiBuilder.AddWidgetProducer("scrollbar", LoadScrollbarWidget);
		m_guiBuilder.AddWidgetProducer("checkbox", LoadCheckboxWidget);
		m_guiBuilder.AddWidgetProducer("colorcheckbox", LoadColorCheckboxWidget);
		m_guiBuilder.AddWidgetProducer("checkboxgroup", LoadCheckBoxGroupWidget);
		m_guiBuilder.AddWidgetProducer("blink", LoadBlinkWidget);
		m_guiBuilder.AddWidgetProducer("filteredlist", LoadFilteredListWidget);
		m_guiBuilder.AddWidgetProducer("dotbar", LoadDotbarWidget);
		m_guiBuilder.AddWidgetProducer("spritebar", LoadSpriteBarWidget);
		m_guiBuilder.AddWidgetProducer("details", LoadDetailsWidget);
		
		@g_effectUnit = Resources::GetUnitProducer("system/effect.unit");
		@g_floatTextFont = Resources::GetBitmapFont("gui/fonts/font_hw8.fnt");
		@g_floatTextFontBig = Resources::GetBitmapFont("gui/fonts/arial11.fnt");
		
		
		AddVar("ui_txt", true);
		AddVar("ui_txt_plr_hurt", Tweak::FloatingTextColor_PlayerHurt);
		AddVar("ui_txt_plr_hurt_magic", Tweak::FloatingTextColor_PlayerHurtMagical);
		AddVar("ui_txt_enemy_hurt", Tweak::FloatingTextColor_EnemyHurt);
		AddVar("ui_txt_enemy_hurt_husk", Tweak::FloatingTextColor_EnemyHurtHusk);
		AddVar("ui_txt_plr_heal", Tweak::FloatingTextColor_PlayerHeal);
		AddVar("ui_txt_enemy_heal", Tweak::FloatingTextColor_EnemyHeal);
		AddVar("ui_txt_enemy_immortal", Tweak::FloatingTextColor_EnemyImmortal);
		AddVar("ui_txt_plr_armor", Tweak::FloatingTextColor_PlayerArmor);
		AddVar("ui_txt_plr_ammo", Tweak::FloatingTextColor_PlayerAmmo);
		AddVar("ui_txt_plr_ammo_max", Tweak::FloatingTextColor_PlayerAmmoMax);
		AddVar("ui_txt_pickup", Tweak::FloatingTextColor_Pickup);

		AddVar("ui_hide_fog", false, null, cvar_flags::Cheat);

		AddVar("ui_debug_handicap", false, CvarDebugHandicap);

		AddVar("g_screenshake", 1.0f);
		AddVar("g_gore", true);

		AddVar("debug_widgets", false, CvarDebugWidgets);
		AddVar("inspect_widget", false, CvarInspectWidget);
		AddVar("g_start_level", 0, null, cvar_flags::Cheat);

		AddVar("g_autoswitch_pickup", false);
		AddVar("g_autoswitch_empty", true);
		AddVar("g_local_player_marker", false);
		AddVar("g_player_markers", true);
		AddVar("g_laser_sight", -1);
		AddVar("g_movedir_snap", 16);
		AddVar("g_mousemove_speed", 40.0f);

		AddVar("ui_hud_stats", true);
		AddVar("ui_hud_skills", true);
		AddVar("ui_hud_bossbar", true);
		AddVar("ui_hud_bossbar_actors", true);
		AddVar("ui_hud_topbar", true);

		AddVar("ui_draw_widgets", true);
		AddVar("ui_draw_plr_names", 1);
		AddVar("ui_draw_plr_names_real", false, CvarPlayerNamesChanged);
		AddVar("ui_draw_plr_stats", true);
		AddVar("ui_draw_vignette", true);
		AddVar("ui_player_measure", false);
		AddVar("ui_cursor_unit", false);
		AddVar("ui_cursor_alpha", 1.0);
		AddVar("ui_chat_fade_time", 7000);
		AddVar("ui_chat_dialog", true);
		AddVar("ui_chat_scale", 1.0);
		AddVar("ui_chat_width", 0.35);
		AddVar("ui_hardware_cursor", false, CvarHardwareCursor);

		Tutorial::Initialize();
		
		AddVar("ui_show_intro", true);

		AddVar("ui_waypoint_player", 1.0f);
		AddVar("ui_waypoint_world", 1.0f);

		AddVar("g_wheel_always", false);
		AddVar("g_wheel_nextprev", true);
		AddVar("g_wheel_number", true);
		AddVar("g_wheel_showammo", true);
		AddVar("g_wheel_accurate", -1);

		AddVar("g_tile_effects", true, SetTileEffectsCvar);

		AddVar("ui_bars_visibility", 0);
		AddVar("ui_key_count", false);
		AddVar("ui_speechbubble_alpha", 1.0f);
		AddVar("ui_cursor_health", false);
		AddVar("ui_cursor_health_alpha", 0.5f);
		AddVar("ui_minimap_alpha", 0.75);
		AddVar("ui_scale", 1.0, SetUIScaleCVar);
		
		
		@m_widgetInspector = WidgetInspector();

		if (!GetVarBool("ui_hardware_cursor"))
			Platform::HideCursor();

		@m_levelEndScreen = LevelEndScreen(m_guiBuilder);

		MusicManager::Initialize();
		EnvironmentSoundSystem::Initialize();

		@m_hudSpectate = HUDSpectate(m_guiBuilder);

		@m_fntPlayerName = Resources::GetBitmapFont("gui/fonts/arial11.fnt");

		@m_tooltip = Tooltip(Resources::GetSValue("gui/tooltip.sval"));
		
		@m_safeGore = LoadGore("effects/gibs/no_gore.sval");
		

		AddFunction("list_flags", ListFlagsCFunc, cvar_flags::Cheat);
	}

	int GetPlayersAlive()
	{
		int ret = 0;
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer != 255 && !g_players[i].IsDead())
				ret++;
		}
		return ret;
	}

	void ShowDialog(string id, string question, string buttonYes, string buttonNo, IWidgetHoster@ returnHost) override
	{
		if (m_dialogWindow is null)
			@m_dialogWindow = DialogWindow(m_guiBuilder);

		m_dialogWindow.SetID(id);
		m_dialogWindow.SetButtonYes(buttonYes);
		m_dialogWindow.SetButtonNo(buttonNo);
		m_dialogWindow.SetReturnHost(returnHost);
		m_dialogWindow.SetQuestion(question);
		m_dialogWindow.m_visible = true;
		AddWidgetRoot(m_dialogWindow);
	}

	void ShowDialog(string id, string message, string button, IWidgetHoster@ returnHost) override
	{
		if (m_dialogWindow is null)
			@m_dialogWindow = DialogWindow(m_guiBuilder);

		m_dialogWindow.SetID(id);
		m_dialogWindow.SetButtonYes("");
		m_dialogWindow.SetButtonNo(button);
		m_dialogWindow.SetReturnHost(returnHost);
		m_dialogWindow.SetQuestion(message);
		m_dialogWindow.m_visible = true;
		AddWidgetRoot(m_dialogWindow);
	}

	void ShowInputDialog(string id, string message, IWidgetHoster@ returnHost, string defaultInput = "") override
	{
		if (m_dialogWindow is null)
			@m_dialogWindow = DialogWindow(m_guiBuilder);

		m_dialogWindow.SetID(id);
		m_dialogWindow.SetInput(defaultInput);
		m_dialogWindow.SetReturnHost(returnHost);
		m_dialogWindow.SetQuestion(message);
		m_dialogWindow.m_visible = true;
		AddWidgetRoot(m_dialogWindow);

		m_dialogWindow.FocusInput();
	}

	bool ShowOffscreenPlayer(PlayerBase@ player)
	{
		return true;
	}

	bool IsUserWindowVisible()
	{
		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i].m_visible)
				return true;
		}
		return false;
	}

	void ShowUserWindow(string id)
	{
		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i].GetScriptID() == id && !m_userWindows[i].m_visible)
				m_userWindows[i].Show();
			else if (m_userWindows[i].m_visible)
				m_userWindows[i].Close();
		}
	}

	void ShowUserWindow(UserWindow@ window)
	{
		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i] is window && !m_userWindows[i].m_visible)
				m_userWindows[i].Show();
			else if (m_userWindows[i].m_visible)
				m_userWindows[i].Close();
		}
	}

	void CloseUserWindow()
	{
		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i].m_visible)
				m_userWindows[i].Close();
		}
	}

	void ToggleUserWindow(UserWindow@ window)
	{
		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i] is window)
			{
				if (window.m_visible)
					window.Close();
				else
					window.Show();
			}
			else if (m_userWindows[i].m_visible)
				m_userWindows[i].Close();
		}
	}

	bool ShouldFreezeControls()
	{
		for (uint i = 0; i < m_widgetScriptHosts.length(); i++)
		{
			if (m_widgetScriptHosts[i].ShouldFreezeControls())
				return true;
		}

		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i].IsVisible())
				return true;
		}

		return (m_dialogWindow !is null && m_dialogWindow.m_visible)
		    || (m_levelEndScreen !is null && m_levelEndScreen.m_visible);
	}

	bool ShouldDisplayCursor()
	{
		for (uint i = 0; i < m_widgetScriptHosts.length(); i++)
		{
			if (m_widgetScriptHosts[i].ShouldDisplayCursor())
				return true;
		}

		for (uint i = 0; i < m_userWindows.length(); i++)
		{
			if (m_userWindows[i].IsVisible())
				return true;
		}

		if (m_dialogWindow !is null && m_dialogWindow.m_visible)
			return true;

		if (m_levelEndScreen !is null && m_levelEndScreen.m_visible)
			return true;

		if (!m_paused && m_currInput !is null && !m_currInput.UsingGamepad)
			return true;

		return false;
	}

	void ResizeWindow(int w, int h, float scale)
	{
		if(scale == 0 || w == 0 || h == 0)
			return;

		scale *= GetVarFloat("ui_scale");
			
		m_wndWidth = int(w / scale);
		m_wndHeight = int(h / scale);
		m_wndAspect = m_wndWidth / float(m_wndHeight);
		m_wndScale = scale;
		m_wndInvScaleTransform = mat::scale(mat4(), 1.0 / scale);

		for (uint i = 0; i < m_widgetRoots.length(); i++)
			m_widgetRoots[i].DoLayout();

		auto hud = GetHUD();
		if (hud !is null)
			hud.DoLayout();
	}

	HUD@ GetHUD() override { return null; }

	ScreenShake@ ShakeScreen(int tm, float amount, vec3 pos = vec3(), float range = -1.0f)
	{
		float scale = GetVarFloat("g_screenshake");
		if (scale <= 0.0f)
			return null;

		ScreenShake@ newShake = ScreenShake();
		newShake.m_time = newShake.m_timeC = tm;
		newShake.m_amount = amount * scale;
		newShake.m_position = pos;
		newShake.m_range = range;
		m_screenShake.insertLast(newShake);

		return newShake;
	}

	vec2 GetMousePos()
	{
		if (m_mice.length() == 0)
			return vec2();
		return m_mice[0].m_pos;
	}

	void UpdateMouse(int ms, GameInput& gameInput, MenuInput& menuInput)
	{
		for (uint i = 0; i < m_mice.length(); i++)
			m_mice[i].Update(ms);
	}

	void DrawMouse(int idt, SpriteBatch& sb)
	{
		sb.Begin(g_gameMode.m_wndWidth, g_gameMode.m_wndHeight, m_wndScale);

		if (m_widgetRoots.length() > 0)
		{
			if (m_mice.length() != 0)
				m_mice[0].DrawTooltip(idt, sb, m_tooltip);
		}

		for (uint i = 0; i < m_mice.length(); i++)
		{
			if (m_mice[i].m_real && m_usingUICursor && GetVarBool("ui_hardware_cursor"))
				continue;
			m_mice[i].Draw(idt, sb);
		}

		sb.End();
	}

	void Paused(bool paused)
	{
		m_paused = paused;
	}
	
	void UpdatePausedFrame(int ms, GameInput& gameInput, MenuInput& menuInput)
	{
		@m_currInput = gameInput;
		@m_currInputMenu = menuInput;
	
		UpdateWidgets(ms, gameInput, menuInput);
		UpdateMouse(ms, gameInput, menuInput);
	}
	
	void UpdateFrame(int ms, GameInput& gameInput, MenuInput& menuInput)
	{
		m_gameTime += ms;
		
		if (m_mice.length() == 0)
			m_mice.insertLast(IngameMouse(gameInput, menuInput));
		else
		{
			@m_mice[0].m_inputGame = gameInput;
			@m_mice[0].m_inputMenu = menuInput;
		}

		MusicManager::Update(ms);

		for (uint i = 0; i < m_screenShake.length(); i++)
		{
			m_screenShake[i].Update(ms);
			if (m_screenShake[i].m_timeC <= 0)
				m_screenShake.removeAt(i--);
		}
		
		@m_currInput = gameInput;
		@m_currInputMenu = menuInput;
		
		array<vec2> pingPos;
		
		for (uint i = 0; i < g_players.length(); i++)
		{
			Actor@ a = g_players[i].actor;
			if (a !is null)
				pingPos.insertLast(xy(a.m_unit.GetPosition()));
		}

		if (pingPos.length() == 0)
			pingPos.insertLast(m_camPos);
		
		g_scene.Ping(pingPos);

		if (m_spectating)
		{
			if (m_levelEndScreen.m_visible)
				StopSpectating();
			else if (gameInput.Attack1.Pressed)
				SpectateNextPlayer();
		}

		UpdateWidgets(ms, gameInput, menuInput);
		UpdateGibs(ms);
		
		
%PROFILE_START AttachedSounds
		for (uint i = 0; i < m_attachedSounds.length();)
		{
			if (m_attachedSounds[i].unit.IsDestroyed() || !m_attachedSounds[i].sound.IsPlaying())
				m_attachedSounds.removeAt(i);
			else
			{
				m_attachedSounds[i].sound.SetPosition(m_attachedSounds[i].unit.GetPosition());
				i++;
			}
		}
%PROFILE_STOP

%PROFILE_START FloatingTexts
		for (uint i = 0; i < g_floatingTexts.length();)
		{
			g_floatingTexts[i].Update(ms);
			if (!g_floatingTexts[i].m_alive)
				g_floatingTexts.removeAt(i);
			else
				i++;
		}
%PROFILE_STOP

		UpdateMouse(ms, gameInput, menuInput);
	}

	void SpectateUpdateHUD()
	{
		if (!m_spectating)
			return;

		auto spectatingRecord = g_players[m_spectatingPlayer];
		auto spectatingPlayer = cast<PlayerHusk>(spectatingRecord.actor);
	}

	void StopSpectating()
	{
		m_spectating = false;
	}

	void BeginSpectating()
	{
		m_spectating = true;
		SpectateUpdateHUD();
	}

	void ToggleSpectating()
	{
		if (m_spectating)
			StopSpectating();
		else
			BeginSpectating();
	}

	void SpectateNextPlayer()
	{
		int startIndex = m_spectatingPlayer;
		do
		{
			m_spectatingPlayer++;
			if (uint(m_spectatingPlayer) >= g_players.length())
				m_spectatingPlayer = 0;
		}
		while (m_spectatingPlayer != startIndex && g_players[m_spectatingPlayer].IsDead());

		SpectateUpdateHUD();
	}

	void FocusTopRoot()
	{
		if (m_widgetRoots.length() == 0)
			return;
		m_widgetRoots[m_widgetRoots.length() - 1].m_forceFocus = true;

		if (m_widgetUnderCursor !is null)
		{
			m_widgetUnderCursor.SetHovering(false, m_widgetUnderCursor.GetCenter());
			@m_widgetUnderCursor = null;
		}

		if (m_widgetInputFocus !is null)
			@m_widgetInputFocus = null;

		m_switchingWidgetHoster = true;
	}

	void AddWidgetRoot(IWidgetHoster@ host) override
	{
		m_widgetRoots.insertLast(host);
		FocusTopRoot();
	}

	void RemoveWidgetRoot(IWidgetHoster@ host) override
	{
		int i = m_widgetRoots.findByRef(host);
		if (i != -1)
			m_widgetRoots.removeAt(i);
		FocusTopRoot();
	}

	void ReplaceWidgetRoot(IWidgetHoster@ find, IWidgetHoster@ replace) override
	{
		int i = m_widgetRoots.findByRef(find);
		if (i != -1)
			@m_widgetRoots[i] = replace;
		else
			m_widgetRoots.insertLast(replace);
		FocusTopRoot();
	}

	void ReplaceTopWidgetRoot(IWidgetHoster@ host) override
	{
		if (m_widgetRoots.length() == 0)
			m_widgetRoots.insertLast(host);
		else
			@m_widgetRoots[m_widgetRoots.length() - 1] = host;
		FocusTopRoot();
	}

	void SetExclusiveWidgetRoot(IWidgetHoster@ host) override
	{
		m_widgetRoots.removeRange(0, m_widgetRoots.length());
		m_widgetRoots.insertLast(host);
		FocusTopRoot();
	}

	void ClearWidgetRoot() override
	{
		m_widgetRoots.removeRange(0, m_widgetRoots.length());
		@m_widgetInputFocus = null;
	}

	bool MenuBack()
	{
		if (m_widgetInputFocus !is null)
		{
			@m_widgetInputFocus = null;
			return true;
		}

		if (m_widgetScriptHosts.length() > 0)
		{
			m_widgetScriptHosts[0].Stop();
			return true;
		}

		for (int i = m_userWindows.length() - 1; i >= 0; i--)
		{
			if (m_userWindows[i].IsVisible())
			{
				m_userWindows[i].Close();
				return true;
			}
		}

		if (m_dialogWindow !is null && m_dialogWindow.m_visible)
		{
			m_dialogWindow.Close();
			return true;
		}

		return false;
	}

	void SetCursorGame()
	{
		if (m_currCursor is Platform::CursorAimNormal)
			return;

		m_usingUICursor = false;
		@m_currCursor = Platform::CursorAimNormal;

		Platform::HideCursor();
	}

	void SetCursorUI()
	{
		Platform::CursorInfo@ cursor = m_currCursor;
		if (m_widgetUnderCursor !is null && m_widgetUnderCursor.m_hovering && m_widgetUnderCursor.m_cursor !is null)
			@cursor = m_widgetUnderCursor.m_cursor;
		else
			@cursor = Platform::CursorNormal;

		if (m_currCursor is cursor)
			return;

		m_usingUICursor = true;
		@m_currCursor = cursor;

		if (GetVarBool("ui_hardware_cursor"))
			Platform::ShowCursor();
		else
			Platform::HideCursor();
	}

	void UpdateCurrentCursor()
	{
		if (m_widgetRoots.length() == 0)
			SetCursorGame();
		else
			SetCursorUI();
	}

	void UpdateWidgets(int ms, GameInput& gameInput, MenuInput& menuInput)
	{
		g_menuTime += ms;

		UpdateCurrentCursor();

		int width = m_wndWidth;
		int height = m_wndHeight;
		float scale = m_wndScale;

		for (uint i = 0; i < m_widgetScriptHosts.length(); i++)
			m_widgetScriptHosts[i].Update(ms);

		for (uint i = 0; i < m_userWindows.length(); i++)
			m_userWindows[i].Update(ms);

		if (m_hudSpectate !is null && m_spectating)
			m_hudSpectate.Update(ms);

		bool ignoreInput = false;
		if (m_widgetInputFocus !is null)
			ignoreInput = m_widgetInputFocus.UpdateInput(gameInput);

		bool underCursorValid = m_widgetUnderCursor !is null;
		if (underCursorValid)
		{
			bool inRoots = false;
			for (uint i = 0; i < m_widgetRoots.length(); i++)
			{
				if (m_widgetUnderCursor.m_host is m_widgetRoots[i])
				{
					inRoots = true;
					break;
				}
			}
			if (!inRoots)
				underCursorValid = false;
		}
		if (!underCursorValid)
			@m_widgetUnderCursor = null;

		for (int i = int(m_widgetRoots.length()) - 1; i >= 0; i--)
		{
			vec2 mousePos = GetMousePos();
			m_widgetRoots[i].UpdateInput(vec2(), vec2(width, height), vec3(mousePos.x / scale, mousePos.y / scale, gameInput.MouseWheelDelta));
			if (m_widgetRoots[i].BlocksLower())
				break;
		}

		if (menuInput.Forward.Released)
		{
			if (m_widgetInputFocus !is null && !m_widgetInputFocus.m_hovering && !m_widgetInputFocus.m_priorityFocus)
			{
				@m_widgetInputFocus = null;
				if (ignoreInput)
					ignoreInput = false;
			}
			else if (m_widgetUnderCursor !is null && m_widgetUnderCursor.m_canFocusInput)
				@m_widgetInputFocus = m_widgetUnderCursor;
		}

		if (ignoreInput)
			return;

		if (m_switchingWidgetHoster)
		{
			if (!menuInput.Forward.Pressed && !menuInput.Forward.Down && !menuInput.Forward.Released)
				m_switchingWidgetHoster = false;
		}

		// Widgets that can be interacted with must be visible and must have a parent accompanying their child at all times.
		if (m_widgetUnderCursor !is null && (!m_widgetUnderCursor.m_visible || m_widgetUnderCursor.m_parent is null))
			@m_widgetUnderCursor = null;

		if (m_widgetUnderCursor !is null && m_widgetUnderCursor.m_canFocus)
		{
			auto w = m_widgetUnderCursor;

			if (w.m_hovering && !m_switchingWidgetHoster)
			{
				Widget@ wb = w;
				while (wb !is null) {
					bool propogate = true;
					vec2 mousePosRel = (GetMousePos() / m_wndScale) - wb.m_origin;
					if (menuInput.Forward.Pressed)
						propogate = !wb.OnMouseDown(mousePosRel);
					else if (menuInput.Forward.Released)
					{
						if (wb.m_canDoubleClick && wb.m_doubleClickTime > 0 && (int(wb.m_doubleClickPos.x) == int(mousePosRel.x) && int(wb.m_doubleClickPos.y) == int(mousePosRel.y)))
						{
							wb.m_doubleClickTime = 0;
							propogate = !wb.OnDoubleClick(mousePosRel);
						}
						else
						{
							wb.m_doubleClickTime = g_doubleClickTime;
							wb.m_doubleClickPos = mousePosRel;
							propogate = !wb.OnClick(mousePosRel);
						}
						if (wb.OnMouseUp(mousePosRel))
							propogate = false;
					}
					if (!propogate)
						break;
					@wb = wb.m_parent;
				}
			}

			bool changedFocus = false;
			if (menuInput.Up.Pressed)
				changedFocus = w.FocusTowards(WidgetDirection::Up);
			else if (menuInput.Down.Pressed)
				changedFocus = w.FocusTowards(WidgetDirection::Down);

			if (menuInput.Left.Pressed)
				changedFocus = w.FocusTowards(WidgetDirection::Left);
			else if (menuInput.Right.Pressed)
				changedFocus = w.FocusTowards(WidgetDirection::Right);

			if (changedFocus)
				w.SetHovering(false, w.GetCenter(), true);
		}
		else if (menuInput.Up.Pressed || menuInput.Down.Pressed || menuInput.Left.Pressed || menuInput.Right.Pressed)
		{
			// give focus to the first focusable widget we can find
			for (uint i = 0; i < m_widgetRoots.length(); i++)
			{
				auto w = FirstFocusable(m_widgetRoots[i].m_widget);
				if (w !is null)
				{
					w.SetHovering(true, w.GetCenter(), true);
					break;
				}
			}
		}

		if (m_dialogWindow !is null)
			m_dialogWindow.Update(ms);

		if (GetVarBool("inspect_widget"))
			m_widgetInspector.Update(ms);
	}

	Widget@ FirstFocusable(Widget@ w)
	{
		if (w.m_canFocus)
			return w;

		for (uint i = 0; i < w.m_children.length(); i++)
		{
			auto ww = w.m_children[i];
			if (ww.m_canFocus)
				return ww;
			auto wwf = FirstFocusable(ww);
			if (wwf !is null)
				return wwf;
		}

		return null;
	}

	
	
	void DrawFloatingTexts(int idt, SpriteBatch& sb)
	{
		for (uint i = 0; i < g_floatingTexts.length(); i++)
			g_floatingTexts[i].Draw(idt, sb);
	}

	vec2 GetCameraPos(int idt)
	{
		PlayerRecord@ player = null;

		if (m_spectating)
			@player = g_players[m_spectatingPlayer];
		else
			@player = GetLocalPlayerRecord();

		if (player !is null && player.actor !is null)
		{
			m_camPos = xy(player.actor.m_unit.GetInterpolatedPosition(idt));
			m_camPos.y -= Tweak::PlayerCameraHeight;
			
			if (player.local)
			{
				m_camPosLastLocal = m_camPos;
				m_camPosLastLocalSet = true;
			}
		}
		else if (player !is null && player.actor is null && player.local && m_camPosLastLocalSet)
			m_camPos = m_camPosLastLocal;
		else if (g_prepareCameras.length() > 0)
		{
			if (g_prepareCameraIndex == -1)
				g_prepareCameraIndex = randi(g_prepareCameras.length());
			m_camPos = xy(g_prepareCameras[g_prepareCameraIndex].Position);
		}
		else if (m_levelStarts.length() > 0)
			m_camPos = xy(m_levelStarts[0].Position);

		vec2 shake;

		for (uint i = 0; i < m_screenShake.length(); i++)
			shake += m_screenShake[i].GetCameraOffset(xyz(m_camPos), idt);

		return m_camPos + shake;
	}

	vec4 GetVignette(int idt)
	{
		if (!GetVarBool("ui_draw_vignette"))
			return vec4(0,0,0,0);

		PlayerRecord@ player = null;

		if (m_spectating)
			@player = g_players[m_spectatingPlayer];
		else
			@player = GetLocalPlayerRecord();

		float hp = (player !is null) ? player.CurrentHealthScalar() : 0;
		float timePulse = sin((g_scene.GetTime() + idt) * lerp(0.006, 0.003, hp / 3.0));
		vec4 vignette(0.7 + timePulse * 0.075, 0, 0, 0);
		if (hp <= 0.3)
			vignette.a = 1.0;

		return vignette;
	}

	bool ShouldDisplayPlayerNames()
	{
%if CFG_SPLITSCREEN
		return false;
%else
		return true;
%endif
	}

	void PreRenderFrame(int idt)
	{
		for (uint i = 0; i < m_preRenderables.length();)
		{
			if (m_preRenderables[i].PreRender(idt))
				m_preRenderables.removeAt(i);
			else
				i++;
		}
		
		for (uint i = 0; i < m_attachedEffects.length();)
		{
			if (m_attachedEffects[i].unit.IsDestroyed() || m_attachedEffects[i].effect.m_unit.IsDestroyed())
				m_attachedEffects.removeAt(i);
			else
			{
				m_attachedEffects[i].effect.m_unit.SetPosition(m_attachedEffects[i].unit.GetInterpolatedPosition(idt));
				i++;
			}
		}

		GetCameraPos(idt);
		Sound::SetListener(xyz(m_camPos), vec3(0, 0, -1), vec3(0, -1, 0));
	}

	string GetPlayerDisplayName(PlayerRecord@ record)
	{
		string ret;
		if (GetVarBool("ui_draw_plr_names_real"))
			ret = record.GetLobbyName();
		else
			ret = record.GetName();

		if (ret.length() > 12)
			ret = ret.substr(0, 12) + "..";

		return EscapeString(ret);
	}

	void DisplayPlayerName(SpriteBatch& sb, PlayerRecord@ record, PlayerHusk@ plr, vec2 pos)
	{
		if (plr.m_textName is null)
		{
			string playerName = GetPlayerDisplayName(record);
			@plr.m_textName = m_fntPlayerName.BuildText(playerName, -1, TextAlignment::Center);
			plr.m_textName.SetColor(ColorForPlayer(record));
		}
		sb.DrawString(pos - vec2(plr.m_textName.GetWidth() / 2, 16 + plr.m_textName.GetHeight()), plr.m_textName);
	}

	void DisplayPlayerHealth(SpriteBatch& sb, PlayerRecord@ record, PlayerHusk@ plr, vec2 pos)
	{
		vec4 colorBackground = vec4(0, 0, 0, 1);
		vec4 colorEmpty = vec4(0.16, 0.06, 0.06, 1);
		vec4 colorFilled = vec4(1, 0, 0, 1);

		int barWidth = 16;
		int barHeight = 3;

		int x = int(pos.x - barWidth / 2);
		int y = int(pos.y - 14);
		sb.FillRectangle(vec4(x, y, barWidth, 3), colorBackground);

		int w = int((barWidth - 2) * clamp(record.hp, 0.0f, 1.0f));
		int h = barHeight - 2;
		sb.FillRectangle(vec4(x + 1, y + 1, w, h), colorFilled);

		x += w;
		w = (barWidth - 2) - w;
		sb.FillRectangle(vec4(x + 1, y + 1, w, h), colorEmpty);
	}

	void RenderFrame(int idt, SpriteBatch& sb)
	{
		sb.PushTransformation(mat::scale(mat4(), GetVarFloat("ui_scale")));
	
		for (uint i = 0; i < g_players.length(); i++)
		{
			PlayerRecord@ record = g_players[i];
			PlayerHusk@ plr = cast<PlayerHusk>(record.actor);
			if (plr is null)
				continue;

			int showNames = GetVarInt("ui_draw_plr_names");

			bool willShowNames = false;
			if (showNames == 1)
				willShowNames = true;
			else if (showNames == 0)
				willShowNames = (cast<Town>(this) !is null);

			vec2 playerHuskPos = ToScreenspace(plr.m_unit.GetInterpolatedPosition(idt)) / m_wndScale;

			if (ShouldDisplayPlayerNames() && willShowNames)
				DisplayPlayerName(sb, record, plr, playerHuskPos);
		}

		if (GetVarBool("ui_draw_plr_stats"))
		{
			for (uint i = 0; i < g_players.length(); i++)
			{
				PlayerRecord@ record = g_players[i];
				PlayerHusk@ plr = cast<PlayerHusk>(record.actor);
				if (plr is null)
					continue;

				vec2 playerHuskPos = ToScreenspace(plr.m_unit.GetInterpolatedPosition(idt)) / m_wndScale;
				DisplayPlayerHealth(sb, record, plr, playerHuskPos);
			}
		}

		if (GetVarBool("ui_draw_widgets"))
		{
%PROFILE_START DrawWidgets

			PlayerRecord@ player = null;
			if (m_spectating)
				@player = g_players[m_spectatingPlayer];
			else
				@player = GetLocalPlayerRecord();
		
			sb.Begin(m_wndWidth, m_wndHeight, m_wndScale);
			RenderWidgets(player, idt, sb);
			sb.End();
			
%PROFILE_STOP
		}

		if (GetVarBool("ui_player_measure") && m_mice.length() > 0)
		{
			auto player = GetLocalPlayer();
			if (player !is null)
			{
				vec2 posMouse = m_mice[0].GetPos(idt);

				vec3 posPlayer = player.m_unit.GetPosition();
				vec3 posMouseWorld = ToWorldspace(posMouse);

				auto font = Resources::GetBitmapFont("gui/fonts/font_hw8.fnt");
				auto text = font.BuildText(round(dist(posPlayer, posMouseWorld)) + "px");
				sb.DrawString((posMouse / m_wndScale) + vec2(-text.GetWidth() / 2, 12), text);
			}
		}

		if (GetVarBool("ui_cursor_unit") && m_mice.length() > 0)
		{
			vec2 posMouse = m_mice[0].GetPos(idt);
			vec3 posMouseWorld = ToWorldspace(posMouse);

			array<UnitPtr>@ units = g_scene.QueryCircle(xy(posMouseWorld), 8, ~0, RaycastType::Any, true);
			string strUnits = "";
			for (uint i = 0; i < units.length(); i++)
				strUnits += units[i].GetDebugName() + "\n";

			auto font = Resources::GetBitmapFont("gui/fonts/font_hw8.fnt");
			auto text = font.BuildText(strUnits, -1, TextAlignment::Center);
			sb.DrawString((posMouse / m_wndScale) + vec2(-text.GetWidth() / 2, 20), text);
		}

		if (ShouldDisplayCursor())
			DrawMouse(idt, sb);

		int numSessions = Platform::GetSessionCount();
		int numPeer = GetLocalPlayerRecord().peer;
		vec4 borderColor = vec4(0, 0, 0, 1);
		if (numSessions > 1)
		{
			sb.Begin(m_wndWidth, m_wndHeight, m_wndScale);

			vec4 rect;
			if (numSessions == 2)
			{
				if (numPeer == 0)
					rect = vec4(m_wndWidth - 1, 0, 1, m_wndHeight);
				else if (numPeer == 1)
					rect = vec4(0, 0, 1, m_wndHeight);
				sb.DrawSprite(null, rect, rect, borderColor);
			}
			else if (numSessions == 3 || numSessions == 4)
			{
				if ((numPeer % 2) == 0)
					rect = vec4(m_wndWidth - 1, 0, 1, m_wndHeight);
				else if ((numPeer % 2) == 1)
					rect = vec4(0, 0, 1, m_wndHeight);
				sb.DrawSprite(null, rect, rect, borderColor);

				if (numPeer < 2)
					rect = vec4(0, m_wndHeight - 1, m_wndWidth, 1);
				else
					rect = vec4(0, 0, m_wndWidth, 1);
				sb.DrawSprite(null, rect, rect, borderColor);
			}

			sb.End();
		}
		
		sb.PopTransformation();
	}

	vec4 ColorForPlayer(PlayerRecord@ record)
	{
		return ParseColorRGBA("#" + GetPlayerColor(record.peer) + "ff");
	}

	void RenderWidgets(PlayerRecord@ player, int idt, SpriteBatch& sb)
	{
		for (uint i = 0; i < m_widgetScriptHosts.length(); i++)
			m_widgetScriptHosts[i].Draw(sb, idt);

		if (m_hudSpectate !is null && m_spectating)
			m_hudSpectate.Draw(sb, idt);

		for (uint i = 0; i < m_userWindows.length(); i++)
			m_userWindows[i].Draw(sb, idt);

		if (m_dialogWindow !is null)
			m_dialogWindow.Draw(sb, idt);

		if (g_debugWidgets)
		{
			string hosterDebug = "";

			hosterDebug += "\\cff0000Widget Roots\n";
			for (uint i = 0; i < m_widgetRoots.length(); i++)
				hosterDebug += "\\caaaaaa" + i + " \\cffffff" + m_widgetRoots[i].m_filenameDef + "\n";

			BitmapFont@ fontDebug = Resources::GetBitmapFont("system/system_small.fnt");
			BitmapString@ text = fontDebug.BuildText(hosterDebug);

			sb.FillRectangle(vec4(10, 10, text.GetWidth(), text.GetHeight()), vec4(0, 0, 0, 0.7f));
			sb.DrawString(vec2(10, 10), text);
		}

		if (GetVarBool("inspect_widget"))
			m_widgetInspector.Draw(sb, idt);
	}

	SValue@ Save()
	{
		SValueBuilder builder;
		builder.PushDictionary();
		builder.PushInteger("level-count", m_levelCount);
		Save(builder);
		return builder.Build();
	}
	
	void Save(SValueBuilder& builder)
	{
		builder.PushString("start-id", g_startId);
		builder.PushVector2("spawn-pos", g_spawnPos);
		
		int shortcut = 0;
		int numPlrs = 0;
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;
		
			numPlrs++;
			shortcut = max(shortcut, g_players[i].shortcut);
			if (g_players[i].newGamePlus > g_ngp)
				shortcut = 1000;
		}
		
		builder.PushInteger("num-plrs", numPlrs);
		builder.PushInteger("shortcut", shortcut);
		MusicManager::Save(builder);
		
		
		auto flagKeys = g_flags.m_flags.getKeys();
		if (flagKeys.length() > 0)
		{
			builder.PushDictionary("flags");
			
			for (uint i = 0; i < flagKeys.length(); i++)
			{
				int64 state;
				g_flags.m_flags.get(flagKeys[i], state);
				
				FlagState flag = FlagState(state);
				if (flag == FlagState::Level)
					builder.PushBoolean(flagKeys[i], false);
				else if (flag == FlagState::Run)
					builder.PushBoolean(flagKeys[i], true);
			}

			builder.PopDictionary();
		}
		
		
		SavePlayer(GetLocalPlayerRecord());
	}
	
	void SavePlayer(PlayerRecord& player, bool saveLevel = false)
	{
		if (!player.local)
			return;
	
		SValueBuilder plrBuilder;
		
		plrBuilder.PushDictionary("player");
		SavePlayer(plrBuilder, player);
		plrBuilder.PopDictionary();
		
		if (player.IsDead() || player.hp <= 0)
			saveLevel = false;
		
		SaveCharacter(plrBuilder.Build(), saveLevel);
	}
	
	void SavePlayer(SValueBuilder& builder, PlayerRecord& player)
	{
		if (player.IsDead() || player.hp <= 0)
			builder.PushFloat("hp", -1);
		else
			builder.PushFloat("hp", player.hp);
		
		builder.PushFloat("mana", player.mana);
		builder.PushInteger("armor", player.armor);
		builder.PushInteger("experience", player.experience);
		builder.PushInteger("level", player.level);
		builder.PushInteger("free-lives-taken", player.freeLivesTaken);
		builder.PushInteger("kills", player.kills);
		builder.PushInteger("kills-total", player.killsTotal);
		builder.PushInteger("deaths", player.deaths);
		builder.PushInteger("deaths-total", player.deathsTotal);
		builder.PushInteger("pickups", player.pickups);
		builder.PushInteger("pickups-total", player.pickupsTotal);

		if (player.armorDef !is null)
			builder.PushInteger("armor-def", player.armorDef.m_pathHash);
		
		if (player.actor !is null)
			builder.PushVector2("pos", xy(player.actor.m_unit.GetPosition()));

		builder.PushArray("perks");

		for (uint i = 0; i < player.perks.length(); i++)
			builder.PushInteger(player.perks[i]);

		builder.PopArray();
		
		if (player.runEnded)
			builder.PushBoolean("in-town", true);
	}
	
	void LoadPlayer(SValue& data, PlayerRecord& player)
	{
		auto perksData = data.GetDictionaryEntry("perks");
		if (perksData !is null && perksData.GetType() == SValueType::Array)
		{
			auto arr = perksData.GetArray();
			for (uint i = 0; i < arr.length(); i++)
				player.perks.insertLast(arr[i].GetInteger());
		}

		player.RefreshPerkData();

		player.hp = GetParamFloat(UnitPtr(), data, "hp", false, 1.0);
		player.mana = GetParamFloat(UnitPtr(), data, "mana", false, 1.0);
		player.armor = GetParamInt(UnitPtr(), data, "armor", false, 0);
		@player.armorDef = LoadArmorDef(GetParamInt(UnitPtr(), data, "armor-def", false));
		player.experience = GetParamInt(UnitPtr(), data, "experience", false, 0);
		player.level = GetParamInt(UnitPtr(), data, "level", false, 1);
		player.freeLivesTaken = GetParamInt(UnitPtr(), data, "free-lives-taken", false, 0);
		player.killsTotal = GetParamInt(UnitPtr(), data, "kills-total", false, 0);
		player.deathsTotal = GetParamInt(UnitPtr(), data, "deaths-total", false, 0);
		player.pickupsTotal = GetParamInt(UnitPtr(), data, "pickups-total", false, 0);

		if (player.hp <= 0.0f)
			player.deadTime = 1;

		//if (sMode != StartMode::Continue)
		{
			player.kills = GetParamInt(UnitPtr(), data, "kills", false, 0);
			player.deaths = GetParamInt(UnitPtr(), data, "deaths", false, 0);
			player.pickups = GetParamInt(UnitPtr(), data, "pickups", false, 0);
		}
		
		//print("Loaded plr hp: " + player.hp);
		
		//builder.PushVector2("pos", xy(player.actor.m_unit.GetPosition()));
	}

	PlayerRecord@ CreatePlayerRecord()
	{
		return PlayerRecord();
	}

	void Start(uint8 peer, SValue@ save, StartMode sMode)
	{
		ActivatePlayerRecord(peer);
	
		bool loadedStartPos = false;
		WorldScript::LevelStart@ loadedLevelStart = null;

		if (m_useSpawnLogic)
		{
			if ((sMode == StartMode::Continue || sMode == StartMode::StartGame) && !g_useSpawnPos)
			{
				string startId = "";
		
				auto startIdV = (save !is null) ? save.GetDictionaryEntry("start-id") : null;
				if (startIdV !is null && startIdV.GetType() == SValueType::String)
					startId = startIdV.GetString();
			
				for (uint i = 0; i < m_levelStarts.length(); i++)
				{
					if (m_levelStarts[i].StartID == startId)
					{
						g_spawnPos = xy(m_levelStarts[i].Position);
						loadedStartPos = true;
						@loadedLevelStart = m_levelStarts[i];
						break;
					}
				}
			}
			
			if (!loadedStartPos && save !is null)
			{
				auto spawnPosV = save.GetDictionaryEntry("spawn-pos");
				if (spawnPosV !is null && spawnPosV.GetType() == SValueType::Vector2)
					g_spawnPos = spawnPosV.GetVector2();
			}
		}
		
		
		if (save !is null)
		{
			if (sMode != StartMode::Continue)
				MusicManager::Load(save);
		
			auto flagsData = save.GetDictionaryEntry("flags");
			if (flagsData !is null && flagsData.GetType() == SValueType::Dictionary)
			{
				auto flagsDict = flagsData.GetDictionary();
				auto flagsKeys = flagsDict.getKeys();
				
				for (uint i = 0; i < flagsKeys.length(); i++)
				{
					SValue@ flagData = null;
					if (!flagsDict.get(flagsKeys[i], @flagData))
						continue;
					
					if (flagData is null || flagData.GetType() != SValueType::Boolean)
						continue;

					bool persistent = flagData.GetBoolean();
					if (!persistent && sMode == StartMode::Continue)
						continue;

					g_flags.Set(flagsKeys[i], persistent ? FlagState::Run : FlagState::Level);
				}
			}
		}

		m_started = true;
	}
	
	void PostStart()
	{
		SpawnPlayers();
		/*
		if (loadedLevelStart !is null)
		{
			auto script = WorldScript::GetWorldScript(g_scene, loadedLevelStart);
			if (script !is null)
				script.Execute();
		}
		*/
		RefreshMultiplayerScaling();
	}

	
	void ActivatePlayerRecord(uint8 peer)
	{
		uint64 id = GetUniquePeerId(peer);
		bool local = Lobby::IsPlayerLocal(peer);
	
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].id == id)
			{
				g_players[i].id = id;
				g_players[i].peer = peer;
				g_players[i].local = local;
				
				auto plrSave = LoadCharacter(peer);
				if (plrSave !is null)
					LoadPlayer(plrSave, g_players[i]);
			
				RefreshMultiplayerScaling();
				return;
			}
		}
	
		PlayerRecord@ plr = CreatePlayerRecord();
		plr.peer = peer;
		plr.local = local;
		plr.id = id;
		@plr.actor = null;
		
		InitializePlayer(plr);
		g_players.insertLast(plr);
		
		auto plrSave = LoadCharacter(peer);
		if (plrSave !is null)
			LoadPlayer(plrSave, plr);
			
		RefreshMultiplayerScaling();
	}
	
	void InitializePlayer(PlayerRecord& player)
	{
		player.hp = 1.0;
		player.armor = 0;
		if (player.level == 0)
			player.level = 1;
		player.RefreshPerkData();
	}
	
	void GetPlayerSave(uint8 peer)
	{
		if (Lobby::IsPlayerLocal(peer))
			return;
			
		ActivatePlayerRecord(peer);
	}

	void AddPlayer(uint8 peer)
	{
		if (Lobby::IsPlayerLocal(peer))
			return;
	
		ActivatePlayerRecord(peer);
		RefreshMultiplayerScaling();
		
		if (Network::IsServer())
		{
			for (uint i = 0; i < g_players.length(); i++)
			{
				if (g_players[i].peer == 255)
					continue;

				/*
				if (m_started && g_players[i].peer == peer)
				{
					// Immediately spawn drop-in players
					SpawnPlayer(i);
					continue;
				}
				*/
					
				if (g_players[i].actor is null)
					continue;
			
				auto unit = g_players[i].actor.m_unit;
				(Network::Message("SpawnPlayer") << g_players[i].peer << xy(unit.GetPosition()) << unit.GetId() << g_players[i].team).SendToPeer(peer);
			}
		}
	}
	
	void RemovePlayer(uint8 peer, bool kicked)
	{
		auto plr = PlayerHandler::GetPlayerRecord(peer);
		if (plr is null)
			return;
	
		plr.peer = 255;
		if (plr.actor !is null)
		{
			plr.actor.m_unit.Destroy();
			@plr.actor = null;
		}
		
		RefreshMultiplayerScaling();
	}
	
	void RefreshMultiplayerScaling()
	{
		int num = 0;
		int highLvl = 0;
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == 255)
				continue;
			
			num++;
			highLvl = max(highLvl, g_players[i].level);
		}
		
		auto plr = GetLocalPlayerRecord();
		int lDiff = max(0, (plr is null ? highLvl : plr.level) - highLvl);
		
		g_mpEnemyHealthScale = (num - 1) * pow(num, -0.4) + (num - 1) * 0.3f;
		g_mpExpScale = pow(0.9f,  num - 1) * pow(0.935, lDiff);
		
		print("MP enemy health scale: " + g_mpEnemyHealthScale + ", exp scale: " + g_mpExpScale);
	}
	
	void RestartGame()
	{
	}

	void PlayerDied(PlayerRecord@ player, PlayerRecord@ killer, DamageInfo di)
	{
	}

	void SpawnPlayers()
	{
	/*
		if (!Network::IsServer())
			return;
	*/
	
		vec2 spawnPos(-1, -1);
		if (g_spawnPos.x != 0 || g_spawnPos.y != 0)
			spawnPos = g_spawnPos;
			
		bool isTown = cast<Town>(this) !is null;

		for (uint i = 0; i < g_players.length(); i++)
		{
			if (!g_players[i].local)
				continue;

			if (g_players[i].hp <= 0 && !isTown)
			{
				if (Network::IsServer())
					SpawnPlayerCorpse(i);
				else
					(Network::Message("SpawnPlayerCorpse") << g_players[i].peer << spawnPos).SendToHost();
			}
			else
			{
				if (Network::IsServer())
					SpawnPlayer(i);
				else
					(Network::Message("SpawnPlayer") << g_players[i].peer << spawnPos << 0 << 0).SendToHost();
			}
		}

		m_spawnedInitial = true;
	}

	vec2 GetPlayerSpawnPosition(PlayerRecord& record)
	{
		/*
		if (m_spawnedInitial)
			return g_spawnPos;

		int index = record.peer;
		int count = g_players.length();
		float dist = (count > 4 ? 16.0f : 32.0f);
		float maxdist = (min(count, 8) - 1) * dist;
		return g_spawnPos + vec2(-(maxdist / 2.0f) + (index % 8) * dist, 0);
		*/
		
		return g_spawnPos;
	}

	void SpawnPlayer(int i, vec2 pos = vec2(-1, -1), int unitId = 0, uint team = 0) override
	{
		if (g_players[i].peer == 255)
			return;

		if (g_players[i].actor !is null)
			return;

		if (team > 0)
			g_players[i].team = team;

		UnitPtr unit;
		vec3 spawnPos = xyz(pos);
		if (Network::IsServer() && pos.x == -1 && pos.y == -1)
			spawnPos = xyz(GetPlayerSpawnPosition(g_players[i]));

		if (g_players[i].local)
			unit = Resources::GetUnitProducer("players/player.unit").Produce(g_scene, spawnPos, unitId);
		else
			unit = Resources::GetUnitProducer("players/player_husk.unit").Produce(g_scene, spawnPos, unitId);

		g_players[i].AssignUnit(unit);

		if (team > 0)
			g_players[i].actor.SetTeam(team, false);

		if (Network::IsServer())
			(Network::Message("SpawnPlayer") << g_players[i].peer << xy(unit.GetPosition()) << unit.GetId() << team).SendToAll();

		cast<PlayerBase>(unit.GetScriptBehavior()).Initialize(g_players[i]);
	}

	void SpawnPlayerCorpse(int i, vec2 pos = vec2(-1, -1)) override
	{
		if (g_players[i].peer == 255)
			return;

		if (g_players[i].actor !is null)
			return;

		UnitPtr unit;
		vec3 spawnPos = xyz(pos);
		if (Network::IsServer() && pos.x == -1 && pos.y == -1)
			spawnPos = xyz(GetPlayerSpawnPosition(g_players[i]));

		auto corpse = Resources::GetUnitProducer("players/player_corpse.unit").Produce(g_scene, spawnPos);
		@g_players[i].corpse = cast<PlayerCorpse>(corpse.GetScriptBehavior());
		g_players[i].corpse.Initialize(g_players[i]);

		if (Network::IsServer())
			(Network::Message("SpawnPlayerCorpse") << g_players[i].peer << xy(spawnPos)).SendToAll();
	}
	
	void AttemptRespawn(uint8 peer) override
	{
		if (!Network::IsServer())
			return;

		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == peer)
			{
				if (!g_players[i].IsDead())
					return;

				(Network::Message("ResetPlayerHealthArmor") << g_players[i].peer).SendToAll();

				g_players[i].hp = 1.0;
				g_players[i].armor = 0;

				SpawnPlayer(i, vec2(), 0, g_players[i].team);
				return;
			}
		}
	}

	float FilterAction(Actor@ a, Actor@ owner, float selfDmg, float teamDmg, float enemyDmg, uint teamOverride = 1) override
	{
		if (teamOverride == 1)
		{
			if (owner is null)
				return 1;
			teamOverride = owner.Team;
		}
	
		if (a.Team != teamOverride)
			return enemyDmg;

		if (teamOverride == g_team_player)
			return teamDmg * Tweak::FriendlyFireScale;

		return teamDmg;
	}

	//TODO: Should we move these "gamemode hooks" somewhere else? Overriding these is convinient, but maybe not the best place..
	void RefreshPlayerScene(PlayerBase@ player, CustomUnitScene@ scene)
	{
	}

	/**
	 * Compatibility layer due to revision 9030
	 */
	void _Deprecation9030() { if (_Deprecation9030Printed) return; _Deprecation9030Printed = true; PrintError("Warning: BaseGameMode's mouse values are deprecated, use m_mice array instead."); } bool _Deprecation9030Printed;
	bool get_m_mouseReal() { _Deprecation9030(); return m_mice[0].m_real; } void set_m_mouseReal(bool real) { _Deprecation9030(); m_mice[0].m_real = real; }
	vec2 get_m_mouseScreenPosPrev() { _Deprecation9030(); return m_mice[0].m_posPrev; } void set_m_mousePosPrev(vec2 p) { _Deprecation9030(); m_mice[0].m_posPrev = p; }
	vec2 get_m_mouseScreenPos() { _Deprecation9030(); return m_mice[0].m_pos; } void set_m_mousePos(vec2 p) { _Deprecation9030(); m_mice[0].m_pos = p; }
	bool get_m_usingRealCursor() { _Deprecation9030(); return get_m_mouseReal(); } void set_m_usingRealCursor(bool b) { _Deprecation9030(); set_m_mouseReal(b); }
	bool get_m_showCursor() { _Deprecation9030(); return _m_showCursor; } void set_m_showCursor(bool b) { _Deprecation9030(); _m_showCursor = b; } bool _m_showCursor = true;
	int get_m_currCursorColorC() { _Deprecation9030(); return m_mice[0].m_colorC; } void set_m_currCursorColorC(int c) { _Deprecation9030(); m_mice[0].m_colorC = c; }
	vec3 get_m_currCursorColor() { _Deprecation9030(); return m_mice[0].m_color; } void set_m_currCursorColor(vec3 color) { _Deprecation9030(); m_mice[0].m_color = color; }
}
