namespace Skills
{
	class Charge : ActiveSkill
	{
		array<IEffect@>@ m_effects;

		int m_speed;
		int m_duration;
		int m_durationC;
		vec2 m_dir;
		int m_dustC;
		string m_dustFx;
		bool m_husk;
		UnitPtr m_lastCollision;
		
		string m_hitFx;
		SoundEvent@ m_hitSnd;

		bool m_hitSensors;
		

		Charge(UnitPtr unit, SValue& params)
		{
			super(unit, params);
		
			@m_effects = LoadEffects(unit, params);
			
			m_speed = GetParamInt(unit, params, "speed", false, 3);
			m_duration = GetParamInt(unit, params, "duration", false, 1000);
			m_durationC = 0;
			
			m_dustFx = GetParamString(unit, params, "dust-fx", false);
			
			m_hitFx = GetParamString(unit, params, "hit-fx", false);
			@m_hitSnd = Resources::GetSoundEvent(GetParamString(unit, params, "hit-snd", false));

			m_hitSensors = GetParamBool(unit, params, "hit-sensors", false);
		}
		
		void Initialize(Actor@ owner, ScriptSprite@ icon, uint id) override
		{
			ActiveSkill::Initialize(owner, icon, id);
			PropagateWeaponInformation(m_effects, id + 1);
			
			m_husk = false;
		}
		
		TargetingMode GetTargetingMode(int &out size) override
		{
			size = 0;
			return TargetingMode::Direction;
		}
		
		void DoActivate(SValueBuilder@ builder, vec2 target) override
		{
			m_durationC = m_duration;
			m_dir = normalize(target);
			m_lastCollision = UnitPtr();
			cast<PlayerBase>(m_owner).SetCharging(true);
			PlaySkillEffect(m_dir);
		}
		
		void CancelCharge()
		{
			m_durationC = 0;
			cast<PlayerBase>(m_owner).SetCharging(false);
		}

		void NetDoActivate(SValue@ param, vec2 target) override
		{
			cast<PlayerBase>(m_owner).SetCharging(true);
			PlaySkillEffect(target);
		}
		
		void OnCollide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxOther) override
		{
			if (m_durationC <= 0)
				return;

			bool isSensor = fxOther.IsSensor();
			if (isSensor && !m_hitSensors)
				return;

			HitUnit(unit, pos, isSensor);
			/*
			else if (dot(normal, m_dir) > 0.75)
				CancelCharge();
			*/
		}
		
		vec2 GetMoveDir() override 
		{
			//return vec2();
			return (m_durationC > 0) ? (m_dir * m_speed) : vec2(); 
		}
		
		void PlayHitEffect(vec2 pos)
		{
			PlayEffect(m_hitFx, pos);
			PlaySound3D(m_hitSnd, xyz(pos));
		}

		bool HitUnit(UnitPtr unit, vec2 pos, bool sensor = false)
		{
			if (!unit.IsValid())
				return true;
			
			ref@ b = unit.GetScriptBehavior();
			IProjectile@ p = cast<IProjectile>(b);
			if (p !is null)
				return true;
			
			auto dt = cast<IDamageTaker>(b);
			if (dt !is null)
			{
				if (dt.ShootThrough(pos, m_dir))
					return true;

				if (m_lastCollision != unit)
				{
					m_lastCollision = unit;
					ApplyEffects(m_effects, m_owner, unit, pos, m_dir, 1.0, m_husk);
					PlayHitEffect(pos);
					
					return !dt.Impenetrable();
				}
			}

			if (m_lastCollision != unit)
			{
				m_lastCollision = unit;
				ApplyEffects(m_effects, m_owner, unit, pos, m_dir, 1.0f, m_husk);
				PlayHitEffect(pos);
				return sensor;
			}
			
			return sensor;
		}


		void DoUpdate(int dt) override
		{
			if (m_durationC > 0)
			{
				m_durationC -= dt;
				m_owner.SetUnitScene(m_animation, false);
				
				m_dustC -= dt;
				if (m_dustC <= 0)
				{
					m_dustC += randi(66) + 33;
					PlayEffect(m_dustFx, xy(m_owner.m_unit.GetPosition()));
				}
				
				vec2 from = xy(m_owner.m_unit.GetPosition()) ;//+ m_dir * 3;
				vec2 to = from + m_dir * m_speed * dt / 33.0;
			
				array<RaycastResult>@ results = g_scene.RaycastWide(4, 3, from, to + m_dir * 3, ~0, RaycastType::Any);
				for (uint i = 0; i < results.length(); i++)
				{
					RaycastResult res = results[i];
					//if (res.fixture.IsSensor())
					//	continue;
					
					HitUnit(res.FetchUnit(g_scene), res.point, res.fixture.IsSensor());
				}
				
//				m_owner.m_unit.SetPosition(to.x, to.y, 0, true);

				if (m_durationC <= 0)
					CancelCharge();
			}
		}
	}
}