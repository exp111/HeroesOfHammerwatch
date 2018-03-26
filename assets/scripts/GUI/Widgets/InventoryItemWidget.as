class InventoryItemWidget : Widget
{
	ActorItem@ m_item;

	Sprite@ m_spriteDot;

	vec4 m_colorItem;
	vec4 m_colorSet;

	InventoryItemWidget()
	{
		super();
	}

	Widget@ Clone() override
	{
		InventoryItemWidget@ w = InventoryItemWidget();
		CloneInto(w);
		return w;
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		Widget::Load(ctx);

		LoadWidthHeight(ctx);

		auto def = ctx.GetGUIDef();
		@m_spriteDot = def.GetSprite("inventory-item-dot");

		m_canFocus = true;
	}

	void Set(ActorItem@ item)
	{
		@m_item = item;

		m_tooltipTitle = "\\c" + GetItemQualityColorString(item.quality) + utf8string(Resources::GetString(item.name)).toUpper().plain();
		m_tooltipText = Resources::GetString(item.desc);

		if (item.set !is null)
		{
			m_tooltipText += "\n\n";
			m_tooltipText += GetItemSetColorString(item);
		}

		m_colorItem = GetItemQualityColor(m_item.quality);
		m_colorSet = ParseColorRGBA("#" + SetItemColorString + "FF");
	}

	void DoDraw(SpriteBatch& sb, vec2 pos) override
	{
		m_item.icon.Draw(sb, pos + vec2(2, 2), g_menuTime);

		int dotX = m_width - m_spriteDot.GetWidth() - 2;
		int dotY = m_height - m_spriteDot.GetHeight() - 2;

		if (m_item.quality != ActorItemQuality::Common)
		{
			vec2 dotPos = pos + vec2(dotX, dotY);
			sb.DrawSprite(dotPos, m_spriteDot, g_menuTime, m_colorItem);
			dotX -= m_spriteDot.GetWidth() - 1;
		}

		if (m_item.set !is null)
		{
			bool isActive = false;
			for (uint i = 0; i < m_item.set.bonuses.length(); i++)
			{
				if (m_item.set.bonuses[i].tmpActive)
				{
					isActive = true;
					break;
				}
			}

			if (isActive)
			{
				vec2 dotPos = pos + vec2(dotX, dotY);
				sb.DrawSprite(dotPos, m_spriteDot, g_menuTime, m_colorSet);
				dotX -= m_spriteDot.GetWidth() - 1;
			}
		}
	}
}

ref@ LoadInventoryItemWidget(WidgetLoadingContext &ctx)
{
	InventoryItemWidget@ w = InventoryItemWidget();
	w.Load(ctx);
	return w;
}
