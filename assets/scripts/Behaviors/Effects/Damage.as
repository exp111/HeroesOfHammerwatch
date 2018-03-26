class Damage : IEffect
{
	int m_physicalDmg;
	int m_magicalDmg;
	bool m_canKill;
	bool m_melee;
	uint m_weaponInfo;
	vec2 m_armorMul;

	Damage(UnitPtr unit, SValue& params)
	{
		int dmg = GetParamInt(unit, params, "dmg", false, 0);
	
		m_physicalDmg = GetParamInt(unit, params, "physical", false, dmg);
		m_magicalDmg = GetParamInt(unit, params, "magical", false, 0);
		
		m_armorMul = vec2(
			GetParamFloat(unit, params, "armor-mul", false, 1), 
			GetParamFloat(unit, params, "resistance-mul", false, 1));
		
		m_canKill = GetParamBool(unit, params, "can-kill", false, true);
		m_melee = GetParamBool(unit, params, "melee", false, false);
	}
	
	void SetWeaponInformation(uint weapon)
	{
		m_weaponInfo = weapon;
	}

	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		target.TriggerCallbacks(UnitEventType::Damaged);
	
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;

		if (!FilterHuskDamage(owner, target, husk))
			return false;
	
		float dmgMul = owner is null ? 1.0f : owner.GetDamageMulTarget(m_melee, target);
		IDamageTaker@ dmgTaker = cast<IDamageTaker>(target.GetScriptBehavior());
		dmgMul *= intensity;
		
		auto dmgInfo = DamageInfo(owner, damage_round(float(m_physicalDmg) * dmgMul), damage_round(float(m_magicalDmg) * dmgMul), m_melee, m_canKill, m_weaponInfo);
		dmgInfo.ArmorMul = m_armorMul;

		dmgTaker.Damage(dmgInfo, pos, dir);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		if (!target.IsValid())
			return false;
	
		IDamageTaker@ dmgTaker = cast<IDamageTaker>(target.GetScriptBehavior());
		
		if (dmgTaker is null)
			return false;

		return true;
	}

	bool NeedsFilter()
	{
		return true;
	}
}