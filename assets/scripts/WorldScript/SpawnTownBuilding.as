namespace WorldScript
{
	[WorldScript color="#DBB1DE" icon="system/icons.png;192;288;32;32"]
	class SpawnTownBuilding
	{
		vec3 Position;

		[Editable]
		string TypeName;


		/*
		int m_debugDrawLastDistance;

		void DebugDrawRect(vec2 pos, SpriteBatch& sb, int distance, vec4 color)
		{
			vec4 rect;

			// Left, Right, Top, Bottom
			rect = vec4(pos.x - distance, pos.y - 16, 1, 32); sb.DrawSprite(null, rect, rect, color);
			rect = vec4(pos.x + distance, pos.y - 16, 1, 32); sb.DrawSprite(null, rect, rect, color);
			rect = vec4(pos.x - 16, pos.y - distance, 32, 1); sb.DrawSprite(null, rect, rect, color);
			rect = vec4(pos.x - 16, pos.y + distance, 32, 1); sb.DrawSprite(null, rect, rect, color);

			int lineDistance = distance - m_debugDrawLastDistance;

			// Left, Right, Top, Bottom
			rect = vec4(pos.x - distance + 1, pos.y, lineDistance - 1, 1); sb.DrawSprite(null, rect, rect, color);
			rect = vec4(pos.x + distance - lineDistance + 1, pos.y, lineDistance - 1, 1); sb.DrawSprite(null, rect, rect, color);
			rect = vec4(pos.x, pos.y - distance + 1, 1, lineDistance - 1); sb.DrawSprite(null, rect, rect, color);
			rect = vec4(pos.x, pos.y + distance - lineDistance + 1, 1, lineDistance - 1); sb.DrawSprite(null, rect, rect, color);

			m_debugDrawLastDistance = distance;
		}

		void DebugDraw(vec2 pos, SpriteBatch& sb)
		{
			m_debugDrawLastDistance = 0;

			DebugDrawRect(pos, sb, 64, vec4(1, 1, 1, 0.25));
			DebugDrawRect(pos, sb, 128, vec4(0, 0, 1, 0.25));
			DebugDrawRect(pos, sb, 192, vec4(1, 1, 0, 0.25));
		}
		*/
	}
}
