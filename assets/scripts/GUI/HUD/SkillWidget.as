class SkillWidget : Widget
{
	GUIDef@ m_def;

	Skills::ActiveSkill@ m_skill;

	SkillWidget()
	{
		super();

		m_width = 0;
		m_height = 0;
	}

	Widget@ Clone() override
	{
		auto w = SkillWidget();
		w.SetSkill(m_skill);
		return w;
	}

	void SetSkill(Skills::Skill@ skill)
	{
		@m_skill = cast<Skills::ActiveSkill>(skill);
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		@m_def = ctx.GetGUIDef();
		Widget::Load(ctx);
	}

	void DoDraw(SpriteBatch& sb, vec2 pos) override
	{
		if (m_skill is null || m_skill.m_icon is null)
			return;

		int idt = 0;

		auto frame = m_skill.m_icon.GetFrame(0);
		vec4 p = vec4(pos.x, pos.y, frame.z, frame.w);

		auto texture_cd = Resources::GetTexture2D("gui/icons_skills_cd.png");
		if (texture_cd is null)
		{
			sb.EnableColorize(vec4(0.1,0.1,0.1, 1), vec4(2,2,2, 1), vec4(4,4,4, 1));
			sb.DrawSprite(m_skill.m_icon.m_texture, p, frame, vec4(4,4,4,1));
			sb.DisableColorize();
		}
		else
			sb.DrawSprite(texture_cd, p, frame);

		sb.DrawSpriteRadial(m_skill.m_icon.m_texture, p, frame, 1.0 - m_skill.GetCooldownProgess(idt), vec4(1,1,1,1));
	}
}

ref@ LoadSkillWidget(WidgetLoadingContext &ctx)
{
	SkillWidget@ w = SkillWidget();
	w.Load(ctx);
	return w;
}
