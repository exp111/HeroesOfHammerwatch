class PlaySound : IEffect, IAction
{
	SoundEvent@ m_snd;
	bool m_2d;

	PlaySound(UnitPtr unit, SValue& params)
	{
		string fnm = GetParamString(unit, params, "sound");
		@m_snd = Resources::GetSoundEvent(fnm);
		if (m_snd is null)
			print("WARNING: Sound resource not found: " + fnm);
		m_2d = GetParamBool(unit, params, "2d", false);
	}

	void SetWeaponInformation(uint weapon) {}
	bool NeedNetParams() { return false; }
	
	bool DoAction(SValueBuilder@ builder, Actor@ owner, Actor@ target, vec2 pos, vec2 dir, float intensity)
	{
		Do(pos);
		return true;
	}
	
	bool NetDoAction(SValue@ param, Actor@ owner, vec2 pos, vec2 dir)
	{
		Do(pos);
		return true;
	}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;
	
		Do(pos);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		if (intensity <= 0)
			return false;
	
		return true;
	}
	
	void Do(vec2 pos)
	{
		if (m_2d)
			m_snd.Play();
		else
			m_snd.Play(xyz(pos));
	}
	
	void Update(int dt, int cooldown)
	{
	}

	bool NeedsFilter()
	{
		return false;
	}
}