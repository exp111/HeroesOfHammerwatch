namespace Upgrades
{
	class UpgradeStep
	{
		Upgrade@ m_upgrade;

		int m_costGold;
		int m_costOre;
		int m_costSkillPoints;

		string m_name;
		string m_description;
		ScriptSprite@ m_sprite;

		int m_level;

		int m_restrictShopLevelMin;
		int m_restrictShopLevelMax;
		int m_restrictPlayerLevelMin;
		string m_restrictFlag;

		UpgradeStep(Upgrade@ upgrade, SValue@ params, int level)
		{
			@m_upgrade = upgrade;

			m_costGold = GetParamInt(UnitPtr(), params, "cost-gold", false);
			m_costOre = GetParamInt(UnitPtr(), params, "cost-ore", false);
			m_costSkillPoints = GetParamInt(UnitPtr(), params, "cost-skillpoints", false);

			m_name = GetParamString(UnitPtr(), params, "name", false);
			m_description = GetParamString(UnitPtr(), params, "desc", false);

			auto arrSprite = GetParamArray(UnitPtr(), params, "icon", false);
			if (arrSprite !is null)
				@m_sprite = ScriptSprite(arrSprite);

			m_level = GetParamInt(UnitPtr(), params, "level", false, level);

			m_restrictShopLevelMin = GetParamInt(UnitPtr(), params, "restrict-shop-level-min", false, -1);
			m_restrictShopLevelMax = GetParamInt(UnitPtr(), params, "restrict-shop-level-max", false, -1);
			m_restrictPlayerLevelMin = GetParamInt(UnitPtr(), params, "restrict-player-level-min", false, -1);
			m_restrictFlag = GetParamString(UnitPtr(), params, "restrict-flag", false, "");
		}

		string GetButtonText()
		{
			return Resources::GetString(m_name);
		}

		string GetTooltipTitle()
		{
			return Resources::GetString(m_name);
		}

		string GetTooltipDescription()
		{
			return Resources::GetString(m_description);
		}

		ScriptSprite@ GetSprite()
		{
			if (m_sprite is null)
				return m_upgrade.m_sprite;
			return m_sprite;
		}

		void DrawShopIcon(ShopButtonWidget@ widget, SpriteBatch& sb, vec2 pos, vec2 size, vec4 color)
		{
		}

		bool IsOwned(PlayerRecord@ record)
		{
			for (uint i = 0; i < record.upgrades.length(); i++)
			{
				auto ownedUpgrade = record.upgrades[i];
				if (ownedUpgrade.m_id == m_upgrade.m_id && ownedUpgrade.m_level >= m_level)
					return true;
			}
			return false;
		}

		bool CanAfford(PlayerRecord@ record)
		{
			bool inTown = (cast<Town>(g_gameMode) !is null);

			int costGold = int(m_costGold * PayScale());
			int costOre = int(m_costOre * PayScale());

			if (inTown)
			{
				auto gm = cast<Campaign>(g_gameMode);
				if (gm is null)
					return false;

				if (costGold > gm.m_townLocal.m_gold)
					return false;

				if (costOre > gm.m_townLocal.m_ore)
					return false;
			}
			else
			{
				if (costGold > record.runGold)
					return false;

				if (costOre > record.runOre)
					return false;
			}

			if (m_costSkillPoints > record.skillPoints)
				return false;

			return true;
		}

		float PayScale()
		{
			return 1.0f;
		}

		void PayForUpgrade(PlayerRecord@ record)
		{
			if (!CanAfford(record))
			{
				PrintError("Tried paying for upgrade while we can not afford the upgrade.");
				return;
			}

			bool inTown = (cast<Town>(g_gameMode) !is null);

			if (inTown)
			{
				auto gm = cast<Campaign>(g_gameMode);
				if (gm is null)
					return;

				gm.m_townLocal.m_gold -= int(m_costGold * PayScale());
				gm.m_townLocal.m_ore -= int(m_costOre * PayScale());
			}
			else
			{
				record.runGold -= int(m_costGold * PayScale());
				record.runOre -= int(m_costOre * PayScale());
			}

			record.skillPoints -= m_costSkillPoints;

			Stats::Add("spent-gold", m_costGold, record);
			Stats::Add("spent-ore", m_costOre, record);
			Stats::Add("spent-skillpoints", m_costSkillPoints, record);
		}

		bool BuyNow(PlayerRecord@ record)
		{
			return ApplyNow(record);
		}

		bool ApplyNow(PlayerRecord@ record)
		{
			return false;
		}
	}
}
