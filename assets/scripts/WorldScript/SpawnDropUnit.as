namespace WorldScript
{
	[WorldScript color="170 232 238" icon="system/icons.png;256;0;32;32"]
	class SpawnDropUnit : IOnDropped
	{
		vec3 Position;

		[Editable]
		UnitProducer@ UnitType;

		[Editable]
		string SceneName;

		[Editable default=100.0]
		float Height;

		[Editable default=0.05]
		float InitialFallSpeed;

		[Editable default=0.4]
		float MaxFallSpeed;

		[Editable default=1.1]
		float FallSpeedMultiplier;

		[Editable validation=IsExecutable]
		UnitFeed DropTrigger;
		
		[Editable default=false]
		bool AggroEnemy;
		
		
		UnitSource LastSpawned;
		UnitSource AllSpawned;
		

		bool IsExecutable(UnitPtr unit)
		{
			WorldScript@ script = WorldScript::GetWorldScript(unit);
			if (script is null)
				return false;

			return script.IsExecutable();
		}

		UnitPtr ProduceUnit(int id, vec3 pos)
		{
			auto prod = Resources::GetUnitProducer("system/drop_spawn.unit");
			if (prod is null)
				return UnitPtr();

			if (UnitType is null)
			{
				auto script = WorldScript::GetWorldScript(g_scene, this);
				PrintError("Undefined UnitType in worldscript SpawnDropUnit with unit ID " + script.GetUnit().GetId());
				return UnitPtr();
			}

			//TODO: Use UnitType's default scene if none is given?
			auto scene = UnitType.GetUnitScene(SceneName);
			if (scene is null)
			{
				PrintError("Scene '" + SceneName + "' is not found!");
				return UnitPtr();
			}

			UnitPtr u = prod.Produce(g_scene, pos, id);
			u.SetUnitScene(scene, true);
			auto dropper = cast<DropSpawnBehavior>(u.GetScriptBehavior());
			dropper.Initialize(this, UnitType, InitialFallSpeed, MaxFallSpeed, FallSpeedMultiplier, Height);
			
			return u;
		}

		SValue@ ServerExecute()
		{
			vec3 pos = JitterSpawnPos(Position);
			pos.z = Height;
		
			UnitPtr u = ProduceUnit(0, pos);

			SValueBuilder sval;
			sval.PushArray();
			sval.PushInteger(u.GetId());
			sval.PushVector3(u.GetPosition());
			sval.PopArray();
			return sval.Build();
		}

		void ClientExecute(SValue@ val)
		{
			auto arr = val.GetArray();
			ProduceUnit(arr[0].GetInteger(), arr[1].GetVector3());
		}
		
		void OnDropped(UnitPtr unit)
		{
			if (AggroEnemy)
			{
				auto enemyBehavior = cast<CompositeActorBehavior>(unit.GetScriptBehavior());
				if (enemyBehavior !is null)
					enemyBehavior.MakeAggro();
			}
		
			if (!Network::IsServer())
				return;
		
			if (unit.IsValid())
			{
				LastSpawned.Replace(unit);
				AllSpawned.Add(unit);
			}
		
			auto arr = DropTrigger.FetchAll();
			for (uint i = 0; i < arr.length(); i++)
			{
				auto script = WorldScript::GetWorldScript(arr[i]);
				if (script !is null)
					script.Execute();
			}
		}
	}
}
