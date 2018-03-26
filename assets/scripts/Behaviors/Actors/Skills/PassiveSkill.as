namespace Skills
{
	class PassiveSkill : Skill
	{
		array<Modifiers::Modifier@> m_modifiers;
	
		PassiveSkill(UnitPtr unit, SValue& params)
		{
			super(unit);
			
			m_modifiers = Modifiers::LoadModifiers(unit, params);
		}

		array<Modifiers::Modifier@>@ GetModifiers() override
		{
			return m_modifiers;
		}
	}
}