namespace WorldScript
{
	[WorldScript color="238 232 170" icon="system/icons.png;256;0;32;32"]
	class SpawnPrefab
	{
		vec3 Position;
	
		[Editable]
		Prefab@ Prefab;
		
		
		SValue@ ServerExecute()
		{
			if (Prefab !is null)
				Prefab.Fabricate(g_scene, Position);

			return null;
		}
		
		void ClientExecute(SValue@ val)
		{
			ServerExecute();
		}
	}
}