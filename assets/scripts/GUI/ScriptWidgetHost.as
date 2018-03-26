class ScriptWidgetHost : IWidgetHoster
{
	WorldScript::OpenInterface@ m_script;

	ScriptWidgetHost()
	{
		super();
	}

	void Initialize() { }
	bool ShouldFreezeControls() { return false; }
	bool ShouldDisplayCursor() { return false; }

	void Stop()
	{
		m_script.Stop();
	}
}
