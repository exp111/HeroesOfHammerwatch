namespace WorldScript
{
	[WorldScript color="238 232 170" icon="system/icons.png;256;0;32;32"]
	class SpawnUnit
	{
		vec3 Position;
	
		[Editable]
		UnitProducer@ UnitType;

		[Editable]
		string SceneName;

		[Editable]
		int Layer;
		
		[Editable default=false]
		bool AggroEnemy;
		
		UnitSource LastSpawned;
		UnitSource AllSpawned;
		
		bool m_needNetSync;
		
		void Initialize()
		{
			m_needNetSync = UnitType !is null && !IsNetsyncedExistance(UnitType.GetNetSyncMode());
		}
		
		UnitPtr ProduceUnit(int id, bool server)
		{
			if (UnitType is null)
			{
				auto script = WorldScript::GetWorldScript(g_scene, this);
				PrintError("Undefined UnitType in worldscript SpawnUnit with unit ID " + script.GetUnit().GetId());
				return UnitPtr();
			}

			vec3 pos = JitterSpawnPos(Position);
			
			UnitPtr u;
			
			if (server || m_needNetSync)
				u = UnitType.Produce(g_scene, pos, id);
			else
				u = g_scene.GetUnit(id);
				
			if (AggroEnemy)
			{
				auto enemyBehavior = cast<CompositeActorBehavior>(u.GetScriptBehavior());
				if (enemyBehavior !is null)
					enemyBehavior.MakeAggro();
			}
				
			if (SceneName != "")
				u.SetUnitScene(SceneName, true);
			if (Layer != 0)
				u.SetLayer(Layer);

			return u;
		}		
		
		SValue@ ServerExecute()
		{
			UnitPtr u = ProduceUnit(0, true);
			if (!u.IsValid())
				return null;

			LastSpawned.Replace(u);
			AllSpawned.Add(u);
			
			if (!m_needNetSync && SceneName == "")
				return null;
			
			SValueBuilder sval;
			sval.PushInteger(u.GetId());
			return sval.Build();
		}
		
		void ClientExecute(SValue@ val)
		{
			if (val is null)
				return;

			ProduceUnit(val.GetInteger(), false);
		}
	}
	
	
	vec3 JitterSpawnPos(vec3 pos)
	{
		//pos.x += randf() / 100.0;
		//pos.y += randf() / 100.0;
		return pos;
	}
}