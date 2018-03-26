namespace WorldScript
{
	[WorldScript color="#8fbc8f" icon="system/icons.png;0;384;32;32"]
	class Variable
	{
		[Editable]
		int Value;
		
		SValue@ Save()
		{
			SValueBuilder sval;
			sval.PushInteger(Value);
			return sval.Build();
		}
		
		void Load(SValue@ data)
		{
			Value = data.GetInteger();
		}
		
		void DebugDraw(vec2 pos, SpriteBatch& sb)
		{
			auto sysFont = Resources::GetBitmapFont("system/system.fnt");
			auto text = sysFont.BuildText("" + Value);
			
			sb.DrawString(pos - vec2(text.GetWidth(), text.GetHeight() - 1) / 2, text);
		}
	}
}