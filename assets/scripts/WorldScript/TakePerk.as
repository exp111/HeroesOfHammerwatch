namespace WorldScript
{
	[WorldScript color="#FF997A" icon="system/icons.png;416;352;32;32"]
	class TakePerk
	{
		[Editable]
		string Perk;

		SValue@ ServerExecute()
		{
			for (uint i = 0; i < g_players.length(); i++)
				g_players[i].TakePerk(Perk);
			return null;
		}

		void ClientExecute(SValue@ val)
		{
			ServerExecute();
		}
	}
}
