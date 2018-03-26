enum DamageType
{
	//HEAL		=   0,
	TRAP 		=   1,
	PIERCING 	=   2,
	BLUNT		=   4,
	EXPLOSION	=   8,
	BIO			=  16,
	FIRE		=  32,
	ENERGY		=  64,
	FROST		= 128,
}

class DamageInfo
{
	uint8 DamageType;
	int32 Damage;
	
	Actor@ Attacker;
	int32 PhysicalDamage;
	int32 MagicalDamage;
	bool Melee;
	bool CanKill;
	uint Weapon;
	int Crit;
	vec2 ArmorMul;
	
	
	DamageInfo()
	{
		DamageType = uint8(DamageType::PIERCING);
		@Attacker = null;
		CanKill = true;
		Crit = 0;
		ArmorMul = vec2(1, 1);
	}

	DamageInfo(uint8 dmgType, Actor@ attacker, int16 dmg, bool melee, bool canKill, uint weapon)
	{
		DamageType = dmgType;
		@Attacker = attacker;
		PhysicalDamage = dmg;
		Melee = melee;
		CanKill = canKill;
		Weapon = weapon;
		Crit = 0;
		ArmorMul = vec2(1, 1);
	}
	
	
	DamageInfo(Actor@ attacker, int32 physDmg, int magicDmg, bool melee, bool canKill, uint weapon)
	{
		DamageType = DamageType::TRAP;
		Damage = physDmg + magicDmg;
		
		@Attacker = attacker;
		PhysicalDamage = physDmg;
		MagicalDamage = magicDmg;
		Melee = melee;
		CanKill = canKill;
		Weapon = weapon;
		Crit = 0;
		ArmorMul = vec2(1, 1);
	}
}

uint8 GetParamDamageType(UnitPtr owner, SValue@ params, string name, bool required = true, uint8 def = uint8(DamageType::PIERCING))
{
	string dt = GetParamString(owner, params, name, required, "");
	if (dt == "")
		return def;

	uint8 ret = 0;
		
	auto dts = dt.split(" ");
	for (uint i = 0; i < dts.length(); i++)
	{
		if (dts[i] == "heal")
			return 0;
		else if (dts[i] == "trap")
			ret |= uint8(DamageType::TRAP);
		else if (dts[i] == "pierce")
			ret |= uint8(DamageType::PIERCING);
		else if (dts[i] == "piercing")
			ret |= uint8(DamageType::PIERCING);
		else if (dts[i] == "blunt")
			ret |= uint8(DamageType::BLUNT);
		else if (dts[i] == "explosion")
			ret |= uint8(DamageType::EXPLOSION);
		else if (dts[i] == "bio")
			ret |= uint8(DamageType::BIO);
		else if (dts[i] == "fire")
			ret |= uint8(DamageType::FIRE);
		else if (dts[i] == "energy")
			ret |= uint8(DamageType::ENERGY);
		else if (dts[i] == "frost")
			ret |= uint8(DamageType::FROST);
		else
			print("Damage type not found: " + dts[i]);
	}
	
	return ret;
}

interface IDamageTaker
{
	int Damage(DamageInfo dmg, vec2 pos, vec2 dir);
	void NetDamage(DamageInfo dmg, vec2 pos, vec2 dir);
	bool Impenetrable();
	bool ShootThrough(vec2 pos, vec2 dir);
	bool IsDead();
	bool Ricochets();
}

class ADamageTaker : IDamageTaker
{
	int Damage(DamageInfo dmg, vec2 pos, vec2 dir) override { return 0; }
	void NetDamage(DamageInfo dmg, vec2 pos, vec2 dir) override {}
	bool Impenetrable() override { return false; }
	bool ShootThrough(vec2 pos, vec2 dir) override { return false; }
	bool IsDead() override { return false; }
	bool Ricochets() override { return true; }
}