namespace WorldScript
{
	enum RandomStuffEffect
	{
		None,
		GiveItem,
		GiveOre,
		GiveGold,
		GiveExperience,
		GiveKeys,
		DepositGold,
		DepositOre,
		Rejuvenate
	}


	[WorldScript color="210 105 30" icon="system/icons.png;96;96;32;32"]
	class RandomStuff : IUsable, IWidgetHoster
	{
		bool Enabled;

		[Editable]
		array<CollisionArea@>@ Areas;
		
		[Editable default=0]
		int Act;
		
		[Editable]
		UnitFeed Unit;
		[Editable]
		string UseScene;

		
		RandomStuffEffect m_activeEffect = RandomStuffEffect::None;
		bool m_used = false;
		
		
		void Initialize()
		{
			for (uint i = 0; i < Areas.length(); i++)
			{
				Areas[i].AddOnEnter(this, "OnEnter");
				Areas[i].AddOnExit(this, "OnExit");
			}
		}
		
		Player@ GetPlayer(UnitPtr unit)
		{
			if (!unit.IsValid())
				return null;
			
			ref@ behavior = unit.GetScriptBehavior();
			
			if (behavior is null)
				return null;
		
			return cast<Player>(behavior);
		}
		
		void OnEnter(UnitPtr unit, vec2 pos, vec2 normal)
		{
			Player@ plr = GetPlayer(unit);
			if (plr !is null)
				plr.AddUsable(this);
		}
		
		void OnExit(UnitPtr unit)
		{
			Player@ plr = GetPlayer(unit);
			if (plr !is null)
				plr.RemoveUsable(this);
		}
		
		UnitPtr GetUseUnit()
		{
			return WorldScript::GetWorldScript(g_scene, this).GetUnit();
		}

		bool CanUse(PlayerBase@ player)
		{
			if (!Enabled)
				return false;
		
			if (m_used && player.m_record.local)
				return false;

			return true;
		}
		
		void OnFunc(Widget@ sender, string name) override
		{
			if (name == "q yes" || name == "q")
			{
				m_used = true;
				if (UseScene != "")
				{
					auto units = Unit.FetchAll();
					for (uint i = 0; i < units.length(); i++)
						units[i].SetUnitScene(UseScene, true);
				}
				
				Platform::Service.UnlockAchievement("imp");
				
				auto player = GetLocalPlayer();
			
				switch(m_activeEffect)
				{
				case RandomStuffEffect::GiveItem:
					GiveItemImpl(g_items.TakeRandomItem(ActorItemQuality::Common), player, true);
					break;
					
				case RandomStuffEffect::GiveOre:
					GiveOreImpl(int(pow(1.75f, Act) * 2 + 0.5f), player);
					break;

				case RandomStuffEffect::GiveGold:
					GiveGoldImpl(int(pow(2, Act)) * 750, player);
					break;

				case RandomStuffEffect::GiveExperience:
				{
					int xp = (player.m_record.LevelExperience(player.m_record.level) - player.m_record.LevelExperience(player.m_record.level - 1)) / 3;
					player.m_record.GiveExperience(int(xp * g_allModifiers.ExpMul(player, null)));
					break;
				}

				case RandomStuffEffect::GiveKeys:
				{
					player.m_record.keys[0]++;
					Stats::Add("key-found-" + 0, 1, player.m_record);
					(Network::Message("PlayerGiveKey") << 0 << 1).SendToAll();
					
					player.m_record.keys[1]++;
					Stats::Add("key-found-" + 1, 1, player.m_record);
					(Network::Message("PlayerGiveKey") << 1 << 1).SendToAll();
					
					player.m_record.keys[2]++;
					Stats::Add("key-found-" + 2, 1, player.m_record);
					(Network::Message("PlayerGiveKey") << 2 << 1).SendToAll();
					
					if (randi(100) < 50)
					{
						player.m_record.keys[3]++;
						Stats::Add("key-found-" + 3, 1, player.m_record);
						(Network::Message("PlayerGiveKey") << 3 << 1).SendToAll();
					}
					break;
				}
				
				case RandomStuffEffect::DepositGold:
				{
					int takeGold = player.m_record.runGold;
					player.m_record.runGold = 0;
					
					cast<Campaign>(g_gameMode).m_townLocal.m_gold += takeGold;
					Stats::Add("gold-stored", takeGold, player.m_record);

					break;
				}
					
				case RandomStuffEffect::DepositOre:
				{
					int takeOre = player.m_record.runOre;
					player.m_record.runOre = 0;
					
					cast<Campaign>(g_gameMode).m_townLocal.m_ore += takeOre;
					Stats::Add("ores-stored", takeOre, player.m_record);
			
					break;
				}
				
				case RandomStuffEffect::Rejuvenate:
				{
					player.m_record.potionChargesUsed = 0;
					player.m_record.hp = 1.0f;
					player.m_record.mana = 1.0f;

					AddFloatingText(FloatingTextType::Pickup, Resources::GetString(".hud.potionrefill"), player.m_unit.GetPosition());
					break;
				}
				}
			}
		}

