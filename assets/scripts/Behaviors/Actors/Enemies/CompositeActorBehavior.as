class CompositeActorBehaviorEvading : CompositeActorBehavior
{
	float m_evadePhysical;
	float m_evadeMagical;
	string m_evadeFx;
	
	
	CompositeActorBehaviorEvading(UnitPtr unit, SValue& params)
	{
		super(unit, params);
		
		m_evadePhysical = GetParamFloat(unit, params, "evade-physical", false, 0);
		m_evadeMagical = GetParamFloat(unit, params, "evade-magical", false, 0);
		m_evadeFx = GetParamString(unit, params, "evade-fx", false);
	}

	int Damage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		bool evaded = false;
		
		if (dmg.PhysicalDamage > 0 && randf() <= m_evadePhysical)
		{
			dmg.PhysicalDamage = 0;
			evaded = true;
		}
		if (dmg.MagicalDamage > 0 && randf() <= m_evadeMagical)
		{
			dmg.MagicalDamage = 0;
			evaded = true;
		}
		
		if (evaded)
			PlayEffect(m_evadeFx, m_unit.GetPosition());
	
		if (dmg.PhysicalDamage == 0 && dmg.MagicalDamage == 0)
			return 0;
	
		return CompositeActorBehavior::Damage(dmg, pos, dir);
	}
}

class CompositeActorBehaviorColorized : CompositeActorBehavior
{
	float m_colorSpeed;
	vec3 m_colorA;
	vec3 m_colorB;

	CompositeActorBehaviorColorized(UnitPtr unit, SValue& params)
	{
		super(unit, params);
		
		m_colorSpeed = GetParamFloat(unit, params, "colorize-speed", false, 1);
		
		
		array<SValue@>@ colorArr = GetParamArray(unit, params, "colorize", true);
		if (colorArr !is null)
		{
			m_colorA = colorArr[0].GetVector3();
			m_colorB = colorArr[1].GetVector3();
		}
	}	

	void Update(int dt) override
	{
		CompositeActorBehavior::Update(dt);
		
		float xt = (sin(g_scene.GetTime() / 1000.0 * m_colorSpeed) + 1.0) / 2.0;
		auto color = lerp(m_colorA, m_colorB, xt);
		m_unit.SetMultiColor(0, xyzw(color * 0.1, 1), xyzw(color * 0.5, 1), xyzw(color * 2, 1));
	}
}


class CompositeActorBehavior : Actor
{
	float m_hp;
	int m_maxHp;
	float m_mpScaleFact;
	uint m_maxRange;
	int m_aggroRange;
	bool m_impenetrable;
	int m_expReward;
	bool m_targetable;
	bool m_immortal;
	bool m_canHeal;
	bool m_dead;
	
	array<ICompositeActorSkill@> m_skills;
	ActorMovement@ m_movement;
	
	SoundEvent@ m_aggroSound;
	SoundEvent@ m_hurtSound;
	SoundEvent@ m_immortalSound;
	SoundEvent@ m_deathSound;

	Actor@ m_target;
	bool m_targeting;
	bool m_mustSeeTarget;
	int m_targetSearchCd;
	
	LootDef@ m_lootDef;
	GoreSpawner@ m_gore;
	vec2 m_armor;
	string m_enemyType;
	
	ActorBuffList m_buffs;
	bool m_noBuffs;
	float m_debuffScale;
	EffectParams@ m_effectParams;
	bool m_holdAngleOnCast;
	float m_dmgColor;

	string m_hitFx;

	bool m_frozen;

	int m_unitHeight;

	array<uint> m_buffsImmune;
	uint64 m_buffsImmuneTags;

%if MOD_ACHIEVEMENT_CHECKS
	int m_achieveGroup;
%endif
	
	
	
