ScriptSprite@ GetFaceSprite(string charClass, int face)
{
	SValue@ svalClass = Resources::GetSValue("players/" + charClass + "/char.sval");
	if (svalClass is null)
	{
		PrintError("Couldn't get SValue file for class \"" + charClass + "\"");
		return null;
	}
	else
	{
		int faceY = GetParamInt(UnitPtr(), svalClass, "face-y");
		return ScriptSprite(Resources::GetTexture2D("gui/icons_faces.png"), vec4(face * 24, faceY, 24, 24));
	}
}

class ClassStats
{
	pfloat base_health;
	pfloat base_mana;
	pfloat base_health_regen;
	pfloat base_mana_regen;
	pfloat base_armor;
	pfloat base_resistance;

	pfloat level_health;
	pfloat level_mana;
	pfloat level_health_regen;
	pfloat level_mana_regen;
	pfloat level_armor;
	pfloat level_resistance;
}

class OwnedUpgrade
{
	string m_id;
	pint m_level;

	Upgrades::UpgradeStep@ m_step;
}

enum ClassFlags
{
	Paladin = 1,
	Ranger = 2,
	Sorcerer = 4,
	Warlock = 8,
	Thief = 16,
	Priest = 32,
	Wizard = 64
}

class PlayerRecord
{
	string name; //NOTE: This can be utf8!

	uint8 peer;
	uint64 id;
	Actor@ actor;
	bool local;

	pfloat handicap;
	pint previousRun;

	pint newGamePlus;
	
	pint healthBonus;
	pint freeLives;
	pint freeLivesTaken;

	ClassStats classStats;
	pfloat hp;
	pfloat mana;
	bool runEnded;

	pint titleIndex;
	pint shortcut;

	pint runGold;
	pint runOre;
	pint skillPoints;

	pint townTitleSync;

	pint randomBuffNegative;
	pint randomBuffPositive;

	array<string> items;
	int potionChargesUsed;

	array<OwnedUpgrade@> upgrades;
	array<pint> levelSkills = { 1, 1, 0, 0, 0, 0, 0 };
	array<pint> keys = { 0, 0, 0, 0, 0 };

	int generalStoreItemsSaved = -1;
	int generalStoreItemsPlume;
	array<uint> generalStoreItems;

	string charClass;
	int skinColor;
	int color1;
	int color2;
	int color3;
	int face;
	float voice;

	uint deadTime;
	PlayerCorpse@ corpse;
	array<int> soulLinks;
	int soulLinkedBy = -1;

	pint armor;
	ArmorDef@ armorDef;
	pint experience;
	pint level;

	uint team;
	pint kills;
	pint killsTotal;
	pint deaths;
	pint deathsTotal;

	array<uint> perks;

	pint pickups;
	pint pickupsTotal;

	bool readyState;

	dictionary userdata;

	Stats::StatList@ statistics;
	Stats::StatList@ statisticsSession;

	Modifiers::ModifierList@ modifiers;
	Modifiers::ModifierList@ modifiersItems;
	Modifiers::ModifierList@ modifiersSkills;
	Modifiers::ModifierList@ modifiersUpgrades;
	Modifiers::ModifierList@ modifiersBuffs;
	Modifiers::ModifierList@ modifiersTitles;

	PlayerRecord()
	{
		mana = 1.0;
		handicap = 0.8;

		@statistics = Stats::LoadList("tweak/stats.sval");
		@statisticsSession = Stats::LoadList("tweak/stats.sval");

		@modifiersItems = Modifiers::ModifierList();
		@modifiersSkills = Modifiers::ModifierList();
		@modifiersUpgrades = Modifiers::ModifierList();
		@modifiersBuffs = Modifiers::ModifierList();
		@modifiersTitles = Modifiers::ModifierList();

		@modifiers = Modifiers::ModifierList();
		modifiers.Add(modifiersItems);
		modifiers.Add(modifiersSkills);
		modifiers.Add(modifiersUpgrades);
		modifiers.Add(modifiersBuffs);
		modifiers.Add(modifiersTitles);

		modifiersItems.m_name = Resources::GetString(".modifier.list.player.items");
		modifiersSkills.m_name = Resources::GetString(".modifier.list.player.skills");
		modifiersUpgrades.m_name = Resources::GetString(".modifier.list.player.upgrades");
		modifiersBuffs.m_name = Resources::GetString(".modifier.list.player.buffs");
		modifiersTitles.m_name = Resources::GetString(".modifier.list.player.titles");
	}

