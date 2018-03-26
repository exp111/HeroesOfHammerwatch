enum ActorItemQuality
{
	Common,
	Uncommon,
	Rare,
	Legendary
}

class ActorItem
{
	string id;
	uint idHash;
	string name;
	string desc;
	ScriptSprite@ icon;
	ActorItemQuality quality;
	int cost;
	string requiredFlag;
	bool buyInTown;
	bool buyInDungeon;
	array<Modifiers::Modifier@> modifiers;
	bool inUse;
	ActorSet@ set;
}

class ActorSet
{
	string name;
	array<ActorSetBonus@> bonuses;
	
	
	int tmpCount;
	int tmpCountLocal;

	int tmpGetActiveBonuses()
	{
		int ret = 0;
		for (uint i = 0; i < bonuses.length(); i++)
		{
			if (bonuses[i].tmpActive)
				ret++;
		}
		return ret;
	}
}

class ActorSetBonus
{
	int num;
	string desc;
	array<Modifiers::Modifier@> modifiers;
	
	
	bool tmpActive;
}



ActorItemQuality ParseActorItemQuality(string quality)
{
	if (quality == "legendary")
		return ActorItemQuality::Legendary;
	else if (quality == "rare")
		return ActorItemQuality::Rare;
	else if (quality == "uncommon")
		return ActorItemQuality::Uncommon;
	else
		return ActorItemQuality::Common;
}

string GetItemQualityName(ActorItemQuality quality)
{
	if (quality == ActorItemQuality::Common)
		return "common";
	else if (quality == ActorItemQuality::Uncommon)
		return "uncommon";
	else if (quality == ActorItemQuality::Rare)
		return "rare";
	else if (quality == ActorItemQuality::Legendary)
		return "legendary";
	return "";
}

string SetItemColorString = "ffc800";

string GetItemQualityColorString(ActorItemQuality quality)
{
	if (quality == ActorItemQuality::Common)
		return "ffffff";
	else if (quality == ActorItemQuality::Uncommon)
		return "42ff00";
	else if (quality == ActorItemQuality::Rare)
		return "00c0ff";
	else if (quality == ActorItemQuality::Legendary)
		return "ff2400";
	return "";
}

string GetItemSetColorString(ActorItem@ item)
{
	if (item.set is null)
		return "";

	string ret = "\\c" + SetItemColorString + Resources::GetString(item.set.name) + " (" + item.set.tmpCountLocal + ")\\d";

	for (uint i = 0; i < item.set.bonuses.length(); i++)
	{
		ActorSetBonus@ bonus = item.set.bonuses[i];
		ret += "\n  \\c" + (bonus.tmpActive ? SetItemColorString : "7f7f7f") + bonus.num + ": " + Resources::GetString(bonus.desc) + "\\d";
	}

	return ret;
}

vec4 GetItemQualityColor(ActorItemQuality quality)
{
	return ParseColorRGBA("#" + GetItemQualityColorString(quality) + "ff");
}

void AddItemFiles()
{
	g_items.Clear();

	g_items.AddItemFile("items/common.sval");
	g_items.AddItemFile("items/uncommon.sval");
	g_items.AddItemFile("items/rare.sval");
	g_items.AddItemFile("items/legendary.sval");
	
	g_items.AddSetFile("items/sets.sval");
}

class ActorItems
{
	array<ActorItem@> m_allItemsList;
	array<ActorSet@> m_sets;

	
	void Clear()
	{
		m_allItemsList.removeRange(0, m_allItemsList.length());
		m_sets.removeRange(0, m_sets.length());
	}	
	
