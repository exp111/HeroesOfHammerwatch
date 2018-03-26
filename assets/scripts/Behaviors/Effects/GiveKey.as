class GiveKey : IEffect
{
	int m_lock;
	int m_amount;

	GiveKey(UnitPtr unit, SValue& params)
	{
		m_lock = GetParamInt(unit, params, "lock");
		m_amount = GetParamInt(unit, params, "amount", false, 1);
	}
	
	void SetWeaponInformation(uint weapon) {}

	bool Apply(Actor@ owner, UnitPtr target, vec2 pos, vec2 dir, float intensity, bool husk)
	{
		if (!CanApply(owner, target, pos, dir, intensity))
			return false;

		auto player = cast<Player>(target.GetScriptBehavior());
		if (player !is null)
		{
			int amount = int(m_amount * g_allModifiers.KeyGainScale(player));

			NetGiveKeyImpl(m_lock, amount, player);

			string strKeyValue = "";
			if (amount == 1)
				strKeyValue = Resources::GetString(".item.key");
			else
			{
				dictionary params = { { "num", amount } };
				strKeyValue = Resources::GetString(".item.key.plural", params);
			}
			AddFloatingText(FloatingTextType::Pickup, strKeyValue, player.m_unit.GetPosition());

			(Network::Message("PlayerGiveKey") << m_lock << amount).SendToAll();
		}

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

void NetGiveKeyImpl(int lock, int amount, PlayerBase@ player)
{
	player.m_record.keys[lock] += amount;
	Stats::Add("key-found-" + lock, amount, player.m_record);
}
