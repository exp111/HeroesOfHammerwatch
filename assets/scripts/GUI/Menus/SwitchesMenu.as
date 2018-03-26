namespace Menu
{
	class SwitchesMenu : Menu
	{
		ScenarioInfo@ m_scenario;
		Menu@ m_receiver;

		array<ScenarioModification@>@ m_allMods;
		array<string> m_preEnabledMods;

		bool m_multiplayer;

		SwitchesMenu(MenuProvider@ provider, Menu@ receiver, ScenarioInfo@ scenario, array<string> enabledMods, bool multiplayer)
		{
			super(provider);

			@m_scenario = scenario;
			@m_receiver = receiver;

			m_preEnabledMods = enabledMods;
			m_multiplayer = multiplayer;

			m_isPopup = true;
		}

		CheckBoxGroupWidget@ MakeRadioGroup(string id)
		{
			Widget@ wTemplateRadioGroup = m_widget.GetWidgetById("template-radiogroup");
			CheckBoxGroupWidget@ ret = cast<CheckBoxGroupWidget>(wTemplateRadioGroup.Clone());
			ret.SetID("modgroup-" + id);
			ret.m_visible = true;
			ret.m_func = "toggle-radio " + id;
			ret.m_dynamicSize = false;
			return ret;
		}

		void Initialize(GUIDef@ def) override
		{
			Widget@ wList = m_widget.GetWidgetById("list");
			if (wList is null)
				return;

			Widget@ wTemplateCheck = m_widget.GetWidgetById("template-check");
			Widget@ wTemplateRadio = m_widget.GetWidgetById("template-radio");
			Widget@ wTemplateSeparator = m_widget.GetWidgetById("template-separator");
			Widget@ wTemplateHeader = m_widget.GetWidgetById("template-header");
			if (wTemplateCheck is null || wTemplateRadio is null || wTemplateSeparator is null || wTemplateHeader is null)
				return;

			@m_allMods = m_scenario.GetModifications();

			CheckBoxGroupWidget@ wCurrentRadioGroup = null;

			for (uint i = 0; i < m_allMods.length(); i++)
			{
				ScenarioModification@ mod = m_allMods[i];

				if (mod.GetMultiplayer() && !m_multiplayer)
					continue;

				string radioGroup = mod.GetRadioGroup();
				if (wCurrentRadioGroup is null && radioGroup != "")
				{
					@wCurrentRadioGroup = MakeRadioGroup(radioGroup);
					wList.AddChild(wCurrentRadioGroup);
				}
				else if (wCurrentRadioGroup !is null)
				{
					if (radioGroup == "")
						@wCurrentRadioGroup = null;
					else if (wCurrentRadioGroup.m_id != "modgroup-" + radioGroup)
					{
						@wCurrentRadioGroup = MakeRadioGroup(radioGroup);
						wList.AddChild(wCurrentRadioGroup);
					}
				}

				Widget@ wNewItem = null;

				if (mod.GetVisual() == ScenarioModificationVisual::None)
				{
					if (wCurrentRadioGroup is null)
						@wNewItem = wTemplateCheck.Clone();
					else
						@wNewItem = wTemplateRadio.Clone();
					wNewItem.m_visible = true;
					wNewItem.SetID("");

					CheckBoxWidget@ wCheck = cast<CheckBoxWidget>(wNewItem.GetWidgetById("checkbox"));
					if (wCheck !is null)
					{
						wCheck.SetID("mod-" + mod.GetID());
						wCheck.SetText(Resources::GetString(mod.GetName()));
						wCheck.m_tooltipText = Resources::GetString(mod.GetTooltip());
						if (wCurrentRadioGroup is null)
							wCheck.m_func = "toggle " + mod.GetID();
						wCheck.m_checked = (m_preEnabledMods.find(mod.GetID()) != -1);
					}
				}
				else if (mod.GetVisual() == ScenarioModificationVisual::Separator)
				{
					@wNewItem = wTemplateSeparator.Clone();
					wNewItem.m_visible = true;
					wNewItem.SetID("");
				}
				else if (mod.GetVisual() == ScenarioModificationVisual::Header)
				{
					@wNewItem = wTemplateHeader.Clone();
					wNewItem.m_visible = true;
					wNewItem.SetID("");

					TextWidget@ wText = cast<TextWidget>(wNewItem.GetWidgetById("text"));
					if (wText !is null)
					{
						wText.SetText(Resources::GetString(mod.GetName()));
						wText.m_tooltipText = Resources::GetString(mod.GetTooltip());
					}
				}

				if (wNewItem !is null)
				{
					if (wCurrentRadioGroup !is null)
					{
						wCurrentRadioGroup.AddChild(wNewItem);
						wCurrentRadioGroup.m_height += wNewItem.m_height;
					}
					else
						wList.AddChild(wNewItem);
				}
			}

			UpdateLockedState();

			DoLayout();
		}

		void UpdateLockedState()
		{
			for (uint i = 0; i < m_allMods.length(); i++)
			{
				ScenarioModification@ mod = m_allMods[i];

				CheckBoxWidget@ wCheck = cast<CheckBoxWidget>(m_widget.GetWidgetById("mod-" + mod.GetID()));
				if (wCheck is null)
					continue;

				string lockedBy = mod.GetLockedBy();
				if (lockedBy == "")
					continue;

				wCheck.m_enabled = true;

				array<string> arrLockedBy = lockedBy.split(",");
				for (uint j = 0; j < arrLockedBy.length(); j++)
				{
					CheckBoxWidget@ wCheckLocker = cast<CheckBoxWidget>(m_widget.GetWidgetById("mod-" + arrLockedBy[j]));
					if (wCheckLocker is null)
						continue;

					if (wCheckLocker.m_checked)
					{
						if (wCheck.m_checked)
						{
							wCheck.m_checked = false;
							OnFunc(null, "toggle " + mod.GetID() + " off");
						}
						wCheck.m_enabled = false;
						break;
					}
				}
			}
		}

		void OnFunc(Widget@ sender, string name) override
		{
			auto parse = name.split(" ");
			if (parse[0] == "toggle")
			{
				CheckBoxWidget@ wCheck = cast<CheckBoxWidget>(m_widget.GetWidgetById("mod-" + parse[1]));
				if (wCheck !is null)
					m_receiver.OnFunc(sender, "set-mod " + parse[1] + " " + (wCheck.m_checked ? "on" : "off"));

				UpdateLockedState();
			}
			else if (parse[0] == "toggle-radio")
			{
				CheckBoxGroupWidget@ wGroup = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("modgroup-" + parse[1]));
				if (wGroup !is null)
				{
					for (uint i = 0; i < wGroup.m_checkboxes.length(); i++)
					{
						CheckBoxWidget@ wCheck = cast<CheckBoxWidget>(wGroup.m_checkboxes[i]);
						m_receiver.OnFunc(sender, "set-mod " + wCheck.m_id.substr(4) + " " + (wCheck.IsChecked() ? "on" : "off"));
					}
				}

				UpdateLockedState();
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
