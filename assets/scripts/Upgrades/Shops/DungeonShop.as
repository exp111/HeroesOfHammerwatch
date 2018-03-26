namespace Upgrades
{
	class DungeonShop : ItemShop
	{
		DungeonShop(SValue& params)
		{
			super(params);
		}

		int GetItemCategory() override
		{
			auto gm = cast<Campaign>(g_gameMode);
			return gm.m_levelCount + 1;
		}

		void NewItems(SValue@ sv, PlayerRecord@ record) override
		{
			ItemShop::NewItems(sv, record);

			if (record !is null && record.items.find("fancy-plume") != -1)
			{
				float costScale = GetParamFloat(UnitPtr(), sv, "cost-scale", false, 1.0f);
				AddPlumeItem(costScale, record);
			}
		}

		void ReadItems(float costScale, PlayerRecord@ record) override
		{
			ItemShop::ReadItems(costScale, record);

			if (record !is null && record.items.find("fancy-plume") != -1)
				AddPlumeItem(costScale, record);
		}

		void AddPlumeItem(float costScale, PlayerRecord@ record)
		{
			if (record.generalStoreItemsPlume == GetItemCategory())
				return;

			print("adding plume item");

			record.generalStoreItemsPlume = GetItemCategory();

			int numCommon = 0;
			int numUncommon = 0;
			int numRare = 0;
			int numLegendary = 0;
			int numTotal = 0;
			for (uint i = 0; i < m_upgrades.length(); i++)
			{
				auto upgrade = cast<ItemUpgrade>(m_upgrades[i]);
				if (upgrade is null)
					continue;

				numTotal++;
				if (upgrade.m_quality == ActorItemQuality::Common) numCommon++;
				else if (upgrade.m_quality == ActorItemQuality::Uncommon) numUncommon++;
				else if (upgrade.m_quality == ActorItemQuality::Rare) numRare++;
				else if (upgrade.m_quality == ActorItemQuality::Legendary) numLegendary++;
			}

			ActorItemQuality extraQuality;

			int rnd = randi(numTotal);
			if (rnd < numCommon) extraQuality = ActorItemQuality::Common;
			else if ((rnd -= numCommon) < numUncommon) extraQuality = ActorItemQuality::Uncommon;
			else if ((rnd -= numUncommon) < numRare) extraQuality = ActorItemQuality::Rare;
			else if ((rnd -= numRare) < numLegendary) extraQuality = ActorItemQuality::Legendary;

			SValueBuilder builder;
			builder.PushDictionary();
			builder.PushString("id", "item-plume");
			builder.PushFloat("cost-scale", costScale);

			auto newUpgrade = ItemUpgrade(builder.Build());
			newUpgrade.m_quality = extraQuality;
			newUpgrade.Set(this);
			m_upgrades.insertLast(newUpgrade);

			record.generalStoreItems.insertLast(newUpgrade.m_item.idHash);
		}
	}
}
