class SpawnUnit : IAction, IEffect
{
	UnitProducer@ m_unit;
	int m_spawnDist;
	bool m_safeSpawning;
	vec2 m_offset;
	bool m_needNetSync;
	bool m_aggro;
	
	string m_sceneName;
	int m_layer;
	
	SpawnUnit(UnitPtr unit, SValue& params)
	{
		@m_unit = Resources::GetUnitProducer(GetParamString(unit, params, "unit"));
		m_safeSpawning = GetParamBool(unit, params, "safe-spawn", false);
		m_spawnDist = GetParamInt(unit, params, "spawn-dist", false);
		m_offset = GetParamVec2(unit, params, "offset", false);
		m_sceneName = GetParamString(unit, params, "scene", false, "");
		m_layer = GetParamInt(unit, params, "layer", false, 0);
		m_aggro = GetParamBool(unit, params, "aggro", false, false);

		m_needNetSync = !IsNetsyncedExistance(m_unit.GetNetSyncMode());
	}
	
	bool NeedNetParams() { return true; }
	void SetWeaponInformation(uint weapon) {}
	
	bool DoAction(SValueBuilder@ builder, Actor@ owner, Actor@ target, vec2 pos, vec2 dir, float intensity)
	{
		if (!m_needNetSync && !Network::IsServer())
		{
			builder.PushFloat(intensity);
			return true;
		}
	
		DoSpawnUnits(builder, owner, pos, dir, intensity, false);
		return true;
	}
	
	UnitPtr DoSpawnUnits(SValueBuilder@ builder, Actor@ owner, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		dir *= m_spawnDist;
		
		if (!m_safeSpawning)
			return DoSpawnUnit(builder, pos + dir, owner, intensity, husk);
		else
		{
			if (m_spawnDist == 0)
			{
				bool canSpawn = true;
				auto res = g_scene.QueryRect(pos, 1, 1, ~0, RaycastType::Any);
				for (uint i = 0; i < res.length; i++)
				{
					if (owner.m_unit != res[i])
					{
						canSpawn = false;
						break;
					}
				}
				
				if (canSpawn)
					return DoSpawnUnit(builder, pos, owner, intensity, husk);
				else
					builder.PushNull();
			}
			else
			{
				if (!g_scene.RaycastQuick(pos, pos + dir, ~0, RaycastType::Any))
					return DoSpawnUnit(builder, pos + dir, owner, intensity, husk);
				else if (!g_scene.RaycastQuick(pos, vec2(pos.x, pos.y - m_spawnDist), ~0, RaycastType::Any))
					return DoSpawnUnit(builder, vec2(pos.x, pos.y - m_spawnDist), owner, intensity, husk);
				else if (!g_scene.RaycastQuick(pos, vec2(pos.x, pos.y + m_spawnDist), ~0, RaycastType::Any))
					return DoSpawnUnit(builder, vec2(pos.x, pos.y + m_spawnDist), owner, intensity, husk);
				else if (!g_scene.RaycastQuick(pos, vec2(pos.x - m_spawnDist, pos.y), ~0, RaycastType::Any))
					return DoSpawnUnit(builder, vec2(pos.x - m_spawnDist, pos.y), owner, intensity, husk);
				else if (!g_scene.RaycastQuick(pos, vec2(pos.x + m_spawnDist, pos.y), ~0, RaycastType::Any))
					return DoSpawnUnit(builder, vec2(pos.x + m_spawnDist, pos.y), owner, intensity, husk);
				else
					builder.PushNull();
			}
		}
		
		return UnitPtr();
	}

	UnitPtr LocalSpawnUnit(vec2 pos, Actor@ owner, float intensity, bool husk, int id = 0)
	{
		auto unit = m_unit.Produce(g_scene, xyz(pos), id);
		
		if (m_sceneName != "")
			unit.SetUnitScene(m_sceneName, true);
				
		if (m_layer != 0)
			unit.SetLayer(m_layer);

		if (m_aggro)
		{
			auto enemyBehavior = cast<CompositeActorBehavior>(unit.GetScriptBehavior());
			if (enemyBehavior !is null)
				enemyBehavior.MakeAggro();
		}
		
		if (owner !is null)
		{
			auto ownedUnit = cast<IOwnedUnit>(unit.GetScriptBehavior());
			if (ownedUnit !is null)
			{
				ownedUnit.Initialize(owner, intensity, husk);
				if (Network::IsServer() && !m_needNetSync)
					(Network::Message("SetOwnedUnit") << unit << owner.m_unit << intensity).SendToAll();
			}
		}

		return unit;
	}
	
	UnitPtr DoSpawnUnit(SValueBuilder@ builder, vec2 pos, Actor@ owner, float intensity, bool husk)
	{
		pos += m_offset;
		UnitPtr unit = LocalSpawnUnit(pos, owner, intensity, husk);
		
		if (builder !is null)
		{
			if (m_needNetSync)
			{
				builder.PushArray();
				builder.PushVector2(pos);
				builder.PushInteger(unit.GetId());
				builder.PushFloat(intensity);
				builder.PopArray();
			}
			else 
				builder.PushNull();
		}
		
		return unit;
	}
	
	bool NetDoAction(SValue@ param, Actor@ owner, vec2 pos, vec2 dir)
	{
		if (m_needNetSync)
		{
			array<SValue@>@ p = param.GetArray();
			LocalSpawnUnit(p[0].GetVector2(), owner, p[2].GetFloat(), true, p[1].GetInteger());
		}
		else if (Network::IsServer())
		{
			float intensity = param.GetFloat();
			auto unit = DoSpawnUnits(null, owner, pos, dir, intensity, false);
			if (owner !is null)
			{
				auto ownedUnit = cast<IOwnedUnit>(unit.GetScriptBehavior());
				if (ownedUnit !is null)
				{
					ownedUnit.Initialize(owner, intensity, false);
					(Network::Message("SetOwnedUnit") << unit << owner.m_unit << intensity).SendToAll();
				}
			}
		}
		
		return true;
	}
	
	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (m_needNetSync)
		{
			if (m_unit.GetNetSyncMode() == NetSyncMode::Manual)
			{
				PrintError("Can't spawn a manually netsynced unit with SpawnUnit effect");
				return false;
			}
		}
		else if (!Network::IsServer())
			return true;

		DoSpawnUnits(null, owner, pos, dir, intensity, husk);
		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		return true;
	}
	
	void Update(int dt, int cooldown)
	{
	}

	bool NeedsFilter()
	{
		return true;
	}
}