namespace WorldScript
{
	enum ShopAreaType
	{
		UpgradeShop,
		Fountain,
		Statues,
		Chapel,
		Skills,
		Townhall
	}

	[WorldScript color="#B0C4DE" icon="system/icons.png;384;352;32;32"]
	class ShopArea : IUsable
	{
		bool Enabled;

		[Editable]
		array<CollisionArea@>@ Areas;

		[Editable type=enum default=0]
		ShopAreaType Type;
		
		[Editable]
		string Category;

		[Editable default=1]
		int ShopLevel;

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

		UnitPtr GetUseUnit()
		{
			return WorldScript::GetWorldScript(g_scene, this).GetUnit();
		}

		bool CanUse(PlayerBase@ player)
		{
			return Enabled;
		}

		void Use(PlayerBase@ player)
		{
			auto gm = cast<Campaign>(g_gameMode);
			if (Type == ShopAreaType::UpgradeShop)
				gm.m_shopMenu.Show(UpgradeShopMenuContent(gm.m_shopMenu, Category), ShopLevel);
			else if (Type == ShopAreaType::Fountain)
				gm.m_shopMenu.Show(FountainShopMenuContent(gm.m_shopMenu), ShopLevel);
			else if (Type == ShopAreaType::Statues)
				gm.m_shopMenu.Show(StatuesShopMenuContent(gm.m_shopMenu), ShopLevel);
			else if (Type == ShopAreaType::Chapel)
				gm.m_shopMenu.Show(ChapelShopMenuContent(gm.m_shopMenu), ShopLevel);
			else if (Type == ShopAreaType::Skills)
				gm.m_shopMenu.Show(SkillsShopMenuContent(gm.m_shopMenu), ShopLevel);
			else if (Type == ShopAreaType::Townhall)
				gm.m_shopMenu.Show(TownhallMenuContent(gm.m_shopMenu), ShopLevel);

			User.Replace(player.m_unit);

			if (Network::IsServer())
				WorldScript::GetWorldScript(g_scene, this).Execute();
		}
		
		void NetUse(PlayerHusk@ player)
		{
			if (Network::IsServer())
				WorldScript::GetWorldScript(g_scene, this).Execute();
		}

		UsableIcon GetIcon(Player@ player)
		{
			if (!Enabled)
				return UsableIcon::None;
			return UsableIcon::Shop;
		}

		SValue@ ServerExecute()
		{
			return null;
		}
	}
}
