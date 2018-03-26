namespace Modifiers
{
	class Block : Modifier
	{
		float m_chance;
		ivec2 m_amount;
	
		Block(UnitPtr unit, SValue& params)
		{
			m_chance = GetParamFloat(unit, params, "chance", false, 1.0);
			int physical = GetParamInt(unit, params, "physical", false, 0);
			int magical = GetParamInt(unit, params, "magical", false, 0);
			m_amount = ivec2(physical, magical);
		}	

		ivec2 DamageBlock(PlayerBase@ player, Actor@ enemy) override
		{ 
			return (randf() <= m_chance) ? m_amount : ivec2();
		}
	}
}