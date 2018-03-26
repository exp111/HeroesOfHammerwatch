namespace Skills
{
	class ShatterMod : Modifiers::Modifier
	{
		float m_chance;
		Skills::ShootProjectileFan@ m_skill;
	
		ShatterMod(float chance, Skills::ShootProjectileFan@ skill)
		{
			m_chance = chance;
			@m_skill = skill;
		}	

		void TriggerEffects(PlayerBase@ player, Actor@ enemy, Modifiers::EffectTrigger trigger) override
		{ 
			if (trigger != Modifiers::EffectTrigger::Kill)
				return;
		
			if (randf() > m_chance)
				return;

			auto pos = xy(enemy.m_unit.GetPosition());

			SValueBuilder builder;
			m_skill.DoShoot(builder, pos, vec2(1, 0));
			(Network::Message("PlayerActiveSkillDoActivate") << m_skill.m_skillId << vec2() << builder.Build()).SendToAll();
		}
	}

	class Shatter : Skill
	{
		array<Modifiers::Modifier@> m_modifiers;

		Shatter(UnitPtr unit, SValue& params)
		{
			super(unit);
			
			float chance = GetParamFloat(unit, params, "chance", false, 0.5);

			auto projFan = cast<Skills::ShootProjectileFan>(cast<PlayerBase>(m_owner).m_skills[2]);
			if (projFan !is null)
				m_modifiers.insertLast(ShatterMod(chance, projFan));
		}

		array<Modifiers::Modifier@>@ GetModifiers() override
		{
			return m_modifiers;
		}
	}	
}