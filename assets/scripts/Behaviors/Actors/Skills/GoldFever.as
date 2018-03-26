namespace Skills
{
	class GoldFeverMod : Modifiers::Modifier
	{
		float m_goldScale;
		float m_dmgScale;
	
		GoldFeverMod(float goldScale, float dmgScale)
		{
			m_goldScale = goldScale;
			m_dmgScale = dmgScale;
		}	

		float GoldGainScale(PlayerBase@ player) override { return m_goldScale; }
		vec2 DamageMul(PlayerBase@ player, Actor@ enemy) override { return vec2(1.0f + float(player.m_record.runGold) * m_dmgScale); }
	}

	class GoldFever : Skill
	{
		array<Modifiers::Modifier@> m_modifiers;

		GoldFever(UnitPtr unit, SValue& params)
		{
			super(unit);
			
			float goldScale = GetParamFloat(unit, params, "gold-scale", false, 1);
			float dmgScale = GetParamFloat(unit, params, "dmg-per-gold", false, 0.01);
			
			m_modifiers.insertLast(GoldFeverMod(goldScale, dmgScale));
		}

		array<Modifiers::Modifier@>@ GetModifiers() override
		{
			return m_modifiers;
		}
	}	
}