namespace GameModeHandler
{
	void SetNgp(int ngp)
	{
		if (Network::IsServer())
			return;

		g_ngp = ngp;
	}

	void GameOver(SValue@ sv)
	{
		BaseGameMode@ gm = cast<BaseGameMode>(g_gameMode);
		if (gm is null)
			return;

		if (gm.m_gameOver !is null)
			gm.m_gameOver.Show(sv);
	}

	void LevelEndContinue(uint8 peer)
	{
		if (g_levelEndScreen is null)
			return; // shouldn't happen

		g_levelEndScreen.PeerReady(peer);
	}

	void LevelConceptContinue(uint8 peer)
	{
		Campaign@ gm = cast<Campaign>(g_gameMode);
		if (gm is null || gm.m_concept is null)
			return;

		gm.m_concept.PeerReady(peer);
	}

	void LevelConceptClose(uint8 peer)
	{
		Campaign@ gm = cast<Campaign>(g_gameMode);
		if (gm is null || gm.m_concept is null)
			return;

		gm.m_concept.Hide();
	}

	void ExtraLives(int lives)
	{
		auto gm = cast<BaseGameMode>(g_gameMode);
		if (gm is null)
			return;

		if (lives > gm.m_extraLives)
			GetHUD().SetExtraLife();
		gm.m_extraLives = lives;
	}

	void SyncFlag(string flag, bool value, bool persistent)
	{
		if (!value)
			g_flags.Delete(flag);
		else
			g_flags.Set(flag, persistent ? FlagState::Run : FlagState::Level);
	}
}
