namespace Tweak
{
	const int ExperiencePerLevel = 750;
	const float ExperienceExponent = 2.25f;
	
	const float DeathExperienceLoss = 0.0f;

	const int ExperienceShareRange = 500;
	const int HalfExperienceShareRange = 1200;
	float ExperienceScale = 1.0f;
}

namespace Perks
{
	float PlayerSpeedMul;
	float PlayerSpeedFwdMul;
	float PlayerSpeedBwdMul;

	float DashChargeTimeMul;
	int MaxDashes;

	float ReloadSpeedMul;

	int HealthBonus;
	int ArmorBonus;
	float DamageMul;
	float DamageTakenMul;
	float DamageMeleeMul;
	float DamageRangedMul;
	int DamageDash;
	float DamageAfterKillMul;

	float DamageKillMultAdd;
	float DamageKillMultSub;
	float DamageKillMultMin;
	float DamageKillMultMax;
	int DamageKillMultTick;

	float SpeedKill;
	int SpeedKillTime;

	float CloseRange;
	int CloseRangeOffset;
	int CloseRangeDist;

	array<float> DamageMulGroups(10);
	array<float> CooldownMulGroups(10);
	array<int> PenetratingGroups(10);
	array<float> PenetratingMulGroups(10);
	array<int> ClipsizeGroups(10);
	array<int> HitscanRicochetGroups(10);
	array<float> HitscanRicochetMulGroups(10);
	array<float> SpreadMulGroups(10);
	array<float> SpreadRangeMulGroups(10);

	float UnstoppableDealt;
	float UnstoppableTaken;
	int UnstoppableTime;

	float ReturnDamage;
	int ReturnDamageMelee;
	bool ReturnDamageQuick;

	int DamageBlock;
	int DamageBlockCooldown;
	float AmmoScale;

	int StaticArmor;

	array<string> ItemsAmmoOnkill;
	float ScavengeOwnedAmmo;

	int Vampire;
	bool VampireHeal;
	PerkAction@ ExplodingPickups;

	float DamageHP;
	float DamageHPThreshold;

	bool HealthAmmo;

	float ArmorPickupMul;
	float HealthPickupMul;

	PerkAction@ ExplodingDash;
	int ExplodingDashCount;
	array<float> ExplodingDashDistance(5);

	array<PerkAction@> ExplodingEnemies(6);

	float CriticalChance;
	float CriticalDamageMul;

	float ClipSizeMul;

	float ExperienceScale;
	float ExperienceScaleMelee;

	float IdleDamage;
	float IdleDamageReceive;
	
	int DamageKillMPScaling()
	{
		int num = 0;
		for (uint i = 0; i < g_players.length(); i++)
			if (g_players[i].peer != 255 && !g_players[i].IsDead())
				num++;
		
		return int(DamageKillMultTick * pow(num, 0.3));
	}
}
