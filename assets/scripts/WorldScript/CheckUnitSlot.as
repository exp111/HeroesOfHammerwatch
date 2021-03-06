namespace WorldScript
{
	[WorldScript color="#FF75B3" icon="system/icons.png;452;63;32;32"]
	class CheckUnitSlot
	{
		[Editable]
		UnitFeed Units;

		[Editable]
		string Slot;

		[Editable type=enum default=0]
		CheckType Type;

		[Editable validation=IsExecutable]
		UnitFeed OnEqual;

		[Editable validation=IsExecutable]
		UnitFeed OnUnequal;

		bool IsExecutable(UnitPtr unit)
		{
			WorldScript@ script = WorldScript::GetWorldScript(unit);
			if (script is null)
				return false;

			return script.IsExecutable();
		}

		SValue@ ServerExecute()
		{
			auto units = Units.FetchAll();
			bool allOk = true;

			uint32 checkSlot = Resources::GetSlot(Slot);

			for (uint i = 0; i < units.length(); i++)
			{
				bool sameType = units[i].GetSlot() == checkSlot;

				if (Type == CheckType::Or && sameType)
				{
					allOk = true;
					break;
				}

				if (!sameType)
				{
					allOk = false;
					if (Type == CheckType::And)
						break;
				}
			}

			array<UnitPtr>@ toExec;
			if (allOk)
				@toExec = OnEqual.FetchAll();
			else
				@toExec = OnUnequal.FetchAll();

			for (uint i = 0; i < toExec.length(); i++)
				WorldScript::GetWorldScript(g_scene, toExec[i].GetScriptBehavior()).Execute();

			return null;
		}
	}
}
