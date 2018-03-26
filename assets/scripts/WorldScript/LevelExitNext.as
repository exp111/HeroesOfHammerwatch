namespace WorldScript
{
	[WorldScript color="100 255 100" icon="system/icons.png;192;288;32;32"]
	class LevelExitNext
	{
		SValue@ ServerExecute()
		{
			Lobby::SetJoinable(false);
			
			auto gm = cast<Campaign>(g_gameMode);
			gm.m_levelCount++;
			gm.m_minimap.Clear();
			
			ivec3 lvl = CalcLevel(gm.m_levelCount);
			
			if (lvl.y == 3)
			{
				if (lvl.x == 0)
				{
					ChangeLevel("levels/boss_mines.lvl");
					return null;
				}
				else if (lvl.x == 1)
				{
					ChangeLevel("levels/boss_prison.lvl");
					return null;
				}
				else if (lvl.x == 2)
				{
					ChangeLevel("levels/boss_armory.lvl");
					return null;
				}
				else if (lvl.x == 3)
				{
					ChangeLevel("levels/boss_archives.lvl");
					return null;
				}
				else if (lvl.x == 4)
				{
					ChangeLevel("levels/boss_chambers.lvl");
					return null;
				}
			}
		
			ChangeLevel("levels/generated.lvl");
			return null;
		}
	}
}
