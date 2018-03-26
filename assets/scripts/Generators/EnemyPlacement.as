enum Enemies
{
	Bats 				=    1,
	Ticks 				=    2,
	Maggots				=    4,
	Skeletons1 			=    8,
	SkeletonArchers1	=   16,
	Ghosts				=   32,
	Eyes				=   64,
	Wisps				=  128,
	Skeletons2			=  256,
	SkeletonArchers2	=  512,
	Liches				= 1024
}

class EnemyList
{
	array<UnitProducer@> m_enemies;
	array<UnitProducer@> m_uniques;
	array<float> m_uniqueChance;
	
	void Add(UnitProducer@ enemy)
	{
		m_enemies.insertLast(enemy);
	}
	
	void Add(UnitProducer@ enemy, int num, float chance)
	{
		for (int i = 0; i < num; i++)
		{
			m_uniques.insertLast(enemy);
			m_uniqueChance.insertLast(chance);
		}
	}
	
	bool IsEmpty() { return m_enemies.length() <= 0 && m_uniques.length() <= 0; }
	
	UnitProducer@ GetUnit() 
	{
		float f = m_enemies.length();
		for (uint i = 0; i < m_uniqueChance.length(); i++)
			f += m_uniqueChance[i];
	
		f *= randf();
		
		if (f < int(m_enemies.length()))
			return m_enemies[int(f)];

		f -= m_enemies.length();
	
		for (uint i = 0; i < m_uniqueChance.length(); i++)
		{
			f -= m_uniqueChance[i];
			
			if (f <= 0)
			{
				auto unit = m_uniques[i];
				m_uniques.removeAt(i);
				m_uniqueChance.removeAt(i);
				return unit;
			}
		}
	
		return m_enemies[randi(m_enemies.length())];
	}
	
	EnemyList@ Copy()
	{
		EnemyList other;
		other.m_enemies = m_enemies;
		other.m_uniques = m_uniques;
		other.m_uniqueChance = m_uniqueChance;
		return other;
	}
}

class EnemyGroupSetting
{
	EnemyList@ m_enemies;
	EnemyList@ m_elites;
	EnemyList@ m_spawners;
	EnemyList@ m_minibosses;
	
	Cell m_cellType;
	int m_baseEnemyCount;
	

	UnitProducer@ GetUnit() { return m_enemies.GetUnit(); }
	UnitProducer@ GetEliteUnit() { return m_elites.GetUnit(); }
	UnitProducer@ GetMinibossUnit() { return m_minibosses.GetUnit(); }
	UnitProducer@ GetSpawnerUnit() { return m_spawners.GetUnit(); }
	
	bool HasEliteUnit() { return !m_elites.IsEmpty(); }
	bool HasMinibossUnit() { return !m_minibosses.IsEmpty(); }
	bool HasSpawnerUnit() { return !m_spawners.IsEmpty(); }

}

class EnemySetting
{
	Enemies m_type;
	int m_ratio;
	
	EnemyList m_enemies;
	EnemyList m_elites;
	EnemyList m_spawners;
	EnemyList m_minibosses;
	
