namespace Modifiers
{
	class ManaGain : Modifier
	{
		float m_scale;

		ManaGain(UnitPtr unit, SValue& params)
		{
			m_scale = GetParamFloat(unit, params, "scale", false, 1);
		}

		float ManaGainScale(PlayerBase@ player) override { return m_scale; }
	}
}