	CompositeActorBehavior(UnitPtr unit, SValue& params)
	{
		SetTeam(GetParamString(unit, params, "team", false, "enemy"), GetParamBool(unit, params, "counts-as-kill", false, true));
		super(unit);

		m_maxHp = int(GetParamInt(unit, params, "hp") * (Fountain::HasEffect(FountainEffect::EnemiesDamaged) ? 0.66f : 1.0f));
		m_hp = 1.0;

		m_floatingHurt = GetParamBool(unit, params, "floating-hurt", false, true);
		
		m_impenetrable = GetParamBool(unit, params, "impenetrable", false, false);
		m_expReward = GetParamInt(unit, params, "experience-reward", false, 0);

		m_unitHeight = GetParamInt(unit, params, "unit-height", false, 16);

		m_aggroRange = GetParamInt(unit, params, "aggro-range", false, 200);
		m_maxRange = uint(max(m_aggroRange, GetParamInt(unit, params, "max-range", false, 300)));

		m_canHeal = GetParamBool(unit, params, "can-heal", false, true);
		
		@m_aggroSound = Resources::GetSoundEvent(GetParamString(unit, params, "aggro-snd", false));
		@m_hurtSound = Resources::GetSoundEvent(GetParamString(unit, params, "hurt-snd", false));
		@m_deathSound = Resources::GetSoundEvent(GetParamString(unit, params, "death-snd", false));
		//@m_immortalSound = Resources::GetSoundEvent("event:/enemies/immortal");
		
		@m_lootDef = LoadLootDef(GetParamString(unit, params, "loot", false));
		@m_gore = LoadGore(GetParamString(unit, params, "gore", false));
		
		
		int armor = GetParamInt(unit, params, "armor", false, 0);
		int resistance = GetParamInt(unit, params, "resistance", false, 0);
		m_armor = vec2(armor, resistance);
		
		if (Fountain::HasEffect(FountainEffect::HalfEnemyArmor))
			m_armor *= 0.5f;
			
		
		m_enemyType = GetParamString(unit, params, "type", false);

		m_mpScaleFact = GetParamFloat(unit, params, "mp-scale-fact", false, 0);
		m_targetable = GetParamBool(unit, params, "targetable", false, true);
		m_targeting = GetParamBool(unit, params, "targeting", false, true);
		if (m_targeting)
			m_mustSeeTarget = GetParamBool(unit, params, "must-see-target", false, true);
		
		m_targetSearchCd = 0;
		
		m_hitFx = GetParamString(unit, params, "hit-fx", false);

		m_crosshairColors = GetParamBool(unit, params, "crosshair-colors", false, true);

		m_debuffScale = GetParamFloat(unit, params, "debuff-scale", false, 1.0f);
		m_noBuffs = GetParamBool(unit, params, "no-buffs", false, false);
		array<SValue@>@ immuneArr = GetParamArray(unit, params, "buffs-immune", false);
		if (immuneArr !is null)
		{
			for (uint i = 0; i < immuneArr.length(); i++)
				m_buffsImmune.insertLast(HashString(immuneArr[i].GetString()));
		}
		m_buffsImmuneTags = GetBuffTags(params, "buffs-immune-");

%if MOD_ACHIEVEMENT_CHECKS
		m_achieveGroup = GetParamInt(unit, params, "achieve-group", false, 0);
%endif
		
		{
			SValue@ movement = GetParamDictionary(unit, params, "movement", true);
			string c = GetParamString(unit, movement, "class");
			
			@m_movement = cast<ActorMovement>(InstantiateClass(c, unit, movement));
		}
		
		
		array<SValue@>@ skillArr = GetParamArray(unit, params, "skills");
		for (uint i = 0; i < skillArr.length(); i++)
		{
			string c = GetParamString(unit, skillArr[i], "class");
			
			ICompositeActorSkill@ skill = cast<ICompositeActorSkill>(InstantiateClass(c, unit, skillArr[i]));
			skill.Initialize(m_unit, this, i);
			
			m_skills.insertLast(skill);
		}

		m_movement.Initialize(m_unit, this);


		
		SValue@ dat = GetParamDictionary(unit, params, "effect-params", false);
		if (dat !is null && dat.GetType() == SValueType::Dictionary)
		{
			@m_effectParams = m_unit.CreateEffectParams();
			
			auto epKeys = dat.GetDictionary().getKeys();
			for (uint i = 0; i < epKeys.length(); i++)
			{
				auto d = dat.GetDictionaryEntry(epKeys[i]);
				if (d !is null && d.GetType() == SValueType::Float && m_effectParams !is null)
					m_effectParams.Set(epKeys[i], d.GetFloat());
			}
			
			m_holdAngleOnCast = GetParamBool(unit, params, "hold-angle-on-cast", false, false);
		}
		
		m_unit.SetCollisionTeam(uint16(GetActorListId(Team)));
		
		if (!Tweak::EnemyInfitniteAggro)
			m_unit.SetUpdateDistanceLimit(int(m_maxRange));
		
		m_dead = false;
		
		m_buffs.Initialize(this);
	}
	
