namespace Modifiers
{
	class SealOfMartyr : Modifier
	{
		vec2 m_damageMul;
	
		SealOfMartyr(UnitPtr unit, SValue& params)
		{
			m_damageMul = vec2(
				GetParamFloat(unit, params, "attack-mul", false, 1),
				GetParamFloat(unit, params, "spell-mul", false, 1));
		
			m_damageMul *= GetParamFloat(unit, params, "mul", false, 1);
		}
		
		vec2 DamageMul(PlayerBase@ player, Actor@ enemy) override {
			return vec2(1.0f, 1.0f) + m_damageMul * clamp(1.0f - player.m_record.hp, 0.0f, 1.0f);
		}
	}
}