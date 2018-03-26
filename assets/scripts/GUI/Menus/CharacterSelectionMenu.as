namespace Menu
{
	class CharacterSelectionMenu : HwrMenu
	{
		CheckBoxGroupWidget@ m_wList;
		Widget@ m_wTemplate;

		ScalableSpriteButtonWidget@ m_wPlayButton;

		string m_context;

		CharacterSelectionMenu(MenuProvider@ provider, string context)
		{
			super(provider);

			m_context = context;
		}

		void Initialize(GUIDef@ def) override
		{
			@m_wList = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("list"));
			@m_wTemplate = m_widget.GetWidgetById("template");

			@m_wPlayButton = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("playbutton"));
			if (m_context != "")
				m_wPlayButton.SetText(Resources::GetString(".mainmenu.character.select.select"));

			ReloadList();
		}

		void Show() override
		{
			HwrMenu::Show();

			ReloadList();
		}

		void ReloadList()
		{
			m_wList.ClearChildren();

			auto arrCharacters = GetCharacters();
			for (uint i = 0; i < arrCharacters.length(); i++)
			{
				auto svChar = arrCharacters[i];

				string name = GetParamString(UnitPtr(), svChar, "name");
				int level = GetParamInt(UnitPtr(), svChar, "level");
				string charClass = GetParamString(UnitPtr(), svChar, "class");
				int face = GetParamInt(UnitPtr(), svChar, "face", false);
				int ngp = GetParamInt(UnitPtr(), svChar, "new-game-plus", false);

				auto wNewItem = cast<CheckBoxWidget>(m_wTemplate.Clone());
				wNewItem.SetID("");
				wNewItem.m_visible = true;
				wNewItem.m_value = "" + i;

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

				m_wList.AddChild(wNewItem);

				if (i == 0)
					wNewItem.SetChecked(true);
			}
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "new")
				OpenMenu(CharacterCreationMenu(m_provider, m_context), "gui/main_menu/character_creation.gui");
			else if (name == "play")
			{
				auto wChecked = m_wList.GetChecked();
				PickCharacter(parseInt(wChecked.GetValue()));
				FinishContext(m_context);
			}
			else if (name == "delete")
			{
				auto wChecked = cast<Widget>(m_wList.GetChecked());
				auto wName = cast<TextWidget>(wChecked.GetWidgetById("name"));
				g_gameMode.ShowDialog(
					"delete",
					Resources::GetString(".mainmenu.character.delete.text", { { "name", wName.m_str } }),
					Resources::GetString(".misc.yes"),
					Resources::GetString(".misc.no"),
					this
				);
			}
			else if (name == "delete yes")
			{
				auto wChecked = m_wList.GetChecked();
				DeleteCharacter(parseInt(wChecked.GetValue()));
				ReloadList();
			}
			else
				HwrMenu::OnFunc(sender, name);
		}
	}
}
