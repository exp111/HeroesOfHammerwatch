array<string> g_actorBuffTags;

int GetActorBuffTag(string tag)
{
	if (tag == "")
		return 0;
		
	for (uint i = 0; i < g_actorBuffTags.length(); i++)
		if (tag == g_actorBuffTags[i])
			return i + 1;

	g_actorBuffTags.insertLast(tag);
	return g_actorBuffTags.length();
}

int ApplyActorBuffTag(uint64 curr, string tag)
{
	auto r = GetActorBuffTag(tag);
	if (r <= 0)
		return curr;
	
	return curr | (1 << r);
}

uint64 GetBuffTags(SValue& params, string prefix = "")
{
	uint64 ret = 0;

	array<SValue@>@ tagArr = GetParamArray(UnitPtr(), params, prefix + "tags", false);
	if (tagArr !is null)
	{
		for (uint i = 0; i < tagArr.length(); i++)
			ret = ApplyActorBuffTag(ret, tagArr[i].GetString());
	}
	else
		ret = ApplyActorBuffTag(ret, GetParamString(UnitPtr(), params, prefix + "tag", false));

	return ret;
}

class ActorBuffDef
{
	uint m_pathHash;
	uint64 m_tags;
	int m_duration;
	bool m_debuff;

	float m_mulSpeed;
	float m_mulSpeedDash;
	float m_mulDamage;
	float m_mulDamageTaken;
	float m_mulExperience;
	vec2 m_mulArmor;
	float m_minSpeed;
	bool m_freeAmmo;
	bool m_disarm;
	bool m_confuse;
	bool m_infDodge;
	bool m_darkness;
	string m_playerHeadSuffix;
	uint8 m_buffDmgType;

	SoundEvent@ m_sound;
	ActorColor@ m_color;
	
	
	int m_tickFreq;
	array<IEffect@>@ m_tickEffects;
	
	int m_moveFreq;
	array<IEffect@>@ m_moveEffects;
	
	array<IEffect@>@ m_dieEffects;
	
	
	UnitScene@ m_effect;

	UnitProducer@ m_icon;
	string m_iconScene;
	int m_iconSizeX;
	int m_iconLayer;

	string m_hud;
	
	
	ActorBuffDef(uint pathHash, SValue& params)
	{
		m_pathHash = pathHash;
		m_tags = GetBuffTags(params);
		m_duration = GetParamInt(UnitPtr(), params, "duration", false, 1000);
		m_debuff = GetParamBool(UnitPtr(), params, "debuff", false, false);
		
		m_mulSpeed = GetParamFloat(UnitPtr(), params, "speed-mul", false, 1.0);
		m_mulSpeedDash = GetParamFloat(UnitPtr(), params, "speed-dash-mul", false, 1.0);
		m_mulDamage = GetParamFloat(UnitPtr(), params, "dmg-mul", false, 1.0);
		m_mulDamageTaken = GetParamFloat(UnitPtr(), params, "dmg-taken-mul", false, 1.0);
		m_mulExperience = GetParamFloat(UnitPtr(), params, "experience-mul", false, 1.0);
		m_mulArmor = vec2(
			GetParamFloat(UnitPtr(), params, "armor-mul", false, 1.0),
			GetParamFloat(UnitPtr(), params, "resistance-mul", false, 1.0));
		
		m_minSpeed = GetParamFloat(UnitPtr(), params, "min-speed", false, 0.0);
		m_freeAmmo = GetParamBool(UnitPtr(), params, "free-ammo", false, false);
		m_disarm = GetParamBool(UnitPtr(), params, "disarm", false, false);
		m_confuse = GetParamBool(UnitPtr(), params, "confuse", false, false);
		m_infDodge = GetParamBool(UnitPtr(), params, "inf-dodge", false, false);
		m_playerHeadSuffix = GetParamString(UnitPtr(), params, "player-head-suffix", false, "");
		m_buffDmgType = GetParamDamageType(UnitPtr(), params, "buff-dmg-type", false, 0);
		
		auto tick = GetParamDictionary(UnitPtr(), params, "tick", false);
		if (tick !is null)
		{
			m_tickFreq = GetParamInt(UnitPtr(), tick, "freq", false, 0);
			@m_tickEffects = LoadEffects(UnitPtr(), tick);
		}
		
		auto move = GetParamDictionary(UnitPtr(), params, "move", false);
		if (move !is null)
		{
			m_moveFreq = GetParamInt(UnitPtr(), move, "freq", false, 0);
			@m_moveEffects = LoadEffects(UnitPtr(), move);
		}
		
		@m_dieEffects = LoadEffects(UnitPtr(), params, "die-");
		
		
		@m_effect = Resources::GetEffect(GetParamString(UnitPtr(), params, "fx", false, ""));
		@m_color = LoadColor(params);

		string iconUnit = GetParamString(UnitPtr(), params, "icon", false, "");
		if (iconUnit != "")
		{
			@m_icon = Resources::GetUnitProducer(iconUnit);
			m_iconScene = GetParamString(UnitPtr(), params, "icon-scene", false, "");
			m_iconSizeX = GetParamInt(UnitPtr(), params, "icon-size-x", false, 10);
			m_iconLayer = GetParamInt(UnitPtr(), params, "icon-layer", false, -1);
		}

		@m_sound = Resources::GetSoundEvent(GetParamString(UnitPtr(), params, "sound", false, ""));

		m_hud = GetParamString(UnitPtr(), params, "hud", false, "");

		m_darkness = GetParamBool(UnitPtr(), params, "darkness", false, false);
	}
}
