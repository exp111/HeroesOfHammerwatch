class Item : IUsable
{
	UnitPtr m_unit;
	ActorItem@ m_item;

	Item(UnitPtr unit, SValue& params)
	{
		m_unit = unit;
		auto quality = ParseActorItemQuality(GetParamString(unit, params, "quality", false, "common"));

		Initialize(g_items.TakeRandomItem(quality));
	}
	
	void Initialize(ActorItem@ item)
	{
		if (item is null)
			return;
			
		@m_item = item;
		
		ScriptSprite@ sprite = m_item.icon;
		
		array<vec4> frames;
		array<int> frameTimes = { 100 };
		
		for (uint i = 0; i < sprite.m_frames.length(); i++)
			frames.insertLast(sprite.m_frames[i].frame);
		
		Material@ mat;
		
		if (m_item.quality == ActorItemQuality::Common)
			@mat = Resources::GetMaterial("items/items.mats:item-common");			
		else if (m_item.quality == ActorItemQuality::Uncommon)
			@mat = Resources::GetMaterial("items/items.mats:item-uncommon");
		else if (m_item.quality == ActorItemQuality::Rare)
			@mat = Resources::GetMaterial("items/items.mats:item-rare");
		else if (m_item.quality == ActorItemQuality::Legendary)
			@mat = Resources::GetMaterial("items/items.mats:item-legendary");
		
		CustomUnitScene unitScene;
		unitScene.AddScene(m_unit.GetUnitScene("shared"), 0, vec2(), 0, 0);
		unitScene.AddSprite(CustomUnitSprite(vec2(6, 6), sprite.m_texture, mat, frames, frameTimes, true, 0), 0, vec2(), 0, 0);
		
		m_unit.SetUnitScene(unitScene, false);
	}
	
	SValue@ Save()
	{
		SValueBuilder sval;
		sval.PushString(m_item.id);
		return sval.Build();
	}
	
	void PostLoad(SValue@ data)
	{
		Initialize(g_items.TakeItem(data.GetString()));
		
		if (m_item is null)
			m_unit.Destroy();
	}

	void Collide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther)
	{
		Player@ player = cast<Player>(unit.GetScriptBehavior());
		if (player is null)
			return;

		if (fxSelf.IsSensor())
			player.AddUsable(this);
	}

	void EndCollision(UnitPtr unit, Fixture@ fxSelf, Fixture@ fxOther)
	{
		Player@ player = cast<Player>(unit.GetScriptBehavior());
		if (player is null)
			return;

		if (fxSelf.IsSensor())
			player.RemoveUsable(this);
	}

	UnitPtr GetUseUnit()
	{
		return m_unit;
	}

	bool CanUse(PlayerBase@ player)
	{
		return true;
	}

	void Use(PlayerBase@ player)
	{
		m_unit.Destroy();
		GiveItemImpl(m_item, player, true);
	}

	void NetUse(PlayerHusk@ player)
	{
	}

	UsableIcon GetIcon(Player@ player)
	{
		return UsableIcon::Generic;
	}
}

void GiveItemImpl(ActorItem@ item, PlayerBase@ player, bool showFloatingText)
{
	player.AddItem(item);

	Stats::Add("items-picked", 1, player.m_record);
	Stats::Add("items-picked-" + GetItemQualityName(item.quality), 1, player.m_record);
	Stats::Add("avg-items-picked", 1, player.m_record);

	auto gm = cast<Campaign>(g_gameMode);
	if (gm !is null)
	{
		ivec3 level = CalcLevel(gm.m_levelCount);
		Stats::Add("avg-items-picked-act-" + (level.x + 1), 1, player.m_record);
	}

	if (showFloatingText)
	{
		AddFloatingText(FloatingTextType::Pickup, Resources::GetString(item.name), player.m_unit.GetPosition() + vec3(0, -5, 0));

		vec3 pos = player.m_unit.GetPosition();
		if (item.quality == ActorItemQuality::Common)
			PlaySound3D(Resources::GetSoundEvent("event:/item/item_common"), pos);
		else if (item.quality == ActorItemQuality::Uncommon)
			PlaySound3D(Resources::GetSoundEvent("event:/item/item_uncommon"), pos);
		else if (item.quality == ActorItemQuality::Rare)
			PlaySound3D(Resources::GetSoundEvent("event:/item/item_rare"), pos);
		else if (item.quality == ActorItemQuality::Legendary)
			PlaySound3D(Resources::GetSoundEvent("event:/item/item_legendary"), pos);
	}
}
