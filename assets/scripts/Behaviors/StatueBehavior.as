class StatueBehavior
{
	UnitPtr m_unit;

	TownStatue@ m_statue;

	StatueBehavior(UnitPtr unit, SValue& params)
	{
		m_unit = unit;
	}

	void SetStatue(TownStatue@ statue)
	{
		@m_statue = statue;

		m_unit.SetHidden(statue is null);
		// SetShouldCollide ?

		if (statue is null)
			return;

		auto def = statue.GetDef();
		m_unit.SetUnitScene(def.m_scene, true);
		m_unit.Colorize(def.m_colors[0], def.m_colors[1], def.m_colors[2]);

		m_unit.GetPhysicsBody().SetStatic(true);
	}
}
