namespace Modifiers
{
	class HealthFilter : FilterModifier
	{
		float m_below;
		float m_above;
		
		HealthFilter(UnitPtr unit, SValue& params)
		{
			super(unit, params);
			
			m_below = GetParamFloat(unit, params, "below", false, -10);
			m_above = GetParamFloat(unit, params, "above", false, 10);
		}	

		bool Filter(PlayerBase@ player, Actor@ enemy) override 
		{
			return player.m_record.hp <= m_below || player.m_record.hp >= m_above; 
		}
	}
}