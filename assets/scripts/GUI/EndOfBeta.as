class EndOfBeta : ScriptWidgetHost
{
	EndOfBeta(SValue& sval)
	{
		super();
	}

	void Initialize() override
	{
		auto gm = cast<Campaign>(g_gameMode);
		gm.OnRunEnd(false);

		auto wButtonTown = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("button-town"));
		if (wButtonTown !is null)
			wButtonTown.m_enabled = Network::IsServer();
	}

	bool ShouldFreezeControls() override { return true; }
	bool ShouldDisplayCursor() override { return true; }

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "town" && Network::IsServer())
			ChangeLevel("levels/town_outlook.lvl");
		else if (name == "plus")
		{
			auto button = cast<ScalableSpriteButtonWidget>(sender);
			if (button !is null)
				button.m_enabled = false;

			auto record = GetLocalPlayerRecord();
			record.newGamePlus++;
			record.titleIndex++;
			record.shortcut = 0;

			if (Network::IsServer())
				ChangeLevel("levels/town_outlook.lvl");
		}
	}
}
