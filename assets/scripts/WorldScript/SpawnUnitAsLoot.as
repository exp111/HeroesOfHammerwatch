namespace WorldScript
{
	[WorldScript color="138 132 170" icon="system/icons.png;256;0;32;32"]
	class SpawnUnitAsLoot
	{
		[Editable]
		UnitProducer@ UnitType;
		
		[Editable]
		UnitFeed SpawnOn;

		[Editable default=0]
		float JitterX;
		[Editable default=0]
		float JitterY;
		
		UnitSource LastSpawned;
		UnitSource AllSpawned;
		
		bool m_needNetSync;
		
		void Initialize()
		{
			m_needNetSync = !IsNetsyncedExistance(UnitType.GetNetSyncMode());
		}
		
		UnitPtr ProduceUnit(vec3 pos, int id)
		{
			pos = JitterSpawnPos(pos);
			return UnitType.Produce(g_scene, pos, id);
		}		
		
		SValue@ ServerExecute()
		{
			LastSpawned.Clear();

			auto units = SpawnOn.FetchAll();
			if (m_needNetSync)
			{
				SValueBuilder sval;
				sval.PushArray();
				
				for (uint i = 0; i < units.length(); i++)
				{
					vec2 pos = xy(units[i].GetPosition());

					pos.x += (randf() * 2.0 - 1.0) * JitterX;
					pos.y += (randf() * 2.0 - 1.0) * JitterY;

					UnitPtr u = ProduceUnit(vec3(pos.x, pos.y, 0), 0);
					sval.PushInteger(u.GetId());
					sval.PushVector2(pos);
					
					LastSpawned.Add(u);
					AllSpawned.Add(u);
				}
				
				sval.PopArray();
				return sval.Build();
			}
			else
			{
				for (uint i = 0; i < units.length(); i++)
				{
					vec2 pos = xy(units[i].GetPosition());

					pos.x += (randf() * 2.0 - 1.0) * JitterX;
					pos.y += (randf() * 2.0 - 1.0) * JitterY;

					UnitPtr u = ProduceUnit(vec3(pos.x, pos.y, 0), 0);
					
					LastSpawned.Add(u);
					AllSpawned.Add(u);
				}
				
				return null;
			}
		}
		
		void ClientExecute(SValue@ val)
		{
			if (val is null)
				return;
		
			auto data = val.GetArray();
			for (uint i = 0; i < data.length(); i += 2)
			{
				vec2 pos = data[i * 2 + 1].GetVector2();
				ProduceUnit(vec3(pos.x, pos.y, 0), data[i * 2].GetInteger());
			}
		}
	}
}