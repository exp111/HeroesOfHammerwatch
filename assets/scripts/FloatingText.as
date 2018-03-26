array<FloatingText@> g_floatingTexts;

enum FloatingTextType
{
	PlayerHurt,
	PlayerHurtMagical,
	PlayerHealed,
	PlayerArmor,
	PlayerAmmo,
	EnemyHurt,
	EnemyHurtHusk,
	EnemyHealed,
	EnemyImmortal,
	Pickup
}

class FloatingText
{
	BitmapString@ m_text;
	FloatingTextType m_type;

	string m_consoleColor;
	string m_floatingText;
	int m_num;
	vec3 m_pos;

	int m_ttl;
	int m_timeLived;
	bool m_alive;

	FloatingText(FloatingTextType type, string color, string text, vec3 pos)
	{
		if (type == FloatingTextType::Pickup)
			@m_text = g_floatTextFontBig.BuildText(color + text, -1, TextAlignment::Center);
		else
			@m_text = g_floatTextFont.BuildText(color + text, -1, TextAlignment::Center);
		m_type = type;

		m_consoleColor = color;
		m_floatingText = text;
		m_pos = pos;
		m_pos.x += randi(8) - 4;
		m_pos.y += randi(8) - 4;

		m_ttl = Tweak::FloatingTextTime;
		m_alive = true;
	}

	void SetColor(string color)
	{
		m_consoleColor = color;
		@m_text = g_floatTextFont.BuildText(color + m_floatingText, -1, TextAlignment::Center);
	}

	void Update(int dt)
	{
		m_ttl -= dt;
		m_timeLived += dt;
		m_pos.y -= dt * FloatingTextSpeed;

		if (m_ttl <= 0)
			m_alive = false;
	}

	void Draw(int idt, SpriteBatch &sb)
	{
		vec3 pos = m_pos;
		pos.y -= idt * FloatingTextSpeed;

		vec2 p = ToScreenspace(pos);
		p.x -= m_text.GetWidth();

		sb.DrawString(p / g_gameMode.m_wndScale, m_text);
	}
}

FloatingText@ AddFloatingText(FloatingTextType type, string text, vec3 pos)
{
%if MOD_NO_HUD
	return null;
%else

	if (!GetVarBool("ui_txt"))
		return null;

	vec2 p = ToScreenspace(pos) / g_gameMode.m_wndScale;
	if (p.x < 0 || p.x > g_gameMode.m_wndWidth || p.y < 0 || p.y > g_gameMode.m_wndHeight)
		return null;

	string color;

	if (type == FloatingTextType::PlayerHurt)
		color = GetConsoleColor("ui_txt_plr_hurt");
	else if (type == FloatingTextType::PlayerHurtMagical)
		color = GetConsoleColor("ui_txt_plr_hurt_magic");
	else if (type == FloatingTextType::EnemyHurt)
		color = GetConsoleColor("ui_txt_enemy_hurt");
	else if (type == FloatingTextType::EnemyHurtHusk)
		color = GetConsoleColor("ui_txt_enemy_hurt_husk");
	else if (type == FloatingTextType::PlayerHealed)
		color = GetConsoleColor("ui_txt_plr_heal");
	else if (type == FloatingTextType::EnemyHealed)
		color = GetConsoleColor("ui_txt_enemy_heal");
	else if (type == FloatingTextType::EnemyImmortal)
		color = GetConsoleColor("ui_txt_enemy_immortal");
	else if (type == FloatingTextType::PlayerArmor)
		color = GetConsoleColor("ui_txt_plr_armor");
	else if (type == FloatingTextType::PlayerAmmo)
		color = GetConsoleColor("ui_txt_plr_ammo");
	else if (type == FloatingTextType::Pickup)
		color = GetConsoleColor("ui_txt_pickup");

	if (color == "")
		return null;

	FloatingText@ fTxt = FloatingText(type, color, text, pos);
	g_floatingTexts.insertLast(fTxt);

	return fTxt;
%endif
}

FloatingText@ AddFloatingNumber(FloatingTextType type, int num, vec3 pos)
{
	FloatingText@ fTxt = AddFloatingText(type, "" + num, pos);
	if (fTxt !is null)
		fTxt.m_num = num;
	return fTxt;
}
