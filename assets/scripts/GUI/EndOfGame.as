class EndOfGame : ScriptWidgetHost
{
	EndOfGame(SValue& sval)
	{
		super();
	}

	void Initialize() override
	{
		auto gm = cast<Campaign>(g_gameMode);
		gm.OnRunEnd(false);
		
		Platform::Service.UnlockAchievement("beat_forsaken_tower");
		if (g_ngp >= 1)
			Platform::Service.UnlockAchievement("beat_forsaken_tower_ng");
		if (g_ngp >= 2)
			Platform::Service.UnlockAchievement("beat_forsaken_tower_ng2");
		if (g_ngp >= 3)
			Platform::Service.UnlockAchievement("beat_forsaken_tower_ng3");
		if (g_ngp >= 4)
			Platform::Service.UnlockAchievement("beat_forsaken_tower_ng4");
		if (g_ngp >= 5)
			Platform::Service.UnlockAchievement("beat_forsaken_tower_ng5");

		auto record = GetLocalPlayerRecord();

		if (record.newGamePlus <= g_ngp)
		{
			record.newGamePlus = g_ngp + 1;
			record.titleIndex++;
		}
		record.shortcut = 0;

		auto town = gm.m_townLocal;
		if (town.m_highestNgp < record.newGamePlus)
		{
			town.m_highestNgp = record.newGamePlus;
			town.m_currentNgp = record.newGamePlus;
		}

		auto wButtonTown = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("button-town"));
		if (wButtonTown !is null)
			wButtonTown.m_enabled = Network::IsServer();
	}

	bool ShouldFreezeControls() override { return true; }
	bool ShouldDisplayCursor() override { return true; }

	void Stop() override
	{
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "town")
			ChangeLevel("levels/town_outlook.lvl");
		else if (name == "stats")
		{
			auto gm = cast<Campaign>(g_gameMode);
			gm.ShowUserWindow(gm.m_playerMenu);
		}
	}
}
