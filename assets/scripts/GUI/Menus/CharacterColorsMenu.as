namespace Menu
{
	class CharacterColorsMenu : Menu
	{
		CharacterCreationMenu@ m_parent;

		CharacterColors::ClassColors@ m_classColors;
		array<UnitWidget@> m_previews;

		CharacterColorsMenu(CharacterCreationMenu@ parent, MenuProvider@ provider)
		{
			super(provider);

			@m_parent = parent;

			m_isPopup = true;
		}

		void Initialize(GUIDef@ def) override
		{
			auto wPreviews = m_widget.GetWidgetById("previews");
			int numPreview = 0;
			for (uint i = 0; i < wPreviews.m_children.length(); i++)
			{
				auto wPreview = cast<UnitWidget>(wPreviews.m_children[i]);
				if (wPreview is null)
					continue;

				wPreview.AddUnit("players/" + m_parent.m_charClass + ".unit", "idle-" + numPreview);
				numPreview++;

				m_previews.insertLast(wPreview);
			}

			@m_classColors = CharacterColors::GetClass(m_parent.m_charClass);
			if (m_classColors is null)
				PrintError("WARNING: Unsupported class '" + m_parent.m_charClass + "' for colors dialog!");
			else
			{
				SetColorGroup("color-skin", "skin", m_classColors.m_skin);
				SetColorGroup("color-1", m_classColors.m_name1, m_classColors.m_1);
				SetColorGroup("color-2", m_classColors.m_name2, m_classColors.m_2);
				SetColorGroup("color-3", m_classColors.m_name3, m_classColors.m_3);
			}

			LoadCurrentColors();
			OnColorsChanged();
		}

		void SetColorGroup(string id, string name, array<array<vec4>> arrColors)
		{
			auto wContainer = m_widget.GetWidgetById(id);

			auto wName = cast<TextWidget>(wContainer.GetWidgetById("name"));
			if (wName !is null)
				wName.SetText(Resources::GetString(name));

			auto wGroup = wContainer.GetWidgetById("colors");
			for (uint i = 0; i < wGroup.m_children.length(); i++)
			{
				auto wCheck = cast<ColorCheckBoxWidget>(wGroup.m_children[i]);
				wCheck.m_fillColor = arrColors[i][1];
			}
		}

		void LoadCurrentColors()
		{
			auto colorSet = m_parent.GetColorSet();

			auto wSkin = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-skin").GetWidgetById("colors"));
			auto w1 = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-1").GetWidgetById("colors"));
			auto w2 = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-2").GetWidgetById("colors"));
			auto w3 = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-3").GetWidgetById("colors"));

			wSkin.SetChecked(colorSet.m_colorSkin);
			w1.SetChecked(colorSet.m_color1);
			w2.SetChecked(colorSet.m_color2);
			w3.SetChecked(colorSet.m_color3);
		}

		void OnColorsChanged()
		{
			auto wSkin = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-skin").GetWidgetById("colors"));
			auto w1 = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-1").GetWidgetById("colors"));
			auto w2 = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-2").GetWidgetById("colors"));
			auto w3 = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("color-3").GetWidgetById("colors"));

			auto colorSet = m_parent.GetColorSet();

			colorSet.m_colorSkin = parseInt(wSkin.GetChecked().GetValue());
			colorSet.m_color1 = parseInt(w1.GetChecked().GetValue());
			colorSet.m_color2 = parseInt(w2.GetChecked().GetValue());
			colorSet.m_color3 = parseInt(w3.GetChecked().GetValue());

			array<array<vec4>> multicolors;
			multicolors.insertLast(m_classColors.m_skin[colorSet.m_colorSkin]);
			multicolors.insertLast(m_classColors.m_1[colorSet.m_color1]);
			multicolors.insertLast(m_classColors.m_2[colorSet.m_color2]);
			multicolors.insertLast(m_classColors.m_3[colorSet.m_color3]);

			for (uint i = 0; i < m_previews.length(); i++)
				m_previews[i].m_multiColors = multicolors;

			m_parent.ColorsChanged();
		}

		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "color-changed")
				OnColorsChanged();
			else
				Menu::OnFunc(sender, name);
		}
	}
}
