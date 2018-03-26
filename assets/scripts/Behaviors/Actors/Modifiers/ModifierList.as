namespace Modifiers
{
	class ModifierList : Modifier
	{
		string m_name;
		array<Modifier@> m_modifiers;

		ModifierList()
		{
		}

		ModifierList(array<Modifier@> modifiers)
		{
			m_modifiers.insertAt(m_modifiers.length(), modifiers);
		}

		void Clear()
		{
			m_modifiers.removeRange(0, m_modifiers.length());
		}

		void Add(Modifier@ modifier)
		{
			m_modifiers.insertLast(modifier);
		}

		void Remove(Modifier@ modifier)
		{
			int index = m_modifiers.findByRef(modifier);
			if (index == -1)
				return;
			m_modifiers.removeAt(index);
		}

		int NumberModifiers()
		{
			int ret = 0;
			for (uint i = 0; i < m_modifiers.length(); i++)
			{
				auto list = cast<ModifierList>(m_modifiers[i]);
				if (list !is null)
					ret += list.NumberModifiers();
				else
					ret++;
			}
			return ret;
		}

		void DumpModifiers(int indent = 0)
		{
			string indentStr = "";
			for (int i = 0; i < indent; i++)
				indentStr += "  ";

			for (uint i = 0; i < m_modifiers.length(); i++)
			{
				auto list = cast<ModifierList>(m_modifiers[i]);
				if (list !is null)
				{
					print(indentStr + "* List \"" + list.m_name + "\"");
					list.DumpModifiers(indent + 1);
				}
				else
					print(indentStr + "* " + Reflect::GetTypeName(m_modifiers[i]));
			}
		}

		vec2 ArmorAdd(PlayerBase@ player, Actor@ enemy) override { vec2 ret; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].ArmorAdd(player, enemy); } return ret; }
		float DamageTakenMul(PlayerBase@ player, DamageInfo &di) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].DamageTakenMul(player, di); } return ret; }
		ivec2 DamageBlock(PlayerBase@ player, Actor@ enemy) override { ivec2 ret; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].DamageBlock(player, enemy); } return ret; }
		bool Evasion(PlayerBase@ player, Actor@ enemy) override { for (uint i = 0; i < m_modifiers.length(); i++) { if (m_modifiers[i].Evasion(player, enemy)) return true; } return false; }
		bool ProjectileBlock(PlayerBase@ player, IProjectile@ proj) override { for (uint i = 0; i < m_modifiers.length(); i++) { if (m_modifiers[i].ProjectileBlock(player, proj)) return true; } return false; }

		ivec2 DamagePower(PlayerBase@ player, Actor@ enemy) override { ivec2 ret; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].DamagePower(player, enemy); } return ret; }
		ivec2 AttackDamageAdd(PlayerBase@ player, Actor@ enemy) override { ivec2 ret; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].AttackDamageAdd(player, enemy); } return ret; }
		vec2 DamageMul(PlayerBase@ player, Actor@ enemy) override { vec2 ret(1,1); for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].DamageMul(player, enemy) - vec2(1,1); } return ret; }
		float SpellCostMul(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].SpellCostMul(player); } return ret; }

		int Crit(PlayerBase@ player, Actor@ enemy, bool spell) override { int ret = 0; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].Crit(player, enemy, spell); } return ret; }
		float CritMul(PlayerBase@ player, Actor@ enemy, bool spell) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].CritMul(player, enemy, spell) - 1.0f; } return ret; }
		vec2 ArmorIgnore(PlayerBase@ player, Actor@ enemy, bool spell) override { vec2 ret = vec2(1); for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].ArmorIgnore(player, enemy, spell); } return ret; } 
		float Lifesteal(PlayerBase@ player, Actor@ enemy, bool spell, int crit) override { float ret = 0; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].Lifesteal(player, enemy, spell, crit); } return ret; } 
		
		ivec2 StatsAdd(PlayerBase@ player) override { ivec2 ret; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].StatsAdd(player); } return ret; }
		float MoveSpeedAdd(PlayerBase@ player) override { float ret = 0; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].MoveSpeedAdd(player); } return ret; }
		vec2 RegenAdd(PlayerBase@ player) override { vec2 ret; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].RegenAdd(player); } return ret; }
		vec2 RegenMul(PlayerBase@ player) override { vec2 ret(1, 1); for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].RegenMul(player); } return ret; }
		float ExpMul(PlayerBase@ player, Actor@ enemy) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].ExpMul(player, enemy) - 1.0f; } return ret; }

		int PotionCharges() override { int ret = 0; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].PotionCharges(); } return ret; }
		float PotionHealMul(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].PotionHealMul(player); } return ret; }
		float PotionManaMul(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].PotionManaMul(player); } return ret; }

		float GoldRunScale() override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].GoldRunScale(); } return ret; }
		float GoldGainScale(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].GoldGainScale(player); } return ret; }
		float OreGainScale(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].OreGainScale(player); } return ret; }
		float KeyGainScale(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].KeyGainScale(player); } return ret; }

		float AllHealthGainScale(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].AllHealthGainScale(player); } return ret; }
		float HealthGainScale(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].HealthGainScale(player); } return ret; }
		float ManaGainScale(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].ManaGainScale(player); } return ret; }

		int ManaFromDamage(PlayerBase@ player, int dmgAmnt) override { int ret = 0; for (uint i = 0; i < m_modifiers.length(); i++) { ret += m_modifiers[i].ManaFromDamage(player, dmgAmnt); } return ret; }
		void DamageTaken(PlayerBase@ player, Actor@ enemy, int dmgAmnt) override { for (uint i = 0; i < m_modifiers.length(); i++) m_modifiers[i].DamageTaken(player, enemy, dmgAmnt); }
		void TriggerEffects(PlayerBase@ player, Actor@ enemy, EffectTrigger trigger) override { for (uint i = 0; i < m_modifiers.length(); i++) m_modifiers[i].TriggerEffects(player, enemy, trigger); }
		array<IEffect@>@ ComboEffects(PlayerBase@ player) override
		{
			array<IEffect@> ret;
			for (uint i = 0; i < m_modifiers.length(); i++)
			{
				auto arr = m_modifiers[i].ComboEffects(player);
				if (arr is null || arr.length() == 0)
					continue;
				ret.insertAt(ret.length(), arr);
			}
			return ret;
		}
		float SkillTimeMul(PlayerBase@ player) override { float ret = 1; for (uint i = 0; i < m_modifiers.length(); i++) { ret *= m_modifiers[i].SkillTimeMul(player); } return ret; }
		
		void Update(PlayerBase@ player, int dt) override
		{
			for (uint i = 0; i < m_modifiers.length(); i++)
				m_modifiers[i].Update(player, dt);
		}
	}
}
