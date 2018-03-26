namespace Modifiers
{
	class BlockProjectile : Modifier
	{
		float m_arc;
		float m_offset;
	
		BlockProjectile(UnitPtr unit, SValue& params)
		{
			m_arc = GetParamInt(unit, params, "arc", true, 90) * PI / 180.0f / 2.0f;
			m_offset = GetParamInt(unit, params, "offset", false, 0) * PI / 180.0f / 2.0f + PI;
		}

		bool ProjectileBlock(PlayerBase@ player, IProjectile@ proj) override 
		{
			auto dir = proj.GetDirection();
			float a = player.m_dirAngle - (atan(dir.y, dir.x) + m_offset);
			a += (a > PI) ? -TwoPI : (a < -PI) ? TwoPI : 0;
						
			return (abs(a) % TwoPI) < m_arc;
		}
	}
}