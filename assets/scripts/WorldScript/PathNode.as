namespace WorldScript
{
	[WorldScript color="#8FBC8B" icon="system/icons.png;224;64;32;32"]
	class PathNode
	{
		[Editable]
		UnitFeed NextPath;

		[Editable]
		float Spread;

		SValue@ ServerExecute()
		{
			return null;
		}

		void ClientExecute(SValue@ val)
		{
		}
	}
}
