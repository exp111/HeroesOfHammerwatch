namespace WorldScript
{
	[WorldScript color="255 0 0" icon="system/icons.png;32;32;32;32"]
	class Wind
	{
		vec3 Position;
		bool Enabled;
		
		[Editable default=100 min=1]
		int Radius;
	
		[Editable default=0]
		int Direction;
		
		[Editable default=0.5]
		float Strength;
		
		[Editable default=1000]
		int ChangeTime;
		
		float m_intensity;
		vec2 m_dir;
		
		void Initialize()
		{
			float ang = Direction / 180.f * PI;
			m_dir = vec2(cos(ang), sin(ang)) * Strength;
			m_intensity = Enabled ? 1.0f : 0.0f;
		}
		
		void DebugDraw(vec2 pos, SpriteBatch& sb)
		{
			sb.DrawCircle(pos, Radius, vec4(1, 0, 0, 1), 25);
			
			float ang = Direction / 180.f * PI;
			vec2 dir = vec2(cos(ang), sin(ang)) * 20;
			sb.DrawArrow(pos - dir, pos + dir, 3, 15, vec4(1, 0, 0, 1));
		}

		void PostUpdate(int dt)
		{
			const float changeSpeed = 1.0f / ChangeTime;
			m_intensity = clamp(m_intensity + dt * (Enabled ? changeSpeed : -changeSpeed), 0.0f, 1.0f);
		
			if (m_intensity <= 0.0f)
				return;
		
			auto res = g_scene.QueryCircle(xy(Position), Radius, ~0, RaycastType::Any, false);
			for (uint i = 0; i < res.length(); i++)
			{
				auto husk = cast<PlayerHusk>(res[i].GetScriptBehavior());
				if (husk is null)
				{
					auto body = res[i].GetPhysicsBody();
					auto vel = body.GetLinearVelocity();
					body.SetLinearVelocity(vel + m_dir * m_intensity);
				}
			}
		}
	}
}