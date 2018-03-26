[GameMode]
class TestLevel : Campaign
{
	TestLevel(Scene@ scene)
	{
		super(scene);
	}

	// TODO: Delete this (USE_MULTIPLAYER)
	void Generate(SValue@ save) {}

	void Start(uint8 peer, SValue@ save, StartMode sMode) override
	{
		Campaign::Start(peer, save, sMode);
		SetLevelFlags(m_levelCount);
		Campaign::PostStart();
		Stats::Add("floors-visited", 1);

		Lobby::SetJoinable(true);
	}
}