	void MakeAggro()
	{
		m_mustSeeTarget = false;
		m_aggroRange = 5000;
		m_maxRange = 5000;

		m_unit.SetUpdateDistanceLimit(int(m_maxRange));
		
		m_movement.MakeAggro();
	}
	
	int GetMaxHp()
	{
		return int((m_maxHp + g_ngp * 15) * (1.0f + g_mpEnemyHealthScale * m_mpScaleFact) * (1.0f + g_ngp * 2.75f));
	}

	float GetHealth() override
	{
		return m_hp;
	}

	int IconHeight() override { return -m_unitHeight - 2; }
	bool IsTargetable() override { return m_targetable; }
	
	vec4 GetOverlayColor()
	{
		if (m_dmgColor <= 0)
			return vec4(1, 1, 1, 0);
		
		if (!IsImmortal())
			return vec4(1, 0, 0, 0.5 * m_dmgColor);
			
		return vec4(160.0/255.0, 0, 1, 0.5 * m_dmgColor);
	}
	
	SValue@ Save()
	{
		SValueBuilder sval;
		sval.PushDictionary();
		
		if (m_hp != 1.0)
			sval.PushFloat("hp", m_hp);
		
		if (m_immortal)
			sval.PushBoolean("immortal", m_immortal);
			
		// TODO: Save skills..  their charges at least
		
		return sval.Build();
	}
	
	void Load(SValue@ data)
	{
		auto hp = data.GetDictionaryEntry("hp");
		if (hp !is null && hp.GetType() == SValueType::Float)
			m_hp = hp.GetFloat();
	
		auto immortal = data.GetDictionaryEntry("immortal");
		if (immortal !is null && immortal.GetType() == SValueType::Boolean)
			m_immortal = immortal.GetBoolean();
	}
	
	
	void SetImmortal(bool immortal) override { m_immortal = immortal; }
	bool IsImmortal(bool ignoreBuffs = false) override
	{ 
		return m_immortal; 
	}

	bool ApplyBuff(ActorBuff@ buff) override
	{
		if (m_unit.IsDestroyed())
			return false;

		if (m_noBuffs)
			return false;
			
		if ((buff.m_def.m_tags & m_buffsImmuneTags) != 0)
			return false;

		if (buff.m_def.m_disarm && buff.m_def.m_mulSpeed == 0)
		{
			auto player = cast<PlayerBase>(buff.m_owner);
			if (player !is null)
				Stats::Add("stun-count", 1, player.m_record);
		}

		if (buff.m_def.m_debuff)
		{
			buff.m_duration = int(buff.m_duration * m_debuffScale * pow(0.9f, g_ngp));
			if (buff.m_duration <= 0)
				return false;
		}
			
		/*
		if (BlockBuff(buff, m_armorDef, m_armorAmnt >= 0 ? m_armorAmnt : 999))
			return false;
		*/

		uint pathHash = buff.m_def.m_pathHash;
		for (uint i = 0; i < m_buffsImmune.length(); i++)
		{
			if (pathHash == m_buffsImmune[i])
				return false;
		}
		
		m_buffs.Add(buff);
		return true;
	}

	bool Impenetrable() override { return m_impenetrable; }

