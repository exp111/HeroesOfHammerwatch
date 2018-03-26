namespace Skills
{
	class ShootProjectileFan : ShootProjectile
	{
		ShootProjectileFan(UnitPtr unit, SValue& params)
		{
			super(unit, params);
		}
		
		vec2 GetShootDir(vec2 dir, int i) override
		{
			if ((m_spread > 0 || m_spreadMin > 0) && m_projectiles > 1)
			{
				float step = m_spread / (m_projectiles - 1);
				float ang = atan(dir.y, dir.x) - m_spread / 2.0 + i * step;

				return vec2(cos(ang), sin(ang));
			}
			
			return dir;
		}
	}
}