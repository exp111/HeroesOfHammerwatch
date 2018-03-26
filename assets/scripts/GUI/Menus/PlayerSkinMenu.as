namespace Menu
{
	class PlayerSkinMenu : Menu
	{
		array<string> m_skins = {
			"serious_sam",
			"bogus_beret",
			"canned_cain",
			"hilarious_harry",
			"marty_mcparty",
			"minotaur_mike",
			"ninja_nobody",
			"pirate_pete",
			"rocking_ryan",
			"wild_wyatt"
		};

		PlayerSkinMenu(MenuProvider@ provider)
		{
			super(provider);

			m_isPopup = true;
		}

		void Initialize(GUIDef@ def) override
		{
			auto wList = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("list"));
			if (wList is null)
				return;

			auto wTemplate = cast<CheckBoxWidget>(m_widget.GetWidgetById("template"));
			if (wTemplate is null)
				return;

			for (uint i = 0; i < m_skins.length(); i++)
			{
				string skinID = m_skins[i];

				CheckBoxWidget@ wNewItem = cast<CheckBoxWidget>(wTemplate.Clone());
				wNewItem.SetID("");
				wNewItem.m_visible = true;
				wNewItem.m_func = "set-skin " + skinID;
				wNewItem.m_value = skinID;

				SpriteWidget@ wFace = cast<SpriteWidget>(wNewItem.GetWidgetById("face"));
				if (wFace !is null)
				{
					Texture2D@ tex = Resources::GetTexture2D("actors/players/skins/" + skinID + "/hud.png");
					wFace.SetSprite(ScriptSprite(tex, vec4(96, 0, 32, 32)));
				}

				TextWidget@ wName = cast<TextWidget>(wNewItem.GetWidgetById("name"));
				if (wName !is null)
					wName.SetText(utf8string(Resources::GetString(".skin." + skinID)).toUpper().plain());

				wList.AddChild(wNewItem);
			}

			string currentSkin = GetVarString("g_plr_skin");
			if (currentSkin == "")
				currentSkin = m_skins[0];
			wList.SetChecked(currentSkin);
		}

		void OnFunc(Widget@ sender, string name) override
		{
			array<string> parse = name.split(" ");
			if (parse[0] == "set-skin")
			{
				SetVar("g_plr_skin", parse[1]);
				Config::SaveVar("g_plr_skin");
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
