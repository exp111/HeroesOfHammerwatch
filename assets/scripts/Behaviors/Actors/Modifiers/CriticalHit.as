namespace Modifiers
{
	class CriticalHit : Modifier
	{
		float m_chance;
		float m_spellChance;
	
		CriticalHit(UnitPtr unit, SValue& params)
		{
			m_chance = GetParamFloat(unit, params, "chance", false, -1);
			m_spellChance = GetParamFloat(unit, params, "spell-chance", false, -1);
		}
		
		int Crit(PlayerBase@ player, Actor@ enemy, bool spell) override 
		{
			if (spell)
				return (randf() <= m_spellChance) ? 1 : 0;
				
			return (randf() <= m_chance) ? 1 : 0;
		}
	}
}