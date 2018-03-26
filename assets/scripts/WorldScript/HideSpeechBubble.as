namespace WorldScript
{
	[WorldScript color="#FF4500" icon="system/icons.png;256;352;32;32"]
	class HideSpeechBubble
	{
		[Editable]
		UnitFeed Bubble;

		[Editable]
		UnitFeed ForPlayer;

		SValue@ ServerExecute()
		{
			ClientExecute(null);
			return null;
		}

		void ClientExecute(SValue@ val)
		{
			UnitPtr unit = ForPlayer.FetchFirst();
			if (unit.IsValid() && cast<Player>(unit.GetScriptBehavior()) is null)
				return;

			auto arr = Bubble.FetchAll();
			for (uint i = 0; i < arr.length(); i++)
			{
				auto bubble = cast<ShowSpeechBubble>(arr[i].GetScriptBehavior());
				if (bubble is null)
				{
					PrintError("Bubble is not a ShowSpeechBubble script!");
					continue;
				}
				bubble.HideBubble();
			}
		}
	}
}
