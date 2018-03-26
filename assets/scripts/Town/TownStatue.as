class TownStatue
{
	string m_id;
	int m_level;

	bool m_sculpted;

	Statues::StatueLevelDef@ GetDef()
	{
		return Statues::GetStatue(m_id, m_level);
	}

	void Save(SValueBuilder& builder)
	{
		builder.PushDictionary(m_id);
		builder.PushInteger("level", m_level);
		builder.PushBoolean("sculpted", m_sculpted);
		builder.PopDictionary();
	}

	void Load(SValue@ sv)
	{
		if (sv.GetType() == SValueType::Integer)
			m_level = sv.GetInteger();
		else
		{
			m_level = GetParamInt(UnitPtr(), sv, "level");
			m_sculpted = GetParamBool(UnitPtr(), sv, "sculpted");
		}
	}
}
