namespace WorldScript
{
	[WorldScript color="210 105 30" icon="system/icons.png;96;96;32;32"]
	class RandomBuff : IUsable, IWidgetHoster
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
		
		
		RandomBuffNegative m_negativeEffect = RandomBuffNegative::None;
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
			if (name == "q yes")
			{
				m_used = true;
				if (UseScene != "")
				{
					auto units = Unit.FetchAll();
					for (uint i = 0; i < units.length(); i++)
						units[i].SetUnitScene(UseScene, true);
				}
				
				Platform::Service.UnlockAchievement("shrine");
				
				auto player = GetLocalPlayer();
			
				if (m_negativeEffect != RandomBuffNegative::TakeDamage)
					player.m_record.randomBuffNegative = player.m_record.randomBuffNegative | m_negativeEffect;
				
				array<RandomBuffPositive> possible = { MoreHp, MoreArmor, MoreExperience, MoreGold, MoreOre, MoreHPRegen, MoreMPRegen, MoreDamage };
				
				for (uint i = 0; i < possible.length(); i++)
				{
					if ((player.m_record.randomBuffPositive & possible[i]) != 0)
					{
						possible.removeAt(i);
						i--;
					}
				}

				auto positiveEffect = possible[randi(possible.length())];
				if (possible.length() > 0)
					player.m_record.randomBuffPositive = player.m_record.randomBuffPositive | positiveEffect;
				
				player.RefreshModifiers();
				
				
				if (m_negativeEffect == RandomBuffNegative::TakeDamage)
				{
					int dmg = GetRandomBuffAmount(m_negativeEffect);
					player.Damage(DamageInfo(null, dmg / 2, dmg / 2, false, true, 0), xy(player.m_unit.GetPosition()), vec2(1,0));
				}

				
				string msg = "";

				switch(positiveEffect)
				{
				case RandomBuffPositive::MoreHp:
					msg = ".random_buff.more_hp";
					break;
				case RandomBuffPositive::MoreArmor:
					msg = ".random_buff.more_armor";
					break;
				case RandomBuffPositive::MoreExperience:
					msg = ".random_buff.more_experience";
					break;
				case RandomBuffPositive::MoreGold:
					msg = ".random_buff.more_gold";
					break;
				case RandomBuffPositive::MoreOre:
					msg = ".random_buff.more_ore";
					break;
				case RandomBuffPositive::MoreHPRegen:
					msg = ".random_buff.more_hp_regen";
					break;
				case RandomBuffPositive::MoreMPRegen:
					msg = ".random_buff.more_mp_regen";
					break;
				case RandomBuffPositive::MoreDamage:
					msg = ".random_buff.more_damage";
					break;
				}
				
				if (msg != "")
					g_gameMode.ShowDialog("a",
						Resources::GetString(msg, { { "amount", GetRandomBuffAmount(positiveEffect) } }),
						Resources::GetString(".menu.ok"),
						this);
			}
		}

		void Use(PlayerBase@ player)
		{
			if (m_negativeEffect == RandomBuffNegative::None)
			{
				array<RandomBuffNegative> possible = { LowerArmor, LowerResistance, NoExperience, NoGoldGain, LowerHPRegen, LowerMPRegen, /*TakeDamage,*/ LowerDamage };
				
				if (player.m_record.MaxHealth() > GetRandomBuffAmount(LowerHp))
					possible.insertLast(LowerHp);
				
				for (uint i = 0; i < possible.length(); i++)
				{
					if ((player.m_record.randomBuffNegative & possible[i]) != 0)
					{
						possible.removeAt(i);
						i--;
					}
				}
				
				if (possible.length() <= 0)
					return;
				
				m_negativeEffect = possible[randi(possible.length())];
			}
			
			string question = "";
			
			switch(m_negativeEffect)
			{
			case RandomBuffNegative::LowerHp:
				question = ".random_buff.lower_hp";
				break;
			case RandomBuffNegative::LowerArmor:
				question = ".random_buff.lower_armor";
				break;
			case RandomBuffNegative::LowerResistance:
				question = ".random_buff.lower_resistance";
				break;
			case RandomBuffNegative::NoExperience:
				question = ".random_buff.no_experience";
				break;
			case RandomBuffNegative::NoGoldGain:
				question = ".random_buff.no_gold";
				break;
			case RandomBuffNegative::LowerHPRegen:
				question = ".random_buff.lower_hp_regen";
				break;
			case RandomBuffNegative::LowerMPRegen:
				question = ".random_buff.lower_mp_regen";
				break;
			case RandomBuffNegative::TakeDamage:
				question = ".random_buff.take_damage";
				break;
			case RandomBuffNegative::LowerDamage:
				question = ".random_buff.lower_damage";
				break;
			}
			
			
			if (question != "")
				g_gameMode.ShowDialog("q",
					Resources::GetString(question, { { "amount", GetRandomBuffAmount(m_negativeEffect) } }),
					Resources::GetString(".misc.yes"),
					Resources::GetString(".misc.no"),
					this);
		}

		UsableIcon GetIcon(Player@ player)
		{
			if (!CanUse(player))
				return Cross;

			return Speech;
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