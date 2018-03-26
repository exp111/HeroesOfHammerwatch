class SorcererProjectile : RayProjectile
{
	SorcererProjectile(UnitPtr unit, SValue& params)
	{
		super(unit, params);
	}
	
	void Update(int dt) override
	{
		float d = m_speed * dt / 33.0;
		m_ttl = int(m_ttl - d);
		if (m_ttl <= 0)
		{
			m_unit.Destroy();
			return;
		}
	
		UpdateSeeking(m_dir, dt);
		
		vec2 from = m_pos;
		m_pos += m_dir * d;
	
		array<RaycastResult>@ results = g_scene.Raycast(from, m_pos, ~0, RaycastType::Shot);
		for (uint i = 0; i < results.length(); i++)
		{
			RaycastResult res = results[i];
			if (!HitUnit(res.FetchUnit(g_scene), res.point, res.normal, m_selfDmg, true))
				return;
		}
	
		m_unit.SetPosition(m_pos.x, m_pos.y, 0, true);

		UpdateSpeed(m_dir, dt);
	}
	
	bool HitUnit(UnitPtr unit, vec2 pos, vec2 normal, float selfDmg, bool bounce) override
	{
		if (!unit.IsValid())
			return true;
		
		ref@ b = unit.GetScriptBehavior();
		/*
		IProjectile@ p = cast<IProjectile>(b);
		if (p !is null)
			return true;
		*/

		bool shouldRetarget = false;
		bool shoulPassThrough = false;
		
		auto dt = cast<IDamageTaker>(b);
		if (dt !is null)
		{
			if (dt.ShootThrough(pos, m_dir))
				return false;
				
			shoulPassThrough = !dt.Impenetrable();
			if (dt is m_owner && selfDmg > 0)
			{
				if (m_lastCollision != unit)
				{
					m_lastCollision = unit;
					ApplyEffects(m_effects, m_owner, unit, pos, m_dir, m_intensity * selfDmg, m_husk);
					shouldRetarget = true;
					
					if (--m_penetration <= 0)
					{
						PlaySound3D(m_soundHit, xyz(pos));
						m_unit.Destroy();
					}
				}
			}
			else if (!(FilterAction(cast<Actor>(b), m_owner, m_selfDmg, m_teamDmg, 1, 1) > 0))
				return true;
			else if (--m_penetration <= 0)
			{
				PlaySound3D(m_soundHit, xyz(pos));
				m_unit.Destroy();
			}
		}

		if (m_lastCollision != unit)
		{
			m_lastCollision = unit;
			ApplyEffects(m_effects, m_owner, unit, pos, m_dir, m_intensity, m_husk);
			shouldRetarget = true;
		}
		
		if (bounce)
		{
			m_speed *= m_bounceSpeedMul;
			m_pos = pos;
			PlaySound3D(m_soundBounce, xyz(pos));
		
			Actor@ target = null;
			if (shouldRetarget)
			{
				auto possibleTargets = g_scene.FetchActorsWithOtherTeam(m_owner.Team, pos, uint(m_ttl));
				int minDist = 10000000;
				
				for (uint i = 0; i < possibleTargets.length(); i++)
				{
					Actor@ a = cast<Actor>(possibleTargets[i].GetScriptBehavior());
					if (a.IsDead() || !a.IsTargetable())
						continue;
					
					if (a.m_unit == unit)
						continue;
					
					int d = distsq(m_owner, a);
					if (d < minDist)
					{
						minDist = d;
						@target = a;
					}
				}
			}
		
			if (target !is null)
				SetDirection(normalize(xy(target.m_unit.GetPosition() - m_unit.GetPosition())));
			else if (!shoulPassThrough)
				SetDirection(normal * -2 * dot(m_dir, normal) + m_dir);
			
			return false;
		}

		return true;
	}

	/*
	void Update(int dt) override
	{
		RayProjectile::Update(dt);
		m_intensity = max(0.05, m_intensity - (m_speed * dt / 33.0f) / 250.0f);
	}
	*/
}