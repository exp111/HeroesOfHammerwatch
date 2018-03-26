class PerkAction
{
	uint m_hash;
	IAction@ m_action;

	PerkAction(string id)
	{
		Init(HashString(id));
	}

	PerkAction(uint id)
	{
		Init(id);
	}

	void Init(uint id)
	{
		m_hash = id;

		SValue@ dat = Resources::GetSValue(id);
		string c = GetParamString(UnitPtr(), dat, "class");
		@m_action = cast<IAction>(InstantiateClass(c, UnitPtr(), dat));
	}

	void Do(Actor@ owner, float mul = 1.0f, vec2 pos = vec2(), vec2 dir = vec2())
	{
		if (pos.x == 0 && pos.y == 0)
			pos = xy(owner.m_unit.GetPosition());

		if (!Network::IsServer())
		{
			(Network::Message("PlayerPerkActionBegin") << m_hash << owner.m_unit << pos << dir << mul).SendToHost();
			return;
		}

		SValueBuilder builder;
		m_action.DoAction(builder, owner, null, pos, dir, mul);
		SValue@ params = builder.Build();

		(Network::Message("PlayerPerkAction") << m_hash << owner.m_unit << pos << dir << params).SendToAll();
	}

	void NetDo(SValue@ params, Actor@ owner, vec2 pos, vec2 dir)
	{
		m_action.NetDoAction(params, owner, pos, dir);
	}
}
