namespace WorldScript
{
	class UnitCallbackList
	{
		array<UnitPtr> m_units;
		array<UnitEventCallbackId> m_callbacks;

		void RegisterEventCallback(UnitPtr unit, UnitEventType event, ref script, string func)
		{
			auto clbk = unit.RegisterEventCallback(event, script, func);
			m_units.insertLast(unit);
			m_callbacks.insertLast(clbk);
		}

		void UnregisterEventCallback(UnitPtr unit)
		{
			for (uint i = 0; i < m_units.length(); i++)
			{
				if (m_units[i] != unit)
					continue;

				m_units[i].UnregisterEventCallback(m_callbacks[i]);
				m_units.removeAt(i);
				m_callbacks.removeAt(i);
				return;
			}
		}
	}
}
