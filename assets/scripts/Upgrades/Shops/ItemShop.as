namespace Upgrades
{
	class ItemShop : UpgradeShop
	{
		SValue@ m_sval;

		ItemShop(SValue& params)
		{
			super(params);

			@m_sval = params;
		}

		int GetItemCategory()
		{
			return 0;
		}

		void ClearItems()
		{
			for (int i = int(m_upgrades.length()) - 1; i >= 0; i--)
			{
				if (cast<ItemUpgrade>(m_upgrades[i]) !is null)
					m_upgrades.removeAt(i);
			}
		}

		void NewItems(SValue@ sv, PlayerRecord@ record)
		{
			float costScale = GetParamFloat(UnitPtr(), sv, "cost-scale", false, 1.0f);

			record.generalStoreItemsSaved = GetItemCategory();
			record.generalStoreItems.removeRange(0, record.generalStoreItems.length());

			auto arrQualities = GetParamArray(UnitPtr(), sv, "qualities");
			for (uint j = 0; j < arrQualities.length(); j++)
			{
				SValueBuilder builder;
				builder.PushDictionary();
				builder.PushString("id", "item-" + j);
				builder.PushFloat("cost-scale", costScale);

				auto newUpgrade = ItemUpgrade(builder.Build());
				newUpgrade.m_quality = ParseActorItemQuality(arrQualities[j].GetString());
				newUpgrade.Set(this);
				m_upgrades.insertLast(newUpgrade);

				record.generalStoreItems.insertLast(newUpgrade.m_item.idHash);
			}
		}

		void ReadItems(float costScale, PlayerRecord@ record)
		{
			for (uint i = 0; i < record.generalStoreItems.length(); i++)
			{
				auto item = g_items.GetItem(record.generalStoreItems[i]);
				if (item is null)
				{
					PrintError("Couldn't find item for hash!");
					continue;
				}

				SValueBuilder builder;
				builder.PushDictionary();
				builder.PushString("id", "item-" + i);
				builder.PushFloat("cost-scale", costScale);

				auto newUpgrade = ItemUpgrade(builder.Build());
				newUpgrade.Set(this, item);
				m_upgrades.insertLast(newUpgrade);
			}
		}

		void OnOpenMenu(int shopLevel, PlayerRecord@ record) override
		{
			ClearItems();

			auto arr = GetParamArray(UnitPtr(), m_sval, "items");
			auto svalLevel = arr[shopLevel - 1];

			if (record.generalStoreItemsSaved == GetItemCategory())
			{
				float costScale = GetParamFloat(UnitPtr(), svalLevel, "cost-scale", false, 1.0f);
				ReadItems(costScale, record);
			}
			else
				NewItems(svalLevel, record);
		}

		ShopIterator@ Iterate(int shopLevel, PlayerRecord@ record) override
		{
			return ItemShopIterator(this, shopLevel, record);
		}

		void SetApplied(ItemUpgrade@ upgrade, PlayerRecord@ record)
		{
			int indexUpgrade = m_upgrades.findByRef(upgrade);
			if (indexUpgrade != -1)
				m_upgrades.removeAt(indexUpgrade);

			int indexStore = record.generalStoreItems.find(upgrade.m_item.idHash);
			if (indexStore != -1)
				record.generalStoreItems.removeAt(indexStore);
		}
	}

	class ItemShopIterator : ShopIterator
	{
		int m_index;

		ItemShopIterator(Shop@ shop, int level, PlayerRecord@ record)
		{
			super(shop, level, record);

			m_index = -1;
			Next();
		}

		bool AtEnd() override
		{
			return m_index >= int(cast<ItemShop>(m_shop).m_upgrades.length());
		}

		Upgrade@ Current() override
		{
			return cast<ItemShop>(m_shop).m_upgrades[m_index];
		}

		void Next() override
		{
			while (true)
			{
				m_index++;

				if (AtEnd())
					break;

				auto upgrade = Current();
				auto itemUpgrade = cast<ItemUpgrade>(upgrade);

				if (itemUpgrade !is null)
				{
					if (itemUpgrade.ShouldBeVisible())
						break;
				}
				else
					break;
			}
		}
	}
}