	uint GetCharFlags()
	{
		if (charClass == "paladin")
			return uint(ClassFlags::Paladin);
		else if (charClass == "ranger")
			return uint(ClassFlags::Ranger);
		else if (charClass == "sorcerer")
			return uint(ClassFlags::Sorcerer);
		else if (charClass == "warlock")
			return uint(ClassFlags::Warlock);
		else if (charClass == "thief")
			return uint(ClassFlags::Thief);
		else if (charClass == "priest")
			return uint(ClassFlags::Priest);
		else if (charClass == "wizard")
			return uint(ClassFlags::Wizard);
		return 0;
	}

	void RefreshModifiers()
	{
		array<ActorSet@> sets;

		modifiers.m_name = GetName();

		// Modifiers for items
		modifiersItems.Clear();
		
		for (uint j = 0; j < sets.length(); j++)
			sets[j].tmpCount = 0;
		
		for (uint j = 0; j < items.length(); j++)
		{
			auto item = g_items.GetItem(items[j]);
			for (uint i = 0; i < item.modifiers.length(); i++)
				modifiersItems.Add(item.modifiers[i]);

			if (item.set !is null)
			{
				bool found = false;
				for (uint i = 0; i < sets.length(); i++)
				{
					if (sets[i] is item.set)
					{
						sets[i].tmpCount++;
						found = true;
						break;
					}
				}

				if (!found)
				{
					item.set.tmpCount = 1;
					sets.insertLast(item.set);
				}
			}
		}

		for (uint j = 0; j < sets.length(); j++)
		{
			int count = sets[j].tmpCount;
			if (local)
				sets[j].tmpCountLocal = count;
			
			array<ActorSetBonus@>@ bonuses = sets[j].bonuses;

			ActorSetBonus@ bestBonus = null;
			for (uint i = 0; i < bonuses.length(); i++)
			{
				if (local)
					bonuses[i].tmpActive = false;
				
				if (bonuses[i].num <= count)
				{
					if (local)
						bonuses[i].tmpActive = true;
					
					@bestBonus = bonuses[i];
				}
			}

			if (bestBonus is null)
				continue;

			for (uint i = 0; i < bestBonus.modifiers.length(); i++)
				modifiersItems.Add(bestBonus.modifiers[i]);
		}

		// Modifiers for skills
		auto player = cast<PlayerBase>(actor);
		if (player !is null)
		{
			modifiersSkills.Clear();
			for (uint j = 0; j < player.m_skills.length(); j++)
			{
				auto mods = player.m_skills[j].GetModifiers();
				if (mods is null)
					continue;

				for (uint i = 0; i < mods.length(); i++)
					modifiersSkills.Add(mods[i]);
			}
		}

		// Modifiers for purchased upgrades
		modifiersUpgrades.Clear();
		for (uint j = 0; j < upgrades.length(); j++)
		{
			auto step = cast<Upgrades::ModifierUpgradeStep>(upgrades[j].m_step);
			if (step is null)
				continue;

			auto mods = step.GetModifiers();
			for (uint i = 0; i < mods.length(); i++)
				modifiersUpgrades.Add(mods[i]);
		}

		modifiersBuffs.Clear();
		modifiersBuffs.Add(Modifiers::RandomBuff(randomBuffPositive, randomBuffNegative));
	}

	float GetHandicap()
	{
		if (g_players.length() == 1)
			return handicap;
		return 0.0f;
	}

	Titles::Title@ GetTitle()
	{
		return g_classTitles.GetTitle(charClass, titleIndex);
	}

	void GiveTitle(int index)
	{
		if (index <= titleIndex)
			return;

		titleIndex = index;
		OnNewTitle();
	}

	void OnNewTitle()
	{
		print("New class title: \"" + GetTitle().m_name + "\"");

		auto player = cast<Player>(actor);
		if (player !is null)
			player.OnNewTitle(GetTitle());
	}

	void AssignUnit(UnitPtr unit)
	{
		@actor = cast<Actor>(unit.GetScriptBehavior());
	}

	int MaxHealth() { return int(classStats.base_health + float(level -1) * classStats.level_health); }
	int MaxMana() { return int(classStats.base_mana + float(level -1) * classStats.level_mana); }
	float HealthRegen() { return classStats.base_health_regen + float(level -1) * classStats.level_health_regen; }
	float ManaRegen() { return classStats.base_mana_regen + float(level -1) * classStats.level_mana_regen; }
	float Armor() { return classStats.base_armor + float(level -1) * classStats.level_armor; }
	float Resistance() { return classStats.base_resistance + float(level -1) * classStats.level_resistance; }