	void Collide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther)
	{
		if (!fxOther.IsSensor())
		{
			for (uint i = 0; i < m_skills.length(); i++)
				m_skills[i].OnCollide(unit, normal);
		
			m_movement.OnCollide(unit, pos, normal, fxSelf, fxOther);
		}	
		//m_unit.GetPhysicsBody().SetStatic(true);
	}
	
	void Kill(Actor@ killer, uint weapon) override
	{
		m_hp = 0;
		Actor::Kill(killer, weapon);
		OnDeath(DamageInfo(0, killer, 1, false, true, weapon), vec2());
	}
	
	void QueuedPathfind(array<vec2>@ path)
	{
		m_movement.QueuedPathfind(path);
		if (path.length() == 0)
			SetTarget(null);
	}
	
	int Damage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		if (m_hp <= 0)
			return 0;
	
		auto localPlayer = cast<Player>(dmg.Attacker);
		if (localPlayer !is null)
			dmg = localPlayer.DamageActor(this, dmg);

		vec2 dmgAmntParts = ApplyArmorParts(dmg, m_buffs.ArmorMul() * (m_armor + vec2(g_ngp * 5)) * dmg.ArmorMul * (1.0f + g_ngp * 0.5f), m_buffs.DamageTakenMul());
		int dmgAmnt = max(0, damage_round(dmgAmntParts.x + dmgAmntParts.y));

		if (!dmg.CanKill && floor(m_hp * float(GetMaxHp())) - dmgAmnt <= 0)
			dmgAmnt = 0;

		if (dmgAmnt > 0)
		{
			DamageInfo di = dmg;
			di.Damage = dmgAmnt;
			di.PhysicalDamage = damage_round(dmgAmntParts.x);
			di.MagicalDamage = damage_round(dmgAmntParts.y);
		
			if (!IsImmortal())
			{
				if (localPlayer !is null)
					localPlayer.DamagedActor(this, di);
			
				NetDamage(di, pos, dir);
				//m_movement.OnDamaged(dmg);

				PlayEffect(m_hitFx, pos);
				
				for (uint i = 0; i < m_skills.length(); i++)
					m_skills[i].OnDamaged();

				//AddFloatingHurt(dmgAmnt);
				UnitHandler::NetSendUnitDamaged(m_unit, dmgAmnt, pos, dir, di.Attacker);
			}
			else
			{
				AddFloatingImmortal(0);
				PlaySound3D(m_immortalSound, m_unit.GetPosition());
			}
			
			m_dmgColor = 1.0;
			
			if (m_hp <= 0)
				OnDeath(di, dir);
		}
		else if (dmgAmnt < 0)
		{
			if (m_hp < 1.0)
			{
				NetHeal(-dmgAmnt);
				(Network::Message("UnitHealed") << m_unit << -dmgAmnt).SendToAll();
			}
		}
		else
			AddFloatingHurt(0);
		
		return dmgAmnt;
	}

	void Heal(int amount) override
	{
		if (!m_canHeal)
			return;

		NetHeal(amount);
		(Network::Message("UnitHealed") << m_unit << amount).SendToAll();
	}

	void NetDamage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		//if (m_hp <= 0)
		//	return;
		
		if (Network::IsServer())
		{
			if (dmg.Attacker !is null && !dmg.Attacker.IsDead())
				if (m_target is null || (dmg.Attacker.Team == g_team_player && m_target.Team != g_team_player))
					SetTarget(dmg.Attacker);
		}
	
		m_hp -= float(dmg.Damage) / float(GetMaxHp());
		m_movement.OnDamaged(dmg);
		
		
		if (dmg.Attacker !is null && dmg.Attacker is GetLocalPlayer())
			AddFloatingHurt(dmg.Damage, dmg.Crit);
		else
			AddFloatingHurt(dmg.Damage, dmg.Crit, FloatingTextType::EnemyHurtHusk);

			
		//if (m_hp <= 0)
		//	OnDeath(dmg, dir);
		
		if (m_hp > 0)
		{
			PlaySound3D(m_hurtSound, m_unit.GetPosition());
			
			if (m_gore !is null)
				m_gore.OnHit(float(dmg.Damage) / float(GetMaxHp()), pos, atan(dir.y, dir.x));
		}
	}
		
	void NetHeal(int amt) override
	{ 
		m_hp = min(1.0, m_hp + float(amt) / float(GetMaxHp()));
		//AddFloatingText(FloatingTextType::EnemyHealed, "" + amt, m_unit.GetPosition());
		AddFloatingGive(amt);
	}

	void Destroyed()
	{
		if (m_countsAsKill)
			g_killedEnemies++;

		m_buffs.Clear();

		for (uint i = 0; i < m_skills.length(); i++)
			m_skills[i].Destroyed();
	}

	void OnDeath(DamageInfo di, vec2 dir)
	{
		if (m_unit.IsDestroyed())
			return;

		TriggerOnDeath(di, dir);
	}

	void TriggerOnDeath(DamageInfo di, vec2 dir, bool local = true)
	{
		if (m_unit.IsDestroyed() || m_dead)
			return;
			
		m_dead = true;

		m_hp = 0;
		PlaySound3D(m_deathSound, m_unit.GetPosition());
		
		m_buffs.OnDeath(this);

		if (m_gore !is null)
			m_gore.OnDeath(di.Damage / float(GetMaxHp()), xy(m_unit.GetPosition()), atan(dir.y, dir.x));
		
		if (local)
		{
			auto attacker = di.Attacker is null || di.Attacker.IsDead() ? UnitPtr() : di.Attacker.m_unit;
			(Network::Message("UnitKilled") << m_unit << attacker << di.Damage << dir << di.Weapon).SendToAll();
		}

		if (di.Attacker !is null)
			di.Attacker.KilledActor(this, di);
		
		if (Network::IsServer())
		{
			if (m_lootDef !is null)
				m_lootDef.Spawn(xy(m_unit.GetPosition()));
				
			for (uint i = 0; i < m_skills.length(); i++)
				m_skills[i].OnDeath();
		
			m_unit.Destroy();
		}

		auto coll = GetActorList(Team);
		if (coll !is null)
		{
			int idx = coll.m_arr.findByRef(this);
			if (idx >= 0)
				coll.m_arr.removeAt(idx);
		}
	}
	
	void NetKill(Actor@ attacker, uint16 dmg, vec2 dir, uint weapon) override
	{
		TriggerOnDeath(DamageInfo(0, attacker, dmg, false, true, weapon), dir, false);
	}
	
	
	
	bool IsDead() override { return m_hp <= 0 || m_dead; }
	
	vec2 GetDirection()
	{
		return vec2(cos(m_movement.m_dir), sin(m_movement.m_dir));
	}

	vec2 GetCastDirection()
	{
		return GetDirection();
	}
	
	
	void NetUseSkill(int skillId, int stage, vec2 pos, SValue@ param) override
	{
		if (m_unit.IsDestroyed())
			return;
			
		m_unit.SetPosition(pos.x, pos.y, m_unit.GetPosition().z, true);
		
		if (skillId >= 0 && uint(skillId) < m_skills.length())
			m_skills[skillId].NetUseSkill(stage, param);
		else
			PrintError("Failed to use netsynced skill " + skillId + " for unit " +  m_unit.GetDebugName());
			
	}
	
	
	int TargetValue(vec2 pos, Actor@ target, uint aggroRange)
	{
		float weight = 1.0f;

		uint d = uint(dist(pos, xy(target.m_unit.GetPosition())));
		if (target is m_target)
		{
			if (!Tweak::EnemyInfitniteAggro && d > uint(m_maxRange))
				return -1;
			/*
			if (target.Team == g_team_player)
				weight *= 0.25f;
			*/
			weight *= 0.7f;
		}
		else
		{
			if (!Tweak::EnemyInfitniteAggro && d > aggroRange)
				return -1;	
			
			if (target.Team == g_team_player)
				weight *= 0.75f;
			
			if (m_mustSeeTarget && !Tweak::EnemiesCanSeeThroughWalls)
			{
				RaycastResult res = g_scene.RaycastClosest(pos, xy(target.m_unit.GetPosition()), ~0, RaycastType::Aim);
				UnitPtr res_unit = res.FetchUnit(g_scene);
				
				if (res_unit.IsValid() && res_unit != target.m_unit)
					return -1;
			}
		}
		
		return int(d * weight);
	}
	
	void SpreadTarget(Actor@ target, int spreadTargetCount) override
	{
		if (m_targeting && m_target is null && !IsDead())
			SetTarget(target, spreadTargetCount);
	}
	
	void NetSetTarget(Actor@ target) override
	{
		if (target !is null && target is GetLocalPlayer())
			MusicManager::AddTension((target !is m_target ? 2.5 : 0.1) * m_expReward / 10.f); 
	
		@m_target = target;
		PlaySound3D(m_aggroSound, m_unit);
	}
	
	void SetTarget(Actor@ newTarget, int spreadTargetCount = 10)
	{
		if (!Network::IsServer())
			return;
			
		if (m_unit.IsDestroyed())
			return;
	
		if (newTarget !is null && newTarget is GetLocalPlayer())
			MusicManager::AddTension((newTarget !is m_target ? 2.5 : 0.1) * m_expReward / 10.f);
		
		if (newTarget !is m_target)
		{
			@m_target = newTarget;
			PlaySound3D(m_aggroSound, m_unit);
			
			if (m_target is null)
				(Network::Message("UnitTarget") << m_unit << UnitPtr()).SendToAll();
			else
			{
				(Network::Message("UnitTarget") << m_unit << m_target.m_unit).SendToAll();
				
				if (spreadTargetCount > 0)
				{
					auto friends = g_scene.FetchActorsWithTeam(Team, xy(m_unit.GetPosition()), 66);
					for (uint i = 0; i < friends.length(); i++)
					{
						cast<Actor>(friends[i].GetScriptBehavior()).SpreadTarget(m_target, spreadTargetCount--);
						if (spreadTargetCount < 0)
							break;
					}
				}
			}
		}
	}
	
	void QueuedFetchActors(array<UnitPtr>@ possibleTargets)
	{
		m_targetSearchCd = 500 + randi(500);

		Actor@ newTarget = null;
		vec2 pos = xy(m_unit.GetPosition());
		uint aggroRange = uint(m_aggroRange);
		uint bestVal = 999999;
	
		for (uint i = 0; i < possibleTargets.length(); i++)
		{
			Actor@ a = cast<Actor>(possibleTargets[i].GetScriptBehavior());
			if (!a.IsDead() && a.IsTargetable())
			{
				int val = TargetValue(pos, a, aggroRange);
				if (val >= 0 && uint(val) < bestVal)
				{
					bestVal = val;
					@newTarget = a;
				}
			}
		}

		SetTarget(newTarget);
	}
	
	
	int SetUnitScene(string scene, bool resetTime)
	{
		m_unit.SetUnitScene(scene, resetTime);
		return m_unit.GetCurrentUnitScene().Length();
	}
	
	void Update(int dt)
	{
		if (IsDead())
		{
			if (!m_dead)
				OnDeath(DamageInfo(0, null, 1, false, true, 0), vec2(1, 0));
			
			return;
		}

		if (m_dmgColor > 0)
			m_dmgColor -= dt / 100.0;
	
		m_buffs.Update(dt);
	

		if (m_target !is null)
		{
			if (m_target is GetLocalPlayer())
				MusicManager::AddTension(0.002 * m_expReward);
		}
	
		if (m_targeting && Network::IsServer())
		{
			m_targetSearchCd -= dt;
			if (m_targetSearchCd <= 0)
			{
				m_targetSearchCd = 1000;
				
				if (Tweak::EnemyInfitniteAggro)
					g_scene.QueueFetchAllActorsWithOtherTeam(m_unit, Team);
				else
					g_scene.QueueFetchActorsWithOtherTeam(m_unit, Team, xy(m_unit.GetPosition()), uint(m_maxRange));
			}
		}
		
		bool isCasting = false;
		if (m_target !is null && !m_frozen)
		{
			bool wasCasting = false;
			for (uint i = 0; i < m_skills.length(); i++)
				if (m_skills[i].IsCasting())
					wasCasting = true;
		
			for (uint i = 0; i < m_skills.length(); i++)
			{
				if (IsDead())
					break;
			
				//m_skills[i].Update(dt, wasCasting);
				m_skills[i].Update(dt, isCasting || wasCasting);
				if (m_skills[i].IsCasting())
					isCasting = true;
			}
		}
		
		if (!IsDead())
			m_movement.Update(dt, isCasting);
		
		if (m_effectParams !is null)
		{
			if (!isCasting || !m_holdAngleOnCast)
				m_effectParams.Set("angle", m_movement.m_dir);
		}
	}
}
