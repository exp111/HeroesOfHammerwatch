class OverheadBossBar
{
	HUD@ m_hud;

	Actor@ m_actor;

	float m_checkpoint = -1;

	int m_barCount;
	int m_barOffset;

	BitmapString@ m_text;

	OverheadBossBar(HUD@ hud)
	{
		@m_hud = hud;
	}

	void Set(Actor@ actor, int barCount, int barOffset, string name)
	{
		BitmapFont@ font = Resources::GetBitmapFont("gui/fonts/font_hw8.fnt");

		@m_actor = actor;
		m_barCount = barCount;
		m_barOffset = barOffset;
		if (font !is null)
			@m_text = font.BuildText(Resources::GetString(name));
	}

	bool Draw(SpriteBatch& sb, int idt)
	{
		Actor@ a = m_actor;
		if (!a.m_unit.IsValid() || a.IsDead())
			return false;

		int barWidthPixels = m_barCount;
		int barHeight = 4;

		vec2 pos = ToScreenspace(a.m_unit.GetInterpolatedPosition(idt)) / g_gameMode.m_wndScale;
		pos += vec2(-(barWidthPixels) / 2, m_barOffset);

		if (m_hud.m_spriteBossbarOn is null)
		{
			float hp = a.GetHealth();

			vec4 fillRect = vec4(pos.x, pos.y, barWidthPixels, barHeight);
			sb.FillRectangle(fillRect, vec4(0, 0, 0, 1));

			vec4 barRect = fillRect;
			barRect.x += 1;
			barRect.y += 1;
			barRect.z -= 2;
			barRect.w -= 2;

			barRect.z *= hp;

			vec4 colorBar = lerp(vec4(1, 0, 0, 1), vec4(0, 1, 0, 1), hp);

			sb.FillRectangle(barRect, colorBar);

			return true;
		}

		int blockWidth = m_hud.m_spriteBossbarOn.GetWidth();
		barHeight = m_hud.m_spriteBossbarOn.GetHeight();
		barWidthPixels *= blockWidth;

		for (int j = 0; j < m_barCount; j++)
		{
			vec2 barPos = pos + vec2(j * blockWidth, 0);

			Sprite@ barSprite = m_hud.m_spriteBossbarOn;
			float factor = j / float(m_barCount);
			float hp = a.GetHealth();

			if (m_checkpoint >= 0 && factor > hp && factor > m_checkpoint)
				@barSprite = m_hud.m_spriteBossbarCheckpoint;
			else if (factor > hp)
				@barSprite = m_hud.m_spriteBossbarOff;
			else if (a.IsImmortal())
				@barSprite = m_hud.m_spriteBossbarInvuln;

			sb.DrawSprite(barPos, barSprite, g_menuTime);
		}

		if (m_text !is null)
		{
			sb.DrawString(vec2(
				pos.x + barWidthPixels / 2 - m_text.GetWidth() / 2,
				pos.y + barHeight / 2 - m_text.GetHeight() / 2 + 1
			), m_text);
		}

		return true;
	}
}
