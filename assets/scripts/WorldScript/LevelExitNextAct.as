namespace WorldScript
{
	[WorldScript color="100 255 100" icon="system/icons.png;192;288;32;32"]
	class LevelExitNextAct
	{
		SValue@ ServerExecute()
		{
			Lobby::SetJoinable(false);
			
			auto gm = cast<BaseGameMode>(g_gameMode);
			gm.m_levelCount += 4;
			ChangeLevel("levels/generated.lvl");
			return null;
		}
	}
}
