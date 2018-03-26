namespace WorldScript
{
	[WorldScript color="200 150 100" icon="system/icons.png;416;384;32;32"]
	class SetBossKilled
	{
		[Editable default=1]
		int BossNumber;

		SValue@ ServerExecute()
		{
			ClientExecute(null);
			return null;
		}

		void ClientExecute(SValue@ val)
		{
			auto localPlayer = GetLocalPlayerRecord();
			
			if (BossNumber == 1)
				Platform::Service.UnlockAchievement("beat_stone_guardian");
			else if (BossNumber == 2)
				Platform::Service.UnlockAchievement("beat_warden");
			else if (BossNumber == 3)
				Platform::Service.UnlockAchievement("beat_three_councilors");
			else if (BossNumber == 4)
				Platform::Service.UnlockAchievement("beat_watcher");
			else if (BossNumber == 5)
				Platform::Service.UnlockAchievement("beat_thundersnow");

				
			auto gm = cast<Campaign>(g_gameMode);
			gm.m_townLocal.m_bossesKilled[BossNumber - 1] |= localPlayer.GetCharFlags();

			int numClasses = 0;
			for (int i = 0; i < 7; i++)
			{
				if ((gm.m_townLocal.m_bossesKilled[BossNumber - 1] & (1 << i)) != 0)
					numClasses++;
			}

			Stats::Max("boss-" + BossNumber + "-killed-class", numClasses, localPlayer);
		}
	}
}
