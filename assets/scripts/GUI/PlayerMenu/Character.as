funcdef float PlayerMenuCharacterTabTooltipFunction(PlayerBase@ player, Modifiers::ModifierList@ list);

class PlayerMenuCharacterTab : MultiplePlayersTab
{
	InventoryWidget@ m_inventory;

	TextWidget@ m_wDungeonTime;
	TextWidget@ m_wDungeonTimePrev;

	Sprite@ m_spriteMana;

	PlayerMenuCharacterTab()
	{
		m_id = "character";
	}

	void OnCreated() override
	{
		MultiplePlayersTab::OnCreated();

		@m_inventory = cast<InventoryWidget>(m_widget.GetWidgetById("inventory"));
		@m_inventory.m_itemTemplate = cast<InventoryItemWidget>(m_widget.GetWidgetById("inventory-template"));

		@m_wDungeonTime = cast<TextWidget>(m_widget.GetWidgetById("dungeon-time"));
		if (m_wDungeonTime !is null)
			m_wDungeonTime.m_visible = (cast<Town>(g_gameMode) is null);
		@m_wDungeonTimePrev = cast<TextWidget>(m_widget.GetWidgetById("dungeon-time-prev"));

		@m_spriteMana = m_def.GetSprite("icon-mana");
	}

	void OnShow() override
	{
		MultiplePlayersTab::OnShow();

		auto gm = cast<Campaign>(g_gameMode);
		if (m_wDungeonTimePrev !is null)
			m_wDungeonTimePrev.SetText("prev: " + formatTime(gm.m_timePlayedDungeonPrev, false, true));
	}

	void Update(int dt) override
	{
		auto gm = cast<Campaign>(g_gameMode);
		if (gm !is null && m_wDungeonTime !is null)
		{
			m_wDungeonTime.SetText(formatTime(gm.m_timePlayedDungeon, false, true));
		}
	}

	void SetTextWidget(string id, string text, bool setColor = false)
	{
		auto w = cast<TextWidget>(m_widget.GetWidgetById(id));
		if (w is null)
			return;
		w.SetText(text, setColor);
	}

	void SetTooltipWidget(string id, string title, string text)
	{
		auto w = cast<TextWidget>(m_widget.GetWidgetById(id));
		if (w is null)
			return;

		w.m_tooltipTitle = title;
		w.m_tooltipText = text;
	}

	void AddTextWidget(string id, string text, bool setColor = false)
	{
		auto w = cast<TextWidget>(m_widget.GetWidgetById(id));
		if (w is null)
			return;
		w.SetText(w.m_str + text, setColor);
	}

	string GetTooltipText(PlayerRecord@ record, PlayerBase@ player, PlayerMenuCharacterTabTooltipFunction@ callback, float base = -1.0f)
	{
		string ret = "";

		if (base >= 0.0f)
			ret += Resources::GetString(".playermenu.character.base", { { "value", formatFloat(base, "", 0, 2) } }) + "\n";

		for (uint i = 0; i < record.modifiers.m_modifiers.length(); i++)
		{
			auto list = cast<Modifiers::ModifierList>(record.modifiers.m_modifiers[i]);
			if (list !is null)
			{
				float value = callback(player, list);
				if (value > 0)
					ret += "+" + value + " " + list.m_name + "\n";
			}
		}

		return strTrim(ret);
	}

	void UpdateNow(PlayerRecord@ record) override
	{
		MultiplePlayersTab::UpdateNow(record);

		auto player = cast<PlayerBase>(record.actor);
		if (player !is null)
			UpdateFromRecord(record, player);

		m_inventory.UpdateFromRecord(record);

		DoLayout();
	}

