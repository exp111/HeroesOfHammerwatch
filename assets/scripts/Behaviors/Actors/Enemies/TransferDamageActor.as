class TransferDamageActor : CompositeActorBehavior
{
	UnitPtr m_transferTarget;

	TransferDamageActor(UnitPtr unit, SValue& params)
	{
		super(unit, params);
	}

	SValue@ Save() override
	{
		SValueBuilder builder;
		builder.PushArray();

		builder.PushInteger(m_transferTarget.GetId());

		builder.PopArray();
		return builder.Build();
	}

	void Load(SValue@ data) override
	{
		// We leave this empty because we use PostLoad() to load something different than CompositeActorBehavior
	}

	void PostLoad(SValue@ data)
	{
		auto arr = data.GetArray();
		m_transferTarget = g_scene.GetUnit(arr[0].GetInteger());
	}

	int Damage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		int ret = CompositeActorBehavior::Damage(dmg, pos, dir);

		if (m_transferTarget.IsValid())
		{
			auto target = cast<IDamageTaker>(m_transferTarget.GetScriptBehavior());
			if (target !is null)
			{
				@dmg.Attacker = this;
				dmg.PhysicalDamage = ret;
				dmg.MagicalDamage = 0;
				dmg.ArmorMul = vec2();
				target.Damage(dmg, xy(m_transferTarget.GetPosition()), dir);
			}
		}

		return ret;
	}
}
