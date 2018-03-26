class ShootRandomEnemy : IEffect
{
	int m_range;
	UnitProducer@ m_prodProj;

	uint m_weaponInfo;

	ShootRandomEnemy(UnitPtr unit, SValue& params)
	{
		m_range = GetParamInt(unit, params, "range");
		@m_prodProj = Resources::GetUnitProducer(GetParamString(unit, params, "projectile"));
	}

	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		// Get all enemies near
		array<UnitPtr>@ enemies = g_scene.FetchActorsWithOtherTeam(owner.Team, pos, m_range);

		// Remove untargetable enemies
		for (int i = 0; i < int(enemies.length()); i++)
		{
			auto actor = cast<Actor>(enemies[i].GetScriptBehavior());
			if (actor is null || !actor.IsTargetable())
			{
				enemies.removeAt(i);
				i--;
			}
		}

		// Pick random enemy
		if (enemies.length() == 0)
			return false;

		UnitPtr enemy = enemies[randi(enemies.length())];

		// Create a projectile and shoot it at them
		auto proj = m_prodProj.Produce(g_scene, xyz(pos));
		if (!proj.IsValid())
			return false;

		IProjectile@ p = cast<IProjectile>(proj.GetScriptBehavior());
		if (p is null)
			return false;

		vec2 shootDir = normalize(xy(enemy.GetPosition()) - pos);
		p.Initialize(owner, shootDir, intensity, husk, cast<Actor>(enemy.GetScriptBehavior()), m_weaponInfo);

		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity)
	{
		if (m_prodProj is null)
			return false;

		if (!target.IsValid())
			return false;

		return true;
	}

	void SetWeaponInformation(uint weapon)
	{
		m_weaponInfo = weapon;
	}

	bool NeedsFilter()
	{
		return true;
	}
}
