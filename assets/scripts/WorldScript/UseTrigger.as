namespace WorldScript
{
	[WorldScript color="210 105 30" icon="system/icons.png;96;96;32;32"]
	class UseTrigger : IUsable
	{
		bool Enabled;

		[Editable]
		array<CollisionArea@>@ Areas;

		[Editable type=enum default=1]
		UsableIcon Icon;

		[Editable type=enum default=0]
		UsableIcon IconDisabled;
		
		UnitSource User;
		
		
		void Initialize()
		{
			for (uint i = 0; i < Areas.length(); i++)
			{
				Areas[i].AddOnEnter(this, "OnEnter");
				Areas[i].AddOnExit(this, "OnExit");
			}
		}
		
		Player@ GetPlayer(UnitPtr unit)
		{
			if (!unit.IsValid())
				return null;
			
			ref@ behavior = unit.GetScriptBehavior();
			
			if (behavior is null)
				return null;
		
			return cast<Player>(behavior);
		}
		
		void OnEnter(UnitPtr unit, vec2 pos, vec2 normal)
		{
			Player@ plr = GetPlayer(unit);
			if (plr !is null)
				plr.AddUsable(this);
		}
		
		void OnExit(UnitPtr unit)
		{
			Player@ plr = GetPlayer(unit);
			if (plr !is null)
				plr.RemoveUsable(this);
		}

		SValue@ ServerExecute()
		{
			return null;
		}

		UnitPtr GetUseUnit()
		{
			return WorldScript::GetWorldScript(g_scene, this).GetUnit();
		}

		bool CanUse(PlayerBase@ player)
		{
			auto ws = WorldScript::GetWorldScript(g_scene, this);
			if (!ws.IsEnabled())
				return false;

			int triggerTimes = ws.GetTriggerTimes();
			if (triggerTimes == 0)
				return false;

			return true;
		}

		void Use(PlayerBase@ player)
		{
			User.Replace(player.m_unit);

			if (Network::IsServer())
				WorldScript::GetWorldScript(g_scene, this).Execute();
		}

		void NetUse(PlayerHusk@ player)
		{
			Use(player);
		}

		UsableIcon GetIcon(Player@ player)
		{
			if (!CanUse(player))
				return IconDisabled;

			return Icon;
		}
	}
}