		void Use(PlayerBase@ player)
		{
			if (m_activeEffect == RandomStuffEffect::None)
			{
				array<RandomStuffEffect> possible = { GiveItem, GiveOre, GiveGold, GiveExperience, GiveKeys, DepositGold };
			
				if (!g_flags.IsSet("mines_elevator") && !g_flags.IsSet("prison_elevator") && !g_flags.IsSet("armory_elevator") && !g_flags.IsSet("archives_elevator") && !g_flags.IsSet("chambers_elevator"))
					possible.insertLast(RandomStuffEffect::DepositOre);
				if (!g_flags.IsSet("mines_well") && !g_flags.IsSet("prison_well") && !g_flags.IsSet("armory_well") && !g_flags.IsSet("archives_well") && !g_flags.IsSet("chambers_well"))
					possible.insertLast(RandomStuffEffect::Rejuvenate);
			
				m_activeEffect = possible[randi(possible.length())];
			}
			
			switch(m_activeEffect)
			{
			case RandomStuffEffect::GiveItem:
				g_gameMode.ShowDialog("q", 
					Resources::GetString(".random_stuff.give_item"), 
					Resources::GetString(".menu.ok"), this);
				break;
			case RandomStuffEffect::GiveOre:
				g_gameMode.ShowDialog("q", 
					Resources::GetString(".random_stuff.give_ore"), 
					Resources::GetString(".menu.ok"), this);
				break;
			case RandomStuffEffect::GiveGold:
				g_gameMode.ShowDialog("q", 
					Resources::GetString(".random_stuff.give_gold"), 
					Resources::GetString(".menu.ok"), this);
				break;
			case RandomStuffEffect::GiveExperience:
				g_gameMode.ShowDialog("q", 
					Resources::GetString(".random_stuff.give_experience"), 
					Resources::GetString(".menu.ok"), this);
				break;
			case RandomStuffEffect::GiveKeys:
				g_gameMode.ShowDialog("q", 
					Resources::GetString(".random_stuff.give_keys"), 
					Resources::GetString(".menu.ok"), this);
				break;
			case RandomStuffEffect::DepositGold:
				g_gameMode.ShowDialog("q",
					Resources::GetString(".random_stuff.deposit_gold"),
					Resources::GetString(".misc.yes"),
					Resources::GetString(".misc.no"),
					this
				);
				break;
			case RandomStuffEffect::DepositOre:
				g_gameMode.ShowDialog("q",
					Resources::GetString(".random_stuff.deposit_ore"),
					Resources::GetString(".misc.yes"),
					Resources::GetString(".misc.no"),
					this
				);
				break;
			case RandomStuffEffect::Rejuvenate:
				g_gameMode.ShowDialog("q", 
					Resources::GetString(".random_stuff.rejuvenate"), 
					Resources::GetString(".menu.ok"), this);
				break;
			}
		}

		UsableIcon GetIcon(Player@ player)
		{
			if (!Enabled)
				return UsableIcon::None;
		
			if (!CanUse(player))
				return UsableIcon::Cross;

			return UsableIcon::Speech;
		}
		
		SValue@ Save()
		{
			SValueBuilder sval;
			sval.PushBoolean(m_used);
			return sval.Build();
		}
		
		void Load(SValue@ data)
		{
			m_used = data.GetBoolean();
		}
		
		void NetUse(PlayerHusk@ player) { }
		void DoLayout() override { }
		void Update(int dt) override { }
		void Draw(SpriteBatch& sb, int idt) override { }
		void UpdateInput(vec2 origin, vec2 parentSz, vec3 mousePos) override { }
	}
}