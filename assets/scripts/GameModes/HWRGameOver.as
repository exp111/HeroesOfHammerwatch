class HWRGameOver : GameOver
{
	HWRGameOver(GUIBuilder@ b)
	{
		super(b);
	}
	
	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "score")
		{
			g_gameMode.RemoveWidgetRoot(this);
			m_score.Show();
		}
		else if (name == "restart" && Network::IsServer())
		{
			ChangeLevel("levels/town_outlook.lvl");
		}
		else if (name == "exit")
		{
			PauseGame(false, false);
			StopScenario();
			return;
		}
		else if (name == "scoreclose")
			g_gameMode.ReplaceTopWidgetRoot(this);
		else
			GameOver::OnFunc(sender, name);
	}
}