	void AddSetFile(string path)
	{
		auto setsData = Resources::GetSValue(path).GetArray();
		if (setsData is null)
			return;

		for (uint i = 0; i < setsData.length(); i++)
		{
			auto setData = cast<SValue>(setsData[i]);
			
			ActorSet set;
			set.name = GetParamString(UnitPtr(), setData, "name", false, "unknown");
			
			array<SValue@>@ items = GetParamArray(UnitPtr(), setData, "items", true);
			for (uint j = 0; j < items.length(); j++)
			{
				auto item = GetItem(items[j].GetString());
				if (item !is null)
					@item.set = set;
				else
					PrintError("Couldn't find item '" + items[j].GetString() + "' for inclusion in a set");
			}
			
			for (uint j = 0; j < items.length(); j++)
			{
				auto bonusData = GetParamDictionary(UnitPtr(), setData, "" + (j + 1), false);
				if (bonusData is null)
					continue;
				
				ActorSetBonus bonus;
				bonus.num = j + 1;
				bonus.desc = GetParamString(UnitPtr(), bonusData, "desc", false, "unknown");
				bonus.modifiers = Modifiers::LoadModifiers(UnitPtr(), bonusData);
				
				set.bonuses.insertLast(bonus);
			}
			
			m_sets.insertLast(set);			
		}
	}
	
	void AddItemFile(string path)
	{
		auto itemsData = Resources::GetSValue(path).GetDictionary();
		array<string>@ itemsKeys = itemsData.getKeys();

		for (uint i = 0; i < itemsKeys.length(); i++)
		{
			auto itemData = cast<SValue>(itemsData[itemsKeys[i]]);
			auto iconArray = GetParamArray(UnitPtr(), itemData, "icon", false);

			ActorItem@ aItem = ActorItem();
		
			aItem.id = itemsKeys[i];
			aItem.idHash = HashString(itemsKeys[i]);
			aItem.name = GetParamString(UnitPtr(), itemData, "name", false, "unknown");
			aItem.desc = GetParamString(UnitPtr(), itemData, "desc", false, "unknown");
			@aItem.icon = ScriptSprite(iconArray);
			aItem.inUse = false;
			aItem.quality = ParseActorItemQuality(GetParamString(UnitPtr(), itemData, "quality", false, "common"));
			aItem.cost = GetParamInt(UnitPtr(), itemData, "cost", false, 0);
			aItem.requiredFlag = GetParamString(UnitPtr(), itemData, "required-flag", false);
			aItem.buyInTown = GetParamBool(UnitPtr(), itemData, "buy-in-town", false, true);
			aItem.buyInDungeon = GetParamBool(UnitPtr(), itemData, "buy-in-dungeon", false, true);
			aItem.modifiers = Modifiers::LoadModifiers(UnitPtr(), itemData, "", aItem.idHash);
			
			m_allItemsList.insertLast(aItem);
		}
	}
	
	ActorItem@ TakeRandomItem(ActorItemQuality quality, bool mustNotBeInUse = true)
	{
		array<ActorItem@> matchingItems;

		for (uint i = 0; i < m_allItemsList.length(); i++)
		{
			auto item = m_allItemsList[i];
			if ((!mustNotBeInUse || !item.inUse) && item.quality == quality)
			{
				if (item.requiredFlag == "" || g_flags.IsSet(item.requiredFlag))
					matchingItems.insertLast(item);
			}
		}

		if (matchingItems.length() <= 0)
		{
			if (m_allItemsList.length() > 0)
				matchingItems.insertLast(m_allItemsList[randi(m_allItemsList.length())]);
		}

		if (matchingItems.length() <= 0)
			return null;

		auto item = matchingItems[randi(matchingItems.length())];
		if (mustNotBeInUse)
			item.inUse = true;
		
		return item;
	}

	ActorItem@ TakeItem(string id)
	{
		ActorItem@ item = GetItem(HashString(id));
		if (item is null)
		{
			PrintError("Couldn't find item with ID \"" + id + "\"");
			return null;
		}
		
		item.inUse = true;
		return item;
	}
	
	ActorItem@ GetItem(string id)
	{
		return GetItem(HashString(id));
	}
	
	ActorItem@ GetItem(uint idHash)
	{
		for (uint i = 0; i < m_allItemsList.length(); i++)
		{
			if (m_allItemsList[i].idHash == idHash)
				return m_allItemsList[i];
		}
		
		return null;
	}
}

ActorItems g_items;
