class GuildHallMenu : UserWindow
{
	MenuTabSystem@ m_tabSystem;

	GuildHallMenu(GUIBuilder@ b)
	{
		super(b, "gui/guildhallmenu.gui");

		@m_tabSystem = MenuTabSystem(this);

		m_tabSystem.AddTab(GuildHallStatsTab());
		m_tabSystem.AddTab(GuildHallAccomplishmentsTab());
		m_tabSystem.AddTab(GuildHallBeastiaryTab());
	}

	string GetScriptID() override { return "guildhall"; }

	void SetTab(string id)
	{
		GlobalCache::Set("guildhallmenu-tab", id);

		m_tabSystem.SetTab(id);
	}

	void Show() override
	{
		if (m_visible)
			return;

		UserWindow::Show();

		PauseGame(true, true);

		string startTab = GlobalCache::Get("guildhallmenu-tab");
		if (startTab == "")
			startTab = "stats";

		SetTab(startTab);
	}

	void Close() override
	{
		if (!m_visible)
			return;

		m_tabSystem.Close();

		UserWindow::Close();

		PauseGame(false, true);
	}

	void Update(int dt) override
	{
		m_tabSystem.Update(dt);

		UserWindow::Update(dt);
	}

	void AfterUpdate()
	{
		if (m_visible)
			m_tabSystem.AfterUpdate();
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "close")
			Close();
		else if (!m_tabSystem.OnFunc(sender, name))
			UserWindow::OnFunc(sender, name);
	}
}
