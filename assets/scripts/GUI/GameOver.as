class GameOver : UserWindow
{
	ScoreDialog@ m_score;

	Widget@ m_wSentences;
	Widget@ m_wSentenceTemplate;
	
	Actor@ m_killingActor;
	

	GameOver(GUIBuilder@ b)
	{
		super(b, "gui/gameover.gui");

		@m_score = ScoreDialog(b, this);
	}

	void Show(SValue@ sv)
	{
		if (m_visible)
			return;
		
		/*
		auto gm = cast<Campaign>(g_gameMode);
		if (gm !is null)
		{
			gm.SaveLocalTown();
			gm.SavePlayer(GetLocalPlayerRecord());
		}
		*/

		cast<BaseGameMode>(g_gameMode).ShowUserWindow(this);

		// Fade in animations (gotta fix this)
		int fadeTime = 1000;
		
		
		
		auto wKiller = m_widget.GetWidgetById("killer");
		if (wKiller !is null)
		{
			if (m_killingActor is null || !m_killingActor.m_unit.IsValid())
				wKiller.m_visible = false;
			else
			{
				wKiller.m_visible = true;
				
				auto killerUnit = cast<TextWidget>(wKiller.GetWidgetById("killer-unit"));
				auto plrKiller = cast<PlayerBase>(m_killingActor);
				if (plrKiller is null)
				{
					auto unit = m_killingActor.m_unit;
					auto@ unitProd = unit.GetUnitProducer();
					auto params = unitProd.GetBehaviorParams();
				
					string unitName = GetParamString(unit, params, "beastiary-name", false);
					if (unitName != "")
						killerUnit.SetText(Resources::GetString(unitName));
					
					/*
					string scene = GetParamString(unit, params, "beastiary-scene", false, "idle-3");
					killerUnit.AddUnit(unit.GetUnitScene(scene));
					killerUnit.m_offset.y = 12 + GetParamInt(unit, params, "unit-height", false, 16);
					killerUnit.m_invalidated = true;
					*/
				}
				else
				{
					auto killerRecord = plrKiller.m_record;
					
					killerUnit.SetText(killerRecord.GetName());
					
					/*
					auto classColors = CharacterColors::GetClass(killerRecord.charClass);
				
					killerUnit.AddUnit("players/" + killerRecord.charClass + ".unit", "idle-3");
					killerUnit.m_multiColors.insertLast(classColors.m_skin[killerRecord.skinColor % classColors.m_skin.length()]);
					killerUnit.m_multiColors.insertLast(classColors.m_1[killerRecord.color1 % classColors.m_1.length()]);
					killerUnit.m_multiColors.insertLast(classColors.m_2[killerRecord.color2 % classColors.m_2.length()]);
					killerUnit.m_multiColors.insertLast(classColors.m_3[killerRecord.color3 % classColors.m_3.length()]);
					
					killerUnit.m_offset.y = 12 + 16;
					killerUnit.m_invalidated = true;
					*/
				}
			}
		}
		

		auto wContainer = m_widget.GetWidgetById("container");
		if (wContainer !is null)
			wContainer.Animate(WidgetVec4Animation("border", vec4(0, 0, 0, 0), vec4(0, 0, 0, 1), fadeTime));

		auto wImage = m_widget.GetWidgetById("image");
		if (wImage !is null)
			wImage.Animate(WidgetVec4Animation("color", vec4(1, 1, 1, 0), vec4(1, 1, 1, 1), fadeTime));

		auto wContent = m_widget.GetWidgetById("content");
		if (wContent !is null)
			wContent.Animate(WidgetBoolAnimation("visible", true, fadeTime));

		auto wMock = cast<TextWidget>(m_widget.GetWidgetById("mock"));
		if (wMock !is null)
			wMock.SetText(Resources::GetString(".gameover.mock." + randi(5)));

		// Restart button
		auto wRestart = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("button_restart"));
		if (wRestart !is null)
			wRestart.m_enabled = Network::IsServer();

		auto record = GetLocalPlayerRecord();
		auto stats = record.statisticsSession;

		// Gold
		auto wGold = cast<TextWidget>(m_widget.GetWidgetById("gold"));
		if (wGold !is null)
			wGold.SetText(stats.GetStatString("gold-found"));

		// Gold stored
		auto wGoldStored = cast<TextWidget>(m_widget.GetWidgetById("gold-stored"));
		if (wGoldStored !is null)
			wGoldStored.SetText(stats.GetStatString("gold-stored"));

		// Ore
		auto wOre = cast<TextWidget>(m_widget.GetWidgetById("ore"));
		if (wOre !is null)
			wOre.SetText(stats.GetStatString("ore-found"));

		// Ore stored
		auto wOreStored = cast<TextWidget>(m_widget.GetWidgetById("ore-stored"));
		if (wOreStored !is null)
			wOreStored.SetText(stats.GetStatString("ores-stored"));
			//wOre.SetText(formatThousands(record.runOre));
			
			
		/*
		// Experience
		auto wExp = cast<TextWidget>(m_widget.GetWidgetById("exp"));
		if (wExp !is null)
			wExp.SetText(formatThousands(record.runExperience));
		
		// Time
		auto wTime = cast<TextWidget>(m_widget.GetWidgetById("time"));
		if (wTime !is null)
			wTime.SetText(stats.GetStatString("time-played"));

		// Kills
		auto wKills = cast<TextWidget>(m_widget.GetWidgetById("kills"));
		if (wKills !is null)
			wKills.SetText(stats.GetStatString("enemies-killed"));
		*/
		
			
		// Sentences
		@m_wSentences = m_widget.GetWidgetById("sentences");
		@m_wSentenceTemplate = m_widget.GetWidgetById("sentence-template");

		array<string> possibleSentences = FindPossibleSentences(record);

		for (int i = 0; i < min(int(possibleSentences.length()), 4); i++)
		{
			int index = randi(possibleSentences.length());
			AddSentence(possibleSentences[index]);
			possibleSentences.removeAt(index);
		}

		g_gameMode.ReplaceTopWidgetRoot(this);

		// Score screen (to be removed?)
		string diffName = GetCurrentDifficultyName();
		dictionary params = { { "diff", utf8string(diffName).toUpper().plain() } };
		m_score.Set(sv, Resources::GetString(".dead.gameover", params));
	}

	void Close() override
	{
		// Do nothing
	}

	void AddSentence(string text)
	{
		auto wNewText = cast<TextWidget>(m_wSentenceTemplate.Clone());
		wNewText.SetID("");
		wNewText.m_visible = true;
		wNewText.SetText(text);
		m_wSentences.AddChild(wNewText);
	}

	array<string> FindPossibleSentences(PlayerRecord@ record)
	{
		array<string> ret;

		auto stats = record.statisticsSession;

		if (g_flags.IsSet("unlock_apothecary"))
		{
			// "You never used your potion!"
			int unusedPotions = ((1 + g_allModifiers.PotionCharges()) - record.potionChargesUsed);
			if (unusedPotions == 0)
				ret.insertLast(Resources::GetString(".gameover.sentence.unused-potion.none"));
			else if (unusedPotions == 1)
				ret.insertLast(Resources::GetString(".gameover.sentence.unused-potion.one"));
			else if (unusedPotions > 0)
				ret.insertLast(Resources::GetString(".gameover.sentence.unused-potion.plural", { { "num", unusedPotions } }));
			else
				ret.insertLast(Resources::GetString(".gameover.sentence.unused-potion.never"));
		}

		// "X keys remain unused."
		int unusedKeys = 0;
		for (uint i = 0; i < record.keys.length(); i++)
			unusedKeys += record.keys[i];
		if (unusedKeys == 1)
			ret.insertLast(Resources::GetString(".gameover.sentence.unused-keys.one"));
		else if (unusedKeys > 0)
			ret.insertLast(Resources::GetString(".gameover.sentence.unused-keys.plural", { { "num", unusedKeys } }));

		// "You died with a lot of unused mana!"
		if (record.mana > 0.9f)
			ret.insertLast(Resources::GetString(".gameover.sentence.unused-mana"));

		// "You're rich!"
		int goldStored = stats.GetStatInt("gold-stored");
		if (goldStored == 0)
			ret.insertLast(Resources::GetString(".gameover.sentence.gold.none"));
		else if (goldStored > 5000)
			ret.insertLast(Resources::GetString(".gameover.sentence.gold.rich"));

		// "You died the first minute."
		if (stats.GetStatInt("time-played") < 60)
			ret.insertLast(Resources::GetString(".gameover.sentence.first-minute"));
		else
			ret.insertLast(Resources::GetString(".gameover.sentence.time", { { "time", stats.GetStatString("time-played") } }));

		// "You wasted X ore."
		int oreFound = stats.GetStatInt("ore-found");
		int oreStored = stats.GetStatInt("ores-stored");
		int oreWasted = oreFound - oreStored;
		if (oreWasted == 1)
			ret.insertLast(Resources::GetString(".gameover.sentence.ore.one"));
		else if (oreWasted > 1)
			ret.insertLast(Resources::GetString(".gameover.sentence.ore.plural", { { "num", oreWasted } }));

		// "You didn't kill any enemies!"
		if (stats.GetStatInt("enemies-killed") == 0)
			ret.insertLast(Resources::GetString(".gameover.sentence.no-enemies"));

		// "You opened X chests."
		int numChests = stats.GetStatInt("chests-opened");
		if (numChests == 1)
			ret.insertLast(Resources::GetString(".gameover.sentence.chests.one"));
		else
			ret.insertLast(Resources::GetString(".gameover.sentence.chests.plural", { { "num", numChests } }));

		// "You took X damage."
		int numDamageTaken = stats.GetStatInt("damage-taken");
		ret.insertLast(Resources::GetString(".gameover.sentence.damage-taken", { { "num", numDamageTaken } }));

		// "You picked up X items."
		int numPickedItems = stats.GetStatInt("items-picked");
		if (numPickedItems == 1)
			ret.insertLast(Resources::GetString(".gameover.sentence.items-picked.one"));
		else
			ret.insertLast(Resources::GetString(".gameover.sentence.items-picked.plural", { { "num", numPickedItems } }));

		// "You visited X floors."
		int numVisitedFloors = stats.GetStatInt("floors-visited");
		if (numVisitedFloors == 1)
			ret.insertLast(Resources::GetString(".gameover.sentence.floors.one"));
		else
			ret.insertLast(Resources::GetString(".gameover.sentence.floors.plural", { { "num", numVisitedFloors } }));

		// "You traveled X km."
		int numTraveledUnits = stats.GetStatInt("units-traveled");
		ret.insertLast(Resources::GetString(".gameover.sentence.units", { { "meters", formatMeters(numTraveledUnits) } }));

		// "You lost X experience."
		int xpLoss = int(float(record.experience - record.LevelExperience(record.level - 1)) * Tweak::DeathExperienceLoss);
		if (xpLoss > 0)
			ret.insertLast(Resources::GetString(".gameover.sentence.experience", { { "num", xpLoss } }));

		return ret;
	}

	void Update(int dt) override
	{
		if (!m_visible)
			return;

		IWidgetHoster::Update(dt);

		m_score.Update(dt);
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		if (!m_visible)
			return;

		UserWindow::Draw(sb, idt);

		m_score.Draw(sb, idt);
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "score")
		{
			g_gameMode.RemoveWidgetRoot(this);
			m_score.Show();
		}
		else if (name == "restart" && Network::IsServer())
		{
			auto gm = cast<BaseGameMode>(g_gameMode);
			if (gm !is null)
				gm.RestartGame();
		}
		else if (name == "exit")
		{
			PauseGame(false, false);
			StopScenario();
			return;
		}
		else if (name == "scoreclose")
			g_gameMode.ReplaceTopWidgetRoot(this);
		else
			UserWindow::OnFunc(sender, name);
	}
}
