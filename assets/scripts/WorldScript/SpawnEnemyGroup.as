namespace WorldScript
{
	[WorldScript color="#bf0000" icon="system/icons.png;32;192;32;32"]
	class SpawnEnemyGroup
	{
		vec3 Position;
	
		[Editable default=28]
		int Radius;
		
		
		SValue@ ServerExecute()
		{
			auto rndLevel = cast<RandomLevel>(g_gameMode);
			if (rndLevel !is null && rndLevel.m_enemyPlacer !is null)
				rndLevel.m_enemyPlacer.PlaceGroup(g_scene, xy(Position), Radius);
		
			return null;
		}
		
		void ClientExecute(SValue@ val)
		{

		}
		
		void DebugDraw(vec2 pos, SpriteBatch& sb)
		{
			sb.DrawCircle(pos, Radius, vec4(1, 0, 0, 1), 25);
		}
	}
}