	Cell m_cellType;
	int m_baseEnemyCount;
	
	
	EnemySetting() { m_ratio = 1; }
	EnemySetting(Enemies type, int ratio, bool spawners = false, bool elites = false, bool minibosses = false, EnemySetting@ extraGroup = null)
	{
		m_type = type;
		m_ratio = ratio;
		
		m_cellType = Cell::Enemies;
		m_baseEnemyCount = 2;
	
		switch (type)
		{
		case Enemies::Bats:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_bats.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/bat_1.unit"));
			
			if (elites)
				m_enemies.Add(Resources::GetUnitProducer("actors/bat_2.unit"));
				
			m_baseEnemyCount = 3;
			break;
			
		case Enemies::Ticks:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_tick.unit"));
				
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/tick_1_elite.unit"));
				
			if (minibosses)
				m_minibosses.Add(Resources::GetUnitProducer("actors/tick_1_mb.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/tick_1.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/tick_1_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/tick_1_small.unit"));
			//m_enemies.Add(Resources::GetUnitProducer("actors/tick_1_small_exploding.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/maggot_1_small.unit"));

			break;
			
		case Enemies::Maggots:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_maggot.unit"));
			
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/maggot_1_elite.unit"));
				
			if (minibosses)
				m_minibosses.Add(Resources::GetUnitProducer("actors/maggot_1_mb.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/maggot_1.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/maggot_1_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/tick_1_small.unit"));
			
			m_cellType = Cell::MaggotEnemies;
			break;
			
		case Enemies::Skeletons1:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_skeleton_1.unit"));
				
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/skeleton_1_elite.unit"));
				
			if (minibosses)
				m_minibosses.Add(Resources::GetUnitProducer("actors/skeleton_1_mb.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_1.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_1_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/archer_1.unit"));
			
			break;
			
		case Enemies::Skeletons2:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_skeleton_2.unit"));
				
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/skeleton_2_elite.unit"));
				
			if (minibosses)
				m_minibosses.Add(Resources::GetUnitProducer("actors/lich_1_mb.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_2.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_2_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_2_spear.unit"));
			
			m_baseEnemyCount = 3;
			break;	
			
		case Enemies::SkeletonArchers1:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_archer_1.unit"));
			
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/archer_1_elite.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/archer_1.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_1.unit"));
			break;
			
		case Enemies::SkeletonArchers2:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_archer_2.unit"));
				
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/lich_1_elite.unit"));

			m_enemies.Add(Resources::GetUnitProducer("actors/archer_2.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/archer_2.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_2.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_2_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/skeleton_2_spear.unit"));
			break;
			
		case Enemies::Ghosts:
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_paladin.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_paladin.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_ranger.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_ranger.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_thief.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_sorcerer.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/ghost_priest.unit"));

			break;
			
		case Enemies::Eyes:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_eye.unit"));
			
			//if (elites)
			//	m_elites.Add(Resources::GetUnitProducer("actors/archer_1_elite.unit"));
			
			if (minibosses)
				m_minibosses.Add(Resources::GetUnitProducer("actors/eye_1_mb.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/eye_1.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/eye_1_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/eye_1_small.unit"));

			m_baseEnemyCount = 4;
			break;
			
		case Enemies::Wisps:
			if (spawners)
				m_spawners.Add(Resources::GetUnitProducer("actors/spawners/spawner_wisp.unit"));
			
			if (elites)
				m_elites.Add(Resources::GetUnitProducer("actors/wisp_2.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/wisp_1.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/wisp_1_small.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/wisp_1_small.unit"));

			m_baseEnemyCount = 1;
			break;
			
			
		case Enemies::Liches:
			if (minibosses)
				m_minibosses.Add(Resources::GetUnitProducer("actors/lich_1_mb.unit"));
			
			m_enemies.Add(Resources::GetUnitProducer("actors/lich_1_elite.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/lich_frost.unit"));
			m_enemies.Add(Resources::GetUnitProducer("actors/battlemage.unit"));
			
			m_baseEnemyCount = 1;
			break;
		}
	}
	
	int opCmp(const EnemySetting &in enemy) const
	{
		if(m_ratio < enemy.m_ratio)
			return -1;
		if(m_ratio > enemy.m_ratio)
			return 1;
		return 0;
	}
	
	EnemyGroupSetting@ MakeGroup()
	{
		EnemyGroupSetting group;
	
		@group.m_enemies = m_enemies.Copy();
		@group.m_elites = m_elites.Copy();
		@group.m_spawners = m_spawners.Copy();
		@group.m_minibosses = m_minibosses.Copy();
		group.m_baseEnemyCount = m_baseEnemyCount;
		group.m_cellType = m_cellType;
	
		return group;
	}
	
	EnemySetting@ AddExtra(string unit, int number, float chance = 1.0)
	{
		if (number > 0)
			m_enemies.Add(Resources::GetUnitProducer(unit), number, chance);

		return this;
	}
}


class EnemyPlacement
{
	array<EnemySetting@> m_enemyTypes;
	ivec2 m_dungeonEntrance;
	int m_maxMinibosses;
	
	EnemyPlacement() {}
	
	EnemyPlacement(Enemies enemies, bool spawners, bool elites, bool minibosses)
	{
		m_maxMinibosses = 3;
	}
	
	
	void AddEnemyGroup(EnemySetting setting)
	{
		m_enemyTypes.insertLast(setting);
	}
	
	
	void Initialize(ivec2 dungeonEntrance)
	{
		m_dungeonEntrance = dungeonEntrance;
		m_enemyTypes.sortDesc();
	}	
	
