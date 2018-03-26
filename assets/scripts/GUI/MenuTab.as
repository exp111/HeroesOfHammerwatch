class MenuTab
{
	string m_id;
	GUIDef@ m_def;
	Widget@ m_widget;

	string GetGuiFilename()
	{
		PrintError("Implement MenuTab::GetGuiFilename!");
		return "";
	}

	void OnCreated()
	{
	}

	void DoLayout()
	{
		m_widget.m_host.DoLayout();
	}

	bool IsVisible()
	{
		return m_widget.m_visible;
	}

	void SetVisible(bool v)
	{
		if (m_widget.m_visible == v)
			return;

		m_widget.m_visible = v;
		if (v)
			OnShow();
	}

	void OnShow()
	{
	}

	void Update(int dt)
	{
	}

	void AfterUpdate()
	{
	}

	void Draw(SpriteBatch& sb, int idt)
	{
	}

	bool OnFunc(Widget@ sender, string name)
	{
		return false;
	}
}
