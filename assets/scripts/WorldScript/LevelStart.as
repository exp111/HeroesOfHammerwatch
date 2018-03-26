namespace WorldScript
{
	[WorldScript color="100 255 100" icon="system/icons.png;96;32;32;32"]
	class LevelStart
	{
		vec3 Position;
		bool Enabled;

		[Editable]
		string StartID;

		void Initialize()
		{
			m_levelStarts.insertLast(this);
		}

		SValue@ ServerExecute()
		{
			return null;
		}

		vec2 GetFormationOffset(int index, int count)
		{
			float dist = 32.0;
			float maxdist = count * dist;
			return vec2(-(maxdist / 2.0) + index * dist, -(dist / 2));
		}

		void DebugDraw(vec2 pos, SpriteBatch& sb)
		{
			float playerBox = 32.0;

			for (int i = 0; i < 4; i++)
			{
				vec4 color = ParseColorRGBA("#" + GetPlayerColor(i) + "7f");
				vec2 spawnPos = pos + GetFormationOffset(i, 4);

				sb.DrawRectangle(vec4(spawnPos.x, spawnPos.y, playerBox - 1, playerBox - 1), color);
			}
		}
	}
}
