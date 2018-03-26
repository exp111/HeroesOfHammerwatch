namespace Modifiers
{
	class CriticalMul : Modifier
	{
		float m_mul;
		float m_spellMul;

		CriticalMul(UnitPtr unit, SValue& params)
		{
			m_mul = GetParamFloat(unit, params, "mul", false, 1.0f);
			m_spellMul = GetParamFloat(unit, params, "spell-mul", false, 1.0f);
		}

		float CritMul(PlayerBase@ player, Actor@ enemy, bool spell) override 
		{
			if (spell)
				return m_spellMul;
			return m_mul;
		}
	}
}
