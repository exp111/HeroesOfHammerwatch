class GuildHallStatsTab : GuildHallMenuTab
{
	Widget@ m_wList;

	Widget@ m_wTemplateGuild;
	Widget@ m_wTemplateCharacter;
	Widget@ m_wTemplateSeparator;

	Widget@ m_wTemplateStats;
	Widget@ m_wTemplateStatsHeader;
	Widget@ m_wTemplateStatsSeparator;

	Widget@ m_wTemplateClasses;
	Widget@ m_wTemplateClassesClass;

	GuildHallStatsTab()
	{
		m_id = "stats";
	}

	void OnShow() override
	{
		GuildHallMenuTab::OnShow();

		@m_wList = m_widget.GetWidgetById("list");

		@m_wTemplateGuild = m_widget.GetWidgetById("template-guild");
		@m_wTemplateCharacter = m_widget.GetWidgetById("template-character");
		@m_wTemplateSeparator = m_widget.GetWidgetById("template-separator");

		@m_wTemplateStats = m_widget.GetWidgetById("template-stats");
		@m_wTemplateStatsHeader = m_widget.GetWidgetById("template-stats-header");
		@m_wTemplateStatsSeparator = m_widget.GetWidgetById("template-stats-separator");

		@m_wTemplateClasses = m_widget.GetWidgetById("template-classes");
		@m_wTemplateClassesClass = m_widget.GetWidgetById("template-classes-class");

		RefreshList();
	}

	bool OnFunc(Widget@ sender, string name) override
	{
		if (name == "details-toggled")
		{
			// We have to do the layout twice to avoid flickering (once from within DetailsWidget and once from here)
			DoLayout();
			return true;
		}
		return false;
	}

	void AddSeparatorToList(Widget@ wList)
	{
		auto wNewItem = m_wTemplateSeparator.Clone();
		wNewItem.SetID("");
		wNewItem.m_visible = true;
		wList.AddChild(wNewItem);
	}

	void AddStatisticsToList(Stats::StatList@ stats, Widget@ wList)
	{
		string lastCategory;

		for (uint i = 0; i < stats.m_stats.length(); i++)
		{
			auto stat = stats.m_stats[i];

			if (stat.m_display == Stats::StatDisplay::None || stat.m_valueInt == 0)
				continue;

			if (stat.m_category != lastCategory)
			{
				if (lastCategory != "")
				{
					auto wNewSeparator = m_wTemplateStatsSeparator.Clone();
					wNewSeparator.m_visible = true;
					wNewSeparator.SetID("");
					wList.AddChild(wNewSeparator);
				}

				lastCategory = stat.m_category;

				auto wNewHeader = m_wTemplateStatsHeader.Clone();
				wNewHeader.m_visible = true;
				wNewHeader.SetID("");

				auto wHeaderCategory = cast<TextWidget>(wNewHeader.GetWidgetById("category"));
				if (wHeaderCategory !is null)
					wHeaderCategory.SetText(utf8string(Resources::GetString(".stats.category." + stat.m_category)).toUpper().plain());

				wList.AddChild(wNewHeader);
			}

			auto wNewItem = m_wTemplateStats.Clone();
			wNewItem.m_visible = true;
			wNewItem.SetID("");

			auto wName = cast<TextWidget>(wNewItem.GetWidgetById("name"));
			if (wName !is null)
				wName.SetText(Resources::GetString(".stats." + stat.m_name));

			auto wValue = cast<TextWidget>(wNewItem.GetWidgetById("value"));
			if (wValue !is null)
			{
				if (stat.m_valueInt == 0)
					wValue.SetText("-");
				else
					wValue.SetText(stat.ToString());
			}

			wList.AddChild(wNewItem);
		}
	}

	void AddGuildToList(Widget@ wList)
	{
		auto gm = cast<Campaign>(g_gameMode);
		auto town = gm.m_townLocal;

		auto wNewItem = cast<DetailsWidget>(m_wTemplateGuild.Clone());
		wNewItem.SetID("");
		wNewItem.m_visible = true;
		wList.AddChild(wNewItem);

		auto title = town.GetTitle();
		auto titleNext = town.GetNextTitle();

		string guildTitle = utf8string(Resources::GetString(title.m_name)).toUpper().plain();

		auto wGuildTitle = cast<TextWidget>(wNewItem.GetWidgetById("guild-title"));
		wGuildTitle.SetText(Resources::GetString(".guildhall.stats.guildtitle", { { "title", guildTitle } }));

		auto wBar = cast<BarWidget>(wNewItem.GetWidgetById("reputation-bar"));
		auto wBarText = cast<TextWidget>(wBar.GetWidgetById("text"));

		if (titleNext !is null)
		{
			int reputation = town.GetReputation();
			int goodStart = title.m_points;
			int goodEnd = titleNext.m_points;
			float scale = ilerp(goodStart, goodEnd, reputation);
			wBar.SetScale(scale);
			wBarText.SetText(formatThousands(reputation) + " / " + formatThousands(goodEnd));
		}
		else
		{
			wBar.m_spriteRectVariation = 1;
			wBarText.SetColor(vec4(0, 1, 0, 1));
		}

		AddStatisticsToList(town.m_statistics, wNewItem.m_wDetails);
	}

	void AddClassesClassToList(Widget@ wList, string className, array<SValue@>@ characters, vec2 anchor)
	{
		SValue@ bestChar = null;
		Titles::Title@ bestCharTitle = null;
		int bestCharTitleIndex = -1;

		for (uint i = 0; i < characters.length(); i++)
		{
			auto charData = characters[i];

			string charClass = GetParamString(UnitPtr(), charData, "class");
			if (charClass != className)
				continue;

			int titleIndex = GetParamInt(UnitPtr(), charData, "title");
			if (titleIndex <= bestCharTitleIndex)
				continue;

			auto title = g_classTitles.GetTitle(className, titleIndex);
			if (title is null)
				continue;

			bestCharTitleIndex = titleIndex;

			@bestChar = charData;
			@bestCharTitle = title;
		}

		auto wNewClass = m_wTemplateClassesClass.Clone();
		wNewClass.SetID("");
		wNewClass.m_visible = true;

		wNewClass.m_anchor = anchor;

		if (bestCharTitle !is null)
		{
			auto wTitle = cast<TextWidget>(wNewClass.GetWidgetById("title"));
			if (wTitle !is null)
				wTitle.SetText(Resources::GetString(bestCharTitle.m_name));

			auto wBonus = wNewClass.GetWidgetById("bonus");
			auto wBonusSprite = cast<SpriteWidget>(wBonus.GetWidgetById("sprite"));
			auto wBonusValue = cast<TextWidget>(wBonus.GetWidgetById("value"));

			auto modifiers = bestCharTitle.m_modifiers;

			vec2 armorAdd = modifiers.ArmorAdd(null, null);
			ivec2 damagePower = modifiers.DamagePower(null, null);
			vec2 regenAdd = modifiers.RegenAdd(null);
			float goldGain = modifiers.GoldGainScale(null);

			if (armorAdd.x > 0)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.armor", { { "amount", formatFloat(armorAdd.x, "", 0, 2) } });
				wBonusSprite.SetSprite("icon-armor");
				wBonusValue.SetText(formatFloat(armorAdd.x, "", 0, 2));
			}
			else if (armorAdd.y > 0)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.resistance", { { "amount", formatFloat(armorAdd.y, "", 0, 2) } });
				wBonusSprite.SetSprite("icon-resistance");
				wBonusValue.SetText(formatFloat(armorAdd.y, "", 0, 2));
			}
			else if (damagePower.x > 0)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.attackpower", { { "amount", damagePower.x } });
				wBonusSprite.SetSprite("icon-attack-power");
				wBonusValue.SetText("" + damagePower.x);
			}
			else if (damagePower.y > 0)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.spellpower", { { "amount", damagePower.y } });
				wBonusSprite.SetSprite("icon-spell-power");
				wBonusValue.SetText("" + damagePower.y);
			}
			else if (regenAdd.x > 0)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.healthregen", { { "amount", formatFloat(regenAdd.x, "", 0, 2) } });
				wBonusSprite.SetSprite("icon-health-regen");
				wBonusValue.SetText(formatFloat(regenAdd.x, "", 0, 2));
			}
			else if (regenAdd.y > 0)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.manaregen", { { "amount", formatFloat(regenAdd.y, "", 0, 2) } });
				wBonusSprite.SetSprite("icon-mana-regen");
				wBonusValue.SetText(formatFloat(regenAdd.y, "", 0, 2));
			}
			else if (goldGain > 1.0f)
			{
				wBonus.m_tooltipText = Resources::GetString(".guildhall.stats.goldgain", { { "amount", ((goldGain - 1.0f) * 100.0f) + "%" } });
				wBonusSprite.SetSprite("icon-gold-gain");
				wBonusValue.SetText("+" + formatFloat((goldGain - 1.0f) * 100.0f, "", 0, 1) + "%");
			}
		}

		if (bestChar !is null)
		{
			int face = GetParamInt(UnitPtr(), bestChar, "face");

			auto wSprite = cast<SpriteWidget>(wNewClass.GetWidgetById("sprite"));
			if (wSprite !is null)
			{
				wSprite.SetSprite(GetFaceSprite(className, face));
				wSprite.m_tooltipTitle = Resources::GetString(".class." + className);
				wSprite.m_tooltipText = GetParamString(UnitPtr(), bestChar, "name");
			}
		}

		wList.AddChild(wNewClass);
	}

	void AddClassesToList(Widget@ wList)
	{
		auto wNewClasses = m_wTemplateClasses.Clone();
		wNewClasses.SetID("");
		wNewClasses.m_visible = true;

		auto characters = GetCharacters();

		auto wNewList = wNewClasses.GetWidgetById("list");
		AddClassesClassToList(wNewList, "paladin", characters, vec2(0.1f, 0.0f));
		AddClassesClassToList(wNewList, "ranger", characters, vec2(0.35f, 0.0f));
		AddClassesClassToList(wNewList, "sorcerer", characters, vec2(0.65f, 0.0f));
		AddClassesClassToList(wNewList, "warlock", characters, vec2(0.9f, 0.0f));
		AddClassesClassToList(wNewList, "thief", characters, vec2(0.25f, 1.0f));
		AddClassesClassToList(wNewList, "priest", characters, vec2(0.50f, 1.0f));
		AddClassesClassToList(wNewList, "wizard", characters, vec2(0.75f, 1.0f));

		wList.AddChild(wNewClasses);
	}

	void AddCharacterToList(Widget@ wList, SValue@ svChar)
	{
		auto wNewItem = cast<DetailsWidget>(m_wTemplateCharacter.Clone());
		wNewItem.SetID("");
		wNewItem.m_visible = true;
		wList.AddChild(wNewItem);

		string name = GetParamString(UnitPtr(), svChar, "name");
		int level = GetParamInt(UnitPtr(), svChar, "level");
		string charClass = GetParamString(UnitPtr(), svChar, "class");
		int face = GetParamInt(UnitPtr(), svChar, "face", false);
		int ngp = GetParamInt(UnitPtr(), svChar, "new-game-plus", false);
		SValue@ svStatistics = svChar.GetDictionaryEntry("statistics");

		auto wUnit = cast<UnitWidget>(wNewItem.GetWidgetById("unit"));
		if (wUnit !is null)
		{
			auto classColors = CharacterColors::GetClass(charClass);

			int colorSkin = GetParamInt(UnitPtr(), svChar, "color-skin");
			int color1 = GetParamInt(UnitPtr(), svChar, "color-1");
			int color2 = GetParamInt(UnitPtr(), svChar, "color-2");
			int color3 = GetParamInt(UnitPtr(), svChar, "color-3");

			wUnit.AddUnit("players/" + charClass + ".unit", "idle-3");
			wUnit.m_multiColors.insertLast(classColors.m_skin[colorSkin % classColors.m_skin.length()]);
			wUnit.m_multiColors.insertLast(classColors.m_1[color1 % classColors.m_1.length()]);
			wUnit.m_multiColors.insertLast(classColors.m_2[color2 % classColors.m_2.length()]);
			wUnit.m_multiColors.insertLast(classColors.m_3[color3 % classColors.m_3.length()]);
		}

		auto wFace = cast<SpriteWidget>(wNewItem.GetWidgetById("face"));
		if (wFace !is null)
			wFace.SetSprite(GetFaceSprite(charClass, face));

		auto wLevel = cast<TextWidget>(wNewItem.GetWidgetById("level"));
		if (wLevel !is null)
		{
			wLevel.SetText("" + level);
			if (ngp == 0)
				wLevel.m_anchor.y = 0.5;
		}

		auto wNGP = cast<TextWidget>(wNewItem.GetWidgetById("ngp"));
		if (wNGP !is null)
		{
			wNGP.m_visible = (ngp > 0);
			if (wNGP.m_visible)
				wNGP.SetText("+" + ngp);
		}

		auto wName = cast<TextWidget>(wNewItem.GetWidgetById("name"));
		if (wName !is null)
		{
			string charClassName = Resources::GetString(".class." + charClass);
			dictionary params = { { "name", name }, { "class", charClassName } };
			wName.SetText(Resources::GetString(".mainmenu.character.select.name", params));
		}

		Stats::StatList@ stats = Stats::LoadList("tweak/stats.sval");

		if (svStatistics !is null)
			stats.Load(svStatistics);

		AddStatisticsToList(stats, wNewItem.m_wDetails);
	}

	void RefreshList()
	{
		auto wList = m_widget.GetWidgetById("list");
		wList.ClearChildren();

		AddGuildToList(wList);

		AddSeparatorToList(wList);
		AddClassesToList(wList);

		auto arrCharacters = GetCharacters();
		for (uint i = 0; i < arrCharacters.length(); i++)
		{
			AddSeparatorToList(wList);
			AddCharacterToList(wList, arrCharacters[i]);
		}

		DoLayout();
	}
}
