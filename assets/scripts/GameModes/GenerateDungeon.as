int g_ngp = 0;

ivec3 CalcLevel(int levelNum)
{
	int act = levelNum / 4;
	return ivec3(act, levelNum % 4, levelNum);
}

void SetLevelFlags(int levelCount)
{
	if (Fountain::HasEffect(FountainEffect::GlassWalks))
		g_flags.Set("glass_walkways", FlagState::Level);
		
	if (Fountain::HasEffect(FountainEffect::NoPrisonButton))
		g_flags.Set("no_prison_button", FlagState::Level);
		
	ivec3 lvl = CalcLevel(levelCount);
	
	g_flags.Set("act_" + lvl.x, FlagState::Level);
	g_flags.Set("lvl_" + lvl.y, FlagState::Level);
	g_flags.Set("lvlcount_" + lvl.z, FlagState::Level);
}

void GenerateDungeon(RandomLevel@ gameMode, int levelCount, int shortcut, int numPlrs)
{
	DungeonGenerator@ dgn;
	EnemyPlacement enemyPlacer;
	
	print("LevelCount: " + levelCount);
	
	//levelCount = 16;
	//levelCount = 12;
	//levelCount = 8;
	//levelCount = 4;
	ivec3 lvl = CalcLevel(levelCount);
	
	
	float levelSizeMul = 1.0f + min(0.5f, 0.1f * g_ngp);
	
	if (Fountain::HasEffect(FountainEffect::BiggerLevels))
		levelSizeMul *= 1.25f;
	
	SetLevelFlags(levelCount);

	//PlayAsMusic(0, Resources::GetSoundEvent("event:/music/act_" + (lvl.x + 1)));
	
	if (lvl.x == 0)
	{
		MinesGenerator mines;
		
		auto brush = GraniteMineBrush();
		brush.m_grassChanceAdjustment = -3 * lvl.y;
		@mines.m_brush = brush;
		
	
		if (lvl.y == 0)
			g_flags.Set("no_flowers", FlagState::Level);

		mines.Width = int((1500 + lvl.y * 100) * levelSizeMul);
		mines.Height = int((1500 + lvl.y * 100) * levelSizeMul);
		
		
		mines.Density = 1;
		mines.RoomChance = 0.1;
		mines.RoomSize = 12;
		mines.NumDeadEndsFill = 5;
		mines.MaxCliffNum = 0;
		mines.Prefabs = true;

		
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Bats, 1, true, lvl.y >= 2));
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Ticks, 3, true, lvl.y >= 1, lvl.y >= 2).AddExtra("actors/tick_1_small_exploding.unit", 2));
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Maggots, (lvl.y == 0) ? 1 : 2, true, lvl.y >= 1, false));
		
		enemyPlacer.m_maxMinibosses = 2 + g_ngp * 2 + numPlrs;
		mines.MinEnemyGroups = 8 + lvl.y * 5 + g_ngp * 2 + numPlrs * 2;
		
		@dgn = mines;
	}
	else if (lvl.x == 1)
	{
		PrisonGenerator prison;
		prison.Tileset = DungeonTileset::Prison;
	
		prison.Width = int((1700 + lvl.y * 100) * levelSizeMul);
		prison.Height = int((1700 + lvl.y * 100) * levelSizeMul);
		
		
		prison.Density = 2.5;
		prison.RoomChance = 0.2;
		prison.RoomSize = 12;
		prison.NumDeadEndsFill = 20;
		prison.MaxCliffNum = 5;
		prison.Prefabs = true;
		

		if (lvl.y < 1)
			enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Ticks, 3, true, true));
		
		if (lvl.y < 2)
			enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Bats, 3, true, true));

		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Maggots, 3, true, true, lvl.y >= 2));
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::SkeletonArchers1, 2, true, lvl.y >= 1, false));
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Skeletons1, 3, true, lvl.y >= 1, false).AddExtra("actors/bannerman_bloodlust.unit", (lvl.y >= 1) ? 1 : 0, 0.75f));
		
		enemyPlacer.m_maxMinibosses = 3 + g_ngp * 2 + numPlrs;
		prison.MinEnemyGroups = 20 + lvl.y * 3 + g_ngp * 2 + numPlrs * 2;
		
		@dgn = prison;
	}
	else if (lvl.x == 2)
	{
		ArmoryGenerator armory;
		armory.Tileset = DungeonTileset::Armory;
	
		armory.Width = int((1900 + lvl.y * 100) * levelSizeMul);
		armory.Height = int((1900 + lvl.y * 100) * levelSizeMul);
		auto sz = Rectangularize(armory.Width, armory.Height, 0.25);
		armory.Width = sz.x;
		armory.Height = sz.y;
		
		armory.RoomSize = 17 + numPlrs;
		armory.MaxCliffNum = 2;
		armory.Prefabs = true;
		
		if (lvl.y < 1)
			enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::SkeletonArchers1, 1, true, true, false));
		
		if (lvl.y < 2)
			enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Skeletons1, 1, true, true, false).AddExtra("actors/bannerman_bloodlust.unit", 1, 0.5f));

		auto skelGroup = EnemySetting(Enemies::Skeletons1, 1, true, true, lvl.y >= 2)
			.AddExtra("actors/bannerman_bloodlust.unit", 1, 0.2f)
			.AddExtra("actors/bannerman_protection.unit", 1, 0.2f)
			.AddExtra("actors/skeleton_1_spear.unit", 4, 1.5f);
		
		if (lvl.y >= 1)
			skelGroup.AddExtra("actors/lich_summ_1.unit", 1, 0.1f);
		
			
		enemyPlacer.AddEnemyGroup(skelGroup);
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::SkeletonArchers1, 1, true, true, false).AddExtra("actors/lich_1.unit", 2));
		
		enemyPlacer.m_maxMinibosses = 4 + g_ngp * 2 + numPlrs * 2;
		armory.MinEnemyGroups = 24 + numPlrs * 5 + lvl.y * 5 + g_ngp * 5;
		
		@dgn = armory;
	}
	else if (lvl.x == 3)
	{
		ArchivesGenerator archives;
		archives.Tileset = DungeonTileset::Archives;
	
		archives.Width = int((1850 + lvl.y * 50) * levelSizeMul);
		archives.Height = int((1850 + lvl.y * 50) * levelSizeMul);
		auto sz = Rectangularize(archives.Width, archives.Height, 0.25);
		archives.Width = sz.x;
		archives.Height = sz.y;
		
		archives.Padding = 20;
		archives.PathWidth = 5;
		archives.Prefabs = true;

		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Ghosts, 1, true, true, false));
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Eyes, 5, true, true, lvl.y >= 1)
			.AddExtra("actors/lich_1.unit", 2, 0.8f));
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Wisps, 5, true, lvl.y >= 1, false)
			.AddExtra("actors/lich_1.unit", 2, 0.8f));
		
		enemyPlacer.m_maxMinibosses = 0; //4 + lvl.y * (3 + g_ngp * 2) + numPlrs;
		archives.MinEnemyGroups = 35 + lvl.y * 6 + g_ngp * 4 + numPlrs * 4;
		
		@dgn = archives;
	}
	else
	{
		ChambersGenerator chambers;
		chambers.Tileset = DungeonTileset::Chambers;
		
		chambers.Width = int((2050 + lvl.y * 150) * levelSizeMul);
		chambers.Height = int((2850 + lvl.y * 150) * levelSizeMul);
		
		chambers.Padding = 43;
		chambers.Splits = 8 + lvl.y;
		chambers.Prefabs = true;
		
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::SkeletonArchers2, 2, true, lvl.y >= 1, false));
			
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Skeletons2, 4, true, true, lvl.y >= 2)
			.AddExtra("actors/bannerman_healing.unit", 1, 0.1f));
		
		enemyPlacer.AddEnemyGroup(EnemySetting(Enemies::Liches, 1, true, true, lvl.y >= 2));
		
		enemyPlacer.m_maxMinibosses = 6 + lvl.y * (4 + g_ngp * 2) + numPlrs * 2;
		chambers.MinEnemyGroups = 40 + lvl.y * 12 + g_ngp * 15 + numPlrs * 10;
		
		@dgn = chambers;
	}
	
	if (lvl.y == 0 && shortcut > lvl.x)
		dgn.m_placeActShortcut = true;
	
	@dgn.m_enemyPlacer = enemyPlacer;
	if (gameMode !is null)
		@gameMode.m_enemyPlacer = enemyPlacer;
	
	dgn.MakeBrush();
	dgn.m_brush.m_lvl = lvl;
	dgn.m_numPlrs = numPlrs;
	dgn.Generate(g_scene);
}

ivec2 Rectangularize(int w, int h, float amount)
{
	int tot = w * h;
	w += int((randf() - randf()) * w * amount);
	h = tot / w;
	return ivec2(w, h);
}

array<PrefabToSpawn@> g_prefabsToSpawn;
class PrefabToSpawn
{
	Prefab@ m_pfb;
	vec3 m_pos;
	
	PrefabToSpawn(Prefab@ pfb, vec3 pos)
	{
		@m_pfb = pfb;
		m_pos = pos;
	}
}
