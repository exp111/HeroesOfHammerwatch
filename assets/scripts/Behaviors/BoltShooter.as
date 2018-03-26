class BoltShooter : IOwnedUnit
{
	UnitPtr m_unit;
	Actor@ m_owner;
	UnitScene@ m_fx;
	
	UnitScene@ m_loopFx;
	vec2 m_loopFxRadius;
	int m_loopFxInterval;
	int m_loopFxC;

	int m_ttl;
	int m_bolts;
	int m_height;
	int m_range;
	int m_spread;
	int m_shootC;
	bool m_attached;
	bool m_husk;
	bool m_useStormlash;
	Skills::Stormlash@ m_stormlash;
	
	float m_intensity;
	float m_consecutiveMul;
	UnitPtr m_lastUnit;
	
	array<IEffect@>@ m_effects;


	BoltShooter(UnitPtr unit, SValue& params)
	{
		m_unit = unit;
		
		m_ttl = GetParamInt(unit, params, "ttl", true, 2000);
		
		m_bolts = GetParamInt(unit, params, "bolts", true, 5);
		m_height = GetParamInt(unit, params, "height", false, 0);
		m_spread = GetParamInt(unit, params, "spread", false, 0);
		m_range = GetParamInt(unit, params, "range", true, 100);
		m_attached = GetParamBool(unit, params, "attached", false, false);
		m_useStormlash = GetParamBool(unit, params, "use-stormlash", false, true);
		m_consecutiveMul = GetParamFloat(unit, params, "consecutive-mul", false, 1.0f);
		
		@m_fx = Resources::GetEffect(GetParamString(unit, params, "fx", false));
		@m_effects = LoadEffects(unit, params);
		
		@m_loopFx = Resources::GetEffect(GetParamString(unit, params, "loop-fx", false));
		m_loopFxRadius = GetParamVec2(unit, params, "loop-fx-radius", false, vec2(100, 100));
		m_loopFxInterval = GetParamInt(unit, params, "loop-fx-interval", false, 100000);
		
		m_loopFxC = m_loopFxInterval;
		m_shootC = 0;
		
		m_intensity = 1.0f;
	}
	
	void Initialize(Actor@ owner, float intensity, bool husk)
	{
		@m_owner = owner;
		m_husk = husk;
		
		if (m_useStormlash)
		{
			auto player = cast<Player>(owner);
			if (player !is null)
				@m_stormlash = cast<Skills::Stormlash>(player.m_skills[6]);
		}
	}
	
	void Update(int dt)
	{
		if (m_attached)
			m_unit.SetPosition(m_owner.m_unit.GetPosition());

		m_loopFxC -= dt;
		while(m_loopFxC <= 0)
		{
			m_loopFxC += m_loopFxInterval;

			vec3 pos = m_unit.GetPosition() + xyz(randdir() * randf() * m_loopFxRadius, 0);
			PlayEffect(m_loopFx, pos);
		}
	
	
		m_shootC -= dt;
		m_ttl -= dt;
		
		while (m_shootC <= 0 && m_bolts > 0)
		{
			m_shootC += m_ttl / m_bolts;
			m_bolts--;
		
			vec2 pos = xy(m_unit.GetPosition());
			auto enemies = g_scene.FetchActorsWithOtherTeam(m_owner.Team, pos, m_range);
			for (int i = 0; i < int(enemies.length()); i++)
			{
				auto actor = cast<Actor>(enemies[i].GetScriptBehavior());
				if (actor is null || !actor.IsTargetable())
				{
					enemies.removeAt(i);
					i--;
				}
			}

			if (enemies.length() == 0)
				continue;
			
			int enemyi = randi(enemies.length());
			auto unit = enemies[enemyi];
			vec2 epos = xy(unit.GetPosition());
			auto diff = epos - pos;
			
			
			if (unit == m_lastUnit)
				m_intensity *= m_consecutiveMul;
			else
				m_intensity = 1.0f;
			
			m_lastUnit = unit;
			
			
			ApplyEffects(m_effects, m_owner, unit, epos, normalize(diff), m_intensity, m_husk);
			DrawLightningBolt(m_fx, pos + vec2(randi(m_spread) - m_spread / 2, randi(m_spread) - m_spread / 2 - m_height), epos + vec2(randi(8) - 4, randi(8) - 4));
			
			if (m_stormlash !is null && randf() <= m_stormlash.m_chance)
			{
				enemies.removeAt(enemyi);
				if (enemies.length() > 0)
				{
					auto unit2 = enemies[randi(enemies.length())];
					vec2 epos2 = xy(unit2.GetPosition());
					auto diff2 = epos2 - epos;
					
					ApplyEffects(m_effects, m_owner, unit2, epos2, normalize(diff2), m_stormlash.m_intensity * m_intensity, m_husk);
					DrawLightningBolt(m_fx, epos, epos2);
				}
			}			
		}

		if (m_ttl <= 0 && m_bolts <= 0)
		{
			m_unit.Destroy();
			return;
		}
	}
}

void DrawLightningBolt(UnitScene@ fx, vec2 from, vec2 to)
{
	if (fx is null)
		return;
	
	float length = dist(from, to);
	int segments = max(1, int(ceil(length / 30)));
	vec2 dir = (to - from) / length;
	float segLen = length / segments;
	vec2 side = vec2(-dir.y, dir.x);
	
	for (int i = 0; i < segments; i++)
	{
		vec2 a = from + dir * i * segLen;
		vec2 b = a + dir * segLen;

		if (i < segments -1)
			b = b + side * (randf() * 12 - 6);

		DrawLightningBoltSegment(fx, a, b);
	}
}

void DrawLightningBoltSegment(UnitScene@ fx, vec2 from, vec2 to)
{
	vec2 diff = to - from;
	dictionary ePs = { 
		{ 'dx', diff.x },
		{ 'dy', diff.y },
		{ 'angle', atan(diff.y, diff.x) },
		{ 'length', length(diff) }
	};
	
	PlayEffect(fx, from, ePs);
}

