class PathFollower
{
	array<vec2>@ m_path;
	uint m_currNode;
	
	int m_unitRadius;
	int m_maxRange;
	
	bool m_flying;
	vec2 m_flyingDir;
	
	UnitPtr m_owner;
	
	vec2 m_cachedTargetPos;
	vec2 m_cachedTargetFrom;
	uint m_newPathfindTime;
	
	vec2 m_lastPos;
	float m_visualDir;
	
	void Initialize(UnitPtr unit, int maxRange, bool flying)
	{
		m_owner = unit;
		m_unitRadius = unit.GetPhysicsBody().GetEstimatedRadius();
		m_maxRange = maxRange;
		m_flying = flying;
		m_flyingDir = randdir();
		
		if (m_flying)
			unit.SetShouldCollide(false);
	}
	
	void QueuedPathfind(array<vec2>@ path)
	{
		if (path.length() <= 1)
			@m_path = null;
		else
			@m_path = path;

		m_currNode = 1;
	}
	
	vec2 FollowPath(vec2 from, vec2 to)
	{
		if (lengthsq(to - from) <= 2 * 2)
			return vec2();
	
		if (m_flying)
		{
			auto dir = normalize(to - from);
			dir = normalize(dir + m_flyingDir * 0.33);
			m_visualDir = atan(dir.y, dir.x);
			return dir;
		}
	
		return FollowPathPathfind(from, to);
	}
	
	vec2 FollowPathPathfind(vec2 from, vec2 to)
	{
		if (Network::IsServer())
		{
			auto currTime = g_scene.GetTime();
			if (m_newPathfindTime < currTime || lengthsq(to - m_cachedTargetPos) > 25 * 25)
			{
				//@m_path = null;
				
				float maxRange = Tweak::EnemyInfitniteAggro ? -1.f : float(m_maxRange);
				g_scene.QueuePathfind(m_owner, from, to, m_unitRadius, maxRange, maxRange);
				
				m_cachedTargetPos = to;
				m_cachedTargetFrom = from;
				m_newPathfindTime = currTime + 500 + randi(1000);
			}
		}

		if (m_path !is null)
		{	
			if (m_path.length() > m_currNode + 1)
			{
				float dt = dot(m_path[m_currNode] - m_path[m_currNode + 1], from - m_path[m_currNode + 1]);
				if (dt > 0 && dt < lengthsq(m_path[m_currNode] - m_path[m_currNode + 1]))
					m_currNode++;
			}
			else if (m_path.length() > m_currNode && lengthsq(from - m_path[m_currNode]) < 10 * 10)
				m_currNode = m_path.length();

			vec2 dir;
			if (m_path.length() > m_currNode)
				dir = m_path[m_currNode] - from;
			else
				dir = to - from;
			
			m_visualDir = atan(dir.y, dir.x);
			
			float l = length(dir);
			if (l > 0)
			{
				if (distsq(m_lastPos, from) <= 0.1)
				{
					m_lastPos = from;
					
					float ang = atan(dir.y, dir.x);
					float da = PI / 4.0f;
					
					auto d1 = vec2(cos(ang + da), sin(ang + da));
					auto d2 = vec2(cos(ang - da), sin(ang - da));

					bool b1 = g_scene.RaycastQuick(from, from + d1 * m_unitRadius * 2, ~0, RaycastType::Any);
					bool b2 = g_scene.RaycastQuick(from, from + d2 * m_unitRadius * 2, ~0, RaycastType::Any);
					
					if (b1 != b2)
					{
						if (b1)
							return d1;
							
						return d2;
					}
				}
			
				m_lastPos = from;
				return dir / l;
			}
			else
			{
				m_currNode++;
				return vec2();
			}
		}
		
		return vec2();
	}
}