	void RemovePoint(DungeonBrush@ brush, Cell cellType, array<ivec2>@ group, int x, int y)
	{
		brush.SetCell(x, y, cellType);
		
		for (uint i = 0; i < group.length(); i++)
		{
			if (group[i].x == x && group[i].y == y)
			{
				group.removeAt(i);
				return;
			}
		}
	}
	
	vec3 MakeSpread(int x, int y)
	{
		//return vec3(0, 0, 0);
		return vec3(randi(x) - x/2, randi(y) - y/2, 0);
	}
	
	vec3 MakeDir(int r)
	{
		return xyz(randdir()) * r;
	}

	void SpawnGroup(Scene@ scene, vec3 pos, int radius, EnemyGroupSetting@ groupSetting)
	{
		int num = int(PI * 2 * radius / 40);
		
		if (radius > 40 && groupSetting.HasSpawnerUnit() && randi(100) < 33)
		{
			int numEnemies = randi(groupSetting.m_baseEnemyCount) + 1;
			num -= numEnemies + 3;
			
			auto spwnPos = pos + vec3(16, 16, 0) + MakeSpread(6, 6);
			groupSetting.GetSpawnerUnit().Produce(scene, spwnPos);
			
			for (int i = 0; i < numEnemies; i++)
				groupSetting.GetUnit().Produce(scene, spwnPos + MakeDir(15));
		}
		else if (m_maxMinibosses > 0 && radius > 30 && groupSetting.HasMinibossUnit() && randi(100) < 25)
		{
			int numEnemies = randi(groupSetting.m_baseEnemyCount - 1) + 1;
			num -= 2;
			
			auto spwnPos = pos + vec3(16, 16, 0) + MakeSpread(6, 6);
			groupSetting.GetMinibossUnit().Produce(scene, spwnPos);
			m_maxMinibosses--;
			
			for (int i = 0; i < numEnemies; i++)
				groupSetting.GetUnit().Produce(scene, spwnPos + MakeDir(12));
		}
		
		int eliteChance = 10;
		if (Fountain::HasEffect(FountainEffect::MoreElites))
			eliteChance = 50;
		
		for (int n = 0; n < num; n++)
		{
			auto sp = pos + xyz(randdir()) * randi(radius - 5);
		
			if (groupSetting.HasEliteUnit() && randi(100) < eliteChance && (num - n) >= 3)
			{
				groupSetting.GetEliteUnit().Produce(scene, sp);
				eliteChance -= 2;
			}
			else
				groupSetting.GetUnit().Produce(scene, sp);
		}
	}
	
