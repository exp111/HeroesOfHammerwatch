WorldScript::BossLichRoom@ g_lichRoom;

class BossLich : CompositeActorBehavior
{
	array<Actor@> m_actorsInside;

	int m_takeMana;
	int m_takeManaTime;
	int m_takeManaTimeC;

	array<UnitPtr> m_insideWalls;

	BossLich(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		m_takeMana = GetParamInt(unit, params, "take-mana", false, 5);
		m_takeManaTime = GetParamInt(unit, params, "take-mana-time", false, 100);
		m_takeManaTimeC = m_takeManaTime;
	}

	void Update(int dt) override
	{
		if (!g_lichRoom.IsInside(m_unit.GetPosition()) || m_insideWalls.length() > 0)
			@m_target = null;
		else if (m_target is null)
			m_targetSearchCd = 0;

		CompositeActorBehavior::Update(dt);

		for (uint i = 0; i < m_skills.length(); i++)
		{
			if (m_skills[i].IsCasting())
				return;
		}

		m_takeManaTimeC -= dt;
		if (m_takeManaTimeC <= 0)
		{
			m_takeManaTimeC = m_takeManaTime;

			for (uint i = 0; i < m_actorsInside.length(); i++)
			{
				auto player = cast<Player>(m_actorsInside[i]);
				if (player is null)
					continue;

				player.TakeMana(m_takeMana);
			}
		}
	}

	void Collide(UnitPtr unit, vec2 pos, vec2 normal)
	{
		auto actor = cast<Actor>(unit.GetScriptBehavior());
		if (actor is null)
			return;

		m_actorsInside.insertLast(actor);
	}

	void Collide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther) override
	{
		if (unit.GetScriptBehavior() is null && !fxOther.IsSensor())
			m_insideWalls.insertLast(unit);

		CompositeActorBehavior::Collide(unit, pos, normal, fxSelf, fxOther);
	}

	void EndCollision(UnitPtr unit)
	{
		int wallIndex = m_insideWalls.find(unit);
		if (wallIndex != -1)
			m_insideWalls.removeAt(wallIndex);

		auto actor = cast<Actor>(unit.GetScriptBehavior());
		if (actor is null)
			return;

		int index = m_actorsInside.findByRef(actor);
		if (index != -1)
			m_actorsInside.removeAt(index);
	}

	vec2 GetCastDirection() override
	{
		array<UnitPtr>@ results = g_scene.FetchActorsWithOtherTeam(Team, xy(m_unit.GetPosition()), 300);
		if (results.length() == 0)
			return GetDirection();

		UnitPtr closestUnit = results[0];
		float closestDistance = distsq(results[0].GetPosition(), m_unit.GetPosition());

		for (uint i = 1; i < results.length(); i++)
		{
			float distance = distsq(results[i].GetPosition(), m_unit.GetPosition());
			if (distance < closestDistance)
			{
				closestDistance = distance;
				closestUnit = results[i];
			}
		}

		return normalize(xy(closestUnit.GetPosition() - m_unit.GetPosition()));
	}

	bool IsTargetable() override
	{
		auto body = m_unit.GetPhysicsBody();
		if (body !is null && !body.IsStatic())
			return false;

		return CompositeActorBehavior::IsTargetable();
	}
}