	int GetFreeLives() { return 0; }

	int LevelExperience(int atLevel)
	{
		return int(Tweak::ExperiencePerLevel * pow(atLevel, Tweak::ExperienceExponent));
	}

	void NetSyncExperience(int lvl, int exp)
	{
		level = lvl;
		experience = exp;
	}

	void GiveExperience(int amount)
	{
		if (amount <= 0)
			return;

		int xpNeeded = 0;
		int xpAdded = amount;
		int levelsAdded = 0;

		Stats::Add("exp-gained", amount, this);
		Stats::Add("avg-exp-gained", amount, this);

		while (true)
		{
			if (level >= (20 + newGamePlus * 5))
				break;
		
			xpNeeded = LevelExperience(level);

			if (experience + xpAdded >= xpNeeded)
			{
				int add = xpNeeded - experience;
				experience += add;

				xpAdded -= add;
				
				skillPoints += Tweak::SkillPointsPerLevelBase + int(level / Tweak::SkillPointsPerLevelMod);
				level++;
				levelsAdded++;
			}
			else
			{
				experience += xpAdded;
				break;
			}
		}

		if (local)
		{
			(Network::Message("PlayerSyncExperience") << level << experience).SendToAll();

			if (levelsAdded > 0)
			{
				if (actor !is null)
					cast<Player>(actor).OnLevelUp(levelsAdded);
				
				if (level >= 20)
					Platform::Service.UnlockAchievement("level20_" + charClass);
				if (level >= 40)
					Platform::Service.UnlockAchievement("level40_" + charClass);
			}
		}
	}

	string GetSkin() { return Lobby::GetPlayerSkin(peer); }

	string GetLobbyName()
	{
		return Lobby::GetPlayerName(peer);
	}

	string GetName()
	{
		/*if (Platform::GetSessionCount() == 1)
			return Lobby::GetPlayerName(peer);

		return "player " + (peer + 1);*/
		return name;
	}

	int GetPing() { return Lobby::GetPlayerPing(peer); }

	bool IsDead()
	{
		return deadTime > 0 && actor is null;
	}

	int CurrentHealth()
	{
		ivec2 extraStats;

		auto localPlayer = cast<Player>(actor);
		if (localPlayer !is null)
			extraStats = g_allModifiers.StatsAdd(localPlayer);

		return int(ceil(hp * (MaxHealth() + extraStats.x)));
	}

	int CurrentMana()
	{
		ivec2 extraStats;

		auto localPlayer = cast<Player>(actor);
		if (localPlayer !is null)
			extraStats = g_allModifiers.StatsAdd(localPlayer);

		return int(floor(mana * MaxMana()));
	}

	float CurrentHealthScalar()
	{
		return hp;
	}

	bool HasBeenDeadFor(uint ms)
	{
		if (!IsDead())
			return false;

		return (deadTime + ms) < g_scene.GetTime();
	}

	int opCmp(const PlayerRecord &in other)
	{
		if (peer < other.peer) return -1;
		else if (peer > other.peer) return 1;
		return 0;
	}

	int GetPerksWorth() { return 0; }
	void FetchPerkKillCounters() { }
	float FetchFloatProd(string name = "") { return 1.0; }
	float FetchFloatSum(string name = "") { return 0.0; }
	int FetchIntSum(string name = "") { return 0; }
	bool FetchBoolAny(string name = "") { return false; }
	PerkAction@ FetchAction(string name = "") { return null; }
	array<string> FetchArrayString(string name = "") { return array<string>(); }
	bool HasPerk(string name) { return false; }
	void GivePerk(string name) { }
	void GivePerk(uint hash) { }
	void TakePerk(string name) { }
	void TakePerk(uint hash) { }
	void RefreshPerkData(uint forPerk = 0) { }

	OwnedUpgrade@ GetOwnedUpgrade(string id)
	{
		for (uint i = 0; i < upgrades.length(); i++)
		{
			if (upgrades[i].m_id == id)
				return upgrades[i];
		}
		return null;
	}
}

namespace Perks
{
	class PerkKillCounter
	{
		uint m_perk;

		int m_current;
		int m_start;

		array<IEffect@>@ m_effects;
	}

	array<PerkKillCounter@> KillCounters;

	string GetPerkDescription(SValue@ perkData, string descriptionKey) { return ""; }
	void KillCount(int n, Actor@ target) { }
}
