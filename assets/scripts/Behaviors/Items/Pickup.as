class Pickup
{
	UnitPtr m_unit;
	bool m_bounce;
	bool m_plrOnly;
	SoundEvent@ m_sound;
	bool m_global;
	bool m_secure;
	bool m_shouldDestroy;

%if MOD_ACHIEVEMENT_CHECKS
	int m_achievementGroup;
%endif

%if MOD_PICKUP_RESPAWN
	int m_respawnTime;
	int m_toRespawn;
%endif
	
	array<IEffect@>@ m_effects;

	bool m_visible;
	
	array<WorldScript::UnitPickedUpTrigger@> m_callbacks;
	
	
	
	Pickup(UnitPtr unit, SValue& params)
	{
		m_unit = unit;

		@m_effects = LoadEffects(unit, params);
		m_bounce = GetParamBool(unit, params, "bounce", false, true);
		@m_sound = Resources::GetSoundEvent(GetParamString(unit, params, "sound", false));
		m_plrOnly = GetParamBool(unit, params, "player-only", false, true);
		m_global = GetParamBool(unit, params, "global", false, false);
		m_secure = GetParamBool(unit, params, "secure", false, false);

%if MOD_ACHIEVEMENT_CHECKS
		m_achievementGroup = GetParamInt(unit, params, "achievement-group", false, -1);
%endif

		if (m_secure)
			m_global = true;
			
		m_shouldDestroy = !IsNetsyncedExistance(m_unit.GetUnitProducer().GetNetSyncMode()) || (m_global && Network::IsServer());

%if MOD_PICKUP_RESPAWN
		m_respawnTime = GetParamInt(unit, params, "respawn-time", false, -1);
%else
		m_unit.SetUpdateDistanceLimit(300);
%endif
		
		g_totalPickups++;
		g_totalPickupsTotal++;
		m_visible = true;
	}

	SValue@ Save()
	{
		SValueBuilder sval;
		sval.PushDictionary();
		
		sval.PushBoolean("visible", m_visible);
		
%if MOD_PICKUP_RESPAWN
		if (!m_visible)
			sval.PushInteger("to-respawn", m_toRespawn);
%endif
			
		return sval.Build();
	}
	
	void PostLoad(SValue@ data)
	{
		auto visible = data.GetDictionaryEntry("visible");
		if (visible !is null && visible.GetType() == SValueType::Boolean)
		{
			if (!visible.GetBoolean())
			{
				Hide();
				
%if MOD_PICKUP_RESPAWN
				auto toRespawn = data.GetDictionaryEntry("to-respawn");
				if (toRespawn !is null && toRespawn.GetType() == SValueType::Integer)
					m_toRespawn = toRespawn.GetInteger();
%endif
			}
		}
	}

	void Hide()
	{
		if (!m_visible)
			return;
			
		m_visible = false;

		m_unit.SetHidden(true);
		m_unit.SetShouldCollide(false);
		
%if MOD_PICKUP_RESPAWN
		m_toRespawn = m_respawnTime;
%endif
	}

	void Show()
	{
		if (m_visible)
			return;

		m_visible = true;
		m_unit.SetHidden(false);
		m_unit.SetShouldCollide(true);
	}

	bool Picked(UnitPtr unit, bool force = false)
	{
		if (!m_visible && !force)
			return false;

		if (ApplyEffects(m_effects, null, unit, xy(m_unit.GetPosition()), vec2(0, 0), 1.0, false))
		{
			if (m_global)
			{
				if (cast<PlayerBase>(unit.GetScriptBehavior()) !is null)
					Hide();
			}
			else
			{
				if (cast<Player>(unit.GetScriptBehavior()) !is null)
					Hide();
			}

			Player@ plr = cast<Player>(unit.GetScriptBehavior());
			if (plr !is null)
			{
				plr.m_record.pickups++;
				plr.m_record.pickupsTotal++;
				if (Perks::ExplodingPickups !is null)
					Perks::ExplodingPickups.Do(plr, plr.GetDamageMul(AttackRangeType::Unspecified));
			}
			else
				PlaySound3D(m_sound, m_unit.GetPosition());

			return true;
		}

		return false;
	}

	bool NetPicked(UnitPtr unit)
	{
		if (!m_visible && Network::IsServer())
			return false;
		
		Picked(unit, true);
		PickedLocalFeedback();
		
		return true;
	}

	void PickedLocalFeedback()
	{
		PlaySound3D(m_sound, m_unit.GetPosition());
		Hide();
	}
	
	void Collide(UnitPtr unit, vec2 pos, vec2 normal)
	{
		if (!m_visible)
			return;

		ref@ b = unit.GetScriptBehavior();
		Player@ a = cast<Player>(b);
		if ((a is null && m_plrOnly) || (a !is null && a.m_record.IsDead()))
			return;
		
		bool picked = false;
		
		if (!m_secure || Network::IsServer())
		{
			if (Picked(unit))
			{
				PickedLocalFeedback();
				picked = true;
				
				if (m_global)
					(Network::Message("UnitPicked") << m_unit << unit).SendToAll();

				if (a !is null)
					(Network::Message("PlayerPickups") << a.m_record.pickups << a.m_record.pickupsTotal).SendToAll();
			}
		}
		else if (CanApplyEffects(m_effects, null, unit, xy(m_unit.GetPosition()), vec2(0, 0), 1.0))
		{
			PickedLocalFeedback();
			picked = true;
			
			(Network::Message("UnitPickSecure") << m_unit << unit).SendToHost();
		}
		
		if (picked && m_callbacks.length() > 0)
		{
			if (m_unit.GetUnitProducer().GetNetSyncMode() != NetSyncMode::None)
			{
				if (!Network::IsServer())
					(Network::Message("UnitPickCallback") << m_unit << unit).SendToHost();
				else
					CallbackPicked(unit);
			}
		}
	}
	
	void CallbackPicked(UnitPtr picker)
	{
		for (uint i = 0; i < m_callbacks.length(); i++)
			m_callbacks[i].UnitPicked(m_unit, picker);
	}
	

	void Update(int dt)
	{
		if (!m_visible)
		{
%if MOD_PICKUP_RESPAWN
			if (m_toRespawn > 0)
			{
				m_toRespawn -= dt;
				if (m_toRespawn <= 0)
					Show();
			}			
			else
				Destroy();
				
			return;
%else
			Destroy();
			return;
%endif
		}

		if (m_bounce)
		{
			const int tPeriod = 1000;
	
			uint time = g_scene.GetTime() % tPeriod;
			float h = (sin(time * PI * 2 / tPeriod) + 1.0) * 1.5;

			m_unit.SetPositionZ(h, true);
		}
	}
	
	void Destroy()
	{
		if (m_shouldDestroy)
			m_unit.Destroy();
	}
	
}

int g_totalPickups;
int g_totalPickupsTotal;
