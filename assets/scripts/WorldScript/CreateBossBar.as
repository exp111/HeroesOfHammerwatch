namespace WorldScript
{
	[WorldScript color="#ff0000" icon="system/icons.png;32;192;32;32"]
	class CreateBossBar
	{
		[Editable validation=IsActor]
		UnitFeed Actors;

		[Editable default=false]
		bool OverActor;

		[Editable default=10]
		int BarCount;

		[Editable default=-50]
		int BarOffset;

		[Editable]
		string Name;

		bool IsActor(UnitPtr unit)
		{
			return cast<Actor>(unit.GetScriptBehavior()) !is null;
		}

		SValue@ ServerExecute()
		{
			HUD@ hud = GetHUD();

			auto units = Actors.FetchAll();
			for (uint i = 0; i < units.length(); i++)
			{
				Actor@ actor = cast<Actor>(units[i].GetScriptBehavior());
				if (OverActor)
					hud.AddBossBarActor(actor, BarCount, BarOffset, Name);
				else
					hud.AddBossBar(actor, Name);
			}

			return null;
		}

		void ClientExecute(SValue@ val)
		{
			ServerExecute();
		}
	}
}
