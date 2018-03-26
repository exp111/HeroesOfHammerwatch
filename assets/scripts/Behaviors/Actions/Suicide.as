class Suicide : IAction, IEffect
{
	uint m_weaponInfo;

	Suicide(UnitPtr unit, SValue& params)
	{
	}
	
	bool NeedNetParams() { return false; }
	void SetWeaponInformation(uint weapon) 
	{
		m_weaponInfo = weapon;
	}
	
	bool DoAction(SValueBuilder@ builder, Actor@ owner, Actor@ target, vec2 pos, vec2 dir, float intensity)
	{
		owner.Kill(owner, m_weaponInfo);
		return true;
	}
	
	bool NetDoAction(SValue@ param, Actor@ owner, vec2 pos, vec2 dir)
	{
		owner.Kill(owner, m_weaponInfo);
		return true;
	}
	
	void Update(int dt, int cooldown)
	{
	}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		owner.Kill(owner, m_weaponInfo);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		return true;
	}

	bool NeedsFilter()
	{
		return true;
	}
}