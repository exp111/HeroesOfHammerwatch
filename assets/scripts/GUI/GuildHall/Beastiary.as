class GuildHallBeastiaryTab : GuildHallMenuTab
{
	GuildHallBeastiaryTab()
	{
		m_id = "beastiary";
	}
	
	void AddCategory(Widget@ wList, string name, array<BestiaryEntry@>@ units)
	{
		auto wTemplateHeader = m_widget.GetWidgetById("template-header");
		auto wTemplateSeparator = m_widget.GetWidgetById("template-separator");
		auto wTemplate = m_widget.GetWidgetById("template");
	
	
		auto wNewSeparator = wTemplateSeparator.Clone();
		wNewSeparator.m_visible = true;
		wNewSeparator.SetID("");
		wList.AddChild(wNewSeparator);


		auto wNewHeader = wTemplateHeader.Clone();
		wNewHeader.m_visible = true;
		wNewHeader.SetID("");

		auto wHeaderType = cast<TextWidget>(wNewHeader.GetWidgetById("type"));
		if (wHeaderType !is null)
			wHeaderType.SetText(Resources::GetString(".bestiary.type." + name));
			
		auto wHeaderNum = cast<TextWidget>(wNewHeader.GetWidgetById("num"));
		if (wHeaderNum !is null)
			wHeaderNum.SetText("" + units.length());

		wList.AddChild(wNewHeader);
		
		for (uint i = 0; i < units.length(); i++)
		{
			auto unit = units[i];
			auto params = unit.m_producer.GetBehaviorParams();
			
			string unitName = GetParamString(UnitPtr(), params, "beastiary-name", false);
			if (unitName == "")
				continue;
			
			/*
			// TODO: Add to tooltip..   show hp after X kills, show armor after Y kills, etc (?)
			string scene = GetParamString(UnitPtr(), params, "beastiary-scene", false, "idle-3");
			int hp = GetParamInt(UnitPtr(), params, "hp")
			int expReward = GetParamInt(UnitPtr(), params, "experience-reward", false, 0);
			int armor = GetParamInt(UnitPtr(), params, "armor", false, 0);
			int resistance = GetParamInt(UnitPtr(), params, "resistance", false, 0);
			*/

			auto wNewItem = wTemplate.Clone();
			wNewItem.m_visible = true;
			wNewItem.SetID("");

			auto wName = cast<TextWidget>(wNewItem.GetWidgetById("name"));
			if (wName !is null)
				wName.SetText(Resources::GetString(unitName));

			auto wKills = cast<TextWidget>(wNewItem.GetWidgetById("kills"));
			if (wKills !is null)
				wKills.SetText("" + unit.m_kills);

			wList.AddChild(wNewItem);
		}
	}
	
	void OnShow() override
	{
		auto wList = m_widget.GetWidgetById("list");
		auto wTemplate = m_widget.GetWidgetById("template");
		
		if (wList is null || wTemplate is null)
			return;

		wList.ClearChildren();
			
		auto town = cast<Campaign>(g_gameMode).m_townLocal;
		
		AddCategory(wList, "beast", town.GetBestiary("beast"));
		AddCategory(wList, "undead", town.GetBestiary("undead"));
		AddCategory(wList, "aberration", town.GetBestiary("aberration"));
		AddCategory(wList, "construct", town.GetBestiary("construct"));

		DoLayout();
	}
}