	void UpdateFromRecord(PlayerRecord@ record, PlayerBase@ player)
	{
		// Keys
		SetTextWidget("keys-0", "" + record.keys[0]);
		SetTextWidget("keys-1", "" + record.keys[1]);
		SetTextWidget("keys-2", "" + record.keys[2]);
		SetTextWidget("keys-3", "" + record.keys[3]);

		// Potion
		auto wPotion = cast<SpriteWidget>(m_widget.GetWidgetById("potion"));
		auto wPotionBar = cast<DotbarWidget>(m_widget.GetWidgetById("potion-bar"));

		if (wPotion !is null && wPotionBar !is null)
		{
			int charges = 1 + record.modifiers.PotionCharges();

			float potionSpriteStep = (4.0f / float(charges));
			int potionSprite = (4 - int(round(potionSpriteStep * record.potionChargesUsed)));

			if (potionSprite < 0 || record.potionChargesUsed == charges) potionSprite = 0;
			else if (potionSprite > 4) potionSprite = 4;

			wPotion.SetSprite("potion-" + potionSprite);
			wPotionBar.m_value = (charges - record.potionChargesUsed);
			wPotionBar.m_max = charges;

			dictionary paramsTitle = { { "num", charges - record.potionChargesUsed }, { "total", charges } };
			wPotion.m_tooltipTitle = Resources::GetString(".playermenu.tooltip.potion.title", paramsTitle);

			float healAmnt = 50 * record.modifiers.PotionHealMul(player);
			float manaAmnt = 50 * record.modifiers.PotionManaMul(player);

			dictionary paramsText = { { "hp", healAmnt }, { "mana", manaAmnt } };
			wPotion.m_tooltipText = Resources::GetString(".playermenu.tooltip.potion.text", paramsText);
		}

		// Skills
		for (uint i = 0; i < player.m_skills.length(); i++)
		{
			Widget@ wSkill = m_widget.GetWidgetById("skill-" + i);
			if (wSkill is null)
				continue;

			auto wSkillIcon = cast<SpriteWidget>(wSkill.GetWidgetById("icon"));
			if (wSkillIcon is null)
				continue;

			int skillLevel = record.levelSkills[i];
			if (skillLevel == 0)
			{
				wSkillIcon.m_visible = false;
				continue;
			}

			wSkillIcon.m_visible = true;

			Skills::Skill@ skill = player.m_skills[i];
			Skills::ActiveSkill@ activeSkill = cast<Skills::ActiveSkill>(skill);

			wSkillIcon.SetSprite(skill.m_icon);
			wSkillIcon.m_tooltipTitle = skill.GetFullName(skillLevel);

			wSkillIcon.ClearTooltipSubs();

			if (i == 0) wSkillIcon.AddTooltipSub(null, Resources::GetString(".misc.primaryskill"));
			else if (i <= 3) wSkillIcon.AddTooltipSub(null, Resources::GetString(".misc.activeskill"));
			else wSkillIcon.AddTooltipSub(null, Resources::GetString(".misc.passiveskill"));

			if (activeSkill !is null && activeSkill.m_costMana > 0)
				wSkillIcon.AddTooltipSub(m_spriteMana, ("" + activeSkill.m_costMana));

			wSkillIcon.m_tooltipText = skill.GetFullDescription(skillLevel);
		}

		// Town info
		auto gm = cast<Campaign>(g_gameMode);
		int townGold = gm.m_townLocal.m_gold;
		int townOre = gm.m_townLocal.m_ore;

		// Character info
		vec2 statArmorAdd = record.modifiers.ArmorAdd(player, null); // armor, resistance
		//ivec2 statDamageBlock; // physical, magical

		ivec2 statDamagePower = record.modifiers.DamagePower(player, null); // attack power, spell power
		ivec2 statDamageAdd = record.modifiers.AttackDamageAdd(player, null); // attack add, spell add

		ivec2 statStatsAdd = record.modifiers.StatsAdd(player); // health, mana
		float statMoveSpeed = min(Tweak::PlayerSpeed + record.modifiers.MoveSpeedAdd(player), Tweak::PlayerSpeedMax);
		vec2 statRegenAdd = record.modifiers.RegenAdd(player); // health, mana
		vec2 statRegenMul = record.modifiers.RegenMul(player); // health, mana
		float statExpMul = record.modifiers.ExpMul(player, null);

		int xpStart = record.LevelExperience(record.level - 1);
		int xpEnd = record.LevelExperience(record.level) - xpStart;
		int xpNow = record.experience - xpStart;

		SetTextWidget("info_health", "" + (record.MaxHealth() + statStatsAdd.x));
		SetTooltipWidget(
			"info_health",
			Resources::GetString(".playermenu.character.health"),
			GetTooltipText(record, player, function(player, list) {
				return list.StatsAdd(player).x;
			}, record.MaxHealth())
		);
		SetTextWidget("info_health_regen", formatFloat((record.HealthRegen() + statRegenAdd.x) * statRegenMul.x, "", 0, 2));
		SetTooltipWidget(
			"info_health_regen",
			Resources::GetString(".playermenu.character.healthregen"),
			GetTooltipText(record, player, function(player, list) {
				return list.RegenAdd(player).x;
			}, record.HealthRegen())
		);

		SetTextWidget("info_mana", "" + (record.MaxMana() + statStatsAdd.y));
		SetTooltipWidget(
			"info_mana",
			Resources::GetString(".playermenu.character.mana"),
			GetTooltipText(record, player, function(player, list) {
				return list.StatsAdd(player).y;
			}, record.MaxMana())
		);

		SetTextWidget("info_mana_regen", formatFloat((record.ManaRegen() + statRegenAdd.y) * statRegenMul.y, "", 0, 2));
		SetTooltipWidget(
			"info_mana_regen",
			Resources::GetString(".playermenu.character.manaregen"),
			GetTooltipText(record, player, function(player, list) {
				return list.RegenAdd(player).y;
			}, record.ManaRegen())
		);

		SetTextWidget("info_armor", "" + (record.Armor() + statArmorAdd.x));
		SetTooltipWidget(
			"info_armor",
			Resources::GetString(".playermenu.character.armor"),
			Resources::GetString(".playermenu.character.armor.description", { { "value", round((1.0f - CalcArmor(record.Armor() + statArmorAdd.x)) * 100.0f) } }) + "\n" +
			GetTooltipText(record, player, function(player, list) {
				return list.ArmorAdd(player, null).x;
			}, record.Armor())
		);
		SetTextWidget("info_resistance", "" + formatFloat(record.Resistance() + statArmorAdd.y, "", 0, 1));
		SetTooltipWidget(
			"info_resistance",
			Resources::GetString(".playermenu.character.resistance"),
			Resources::GetString(".playermenu.character.resistance.description", { { "value", round((1.0f - CalcArmor(record.Resistance() + statArmorAdd.y)) * 100.0f) } }) + "\n" +
			GetTooltipText(record, player, function(player, list) {
				return list.ArmorAdd(player, null).y;
			}, record.Resistance())
		);
		SetTextWidget("info_damage_power_attack", "" + statDamagePower.x);
		SetTooltipWidget(
			"info_damage_power_attack",
			Resources::GetString(".playermenu.character.attackpower"),
			Resources::GetString(".playermenu.character.attackpower.description", { { "value", round((((50.0f + statDamagePower.x) / 50.0f) - 1.0f) * 100.0f) } }) + "\n" +
			GetTooltipText(record, player, function(player, list) {
				return list.DamagePower(player, null).x;
			})
		);
		SetTextWidget("info_damage_power_spell", "" + statDamagePower.y);
		SetTooltipWidget(
			"info_damage_power_spell",
			Resources::GetString(".playermenu.character.spellpower"),
			Resources::GetString(".playermenu.character.spellpower.description", { { "value", round((((50.0f + statDamagePower.y) / 50.0f) - 1.0f) * 100.0f) } }) + "\n" +
			GetTooltipText(record, player, function(player, list) {
				return list.DamagePower(player, null).y;
			})
		);
		SetTextWidget("info_damage_add_attack", "" + statDamageAdd.x);
		SetTooltipWidget(
			"info_damage_add_attack",
			Resources::GetString(".playermenu.character.attackdamage"),
			GetTooltipText(record, player, function(player, list) {
				return list.AttackDamageAdd(player, null).x;
			})
		);
		SetTextWidget("info_damage_add_spell", "" + statDamageAdd.y);
		SetTooltipWidget(
			"info_damage_add_spell",
			Resources::GetString(".playermenu.character.spelldamage"),
			GetTooltipText(record, player, function(player, list) {
				return list.AttackDamageAdd(player, null).y;
			})
		);

		SetTextWidget("info_move_speed", formatFloat(statMoveSpeed, "", 0, 1));
		SetTooltipWidget(
			"info_move_speed",
			Resources::GetString(".playermenu.character.movespeed"),
			GetTooltipText(record, player, function(player, list) {
				return list.MoveSpeedAdd(player);
			}, Tweak::PlayerSpeed)
		);
		SetTextWidget("info_exp", floor((xpNow / float(xpEnd)) * 100) + "%");
		SetTooltipWidget("info_exp", Resources::GetString(".playermenu.tooltip.exp"),
			Resources::GetString(".playermenu.tooltip.exp.total") + " " + formatThousands(record.experience) + "\n" +
			Resources::GetString(".playermenu.tooltip.exp.left") + " " + formatThousands(xpEnd - xpNow) +
			" (" + ceil((1.0f - (xpNow / float(xpEnd))) * 100) + "%)\n" +
			Resources::GetString(".playermenu.tooltip.exp.rate") + " " + round(statExpMul * 100) + "%");

		SetTextWidget("info_gold", formatThousands(record.runGold));
		SetTooltipWidget(
			"info_gold",
			Resources::GetString(".playermenu.character.goldgain"),
			(record.modifiers.GoldGainScale(player) * 100) + "%\n" + 
			GetTooltipText(record, player, function(player, list) {
				return (list.GoldGainScale(player) - 1.0f) * 100;
			})
		);
		
		SetTextWidget("info_gold_town", formatThousands(townGold));
		int rg = max(250, record.runGold);
		SetTooltipWidget("info_gold_town", Resources::GetString(".playermenu.tooltip.tax"),
			((1.0f - ApplyTaxRate(townGold, rg) / float(rg)) * 100) + "%");
		
		SetTextWidget("info_ore", formatThousands(record.runOre));
		SetTextWidget("info_ore_town", formatThousands(townOre));
	}
}
