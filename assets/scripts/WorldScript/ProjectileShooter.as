namespace WorldScript
{
	[WorldScript color="255 0 0" icon="system/icons.png;416;160;32;32"]
	class ProjectileShooter
	{
		vec3 Position;
	
		[Editable]
		UnitProducer@ Projectile;
		
		[Editable default=0]
		int Direction;
		
		[Editable default=0]
		int Spread;
		
		
		UnitPtr ProduceProjectile(int id)
		{
			UnitPtr proj = Projectile.Produce(g_scene, Position, id);
			if (!proj.IsValid())
				return UnitPtr();

			return proj;
		}
		
		SValue@ ServerExecute()
		{
			UnitPtr proj = ProduceProjectile(0);
			if (!proj.IsValid())
				return null;
				
			IProjectile@ p = cast<IProjectile>(proj.GetScriptBehavior());
			if (p is null)
				return null;
			
			float ang = Direction;
			ang += randf() * Spread - Spread / 2.f;
			ang = ang / 180.f * PI;
		
			p.Initialize(null, vec2(cos(ang), sin(ang)), 1.0, false, null, 0);
			
			
			SValueBuilder sval;
			sval.PushArray();
			sval.PushInteger(proj.GetId());
			sval.PushFloat(ang);
			return sval.Build();
		}
		
		void ClientExecute(SValue@ val)
		{
			if (val is null)
				return;
		
			auto arr = val.GetArray();

			UnitPtr proj = ProduceProjectile(arr[0].GetInteger());
			if (!proj.IsValid())
				return;
				
			IProjectile@ p = cast<IProjectile>(proj.GetScriptBehavior());
			if (p is null)
				return;
			
			auto ang = arr[1].GetFloat();
			p.Initialize(null, vec2(cos(ang), sin(ang)), 1.0, true, null, 0);
		}
	}
}