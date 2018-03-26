namespace Modifiers
{
	class Evade : Modifier
	{
		float m_chance;
	
		Evade(UnitPtr unit, SValue& params)
		{
			m_chance = GetParamFloat(unit, params, "chance", true);
		}	

		bool Evasion(PlayerBase@ player, Actor@ enemy) override { return (randf() <= m_chance); }
	}
}