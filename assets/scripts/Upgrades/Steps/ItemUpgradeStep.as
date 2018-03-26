namespace Upgrades
{
	class ItemUpgradeStep : UpgradeStep
	{
		ActorItem@ m_item;

		ItemUpgradeStep(ActorItem@ item, Upgrade@ upgrade, SValue@ params, int level)
		{
			super(upgrade, params, level);

			@m_item = item;

			m_costGold = m_item.cost;
		}

		string GetTooltipTitle() override
		{
			return "\\c" + GetItemQualityColorString(m_item.quality) + UpgradeStep::GetTooltipTitle();
		}

		string GetTooltipDescription() override
		{
			string ret = UpgradeStep::GetTooltipDescription();

			if (m_item.set !is null)
			{
				ret += "\n\n";
				ret += GetItemSetColorString(m_item);
			}

			return ret;
		}

		void DrawShopIcon(ShopButtonWidget@ widget, SpriteBatch& sb, vec2 pos, vec2 size, vec4 color) override
		{
			if (m_item.icon !is null)
			{
				int iconWidth = m_item.icon.GetWidth();
				int iconHeight = m_item.icon.GetHeight();

				m_item.icon.Draw(sb, vec2(
					pos.x + size.x / 2 - iconWidth / 2,
					pos.y + size.y / 3 - iconHeight / 2
				), g_menuTime, color);
			}

			int dotX = int(size.x - widget.m_itemDot.GetWidth() - 2);
			int dotY = int(size.y - widget.m_itemDot.GetHeight() - 2);

			if (m_item.quality != ActorItemQuality::Common)
			{
				vec4 colorDot = GetItemQualityColor(m_item.quality);
				vec2 dotPos = pos + vec2(dotX, dotY);
				sb.DrawSprite(dotPos, widget.m_itemDot, g_menuTime, colorDot);
				dotX -= widget.m_itemDot.GetWidth();
			}

			/*
			if (m_item.set !is null)
			{
				vec2 dotPos = pos + vec2(dotX, dotY);
				sb.DrawSprite(dotPos, widget.m_itemDot, g_menuTime, vec4(1, 0, 1, 1));
				dotX -= widget.m_itemDot.GetWidth();
			}
			*/
		}

		float PayScale() override
		{
			float priceScale = 1.0f;
			if (GetLocalPlayerRecord().items.find("vendors-coin") != -1)
				priceScale *= 0.75f;
			return priceScale;
		}

		void PayForUpgrade(PlayerRecord@ record) override
		{
			if (CanAfford(record))
			{
				Stats::Add("items-bought", 1, record);
				Stats::Add("items-bought-" + GetItemQualityName(m_item.quality), 1, record);
			}

			UpgradeStep::PayForUpgrade(record);
		}

		bool IsOwned(PlayerRecord@ record) override
		{
			return false;
		}

		bool ApplyNow(PlayerRecord@ record) override
		{
			auto player = cast<Player>(record.actor);
			if (player is null)
				return false;

			cast<ItemUpgrade>(m_upgrade).SetApplied(record);

			player.AddItem(m_item);
			return true;
		}
	}
}