	void SpawnGroup(Scene@ scene, DungeonBrush@ brush, array<ivec2>@ group, EnemyGroupSetting@ groupSetting)
	{
		auto cellType = groupSetting.m_cellType;
		int baseEnemyCount = groupSetting.m_baseEnemyCount;
		
		int num = max(6, group.length() / 3);
		int chanceLower = 0;
		
		if (Fountain::HasEffect(FountainEffect::MoreEnemies))
		{
			baseEnemyCount += 1;
			num += 1;
			chanceLower = -5;
		}
		
		int eliteChance = 10;
		if (Fountain::HasEffect(FountainEffect::MoreElites))
			eliteChance = 50;
		
		for (int n = 0; n < num && !group.isEmpty(); n++)
		{
			auto pos = group[randi(group.length())];
			
			auto entranceDt = pos - m_dungeonEntrance;
			if ((entranceDt.x * entranceDt.x + entranceDt.y * entranceDt.y) < (17 * 17))
				continue;
				
			if (brush.GetCell(pos.x, pos.y + 1) == Cell::Wall || brush.GetCell(pos.x, pos.y + 2) == Cell::Wall)
				continue;
			
			if (randi(100) < chanceLower * 2)
				continue;
			
			vec3 midPos = vec3(16 * pos.x + brush.m_posOffset.x + 8, 16 * pos.y + brush.m_posOffset.y + 8, 0);
			if (groupSetting.HasSpawnerUnit() && group.length() >= 4 && randi(100) < max(1, 20 - chanceLower) &&
				brush.GetCell(pos.x + 1, pos.y) == Cell::Floor &&
				brush.GetCell(pos.x + 1, pos.y + 1) == Cell::Floor &&
				brush.GetCell(pos.x, pos.y + 1) == Cell::Floor &&
				brush.GetCell(pos.x + 2, pos.y + 2) == Cell::Floor &&
				brush.GetCell(pos.x - 1, pos.y - 1) == Cell::Floor &&
				brush.GetCell(pos.x + 0, pos.y + 3) == Cell::Floor &&
				brush.GetCell(pos.x + 1, pos.y + 3) == Cell::Floor &&
				brush.GetCell(pos.x + 2, pos.y + 3) == Cell::Floor &&
				brush.GetCell(pos.x + 0, pos.y + 4) == Cell::Floor)
			{
				chanceLower += 2;
			
				RemovePoint(brush, cellType, group, pos.x, pos.y);
				RemovePoint(brush, cellType, group, pos.x + 1, pos.y);
				RemovePoint(brush, cellType, group, pos.x, pos.y + 1);
				RemovePoint(brush, cellType, group, pos.x + 1, pos.y + 1);
				
				auto spwnPos = midPos + vec3(16, 16, 0) + MakeSpread(6, 6);
				groupSetting.GetSpawnerUnit().Produce(scene, spwnPos);
				
				int numEnemies = randi(baseEnemyCount) + 1;
				for (int i = 0; i < numEnemies; i++)
					groupSetting.GetUnit().Produce(scene, spwnPos + MakeDir(15));
			}
			else if (m_maxMinibosses > 0 && groupSetting.HasMinibossUnit() && group.length() >= 6 && randi(100) < (14 - chanceLower) &&
				brush.GetCell(pos.x + 1, pos.y) == Cell::Floor &&
				brush.GetCell(pos.x + 1, pos.y + 1) == Cell::Floor &&
				brush.GetCell(pos.x, pos.y + 1) == Cell::Floor)
			{
				chanceLower += 4;
			
				RemovePoint(brush, cellType, group, pos.x, pos.y);
				RemovePoint(brush, cellType, group, pos.x + 1, pos.y);
				RemovePoint(brush, cellType, group, pos.x, pos.y + 1);
				RemovePoint(brush, cellType, group, pos.x + 1, pos.y + 1);
				
				auto spwnPos = midPos + vec3(16, 16, 0) + MakeSpread(6, 6);
				groupSetting.GetMinibossUnit().Produce(scene, spwnPos);
				m_maxMinibosses--;
				
				int numEnemies = randi(baseEnemyCount - 1) + 1;
				for (int i = 0; i < numEnemies; i++)
					groupSetting.GetUnit().Produce(scene, spwnPos + MakeDir(12));
			}
			else
			{
				RemovePoint(brush, cellType, group, pos.x, pos.y);
				chanceLower++;
				
				int numEnemies = randi(baseEnemyCount) + 1;
				for (int i = 0; i < numEnemies; i++)
				{
					if (groupSetting.HasEliteUnit() && randi(100) < eliteChance && group.length() >= 3)
						groupSetting.GetEliteUnit().Produce(scene, midPos + MakeSpread(5, 5));
					else
						groupSetting.GetUnit().Produce(scene, midPos + MakeSpread(5, 5));
				}
			}
		}
	}	
	
	void Place(Scene@ scene, DungeonBrush@ brush, array<array<ivec2>@> groups)
	{
		int totChance = 0;
		for (uint i = 0; i < m_enemyTypes.length(); i++)
			totChance += m_enemyTypes[i].m_ratio;

		for (uint i = 0; i < groups.length(); i++)
		{
			int n = randi(totChance);
			
			for (uint j = 0; j < m_enemyTypes.length(); j++)
			{
				n -= m_enemyTypes[j].m_ratio;
				if (n < 0)
				{
					SpawnGroup(scene, brush, groups[i], m_enemyTypes[j].MakeGroup());
					break;
				}
			}
		}
	}
	
	void PlaceGroup(Scene@ scene, vec2 pos, int radius)
	{
		int totChance = 0;
		for (uint i = 0; i < m_enemyTypes.length(); i++)
			totChance += m_enemyTypes[i].m_ratio;

		int n = randi(totChance);
		
		for (uint j = 0; j < m_enemyTypes.length(); j++)
		{
			n -= m_enemyTypes[j].m_ratio;
			if (n < 0)
			{
				SpawnGroup(scene, xyz(pos), radius, m_enemyTypes[j].MakeGroup());
				return;
			}
		}
	}
}