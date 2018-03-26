namespace WorldScript
{
	[WorldScript color="50 50 255" icon="system/icons.png;224;288;32;32"]
	class RandomCount
	{
		[Editable validation=IsExecutable]
		UnitFeed ToExecute;
		
		[Editable default=1 min=1 max=100000]
		uint NumToExecute;

		
		bool IsExecutable(UnitPtr unit)
		{
			WorldScript@ script = WorldScript::GetWorldScript(unit);
			if (script is null)
				return false;
		
			return script.IsExecutable();
		}
		
		
		SValue@ ServerExecute()
		{
			array<WorldScript@> scripts;
		
			auto toExec = ToExecute.FetchAll();
			for (uint i = 0; i < toExec.length(); i++)
			{
				WorldScript@ script = WorldScript::GetWorldScript(toExec[i]);
				if (script !is null && script.IsExecutable() && script.GetTriggerTimes() != 0 && script.IsEnabled())
					scripts.insertLast(script);
			}
			
			uint num = NumToExecute;
			int n = 0;
			while (scripts.length() > 0 && num > 0)
			{
				uint i = sr_randi(n++, scripts.length());
				scripts[i].Execute();
				scripts.removeAt(i);
				num--;
			}
			
			return null;
		}
	}
}