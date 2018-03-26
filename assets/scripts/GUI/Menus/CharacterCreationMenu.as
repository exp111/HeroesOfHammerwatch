namespace Menu
{
	class CharacterColorSet
	{
		CharacterColors::ClassColors@ m_classColors;

		int m_colorSkin;
		int m_color1;
		int m_color2;
		int m_color3;
	}

	class CharacterCreationMenu : HwrMenu
	{
		MarkovName@ m_randomNameGen;

		string m_context;

		TextInputWidget@ m_wName;
		SpriteWidget@ m_wFace;

		CheckBoxGroupWidget@ m_wGroupClass;
		SliderWidget@ m_wVoicePitch;

		array<UnitWidget@> m_wPreviews;
		array<ScriptSprite@> m_faces;

		string m_charClass;
		array<CharacterColorSet@> m_charColors;
		int m_face;
		float m_voice;

		CharacterCreationMenu(MenuProvider@ provider, string context)
		{
			super(provider);

			m_context = context;
			m_closeAfterContext = true;

			//m_isPopup = true;
		}

		void Initialize(GUIDef@ def) override
		{
			array<string> names = {
				/*
				"mary", "patricia", "linda", "barbara", "elizabeth", "jennifer", "maria", "susan", "margaret", "dorothy", "lisa", "nancy", "karen", "betty", "helen", "sandra",
				"donna", "carol", "ruth", "sharon", "michelle", "laura", "sarah", "kimberly", "deborah", "james", "john", "robert", "michael", "william", "david", "richard",
				"charles", "joseph", "thomas", "christopher", "daniel", "paul", "mark", "donald", "george", "kenneth", "steven", "edward", "brian", "ronald", "anthony", "kevin",
				"jason", "matthew"
				*/
				"mary", "patricia", "linda", /*"barbara",*/ "elizabeth", "jennifer", "maria", "susan", "margaret", "dorothy", "lisa", "nancy", "karen", "betty", "helen", "sandra",
				"donna", "carol", "ruth", "sharon", "michelle", "laura", "sarah", "kimberly", "deborah", "jessica", "shirley", "cynthia", "angela", "melissa", "brenda", "amy",
				"anna", "rebecca", "virginia", "kathleen", "pamela", "martha", "debra", "amanda", "stephanie", "carolyn", "christine", "marie", "janet", "catherine", "frances",
				"ann", "joyce", "diane", "james", "john", "robert", "michael", "william", "david", "richard", "charles", "joseph", "thomas", "christopher", "daniel", "paul",
				"mark", "donald", "george", "kenneth", "steven", "edward", "brian", "ronald", "anthony", "kevin", "jason", "matthew", "gary", "timothy", "jose", "larry", "jeffrey",
				"frank", "scott", "eric", "stephen", "andrew", "raymond", "gregory", "joshua", "jerry", "dennis", "walter", "patrick", "peter", "harold", "douglas", "henry", "carl",
				"arthur", "ryan", "roger"
			};
			@m_randomNameGen = MarkovName(names);

			@m_wName = cast<TextInputWidget>(m_widget.GetWidgetById("name"));
			m_wName.SetText(m_randomNameGen.GenerateName());

			@m_wFace = cast<SpriteWidget>(m_widget.GetWidgetById("face"));

			@m_wGroupClass = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("group-class"));

			@m_wVoicePitch = cast<SliderWidget>(m_widget.GetWidgetById("voice-pitch"));

			for (uint i = 0; i < m_wGroupClass.m_children.length(); i++)
			{
				auto wCheckbox = cast<CheckBoxWidget>(m_wGroupClass.m_children[i]);

				string className = wCheckbox.GetValue();
				wCheckbox.m_enabled = IsClassUnlocked(className);

				wCheckbox.m_tooltipTitle = Resources::GetString(".class." + className);
				if (wCheckbox.m_enabled)
					wCheckbox.m_tooltipText = Resources::GetString(".class." + className + ".desc");
				else
					wCheckbox.m_tooltipText = Resources::GetString(".class." + className + ".disabled.desc");

				auto classColors = CharacterColors::GetClass(className);

				auto newSet = CharacterColorSet();
				@newSet.m_classColors = classColors;
				newSet.m_colorSkin = randi(classColors.m_skin.length());
				newSet.m_color1 = randi(classColors.m_1.length());
				newSet.m_color2 = randi(classColors.m_2.length());
				newSet.m_color3 = randi(classColors.m_3.length());
				m_charColors.insertLast(newSet);

				auto wPreview = cast<UnitWidget>(wCheckbox.GetWidgetById("preview"));
				wPreview.ClearUnits();

				auto uws = wPreview.AddUnit("players/" + className + ".unit", "idle-3");
				if (uws !is null)
					uws.m_offset = vec2(3, 3);

				m_wPreviews.insertLast(wPreview);
			}

			m_wGroupClass.SetCheckedRandom();
			ClassChanged();
			ColorsChanged();

			m_face = randi(m_faces.length());
			FaceChanged();

			m_voice = randf();

			if (m_wVoicePitch !is null)
				m_wVoicePitch.SetValue(m_voice);
		}

		CharacterColorSet@ GetColorSet()
		{
			return GetColorSet(m_charClass);
		}

		CharacterColorSet@ GetColorSet(string id)
		{
			for (uint i = 0; i < m_charColors.length(); i++)
			{
				if (m_charColors[i].m_classColors.m_id == id)
					return m_charColors[i];
			}
			return null;
		}

		bool IsBuildingLevel(string id, int level)
		{
			auto gm = cast<MainMenu>(g_gameMode);

			auto building = gm.m_town.GetBuilding(id);
			if (building is null)
				return false;

			return (building.m_level >= level);
		}

		bool IsClassUnlocked(string className)
		{
			if (className == "thief")
				return IsBuildingLevel("tavern", 1);

			if (className == "priest")
				return IsBuildingLevel("chapel", 1);

			if (className == "wizard")
			 	return IsBuildingLevel("magicshop", 1);

			if (className == "paladin" || className == "ranger" || className == "sorcerer" || className == "warlock")
				return true;

			return false;
		}

		void ClassChanged()
		{
			m_charClass = m_wGroupClass.GetChecked().GetValue();

			SValue@ svalClass = Resources::GetSValue("players/" + m_charClass + "/char.sval");
			if (svalClass is null)
			{
				PrintError("Couldn't get SValue file for class \"" + m_charClass + "\"");
				return;
			}

			int faceY = GetParamInt(UnitPtr(), svalClass, "face-y");
			int faceCount = GetParamInt(UnitPtr(), svalClass, "face-count");

			m_faces.removeRange(0, m_faces.length());
			for (int i = 0; i < faceCount; i++)
			{
				auto sprite = ScriptSprite(Resources::GetTexture2D("gui/icons_faces.png"), vec4(i * 24, faceY, 24, 24));
				m_faces.insertLast(sprite);
			}

			m_face = randi(m_faces.length());
			FaceChanged();

			auto arrClassSkills = GetParamArray(UnitPtr(), svalClass, "skills");

			for (uint i = 0; i < uint(min(arrClassSkills.length(), 7)); i++)
			{
				string skillFnm = arrClassSkills[i].GetString();
				auto skill = Resources::GetSValue(skillFnm);

				string skillName = GetParamString(UnitPtr(), skill, "name");
				string skillDesc = skillName + ".create";

				auto arrIcon = GetParamArray(UnitPtr(), skill, "icon");
				auto spriteIcon = ScriptSprite(arrIcon);

				auto wSkillIcon = cast<SpriteWidget>(m_widget.GetWidgetById("skill-" + i));
				wSkillIcon.SetSprite(spriteIcon);

				wSkillIcon.m_tooltipTitle = Resources::GetString(skillName);
				wSkillIcon.m_tooltipText = Resources::GetString(skillDesc);
			}
		}

		void FaceChanged()
		{
			if (m_faces.length() == 0 || m_face >= int(m_faces.length()))
				return;
			m_wFace.SetSprite(m_faces[m_face]);
		}

		void ColorsChanged()
		{
			for (uint i = 0; i < m_wPreviews.length(); i++)
			{
				UnitWidget@ w = m_wPreviews[i];
				auto colorSet = m_charColors[i];
				auto classColors = colorSet.m_classColors;
				w.m_multiColors.removeRange(0, w.m_multiColors.length());
				w.m_multiColors.insertLast(classColors.m_skin[colorSet.m_colorSkin]);
				w.m_multiColors.insertLast(classColors.m_1[colorSet.m_color1]);
				w.m_multiColors.insertLast(classColors.m_2[colorSet.m_color2]);
				w.m_multiColors.insertLast(classColors.m_3[colorSet.m_color3]);
			}
		}

		int ColorLeft(int num, int max)
		{
			if (--num < 0)
				num = max - 1;
			return num;
		}

		int ColorRight(int num, int max)
		{
			if (++num >= max)
				num = 0;
			return num;
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto parse = name.split(" ");
			if (name == "class-changed")
				ClassChanged();
			else if (name == "random-name")
				m_wName.SetText(m_randomNameGen.GenerateName());
			else if (parse[0] == "face-left")
			{
				if (--m_face < 0)
					m_face = int(m_faces.length()) - 1;
				FaceChanged();
			}
			else if (parse[0] == "face-right")
			{
				if (++m_face >= int(m_faces.length()))
					m_face = 0;
				FaceChanged();
			}
			else if (parse[0] == "voice-changed")
			{
				m_voice = m_wVoicePitch.GetValue();
			}
			else if (name == "colors")
				OpenMenu(CharacterColorsMenu(this, m_provider), "gui/main_menu/character_colors.gui");
			else if (name == "create-character")
			{
				auto colorSet = GetColorSet();

				SValueBuilder builder;
				builder.PushDictionary();
				builder.PushString("name", m_wName.m_text.plain());
				builder.PushString("class", m_charClass);
				builder.PushString("class", m_charClass);
				builder.PushInteger("color-skin", colorSet.m_colorSkin);
				builder.PushInteger("color-1", colorSet.m_color1);
				builder.PushInteger("color-2", colorSet.m_color2);
				builder.PushInteger("color-3", colorSet.m_color3);
				builder.PushInteger("face", m_face);
				builder.PushFloat("voice", m_voice);

				// Without this, the character list shows level 0
				builder.PushInteger("level", 1);

				CreateCharacter(builder.Build());
				PickCharacter(0);
				FinishContext(m_context);
			}
			else
				HwrMenu::OnFunc(sender, name);
		}
	}
}
