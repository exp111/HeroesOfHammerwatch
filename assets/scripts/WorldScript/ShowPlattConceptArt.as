namespace WorldScript
{
	[WorldScript color="155 220 255" icon="system/icons.png;128;96;32;32"]
	class ShowPlattConceptArt
	{
		[Editable default="gui/concepts/empty.gui"]
		string Filename;
		
		[Editable default="gui/concepts/platt/start.gui"]
		string PlattFilename;

		[Editable]
		string DisplayText;

		[Editable default=".levelend.ok"]
		string ButtonText;

		[Editable validation=IsExecutable]
		UnitFeed OnClosed;

		bool IsExecutable(UnitPtr unit)
		{
			WorldScript@ script = WorldScript::GetWorldScript(unit);
			if (script is null)
				return false;

			return script.IsExecutable();
		}

		SValue@ ServerExecute()
		{
%if !MOD_ROGUELIKE
			auto campaign = cast<Campaign>(g_gameMode);
			campaign.m_concept.Show(Filename, DisplayText, ButtonText, OnClosed.FetchAll(), PlattFilename);
%endif
			return null;
		}

		void ClientExecute(SValue@ val)
		{
			ServerExecute();
		}
	}
}
