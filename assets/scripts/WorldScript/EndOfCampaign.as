namespace WorldScript
{
	[WorldScript color="255 100 100" icon="system/icons.png;192;288;32;32"]
	class EndOfCampaign
	{
		[Editable default="gui/concepts/empty.gui"]
		string Background;

		SValue@ BuildData()
		{
			auto screen = cast<BaseGameMode>(g_gameMode).m_levelEndScreen;
			return screen.m_score.BuildData();
		}

		void ShowInterface(SValue@ sv)
		{
			auto screen = cast<BaseGameMode>(g_gameMode).m_levelEndScreen;
			screen.Show(sv, "", "", Background, true);
		}

		void ClientExecute(SValue@ val)
		{
%if MOD_ROGUELIKE
			RoguelikeLevelExit(val, Background);
			return;
%else
			ShowInterface(val);
%endif
		}

		SValue@ ServerExecute()
		{
			SValue@ data = BuildData();
			ClientExecute(data);
			return data;
		}
	}
}
