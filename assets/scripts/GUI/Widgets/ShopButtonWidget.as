class ShopButtonWidget : ScalableSpriteButtonWidget
{
	Sprite@ m_spriteIconFrame;
	Sprite@ m_spriteIcon;
	Sprite@ m_itemDot;

	Sprite@ m_spriteGold;
	Sprite@ m_spriteOre;
	Sprite@ m_spriteSkillPoints;

	Sprite@ m_spriteCurrency;

	BitmapFont@ m_fontPrice;
	BitmapString@ m_textPrice;

	bool m_canAfford;
	bool m_shopRestricted;

	ShopButtonWidget()
	{
		super();
	}

	void Load(WidgetLoadingContext &ctx) override
	{
		ScalableSpriteButtonWidget::Load(ctx);

		@m_pressSound = null;

		@m_font = Resources::GetBitmapFont("gui/fonts/arial11.fnt");
		@m_fontPrice = Resources::GetBitmapFont("gui/fonts/arial11.fnt");

		auto def = ctx.GetGUIDef();

		@m_spriteIconFrame = def.GetSprite("frame-icon");
		@m_spriteIcon = def.GetSprite(ctx.GetString("icon", false));
		@m_itemDot = def.GetSprite("item-dot");

		@m_spriteGold = def.GetSprite("gold");
		@m_spriteOre = def.GetSprite("ore");
		@m_spriteSkillPoints = def.GetSprite("skill-points");

		m_textOffset = vec2(36, -1);
	}

	Widget@ Clone() override
	{
		ShopButtonWidget@ w = ShopButtonWidget();
		CloneInto(w);
		return w;
	}

	int OwnedGold()
	{
		auto gm = cast<Campaign>(g_gameMode);

		if (cast<Town>(gm) is null)
			return GetLocalPlayerRecord().runGold;

		return gm.m_townLocal.m_gold;
	}

	int OwnedOre()
	{
		auto gm = cast<Campaign>(g_gameMode);

		if (cast<Town>(gm) is null)
			return GetLocalPlayerRecord().runOre;

		return gm.m_townLocal.m_ore;
	}

	void SetPriceGold(int amount)
	{
		@m_spriteCurrency = m_spriteGold;
		m_canAfford = (OwnedGold() >= amount);
		SetPrice(amount);
	}

	void SetPriceOre(int amount)
	{
		@m_spriteCurrency = m_spriteOre;
		m_canAfford = (OwnedOre() >= amount);
		SetPrice(amount);
	}

	void SetPriceSkillPoints(int amount)
	{
		//TODO: I think we will get rid of this soon
		@m_spriteCurrency = m_spriteSkillPoints;
		m_canAfford = (GetLocalPlayerRecord().skillPoints >= amount);
		SetPrice(amount);
	}

	void SetPrice(int amount)
	{
		if (amount > 0)
			@m_textPrice = m_fontPrice.BuildText("" + amount);
		else
			@m_textPrice = null;
	}

	void DrawIcon(SpriteBatch& sb, vec2 pos, vec4 color)
	{
		sb.DrawSprite(pos, m_spriteIconFrame, g_menuTime, color);
		if (m_spriteIcon !is null)
			sb.DrawSprite(pos + vec2(1, 1), m_spriteIcon, g_menuTime, color);
	}

	void UpdateEnabled()
	{
		m_enabled = (m_canAfford && !m_shopRestricted);
	}

	void DoDraw(SpriteBatch& sb, vec2 pos) override
	{
		ScalableSpriteButtonWidget::DoDraw(sb, pos);

		if (!m_enabled)
			sb.EnableColorize(vec4(0, 0, 0, 1), vec4(0.125, 0.125, 0.125, 1), vec4(0.25, 0.25, 0.25, 1));

		DrawIcon(sb, pos + vec2(3, 3), vec4(1,1,1,1));

		if (!m_enabled)
			sb.DisableColorize();

		if (m_width > 64 && m_spriteCurrency !is null && m_textPrice !is null)
		{
			if (m_canAfford)
				m_textPrice.SetColor(GetTextColor());
			else
				m_textPrice.SetColor(vec4(1, 0, 0, 1));

			int currencyWidth = m_textPrice.GetWidth() + 2 + m_spriteCurrency.GetWidth();
			vec2 spritePos;
			vec2 textPos;

			if (m_text is null)
			{
				int contentOffset = m_spriteIconFrame.GetWidth();
				int contentWidth = m_width - contentOffset;

				textPos = vec2(
					pos.x + contentOffset + contentWidth / 2 - currencyWidth / 2,
					pos.y + m_height / 2 - m_textPrice.GetHeight() / 2 - 1
				);
				spritePos = vec2(
					textPos.x + m_textPrice.GetWidth() + 2,
					pos.y + m_height / 2 - m_spriteCurrency.GetHeight() / 2
				);
			}
			else
			{
				spritePos = vec2(
					pos.x + m_width - m_spriteCurrency.GetWidth() - 8,
					pos.y + m_height / 2 - m_spriteCurrency.GetHeight() / 2
				);
				textPos = vec2(
					spritePos.x - m_textPrice.GetWidth() - 2,
					pos.y + m_height / 2 - m_textPrice.GetHeight() / 2 - 1
				);
			}

			sb.DrawSprite(spritePos, m_spriteCurrency, g_menuTime);
			sb.DrawString(textPos, m_textPrice);
		}
	}
}

ref@ LoadShopButtonWidget(WidgetLoadingContext &ctx)
{
	ShopButtonWidget@ w = ShopButtonWidget();
	w.Load(ctx);
	return w;
}
