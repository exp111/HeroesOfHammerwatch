class StatuesShopMenuContent : ShopMenuContent
{
	Widget@ m_wListPlacement;
	ScalableSpriteButtonWidget@ m_wTemplatePlacement;

	Widget@ m_wListBuy;
	ShopButtonWidget@ m_wTemplateBuy;

	StatueSelectMenu@ m_selectMenu;

	StatuesShopMenuContent(ShopMenu@ shopMenu)
	{
		super(shopMenu);
	}

	string GetTitle() override
	{
		return Resources::GetString(".shop.statues");
	}

	void OnShow() override
	{
		@m_wListPlacement = m_widget.GetWidgetById("list");
		@m_wTemplatePlacement = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("template"));

		@m_wListBuy = m_widget.GetWidgetById("buy-list");
		@m_wTemplateBuy = cast<ShopButtonWidget>(m_widget.GetWidgetById("buy-template"));

		RefreshPlacementList();
		RefreshBuyList();
	}

	string GetGuiFilename() override
	{
		return "gui/shop/statues.gui";
	}

	int NumSlotsForLevel()
	{
		int level = m_shopMenu.m_currentShopLevel;
		switch (level)
		{
			case 1: return 2;
			case 2: return 3;
			case 3: return 4;
			case 4: return 6;
			case 5: return 8;
		}
		return 0;
	}

	void RefreshPlacementList()
	{
		m_wListPlacement.ClearChildren();

		auto gm = cast<Campaign>(g_gameMode);

		int numSlots = NumSlotsForLevel();

		for (uint i = gm.m_town.m_statuePlacements.length(); i < uint(numSlots); i++)
		{
			print("new slot: " + i);
			gm.m_town.m_statuePlacements.insertLast("");
		}

		for (int i = 0; i < numSlots; i++)
		{
			string statueID = "";
			TownStatue@ statue = null;
			Statues::StatueLevelDef@ def = null;

			if (uint(i) < gm.m_town.m_statuePlacements.length())
				statueID = gm.m_town.m_statuePlacements[i];

			if (statueID != "")
				@statue = gm.m_town.GetStatue(statueID);

			if (statue !is null)
				@def = statue.GetDef();

			auto wNewItem = cast<ScalableSpriteButtonWidget>(m_wTemplatePlacement.Clone());
			wNewItem.SetID("");
			wNewItem.m_visible = true;
			wNewItem.m_func = "set-statue " + i;

			if (def !is null)
				wNewItem.SetText(Resources::GetString(def.m_name));
			else
				wNewItem.SetText("");

			m_wListPlacement.AddChild(wNewItem);
		}

		m_shopMenu.DoLayout();
	}

	void RefreshBuyList()
	{
		m_wListBuy.ClearChildren();

		auto gm = cast<Campaign>(g_gameMode);
		for (uint i = 0; i < gm.m_town.m_statues.length(); i++)
		{
			auto statue = gm.m_town.m_statues[i];
			if (statue.m_sculpted)
				continue;

			auto def = statue.GetDef();

			auto wNewItem = cast<ShopButtonWidget>(m_wTemplateBuy.Clone());
			wNewItem.SetID("");
			wNewItem.m_visible = true;
			wNewItem.m_func = "buy-statue " + statue.m_id;
			wNewItem.SetPriceOre(def.m_sculptCost);
			wNewItem.SetText(Resources::GetString(def.m_name));
			wNewItem.m_tooltipTitle = Resources::GetString(def.m_name);
			wNewItem.m_tooltipText = Resources::GetString(def.m_desc);
			wNewItem.UpdateEnabled();
			m_wListBuy.AddChild(wNewItem);
		}

		m_shopMenu.CloseTooltip();
		m_shopMenu.DoLayout();
	}

	void OnFunc(Widget@ sender, string name) override
	{
		auto parse = name.split(" ");
		if (parse[0] == "set-statue")
			StatueSelectMenu(g_gameMode.m_guiBuilder, this, parseInt(parse[1])).Show();
		else if (parse[0] == "buy-statue")
		{
			auto gm = cast<Campaign>(g_gameMode);
			auto statue = gm.m_town.GetStatue(parse[1]);

			if (statue is null)
			{
				PrintError("Couldn't find town statue \"" + parse[1] + "\"");
				return;
			}

			statue.m_sculpted = true;

			auto def = statue.GetDef();
			gm.m_town.m_ore -= def.m_sculptCost;

			print("Sculpted \"" + parse[1] + "\" for " + def.m_sculptCost + " ore");

			RefreshBuyList();
		}
	}
}
