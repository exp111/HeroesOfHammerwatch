namespace Modifiers
{
	class GoldGain : Modifier
	{
		float m_scale;

		GoldGain(UnitPtr unit, SValue& params)
		{
			m_scale = GetParamFloat(unit, params, "scale", false, 1);
		}

		float GoldGainScale(PlayerBase@ player) override { return m_scale; }
	}
}
