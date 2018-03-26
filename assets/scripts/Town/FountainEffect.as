enum FountainEffect
{
	None = 0,

	BiggerLevels 	= (1 <<  0),
	MoreEnemies 	= (1 <<  1),
	MoreGold 		= (1 <<  2),
	EnemiesDamaged	= (1 <<  3),
	GlassWalks		= (1 <<  4),
	HalfEnemyArmor	= (1 <<  5),
	NoPrisonButton	= (1 <<  6),
	MoreElites		= (1 <<  7),
	MoreSpecialRooms= (1 <<  8),
	AmazingPickups	= (1 <<  9),
	BadPickups		= (1 << 10),
}

namespace Fountain
{
	FountainEffect RandomGoodEffect(int num, FountainEffect current)
	{
		array<FountainEffect> effects = {
			FountainEffect::MoreGold,
			FountainEffect::EnemiesDamaged,
			FountainEffect::GlassWalks,
			FountainEffect::HalfEnemyArmor,
			FountainEffect::MoreSpecialRooms,
			FountainEffect::AmazingPickups
		};
		return RandomEffectFromArray(effects, num, current);
	}

	FountainEffect RandomBadEffect(int num, FountainEffect current)
	{
		array<FountainEffect> effects = {
			FountainEffect::BiggerLevels,
			FountainEffect::MoreEnemies,
			FountainEffect::MoreElites,
			FountainEffect::NoPrisonButton,
			FountainEffect::BadPickups
		};
		return RandomEffectFromArray(effects, num, current);
	}
	

	bool HasEffect(FountainEffect effect)
	{
		auto gm = cast<Campaign>(g_gameMode);
		if (gm is null)
			return false;

		return uint(gm.m_fountainEffects & effect) != 0;
	}

	FountainEffect RandomEffectFromArray(array<FountainEffect> effects, int num, FountainEffect current)
	{
		FountainEffect ret = FountainEffect::None;
		for (int i = 0; i < num && effects.length() > 0; i++)
		{
			int index = RandomBank::Int(RandomContext::Fountain, effects.length());
			if ((current & effects[index]) != 0)
			{
				effects.removeAt(index);
				i--;
				continue;
			}

			ret = FountainEffect(ret | effects[index]);
			effects.removeAt(index);
		}
		return ret;
	}

	FountainEffect RandomFountainEffects(int &out outNumGood, int &out outNumBad, FountainEffect current)
	{
		int numGood, numBad;

		int numChance = RandomBank::Int(RandomContext::Fountain, 7);
		switch (numChance)
		{
			case 0: numGood = 0; numBad = 2; break; // Something horrible happened
			case 1: numGood = 0; numBad = 1; break; // Something bad happened
			case 2: numGood = 1; numBad = 1; break; // Something happened
			case 3: numGood = 1; numBad = 0; break; // Something good happened
			case 4: numGood = 1; numBad = 0; break; // Something good happened
			case 5: numGood = 2; numBad = 0; break; // Something great happened
			case 6: numGood = 2; numBad = 0; break; // Something great happened
		}

		outNumGood = numGood;
		outNumBad = numBad;

		return FountainEffect(RandomGoodEffect(numGood, current) | RandomBadEffect(numBad, current));
	}
}
