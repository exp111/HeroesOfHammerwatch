class ScalableSpriteIconButtonWidget : ScalableSpriteButtonWidget
{
	Sprite@ m_icon;
	int m_iconSpacing;

	ScalableSpriteIconButtonWidget()
	{
		super();
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		ScalableSpriteButtonWidget::Load(ctx);

		auto def = ctx.GetGUIDef();

		@m_icon = def.GetSprite(ctx.GetString("icon"));
		m_iconSpacing = ctx.GetInteger("icon-spacing", false, 2);
	}

	void DoDraw(SpriteBatch& sb, vec2 pos) override
	{
		ScalableSpriteButtonWidget::DoDraw(sb, pos);

		vec2 posIcon(
			m_width / 2.0f + m_text.GetWidth() / 2.0f + m_iconSpacing,
			m_height / 2.0f - m_icon.GetHeight() / 2.0f + m_textOffset.y
		);
		sb.DrawSprite(pos + posIcon, m_icon, g_menuTime);
	}
}

ref@ LoadScalableSpriteIconButtonWidget(WidgetLoadingContext &ctx)
{
	ScalableSpriteIconButtonWidget@ w = ScalableSpriteIconButtonWidget();
	w.Load(ctx);
	return w;
}
