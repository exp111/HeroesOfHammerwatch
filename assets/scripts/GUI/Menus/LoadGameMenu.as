namespace Menu
{
	class LoadGameMenu : Menu
	{
		FilteredListWidget@ m_wList;
		TextInputWidget@ m_wFilter;
		Widget@ m_wTemplate;
		MenuSaveGameWidget@ m_actingSave;

		bool m_multiplayer;
		bool m_splitscreen;

		Sprite@ m_spriteSaveGameFrame;
		Sprite@ m_spriteSaveGameFrameHover;
		Sprite@ m_spriteSaveGameFrameDown;

		LoadGameMenu(MenuProvider@ provider, bool multiplayer)
		{
			super(provider);

			m_isPopup = true;
			m_multiplayer = multiplayer;
		}

		void Initialize(GUIDef@ def) override
		{
			@m_wFilter = cast<TextInputWidget>(m_widget.GetWidgetById("filter"));
			@m_wList = cast<FilteredListWidget>(m_widget.GetWidgetById("list"));
			@m_wTemplate = m_widget.GetWidgetById("template");

			if (m_wList is null || m_wTemplate is null)
				return;

			array<string>@ arrSaves = Saves::GetSaves();
			for (uint i = 0; i < arrSaves.length(); i++)
			{
				GameSaveInfo gsi = Saves::ReadInfo("saves/" + arrSaves[i]);
				if (!gsi.Valid)
				{
					print("Invalid savegame: " + arrSaves[i]);
					continue;
				}

				if (gsi.Multiplayer != m_multiplayer)
					continue;

				if (m_splitscreen && gsi.Sessions == 1)
					continue;
				else if (!m_splitscreen && gsi.Sessions > 1)
					continue;

				MenuSaveGameWidget@ wNewSave = cast<MenuSaveGameWidget>(m_wTemplate.Clone());
				wNewSave.m_visible = true;
				wNewSave.SetID("");
				wNewSave.Set(this, gsi, arrSaves[i]);
				m_wList.AddChild(wNewSave);
			}

			@m_spriteSaveGameFrame = def.GetSprite("savegame-frame");
			@m_spriteSaveGameFrameHover = def.GetSprite("savegame-frame-hover");
			@m_spriteSaveGameFrameDown = def.GetSprite("savegame-frame-down");
		}

		void ShowLoadFailedDialog()
		{
			print("Failed to load savegame!");
			g_gameMode.ShowDialog(
				"",
				Resources::GetString(".menu.loadgame.failed"),
				Resources::GetString(".menu.ok"),
				this
			);
		}

		void OnFunc(Widget@ sender, string name) override
		{
			array<string> parse = name.split(" ");
			if (parse[0] == "load")
			{
				string filename = name.substr(5);
				print("Load: '" + filename + "'");

				if (m_splitscreen)
				{
					auto splitscreenMenu = SplitscreenSelectionMenu(m_provider);
					splitscreenMenu.m_saveGame = "saves/" + filename;
					OpenMenu(splitscreenMenu, "gui/main_menu/splitscreenselection.gui");
				}
				else if (m_multiplayer)
				{
					Close();
					//TODO: ?
					ShowLoadFailedDialog();
					/*
					if (Saves::Load("saves/" + filename))
						OpenMenu(Menu::LobbyMenu(m_provider, true), "gui/main_menu/lobby.gui");
					else
						ShowLoadFailedDialog();
					*/
				}
				else
				{
					if (!Saves::Load("saves/" + filename))
						ShowLoadFailedDialog();
				}
			}
			else if (parse[0] == "rename")
			{
				MenuSaveGameWidget@ wSave = cast<MenuSaveGameWidget>(sender.m_parent);
				if (wSave is null)
					return;

				@m_actingSave = wSave;

				string fnm = wSave.m_filename;
				string label = fnm.substr(0, fnm.length() - 4);

				g_gameMode.ShowInputDialog("rename-confirm", Resources::GetString(".menu.loadgame.rename"), this, label);
			}
			else if (parse[0] == "rename-confirm")
			{
				TextInputWidget@ wInput = cast<TextInputWidget>(sender);
				if (wInput is null)
					return;

				Saves::Rename(m_actingSave.m_filename, wInput.m_text.plain());
				m_actingSave.m_filename = wInput.m_text.plain() + ".sss";
				m_actingSave.m_label = wInput.m_text.plain();

				ButtonWidget@ wLoad = cast<ButtonWidget>(m_actingSave.GetWidgetById("load"));
				if (wLoad !is null)
					wLoad.SetText(wInput.m_text.plain());
			}
			else if (parse[0] == "delete")
			{
				MenuSaveGameWidget@ wSave = cast<MenuSaveGameWidget>(sender.m_parent);
				if (wSave is null)
					return;

				@m_actingSave = wSave;

				string fnm = wSave.m_filename;
				string label = fnm.substr(0, fnm.length() - 4);

				dictionary params = { { "label", label } };
				g_gameMode.ShowDialog("delete-confirm",
					Resources::GetString(".menu.loadgame.delete", params),
					Resources::GetString(".menu.yes"),
					Resources::GetString(".menu.no"),
					this
				);
			}
			else if (parse[0] == "delete-confirm" && parse[1] == "yes")
			{
				Saves::Delete(m_actingSave.m_filename);
				m_actingSave.RemoveFromParent();
			}
			else if (parse[0] == "filterlist")
				m_wList.SetFilter(m_wFilter.m_text.plain());
			else if (parse[0] == "filterlist-clear")
			{
				m_wFilter.ClearText();
				m_wList.ShowAll();
			}
			else
				Menu::OnFunc(sender, name);
		}
	}
}
