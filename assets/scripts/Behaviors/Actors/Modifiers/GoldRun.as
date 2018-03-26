namespace Modifiers
{
	class GoldRun : Modifier
	{
		float m_scale;

		GoldRun(UnitPtr unit, SValue& params)
		{
			m_scale = GetParamFloat(unit, params, "scale", false, 1);
		}

		float GoldRunScale() override { return m_scale; }
	}
}
