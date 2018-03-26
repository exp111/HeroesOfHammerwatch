namespace Menu
{
	class GameLanguagesMenu : Menu
	{
		GameLanguagesMenu(MenuProvider@ provider)
		{
			super(provider);

			m_isPopup = true;
		}

		void Initialize(GUIDef@ def) override
		{
			auto wLanguages = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("list"));
			auto wTemplate = cast<CheckBoxWidget>(m_widget.GetWidgetById("template"));
			if (wLanguages is null || wTemplate is null)
				return;

			auto arr = Platform::GetLanguages();
			for (uint i = 0; i < arr.length(); i++)
			{
				if (arr[i].id == "english")
					continue;

				auto wNewLanguage = cast<CheckBoxWidget>(wTemplate.Clone());
				wNewLanguage.m_visible = true;
				wNewLanguage.SetID("");
				wNewLanguage.m_value = arr[i].id;
				wNewLanguage.SetText(arr[i].name);
				wLanguages.AddChild(wNewLanguage);
			}

			string currentLanguage = GetVarString("g_language");
			wLanguages.SetChecked(currentLanguage);
		}

		void OnFunc(Widget@ sender, string name) override
		{
			array<string> parse = name.split(" ");
			if (parse[0] == "set-language")
			{
				auto wLanguages = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("list"));
				if (wLanguages !is null)
				{
					ICheckableWidget@ wChecked = wLanguages.GetChecked();
					if (wChecked !is null)
					{
						SetVar("g_language", wChecked.GetValue());
						Config::SaveVar("g_language");
					}
				}
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
