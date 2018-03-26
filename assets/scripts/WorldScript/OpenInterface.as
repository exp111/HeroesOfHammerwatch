namespace WorldScript
{
	[WorldScript color="#B0C4DE" icon="system/icons.png;352;352;32;32"]
	class OpenInterface
	{
		ScriptWidgetHost@ m_interface;

		[Editable]
		UnitFeed ForPlayer;

		[Editable]
		string UserWindowID;

		[Editable]
		string Filename;

		[Editable]
		bool MakeRoot;

		[Editable]
		string Class;

		void Start(SValue@ sval)
		{
			auto gm = cast<BaseGameMode>(g_gameMode);
			if (gm is null)
			{
				PrintError("OpenInterface only works on BaseGameMode!");
				return;
			}

			if (UserWindowID != "")
				gm.ShowUserWindow(UserWindowID);
			else
			{
				if (m_interface !is null)
					Stop();

				if (Class == "")
					@m_interface = ScriptWidgetHost();
				else
				{
					SValueBuilder svb;
					@m_interface = cast<ScriptWidgetHost>(InstantiateClass(Class, svb.Build()));
				}

				m_interface.LoadWidget(g_gameMode.m_guiBuilder, Filename);
				@m_interface.m_script = this;

				gm.m_widgetScriptHosts.insertLast(m_interface);

				if (MakeRoot)
					gm.AddWidgetRoot(m_interface);

				m_interface.Initialize();
			}
		}

		void Stop()
		{
			if (m_interface is null)
				return;

			auto gm = cast<BaseGameMode>(g_gameMode);
			if (gm is null)
			{
				PrintError("OpenInterface only works on BaseGameMode!");
				return;
			}

			int index = gm.m_widgetScriptHosts.findByRef(m_interface);
			if (index != -1)
				gm.m_widgetScriptHosts.removeAt(index);

			if (MakeRoot)
				gm.RemoveWidgetRoot(m_interface);

			@m_interface = null;
		}

		SValue@ ServerExecute()
		{
			ClientExecute(null);
			return null;
		}

		void ClientExecute(SValue@ sval)
		{
			UnitPtr unit = ForPlayer.FetchFirst();
			if (unit.IsValid() && cast<Player>(unit.GetScriptBehavior()) is null)
				return;

			Start(sval);
		}
	}
}
