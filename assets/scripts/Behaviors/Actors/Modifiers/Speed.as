namespace Modifiers
{
	class Speed : Modifier
	{
		float m_movement;
		float m_skillMul;
	
		Speed(UnitPtr unit, SValue& params)
		{
			m_movement = GetParamFloat(unit, params, "movement", false, 0);
			m_skillMul = GetParamFloat(unit, params, "skill-mul", false, 1);
		}

		float MoveSpeedAdd(PlayerBase@ player) override { return m_movement; }
		float SkillTimeMul(PlayerBase@ player) override { return m_skillMul; }
	}
}