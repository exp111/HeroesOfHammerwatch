namespace Modifiers
{
	class OreGain : Modifier
	{
		float m_scale;
		float m_chance;

		OreGain(UnitPtr unit, SValue& params)
		{
			m_scale = GetParamFloat(unit, params, "scale", false, 1);
			m_chance = GetParamFloat(unit, params, "chance", false, 1);
		}

		float OreGainScale(PlayerBase@ player) override
		{
			if (randf() <= m_chance)
				return m_scale;
			return 1;
		}
	}
}
