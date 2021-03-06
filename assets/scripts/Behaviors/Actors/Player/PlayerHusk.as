class PlayerHusk : PlayerBase, IPreRenderable
{
	SoundEvent@ m_dmHit;
	
	vec2 m_dir;
	vec2 m_posTarget;

	BitmapString@ m_textName;
	

	PlayerHusk(UnitPtr unit, SValue& params)
	{
		super(unit, params);
		
		m_unit.SetShouldCollide(false);
		m_posTarget = xy(m_unit.GetPosition());
	
		@m_dmHit = Resources::GetSoundEvent("event:/player/dm-hit");

		m_crosshairColors = true;
	}

	void Initialize(PlayerRecord@ record) override
	{
		PlayerBase::Initialize(record);

		m_preRenderables.insertLast(this);

		if (m_record.corpse is null)
		{
			auto hud = GetHUD();
			if (hud !is null && hud.m_waypoints !is null)
				hud.m_waypoints.AddWaypoint(PlayerWaypoint(m_unit, record));
		}
	}
	
	bool IsHusk() override { return true; }
	bool IsDead() override { return m_record.IsDead(); }

	void Heal(int amount) override
	{
		NetHeal(amount);
	}

	void NetDamage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		if (cast<Player>(dmg.Attacker) !is null)
			PlaySound2D(m_dmHit);
	
		AddFloatingText(FloatingTextType::EnemyHurt, "" + dmg.Damage, m_unit.GetPosition());
		//m_record.hp -= float(dmg.Damage) / float(m_record.MaxHealth());
		
		if (m_gore !is null)
			m_gore.OnHit(float(dmg.Damage) / float(m_record.MaxHealth()), pos, atan(dir.y, dir.x));
	}
	
	void OnDeath(DamageInfo di, vec2 dir) override
	{
		PlayerBase::OnDeath(di, dir);

		m_record.deaths++;
		m_record.deathsTotal++;
		m_record.hp = -1;

%if MOD_SHARED_HP
		Player@ ply = GetLocalPlayer();
		if (ply is null)
			return;

		ply.Kill(di.Attacker, di.Weapon);
%endif
	}

	void KilledActor(Actor@ killed, DamageInfo di) override
	{
		if (cast<CompositeActorBehavior>(killed) is null)
			return;

		/*
		if (killed.m_countsAsKill)
		{
			m_record.kills++;
			m_record.killsTotal++;
		}
		*/

		Actor::KilledActor(killed, di);
	}
	
	void Kill(DamageInfo di)
	{
		OnDeath(di, m_dir);
		Actor::Kill(di.Attacker, 0);
	}
	
	void MovePlayer(vec2 pos, vec2 dir)
	{
		m_posTarget = pos;
		m_dir = dir;
	}
	
	void Dash(int dur, vec2 dir)
	{
		m_dashTime = dur;
		m_dashDir = dir;
	}
	
	void OnLevelUp()
	{
		PlaySound3D(Resources::GetSoundEvent("event:/player/levelup-others"), m_unit);
		PlayEffect("effects/generic/player_levelup.effect", m_unit);
	}	
	
	void Update(int dt) override
	{
		PhysicsBody@ bdy = m_unit.GetPhysicsBody();
		
		float facing;
		if (m_dashTime > 0)
		{
			m_dashTime -= dt;
			facing = atan(m_dashDir.y, m_dashDir.x);			
		}
		else
			facing = atan(m_dir.y, m_dir.x);
		
		SetAngle(facing);
		bool walking = (distsq(m_unit, m_posTarget) > 1);
		
		bool dashing = m_dashTime > 0;
		string scene = (dashing ? m_dashAnim : (walking ? m_walkAnim : m_idleAnim)).GetSceneName(facing);
		
		SetBodyAnim(scene, false);
		UpdateFootsteps(dt, dashing, walking);

		for (uint i = 0; i < m_skills.length(); i++)
			m_skills[i].Update(dt, walking);
			
		//m_unit.SetPositionZ(walking ? ((m_unit.GetUnitSceneTime() / 125) % 2) : 0);
		if (m_playerBobbing)
			m_unit.SetPosition(m_posTarget.x, m_posTarget.y, walking ? ((m_unit.GetUnitSceneTime() / 125) % 2) : 0, true);

		if (m_damageKillMulC > 0)
			m_damageKillMulC -= dt;

		PlayerBase::Update(dt);
	}

	bool PreRender(int idt)
	{
		if (m_unit.IsDestroyed())
			return true;

		return false;
	}
}