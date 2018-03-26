class GroupRectWidget : RectWidget
{
	bool m_dynamicWidth;
	bool m_dynamicHeight;
	bool m_innerSz;

	GroupRectWidget()
	{
		super();
	}

	Widget@ Clone() override
	{
		GroupRectWidget@ w = GroupRectWidget();
		CloneInto(w);
		return w;
	}

	void LoadWidthHeight(WidgetLoadingContext &ctx, bool required = true) override
	{
		// :D
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		int w = ctx.GetInteger("width", false, -1);
		int h = ctx.GetInteger("height", false, -1);

		m_innerSz = ctx.GetBoolean("inner", false, false);

		if (w != -1)
		{
			m_width = w;
			m_dynamicWidth = false;
		}
		else
			m_dynamicWidth = true;

		if (h != -1)
		{
			m_height = h;
			m_dynamicHeight = false;
		}
		else
			m_dynamicHeight = true;

		RectWidget::Load(ctx);
	}

	void DoLayout(vec2 origin, vec2 parentSz) override
	{
		if (!m_innerSz && (m_dynamicWidth || m_dynamicHeight))
		{
			if (m_dynamicWidth)
				m_width = int(parentSz.x);
			if (m_dynamicHeight)
				m_height = int(parentSz.y);

			if (m_offset.x > 0)
				m_width -= int(m_offset.x * 2);
			if (m_offset.y > 0)
				m_height -= int(m_offset.y * 2);

			//CalculateOrigin(origin, parentSz);
		}

		RectWidget::DoLayout(origin, parentSz);

		if (m_innerSz && (m_dynamicWidth || m_dynamicHeight))
		{
			float mw = m_width, mh = m_height;
			float w = 0, h = 0;

			for (uint i = 0; i < m_children.length(); i++)
			{
				auto c = m_children[i];
				if (!c.m_visible)
					continue;

				vec2 o = c.m_origin - m_origin;
				float x2 = o.x + c.m_width;
				float y2 = o.y + c.m_height;

				if (o.x < mw) mw = o.x;
				if (o.y < mh) mh = o.y;

				if (x2 > w) w = x2;
				if (y2 > h) h = y2;
			}

			if (m_children.length() == 0)
				mw = mh = 0;

			if (m_dynamicWidth)
			{
				w += -mw;
				m_width = int(w + m_padding.x * 2);
			}

			if (m_dynamicHeight)
			{
				h += -mh;
				m_height = int(h + m_padding.y * 2);
			}

			RectWidget::DoLayout(origin, parentSz);
		}
	}
}

ref@ LoadGroupRectWidget(WidgetLoadingContext &ctx)
{
	GroupRectWidget@ w = GroupRectWidget();
	w.Load(ctx);
	return w;
}
