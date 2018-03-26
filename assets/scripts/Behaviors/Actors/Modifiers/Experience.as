namespace Modifiers
{
	class Experience : Modifier
	{
		float m_expMul;
	
		Experience(UnitPtr unit, SValue& params)
		{
			m_expMul = GetParamFloat(unit, params, "mul", false, 1);
		}	

		float ExpMul(PlayerBase@ player, Actor@ enemy) override { return m_expMul; }
	}
}