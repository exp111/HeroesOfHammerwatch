class Miniboss : CompositeActorBehavior
{
	int m_bossBarWidth;
	OverheadBossBar@ m_bossBar;
	int m_bossBarTimeC;

	Miniboss(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		m_bossBarWidth = GetParamInt(unit, params, "overhead-bossbar-width", false, -1);
	}

	void NetDamage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		CompositeActorBehavior::NetDamage(dmg, pos, dir);

		if (dmg.Damage != 0 && m_bossBarWidth != -1)
		{
			m_bossBarTimeC = 3000;
			if (m_bossBar is null)
			{
				auto hud = GetHUD();
				if (hud !is null)
					@m_bossBar = hud.AddBossBarActor(this, m_bossBarWidth, -m_unitHeight, "");
			}
		}
	}

	void Update(int dt) override
	{
		if (!IsDead() && m_bossBar !is null)
		{
			m_bossBarTimeC -= dt;
			if (m_bossBarTimeC <= 0)
			{
				auto hud = GetHUD();
				int index = hud.m_arrBosses.findByRef(m_bossBar);
				if (index != -1)
					hud.m_arrBosses.removeAt(index);
				@m_bossBar = null;
			}
		}

		CompositeActorBehavior::Update(dt);
	}
}
