namespace Menu
{
	class Backdrop : IWidgetHoster
	{
		bool m_clipping;
		Rect m_clippingRect;

		Backdrop(GUIBuilder@ b, string fnm)
		{
			LoadWidget(b, fnm);
		}

		void Draw(SpriteBatch& sb, int idt) override
		{
			if (m_clipping)
				sb.PushClipping(m_clippingRect.GetVec4(), true);

			IWidgetHoster::Draw(sb, idt);

			if (m_clipping)
				sb.PopClipping();
		}
	}
}
