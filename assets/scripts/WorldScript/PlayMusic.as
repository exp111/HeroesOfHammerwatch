namespace WorldScript
{
	[WorldScript color="186 85 164" icon="system/icons.png;352;96;32;32"]
	class PlayMusic
	{
		[Editable]
		SoundEvent@ Music;
	
		[Editable]
		int Channel;
	
	
		SValue@ ServerExecute()
		{
			PlayAsMusic(Channel, Music);
			
			/*
			auto sndInstance = Music.PlayTracked(vec3());
			sndInstance.SetLooped(true);
			sndInstance.SetPaused(false);
			*/
			
			return null;
		}
		
		void ClientExecute(SValue@ val)
		{
			ServerExecute();
		}
	}
}