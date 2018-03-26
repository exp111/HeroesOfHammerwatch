class StatueSelectMenu : UserWindow
{
	StatuesShopMenuContent@ m_owner;

	int m_slot;

	StatueSelectMenu(GUIBuilder@ b, StatuesShopMenuContent@ owner, int slot)
	{
		super(b, "gui/shop/statues_select.gui");

		@m_owner = owner;

		m_slot = slot;
	}

	bool BlocksLower() override
	{
		return true;
	}

	void Show() override
	{
		if (m_visible)
			return;

		auto gm = cast<Town>(g_gameMode);

		gm.m_userWindows.insertLast(this);

		Widget@ wList = m_widget.GetWidgetById("list");
		ScalableSpriteButtonWidget@ wTemplate = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("template"));

		auto resetButton = cast<ScalableSpriteButtonWidget>(wTemplate.Clone());
		resetButton.SetID("");
		resetButton.m_visible = true;
		resetButton.m_enabled = (gm.m_town.m_statuePlacements[m_slot] != "");
		resetButton.SetText("reset");
		resetButton.m_func = "set ";
		wList.AddChild(resetButton);

		for (uint i = 0; i < gm.m_town.m_statues.length(); i++)
		{
			auto statue = gm.m_town.m_statues[i];
			auto def = statue.GetDef();
			int placement = gm.m_town.GetStatuePlacement(statue.m_id);

			auto newButton = cast<ScalableSpriteButtonWidget>(wTemplate.Clone());
			newButton.SetID("");
			newButton.m_visible = true;
			newButton.m_enabled = (placement == -1 && statue.m_sculpted);
			newButton.SetText(Resources::GetString(def.m_name));
			newButton.m_tooltipTitle = Resources::GetString(def.m_name);
			newButton.m_tooltipText = Resources::GetString(def.m_desc);
			newButton.m_func = "set " + statue.m_id;
			wList.AddChild(newButton);
		}

		UserWindow::Show();
	}

	void Close() override
	{
		if (!m_visible)
			return;

		auto gm = cast<Town>(g_gameMode);

		int index = gm.m_userWindows.findByRef(this);
		if (index != -1)
			gm.m_userWindows.removeAt(index);

		UserWindow::Close();
	}

	void OnFunc(Widget@ sender, string name) override
	{
		auto parse = name.split(" ");
		if (parse[0] == "set")
		{
			auto gm = cast<Town>(g_gameMode);
			gm.m_town.m_statuePlacements[m_slot] = parse[1];

			gm.SetStatues();
			gm.RefreshTownModifiers();

			m_owner.RefreshPlacementList();

			Close();
		}
		else
			UserWindow::OnFunc(sender, name);
	}
}
