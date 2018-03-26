namespace Modifiers
{
	class Armor : Modifier
	{
		vec2 m_armor;
		float m_dmgTakenMul;
	
		Armor(UnitPtr unit, SValue& params)
		{
			int armor = GetParamInt(unit, params, "armor", false, 0);
			int resistance = GetParamInt(unit, params, "resistance", false, 0);
			m_armor = vec2(armor, resistance);
			
			m_dmgTakenMul = GetParamFloat(unit, params, "dmg-taken-mul", false, 1);
		}	

		vec2 ArmorAdd(PlayerBase@ player, Actor@ enemy) override { return m_armor; }
		float DamageTakenMul(PlayerBase@ player, DamageInfo &di) override { return m_dmgTakenMul; }
	}
}