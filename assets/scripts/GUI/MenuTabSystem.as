class MenuTabSystem
{
	IWidgetHoster@ m_host;

	array<MenuTab@> m_tabs;
	MenuTab@ m_currentTab;

	MenuTabSystem(IWidgetHoster@ host)
	{
		@m_host = host;
	}

	Widget@ GetTabWidget(string id)
	{
		auto wTab = m_host.m_widget.GetWidgetById("tab-" + id);
		if (wTab is null)
		{
			PrintError("Tab widget not found: \"tab-" + id + "\"");
			return null;
		}
		return wTab;
	}

	void AddTab(MenuTab@ tab, GUIBuilder@ b = null)
	{
		if (b is null)
			@b = g_gameMode.m_guiBuilder;

		auto wTab = GetTabWidget(tab.m_id);
		if (wTab !is null)
		{
			@tab.m_def = wTab.AddResource(b, tab.GetGuiFilename());
			@tab.m_widget = wTab;
			wTab.m_visible = false;
			m_tabs.insertLast(tab);
			tab.OnCreated();
		}
	}

	void SetTab(string id)
	{
		for (uint i = 0; i < m_tabs.length(); i++)
		{
			auto tab = m_tabs[i];
			bool isTab = (tab.m_id == id);

			if (tab.IsVisible() != isTab)
				tab.SetVisible(isTab);

			if (isTab)
				@m_currentTab = tab;
		}

		m_host.DoLayout();
	}

	void Close()
	{
		SetTab("");
	}

	void Update(int dt)
	{
		if (m_currentTab !is null)
			m_currentTab.Update(dt);
	}

	void AfterUpdate()
	{
		if (m_currentTab !is null)
			m_currentTab.AfterUpdate();
	}

	void Draw(SpriteBatch& sb, int idt)
	{
		if (m_currentTab !is null)
			m_currentTab.Draw(sb, idt);
	}

	bool OnFunc(Widget@ sender, string name)
	{
		if (m_currentTab !is null && m_currentTab.OnFunc(sender, name))
			return true;

		auto parse = name.split(" ");

		if (parse[0] == "set-tab")
		{
			SetTab(parse[1]);
			return true;
		}

		return false;
	}
}
