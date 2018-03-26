class HUDSpectate : IWidgetHoster
{
	TextWidget@ m_wWho;
	TextWidget@ m_wHelp;

	HUDSpectate(GUIBuilder@ b)
	{
		LoadWidget(b, "gui/spectate.gui");

		@m_wWho = cast<TextWidget>(m_widget.GetWidgetById("who"));
		@m_wHelp = cast<TextWidget>(m_widget.GetWidgetById("help"));
	}

	void Update(int dt) override
	{
		BaseGameMode@ gm = cast<BaseGameMode>(g_gameMode);
		if (gm is null)
			return;

		PlayerRecord@ player = g_players[gm.m_spectatingPlayer];

		if (m_wWho !is null)
		{
			dictionary params = { { "name", player.GetName() } };
			m_wWho.SetText(Resources::GetString(".hud.spectate.who", params));
		}

		IWidgetHoster::Update(dt);
	}
}
