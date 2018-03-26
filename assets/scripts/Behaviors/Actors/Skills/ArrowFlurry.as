namespace Skills
{
	class ArrowFlurry : Whirlnova
	{
		ArrowFlurry(UnitPtr unit, SValue& params)
		{
			super(unit, params);
			@m_projProd = cast<Skills::ShootProjectile>(cast<PlayerBase>(m_owner).m_skills[0]).m_projectile;
		}
	}
}