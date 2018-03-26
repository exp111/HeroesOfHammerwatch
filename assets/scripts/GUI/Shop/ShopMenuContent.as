class ShopMenuContent
{
	ShopMenu@ m_shopMenu;

	GUIDef@ m_def;
	Widget@ m_widget;

	ShopMenuContent(ShopMenu@ shopMenu)
	{
		@m_shopMenu = shopMenu;
	}

	string GetTitle()
	{
		return "none";
	}

	void OnShow()
	{
	}

	void OnClose()
	{
	}

	string GetGuiFilename()
	{
		return "gui/shop/none.gui";
	}

	void Update(int dt)
	{
	}

	void ReloadList()
	{
	}

	bool BuyItem(Upgrades::Upgrade@ upgrade, Upgrades::UpgradeStep@ step)
	{
		auto record = GetLocalPlayerRecord();
		auto player = GetLocalPlayer();

		if (player is null)
		{
			PrintError("Player is dead");
			PlaySound2D(m_shopMenu.m_sndCantBuy);
			return false;
		}

		if (!step.CanAfford(record))
		{
			PrintError("Too expensive");
			PlaySound2D(m_shopMenu.m_sndCantBuy);
			return false;
		}

		if (!step.BuyNow(record))
		{
			PlaySound2D(m_shopMenu.m_sndCantBuy);
			return false;
		}

		if (upgrade.ShouldRemember())
		{
			OwnedUpgrade@ ownedUpgrade = record.GetOwnedUpgrade(upgrade.m_id);
			if (ownedUpgrade !is null)
			{
				ownedUpgrade.m_level = step.m_level;
				@ownedUpgrade.m_step = step;
			}
			else
			{
				@ownedUpgrade = OwnedUpgrade();
				ownedUpgrade.m_id = upgrade.m_id;
				ownedUpgrade.m_level = step.m_level;
				@ownedUpgrade.m_step = step;
				record.upgrades.insertLast(ownedUpgrade);
			}
		}

		(Network::Message("PlayerGiveUpgrade") << upgrade.m_id << step.m_level).SendToAll();

		step.PayForUpgrade(record);
		
		if (step.m_costSkillPoints > 0)
			PlaySound2D(m_shopMenu.m_sndBuySkill);
		else if (step.m_costOre > 0)
			PlaySound2D(m_shopMenu.m_sndBuyOre);
		else
			PlaySound2D(m_shopMenu.m_sndBuyGold);
		
		auto gm = cast<Campaign>(g_gameMode);
		if (gm !is null)
		{
			gm.SaveLocalTown();
			gm.SavePlayer(record);
		}

		return true;
	}

	void OnFunc(Widget@ sender, string name)
	{
		auto parse = name.split(" ");
		if (parse[0] == "buy-item")
		{
			auto btn = cast<UpgradeShopButtonWidget>(sender);
			if (btn !is null)
			{
				if (BuyItem(btn.m_upgrade, btn.m_upgradeStep))
					ReloadList();
			}
		}
	}
}
