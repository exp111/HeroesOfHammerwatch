class GiveGold : IEffect
{
	int m_amount;
	bool m_pickup;

	GiveGold(UnitPtr unit, SValue& params)
	{
		m_amount = GetParamInt(unit, params, "amount");
		m_pickup = GetParamBool(unit, params, "pickup", false, false);
	}
	
	void SetWeaponInformation(uint weapon) {}

	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;

		if (m_pickup)
			GiveGoldImpl(m_amount, GetLocalPlayer());
		else
			GiveGoldImpl(m_amount, cast<Player>(target.GetScriptBehavior()));

		return true;
	}

	bool CanApply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity) override
	{
		return true;
	}

	bool NeedsFilter()
	{
		return false;
	}
}

void GiveGoldImpl(int amount, Player@ player)
{
	if (player is null)
		return;

	amount = roll_round(amount * g_allModifiers.GoldGainScale(player));

	if (Fountain::HasEffect(FountainEffect::MoreGold))
		amount = int(amount * 1.5f);

	(Network::Message("PlayerGiveGold") << amount).SendToAll();

	NetGiveGoldImpl(amount, player);
}

void NetGiveGoldImpl(int amount, PlayerBase@ player)
{
	Stats::Add("gold-found", amount, player.m_record);
	Stats::Add("avg-gold-found", amount, player.m_record);

	auto gm = cast<Campaign>(g_gameMode);
	if (gm !is null)
	{
		ivec3 level = CalcLevel(gm.m_levelCount);
		Stats::Add("avg-gold-found-act-" + (level.x + 1), amount, player.m_record);
	}

	player.m_record.runGold += amount;
}
