namespace WorldScript
{
	[WorldScript color="0 255 0" icon="system/icons.png;0;96;32;32"]
	class HealUnits
	{
		[Editable validation=IsValid]
		UnitFeed Units;

		[Editable default=10 min=0 max=1000000]
		int Amount;

		bool IsValid(UnitPtr unit)
		{
			return cast<Actor>(unit.GetScriptBehavior()) !is null;
		}

		SValue@ ServerExecute()
		{
			array<UnitPtr>@ units = Units.FetchAll();
			for (uint i = 0; i < units.length(); i++)
				cast<Actor>(units[i].GetScriptBehavior()).Heal(Amount);

			return null;
		}
	}
}
