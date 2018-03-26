namespace WorldScript
{
	[WorldScript color="#99FF7A" icon="system/icons.png;416;352;32;32"]
	class GivePerk
	{
		[Editable]
		string Perk;

		SValue@ ServerExecute()
		{
			for (uint i = 0; i < g_players.length(); i++)
				g_players[i].GivePerk(Perk);
			return null;
		}

		void ClientExecute(SValue@ val)
		{
			ServerExecute();
		}
	}
}
