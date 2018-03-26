namespace Modifiers
{
	enum EffectTrigger
	{
		None,
		Hit,
		SpellHit,
		Hurt,
		Kill,
//		Attack,
		CastSpell,
		DrinkPotion,
		CriticalHit,
		Evade
	}

	class Modifier
	{
		void Initialize(uint itemId, uint modId) {}
	
		vec2 ArmorAdd(PlayerBase@ player, Actor@ enemy) { return vec2(); }
		float DamageTakenMul(PlayerBase@ player, DamageInfo &di) { return 1; }
		ivec2 DamageBlock(PlayerBase@ player, Actor@ enemy) { return ivec2(); }
		bool Evasion(PlayerBase@ player, Actor@ enemy) { return false; }
		bool ProjectileBlock(PlayerBase@ player, IProjectile@ proj) { return false; }
		
		ivec2 DamagePower(PlayerBase@ player, Actor@ enemy) { return ivec2(); }
		ivec2 AttackDamageAdd(PlayerBase@ player, Actor@ enemy) { return ivec2(); }
		vec2 DamageMul(PlayerBase@ player, Actor@ enemy) { return vec2(1, 1); }
		float SpellCostMul(PlayerBase@ player) { return 1; }
		
		int Crit(PlayerBase@ player, Actor@ enemy, bool spell) { return 0; }
		float CritMul(PlayerBase@ player, Actor@ enemy, bool spell) { return 1; }
		vec2 ArmorIgnore(PlayerBase@ player, Actor@ enemy, bool spell) { return vec2(1, 1); }
		float Lifesteal(PlayerBase@ player, Actor@ enemy, bool spell, int crit) { return 0; }
		
		ivec2 StatsAdd(PlayerBase@ player) { return ivec2(); }
		float MoveSpeedAdd(PlayerBase@ player) { return 0; }
		vec2 RegenAdd(PlayerBase@ player) { return vec2(); }
		vec2 RegenMul(PlayerBase@ player) { return vec2(1, 1); }
		float ExpMul(PlayerBase@ player, Actor@ enemy) { return 1; }
		
		int PotionCharges() { return 0; }
		float PotionHealMul(PlayerBase@ player) { return 1; }
		float PotionManaMul(PlayerBase@ player) { return 1; }

		float GoldRunScale() { return 1; }
		float GoldGainScale(PlayerBase@ player) { return 1; }
		float OreGainScale(PlayerBase@ player) { return 1; }
		float KeyGainScale(PlayerBase@ player) { return 1; }

		float AllHealthGainScale(PlayerBase@ player) { return 1; }
		float HealthGainScale(PlayerBase@ player) { return 1; }
		float ManaGainScale(PlayerBase@ player) { return 1; }

		int ManaFromDamage(PlayerBase@ player, int dmgAmnt) { return 0; }
		void DamageTaken(PlayerBase@ player, Actor@ enemy, int dmgAmnt) { }
		void TriggerEffects(PlayerBase@ player, Actor@ enemy, EffectTrigger trigger) { }
		array<IEffect@>@ ComboEffects(PlayerBase@ player) { return null; }
		float SkillTimeMul(PlayerBase@ player) { return 1; }
		
		void Update(PlayerBase@ player, int dt) { }
	}
	
	class FilterModifier : Modifier
	{
		Modifier@ m_modifiers;
	
		FilterModifier(UnitPtr unit, SValue& params)
		{
			auto mods = LoadModifiers(unit, params);
			if (mods.length() > 0)
				@m_modifiers = mods[0];
		}
		
		bool Filter(PlayerBase@ player, Actor@ enemy = null) { return false; }
		
		
		vec2 ArmorAdd(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.ArmorAdd(player, enemy) : vec2(); }
		float DamageTakenMul(PlayerBase@ player, DamageInfo &di) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.DamageTakenMul(player, di) : 1; }
		ivec2 DamageBlock(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.DamageBlock(player, enemy) : ivec2(); }
		bool Evasion(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.Evasion(player, enemy) : false; }
		bool ProjectileBlock(PlayerBase@ player, IProjectile@ proj) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.ProjectileBlock(player, proj) : false; }
		
		ivec2 DamagePower(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.DamagePower(player, enemy) : ivec2(); }
		ivec2 AttackDamageAdd(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.AttackDamageAdd(player, enemy) : ivec2(); }
		vec2 DamageMul(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.DamageMul(player, enemy) : vec2(1,1); }
		float SpellCostMul(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.SpellCostMul(player) : 1; }
		
		int Crit(PlayerBase@ player, Actor@ enemy, bool spell) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.Crit(player, enemy, spell) : 0; }
		float CritMul(PlayerBase@ player, Actor@ enemy, bool spell) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.CritMul(player, enemy, spell) : 1; }
		vec2 ArmorIgnore(PlayerBase@ player, Actor@ enemy, bool spell) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.ArmorIgnore(player, enemy, spell) : vec2(1, 1); }
		float Lifesteal(PlayerBase@ player, Actor@ enemy, bool spell, int crit) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.Lifesteal(player, enemy, spell, crit) : 0; }
		
		ivec2 StatsAdd(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.StatsAdd(player) : ivec2(); }
		float MoveSpeedAdd(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.MoveSpeedAdd(player) : 0; }
		vec2 RegenAdd(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.RegenAdd(player) : vec2(); }
		vec2 RegenMul(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.RegenMul(player) : vec2(1, 1); }
		float ExpMul(PlayerBase@ player, Actor@ enemy) override { return (Filter(player, enemy) && m_modifiers !is null) ? m_modifiers.ExpMul(player, enemy) : 1; }

		int PotionCharges() override { return m_modifiers !is null ? m_modifiers.PotionCharges() : 0; }
		float PotionHealMul(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.PotionHealMul(player) : 1; }
		float PotionManaMul(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.PotionManaMul(player) : 1; }

		float GoldRunScale() override { return m_modifiers !is null ? m_modifiers.GoldRunScale() : 1; }
		float GoldGainScale(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.GoldGainScale(player) : 1; }
		float OreGainScale(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.OreGainScale(player) : 1; }
		float KeyGainScale(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.KeyGainScale(player) : 1; }

		float AllHealthGainScale(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.AllHealthGainScale(player) : 1; }
		float HealthGainScale(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.HealthGainScale(player) : 1; }
		float ManaGainScale(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.ManaGainScale(player) : 1; }

		int ManaFromDamage(PlayerBase@ player, int dmgAmnt) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.ManaFromDamage(player, dmgAmnt) : 0; }
		void DamageTaken(PlayerBase@ player, Actor@ enemy, int dmgAmnt) override { if (Filter(player, enemy) && m_modifiers !is null) m_modifiers.DamageTaken(player, enemy, dmgAmnt); }
		void TriggerEffects(PlayerBase@ player, Actor@ enemy, EffectTrigger trigger) override { if (Filter(player, enemy) && m_modifiers !is null) m_modifiers.TriggerEffects(player, enemy, trigger); }
		array<IEffect@>@ ComboEffects(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.ComboEffects(player) : null; }
		float SkillTimeMul(PlayerBase@ player) override { return (Filter(player) && m_modifiers !is null) ? m_modifiers.SkillTimeMul(player) : 1; }
		
		void Update(PlayerBase@ player, int dt)  override
		{
			if (!Filter(player) || m_modifiers is null)
				return;

			m_modifiers.Update(player, dt);
		}
	}

	array<Modifier@>@ LoadModifiers(UnitPtr owner, SValue& params, string prefix = "", uint itemId = 0)
	{
		array<Modifier@> modifiers;
		
		array<SValue@>@ datArr = GetParamArray(owner, params, prefix + "modifiers", false);
		if (datArr !is null)
		{
			for (uint i = 0; i < datArr.length(); i++)
			{
				string c = GetParamString(owner, datArr[i], "class");
				auto mod = cast<Modifier>(InstantiateClass(c, owner, datArr[i]));
				if (mod !is null)
				{
					mod.Initialize(itemId, i);
					modifiers.insertLast(mod);
				}
			}
		}
		else
		{
			SValue@ dat = GetParamDictionary(owner, params, prefix + "modifier", false);
			if (dat !is null)
			{
				string c = GetParamString(owner, dat, "class");
				auto mod = cast<Modifier>(InstantiateClass(c, owner, dat));
				if (mod !is null)
				{
					mod.Initialize(itemId, 0);
					modifiers.insertLast(mod);
				}
			}
		}
		
		return modifiers;
	}

	ModifierList@ LoadModifiersList(UnitPtr owner, SValue& params, string prefix = "")
	{
		return ModifierList(LoadModifiers(owner, params, prefix));
	}
	
	EffectTrigger ParseEffectTrigger(string trigger)
	{
		if (trigger == "hit")
			return EffectTrigger::Hit;
		else if (trigger == "spellhit")
			return EffectTrigger::SpellHit;
		else if (trigger == "hurt")
			return EffectTrigger::Hurt;
		else if (trigger == "kill")
			return EffectTrigger::Kill;
		else if (trigger == "castspell")
			return EffectTrigger::CastSpell;
		else if (trigger == "drinkpotion" || trigger == "potion")
			return EffectTrigger::DrinkPotion;
		else if (trigger == "criticalhit" || trigger == "crit")
			return EffectTrigger::CriticalHit;
		else if (trigger == "evade" || trigger == "dodge")
			return EffectTrigger::Evade;
			
		return EffectTrigger::None;
	}
}

//TODO: Is this ok for multiplayer?
Modifiers::ModifierList g_allModifiers;
