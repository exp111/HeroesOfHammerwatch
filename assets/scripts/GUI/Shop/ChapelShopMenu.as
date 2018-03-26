class ChapelShopMenuContent : ShopMenuContent
{
	Widget@ m_wRowList;
	Widget@ m_wTemplateRow;
	UpgradeShopButtonWidget@ m_wTemplateItem;
	Widget@ m_wTemplateUnknown;
	Widget@ m_wTemplateOwned;
	Widget@ m_wTemplateLocked;

	Sprite@ m_spriteGold;

	int m_convertCost;

	Upgrades::ChapelShop@ m_shop;

	ChapelShopMenuContent(ShopMenu@ shopMenu)
	{
		super(shopMenu);

		@m_shop = cast<Upgrades::ChapelShop>(Upgrades::GetShop("chapel"));
	}

	string GetTitle() override
	{
		return Resources::GetString(".shop.chapel");
	}

	void OnShow() override
	{
		@m_wRowList = m_widget.GetWidgetById("row-list");
		@m_wTemplateRow = m_widget.GetWidgetById("row-template");
		@m_wTemplateItem = cast<UpgradeShopButtonWidget>(m_widget.GetWidgetById("item-template"));
		@m_wTemplateUnknown = m_widget.GetWidgetById("item-template-unknown");
		@m_wTemplateOwned = m_widget.GetWidgetById("item-template-owned");
		@m_wTemplateLocked = m_widget.GetWidgetById("item-template-locked");

		@m_spriteGold = m_def.GetSprite("icon-gold");

		ReloadList();
	}

	int ShouldEnableButton(uint rowIndex, uint columnIndex)
	{
		auto record = GetLocalPlayerRecord();
		auto row = m_shop.m_rows[rowIndex];

		for (uint i = 0; i < row.length(); i++)
		{
			if (row[i].IsOwned(record))
			{
				if (rowIndex == 0)
					return -1;

				auto rowAbove = m_shop.m_rows[rowIndex - 1];
				for (uint j = 0; j < rowAbove.length(); j++)
				{
					if (!rowAbove[j].IsOwned(record))
						continue;

					if (columnIndex == j || columnIndex == j + 1)
						return -1;
					else
						return 0;
				}
				return 0;
			}
		}

		if (rowIndex == 0)
			return 1;

		if (int(rowIndex) >= m_shopMenu.m_currentShopLevel)
			return 0;
		else
		{
			auto rowAbove = m_shop.m_rows[rowIndex - 1];

			if (columnIndex == row.length() - 1)
			{
				if (rowAbove[rowAbove.length() - 1].IsOwned(record))
					return 1;
			}
			else if (columnIndex == 0)
			{
				if (rowAbove[0].IsOwned(record))
					return 1;
			}
			else
			{
				if (rowAbove[columnIndex - 1].IsOwned(record) || rowAbove[columnIndex].IsOwned(record))
					return 1;
			}
		}

		return 0;
	}

	void ReloadList() override
	{
		//TODO: We have to hide the tooltip here

		m_wRowList.ClearChildren();

		m_convertCost = 0;

		int lastOwnedIcon = -1;
		int lastOwnedX = -1;

		auto record = GetLocalPlayerRecord();

		for (uint i = 0; i < m_shop.m_rows.length(); i++)
		{
			auto wRowContainer = m_wTemplateRow.Clone();
			wRowContainer.SetID("");
			wRowContainer.m_visible = true;
			m_wRowList.AddChild(wRowContainer);

			auto wRowItems = wRowContainer.GetWidgetById("items");

			int thisOwnedIcon = -1;
			int thisOwnedX = -1;

			auto row = m_shop.m_rows[i];
			for (uint j = 0; j < row.length(); j++)
			{
				auto upgrade = row[j];
				auto step = upgrade.GetStep(1);

				int shouldEnable = ShouldEnableButton(i, j);

				if (shouldEnable == 0)
				{
					auto newItem = m_wTemplateUnknown.Clone();
					newItem.SetID("");
					newItem.m_visible = true;
					newItem.m_tooltipTitle = step.GetTooltipTitle();
					newItem.m_tooltipText = step.GetTooltipDescription();
					wRowItems.AddChild(newItem);
				}
				else if (shouldEnable == -1 && !step.IsOwned(record))
				{
					auto newItem = m_wTemplateLocked.Clone();
					newItem.SetID("");
					newItem.m_visible = true;
					newItem.m_tooltipTitle = step.GetTooltipTitle();
					newItem.m_tooltipText = step.GetTooltipDescription();

					auto wIcon = cast<SpriteWidget>(newItem.GetWidgetById("icon"));
					if (wIcon !is null)
					{
						if (i == 0)
							wIcon.SetSprite(m_shop.GetIcon(0, j));
						else
						{
							int index = m_shop.GetIconIndex(lastOwnedIcon, j - lastOwnedX);
							wIcon.SetSprite(m_shop.GetIcon(i, index));
						}
					}

					wRowItems.AddChild(newItem);
				}
				else if (step.IsOwned(record))
				{
					m_convertCost += step.m_costGold;

					auto newItem = m_wTemplateOwned.Clone();
					newItem.SetID("");
					newItem.m_visible = true;
					newItem.m_tooltipTitle = step.GetTooltipTitle();
					newItem.m_tooltipText = step.GetTooltipDescription();

					auto wIcon = cast<SpriteWidget>(newItem.GetWidgetById("icon"));
					if (wIcon !is null)
					{
						if (i == 0)
						{
							wIcon.SetSprite(m_shop.GetIcon(0, j));

							thisOwnedIcon = j;
							thisOwnedX = j;
						}
						else
						{
							int index = m_shop.GetIconIndex(lastOwnedIcon, j - lastOwnedX);
							wIcon.SetSprite(m_shop.GetIcon(i, index));

							thisOwnedIcon = index;
							thisOwnedX = j;
						}
					}

					wRowItems.AddChild(newItem);
				}
				else
				{
					auto newButton = cast<UpgradeShopButtonWidget>(m_wTemplateItem.Clone());
					newButton.SetID("");
					newButton.m_visible = true;
					newButton.Set(this, upgrade, step);
					newButton.m_enabled = (newButton.m_enabled && shouldEnable == 1);
					newButton.m_tooltipTitle = step.GetTooltipTitle();
					newButton.AddTooltipSub(m_spriteGold, ("" + step.m_costGold));
					newButton.m_tooltipText = step.GetTooltipDescription();

					if (i == 0)
					{
						@newButton.m_scriptSpriteIcon = m_shop.GetIcon(0, j);
						if (step.IsOwned(record))
						{
							thisOwnedIcon = i;
							thisOwnedX = j;
						}
					}
					else
					{
						int index = m_shop.GetIconIndex(lastOwnedIcon, j - lastOwnedX);
						@newButton.m_scriptSpriteIcon = m_shop.GetIcon(i, index);

						if (step.IsOwned(record))
						{
							thisOwnedIcon = index;
							thisOwnedX = j;
						}
					}

					wRowItems.AddChild(newButton);
				}
			}

			lastOwnedIcon = thisOwnedIcon;
			lastOwnedX = thisOwnedX;
		}

		m_convertCost /= 2;

		auto wButtonConvert = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("convert"));
		if (wButtonConvert !is null)
		{
			auto gm = cast<Campaign>(g_gameMode);
			wButtonConvert.m_enabled = (m_convertCost > 0 && gm.m_townLocal.m_gold >= m_convertCost);

			if (wButtonConvert.m_enabled)
				wButtonConvert.SetText(Resources::GetString(".shop.chapel.convert", { { "cost", m_convertCost } }));
			else
				wButtonConvert.SetText(Resources::GetString(".shop.chapel.convertdisabled"));
		}

		m_shopMenu.DoLayout();
	}

	bool BuyItem(Upgrades::Upgrade@ upgrade, Upgrades::UpgradeStep@ step) override
	{
		if (!ShopMenuContent::BuyItem(upgrade, step))
			return false;

		Stats::Add("blessings-purchased", 1, GetLocalPlayerRecord());
		return true;
	}

	string GetGuiFilename() override
	{
		return "gui/shop/chapel.gui";
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "convert")
		{
			g_gameMode.ShowDialog(
				"convert",
				Resources::GetString(".shop.chapel.convert.prompt", { { "cost", m_convertCost } }),
				Resources::GetString(".menu.yes"),
				Resources::GetString(".menu.no"),
				m_shopMenu
			);
		}
		else if (name == "convert yes")
		{
			auto gm = cast<Campaign>(g_gameMode);
			if (gm.m_townLocal.m_gold < m_convertCost)
			{
				PrintError("Not enough gold to convert!");
				return;
			}

			gm.m_townLocal.m_gold -= m_convertCost;

			auto record = GetLocalPlayerRecord();

			for (uint i = 0; i < m_shop.m_rows.length(); i++)
			{
				auto row = m_shop.m_rows[i];
				for (uint x = 0; x < row.length(); x++)
				{
					auto upgr = row[x];
					if (!upgr.IsOwned(record))
						continue;

					for (uint j = 0; j < record.upgrades.length(); j++)
					{
						auto ownedUpgrade = record.upgrades[j];
						if (ownedUpgrade.m_id == upgr.m_id)
						{
							record.upgrades.removeAt(j);
							break;
						}
					}
				}
			}

			//TODO: Netsync

			GetLocalPlayer().RefreshModifiers();

			ReloadList();
		}
		else
			ShopMenuContent::OnFunc(sender, name);
	}
}
