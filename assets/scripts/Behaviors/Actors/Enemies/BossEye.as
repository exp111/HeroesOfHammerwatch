class BossEye : CompositeActorBehavior
{
	UnitScene@ m_sceneDisappear;
	UnitScene@ m_sceneAppear;

	UnitProducer@ m_prod;

	int m_appearTimeC;
	int m_wispSyncTimeC;

	array<BossEyeWisp@> m_wisps;

	BossEye(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		@m_sceneDisappear = m_unit.GetUnitScene(GetParamString(unit, params, "scene-disappear"));
		@m_sceneAppear = m_unit.GetUnitScene(GetParamString(unit, params, "scene-appear"));

		@m_prod = Resources::GetUnitProducer(GetParamString(unit, params, "wisp-unit"));
	}

	void AddWisps(int num)
	{
		SValueBuilder builder;
		builder.PushArray();

		for (int i = 0; i < num; i++)
		{
			UnitPtr unit = m_prod.Produce(g_scene, m_unit.GetPosition());

			auto wisp = cast<BossEyeWisp>(unit.GetScriptBehavior());
			if (wisp is null)
				return;

			float angle = (i / float(num)) * PI * 2;
			wisp.Set(angle, this);

			builder.PushInteger(unit.GetId());

			m_wisps.insertLast(wisp);
		}

		builder.PopArray();
		(Network::Message("UnitEyeBossWispsAdded") << m_unit << builder.Build()).SendToAll();
	}

	void NetAddWisps(SValue@ params)
	{
		auto arr = params.GetArray();
		if (arr is null)
			return;

		uint num = arr.length();
		for (uint i = 0; i < num; i++)
		{
			int id = arr[i].GetInteger();

			UnitPtr unit = m_prod.Produce(g_scene, m_unit.GetPosition(), id);

			auto wisp = cast<BossEyeWisp>(unit.GetScriptBehavior());
			if (wisp is null)
				return;

			float angle = (i / float(num)) * PI * 2;
			wisp.Set(angle, this);

			m_wisps.insertLast(wisp);
		}
	}

	void ClearWisps()
	{
		for (uint i = 0; i < m_wisps.length(); i++)
			m_wisps[i].Disappear();
		m_wisps.removeRange(0, m_wisps.length());
	}

	void Suspend()
	{
		if (m_frozen)
			return;

		Freeze(true);
		m_unit.SetUnitScene(m_sceneDisappear, true);
	}
	
	void Freeze(bool freeze)
	{
		m_frozen = freeze;
		m_movement.m_enabled = !freeze;
		
		auto body = m_unit.GetPhysicsBody();
		if (body !is null)
			body.SetStatic(freeze);
	
	}

	bool IsTargetable() override
	{
		if (m_frozen)
			return false;
		return CompositeActorBehavior::IsTargetable();
	}

	void Unsuspend()
	{
		if (!m_frozen)
			return;

		m_unit.SetUnitScene(m_sceneAppear, true);
		m_appearTimeC = m_sceneAppear.Length();
	}

	void NetWispSync(SValue@ params)
	{
		auto arr = params.GetArray();
		if (arr is null)
			return;

		if (m_wisps.length() * 2 != arr.length())
			PrintError("Amount of local wisps does not match server wisps!");

		for (int i = 0; i < min(m_wisps.length(), arr.length() / 2); i++)
		{
			m_wisps[i].m_currAngle = arr[i * 2].GetFloat();
			m_wisps[i].m_currDistance = arr[i * 2 + 1].GetFloat();
		}
	}

	void Update(int dt) override
	{
		if (m_appearTimeC > 0)
		{
			m_appearTimeC -= dt;
			if (m_appearTimeC <= 0)
			{
				Freeze(false);
				m_wispSyncTimeC = 2000;
			}
		}

		FindWispTargets();

		if (m_wispSyncTimeC > 0 && Network::IsServer())
		{
			m_wispSyncTimeC -= dt;
			if (m_wispSyncTimeC <= 0)
			{
				m_wispSyncTimeC = 2000;
				SValueBuilder builder;
				builder.PushArray();
				for (uint i = 0; i < m_wisps.length(); i++)
				{
					builder.PushFloat(m_wisps[i].m_currAngle);
					builder.PushFloat(m_wisps[i].m_currDistance);
				}
				builder.PopArray();
				(Network::Message("UnitEyeBossWispsSync") << m_unit << builder.Build()).SendToAll();
			}
		}

		CompositeActorBehavior::Update(dt);
	}

	void FindWispTargets()
	{
		array<PlayerRecord@> players;
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer != 255 && !g_players[i].IsDead())
				players.insertLast(g_players[i]);
		}
		players.sortAsc();

		if (players.length() > 0)
		{
			for (uint i = 0; i < m_wisps.length(); i++)
				@m_wisps[i].m_target = players[i % players.length()].actor;
		}
	}
}
