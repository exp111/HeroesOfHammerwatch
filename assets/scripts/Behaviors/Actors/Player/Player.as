enum AttackRangeType
{
	Melee,
	Ranged,
	Unspecified
}

class Player : PlayerBase, IPreRenderable
{
	array<PlayerUsable@> m_usables;

	bool m_insideJammable;
	
	vec2 m_lastDirection;
	vec2 m_lastSentPos;
	vec2 m_lastSentDir;
	float m_lastSentHP;
	
	bool cvar_god;

	int m_blockDamageCooldown;

	float m_nextHitMul = 1.0;


	UnitScene@ m_fxBlockProjectile;
	SoundEvent@ m_sndBlockProjectile;
	UnitScene@ m_fxDamageBlockRecharged;
	UnitScene@ m_fxDamageBlockHit;
	UnitScene@ m_fxLifesteal;
	SoundEvent@ m_sndNoMana;
	SoundEvent@ m_sndCooldown;

	bool m_enemyExplodePerkSwitch;

	int m_unstoppablePerkC;
	bool m_returningDamage;

	ActorBuffDef@ m_comboBuff;
	int m_comboTime;
	int m_comboCount;
	int m_comboEffectsTime;


	Player(UnitPtr unit, SValue& params)
	{
		super(unit, params);

		
		//TODO: Replace check with something so that on splitscreen, only the first player can use cheats
		//if (Network::IsServer())
		{
			AddVar("noclip", false, SetNoClipCVar, cvar_flags::Cheat);
			AddVar("god", false, SetGodmodeCVar, cvar_flags::Cheat);
			AddVar("clientfollowshost", false, null, cvar_flags::Cheat);
			AddVar("show_all_accomplishments", false, null, cvar_flags::Cheat);

			{
				array<cvar_type> cfuncParams = { cvar_type::String };
				AddFunction("give_item", cfuncParams, GiveItemCFunc, cvar_flags::Cheat);
				AddFunction("give_perk", cfuncParams, GivePerkCFunc, cvar_flags::Cheat);
			}
			
			{
				array<cvar_type> cfuncParams = { cvar_type::Int, cvar_type::Int, cvar_type::Int, cvar_type::Int };
				AddFunction("give_items", cfuncParams, GiveItemsCFunc, cvar_flags::Cheat);
			}

			AddFunction("clear_items", ClearItemsCfunc, cvar_flags::Cheat);
			
			{
				array<cvar_type> cfuncParams = { cvar_type::Int };
				AddFunction("give_experience", cfuncParams, GiveExperienceCFunc, cvar_flags::Cheat);
				AddFunction("give_health", cfuncParams, GiveHealthCFunc, cvar_flags::Cheat);
				AddFunction("give_mana", cfuncParams, GiveManaCFunc, cvar_flags::Cheat);
				AddFunction("give_armor", cfuncParams, GiveArmorCFunc, cvar_flags::Cheat);
				AddFunction("give_key", cfuncParams, GiveKeyCFunc, cvar_flags::Cheat);
				AddFunction("levelup", cfuncParams, LevelupCFunc, cvar_flags::Cheat);

				AddFunction("give_gold", cfuncParams, GiveGoldCFunc, cvar_flags::Cheat);
				AddFunction("give_ore", cfuncParams, GiveOreCFunc, cvar_flags::Cheat);
				AddFunction("give_skillpoints", cfuncParams, GiveSkillpointsCFunc, cvar_flags::Cheat);
			}
			
			{
				array<cvar_type> cfuncParams = { cvar_type::String, cvar_type::Bool, cvar_type::Bool };
				AddFunction("set_flag", cfuncParams, SetFlagCFunc, cvar_flags::Cheat);
			}

			AddFunction("kill", KillCFunc);
			AddFunction("killall", KillAllCFunc, cvar_flags::Cheat);
			AddFunction("revive", ReviveCFunc, cvar_flags::Cheat);
			
			AddFunction("listenemies", ListEnemiesCFunc, cvar_flags::Cheat);

			AddFunction("listmodifiers", ListModifiersCFunc);
		}

		@m_fxBlockProjectile = Resources::GetEffect("effects/players/block_projectile.effect");
		@m_sndBlockProjectile = Resources::GetSoundEvent("event:/player/projectile_block");
		@m_fxDamageBlockRecharged = Resources::GetEffect("effects/animations/perk_protective_barrier_recharge.effect");
		@m_fxDamageBlockHit = Resources::GetEffect("effects/animations/perk_protective_barrier.effect");
		@m_fxLifesteal = Resources::GetEffect("effects/players/lifesteal.effect");
		@m_sndNoMana = Resources::GetSoundEvent("event:/player/no_mana");
		@m_sndCooldown = Resources::GetSoundEvent("event:/player/cooldown");
		@m_comboBuff = LoadActorBuff("players/buffs.sval:combo");
		
		m_returningDamage = false;
	}	

	void Initialize(PlayerRecord@ record) override
	{
		PlayerBase::Initialize(record);

		m_preRenderables.insertLast(this);

		EnableModifiers();
	}

	void EnableModifiers()
	{
		g_allModifiers.Add(m_record.modifiers);
	}

	void DisableModifiers()
	{
		g_allModifiers.Remove(m_record.modifiers);
	}

	int FindUsable(IUsable@ usable)
	{
		for (uint i = 0; i < m_usables.length(); i++)
		{
			if (m_usables[i].m_usable is usable)
				return i;
		}
		return -1;
	}

	void AddUsable(IUsable@ usable)
	{
		int index = FindUsable(usable);
		if (index != -1)
		{
			m_usables[index].m_refCount++;
			return;
		}

		m_usables.insertLast(PlayerUsable(usable));
	}

	void RemoveUsable(IUsable@ usable)
	{
		int index = FindUsable(usable);
		if (index != -1)
		{
			if (--m_usables[index].m_refCount <= 0)
				m_usables.removeAt(index);
			return;
		}
		PrintError("Tried removing unlisted usable");
	}

	IUsable@ GetTopUsable()
	{
		for (uint i = 0; i < m_usables.length(); i++)
		{
			if (m_usables[i].m_usable.CanUse(this))
				return m_usables[i].m_usable;
		}
		if (m_usables.length() > 0)
			return m_usables[0].m_usable;
		return null;
	}

	void RefreshModifiers() override
	{
		PlayerBase::RefreshModifiers();

		// Modifiers for class title
		SValueBuilder builder;
		g_classTitles.RefreshModifiers(builder);
		(Network::Message("PlayerTitleModifiers") << builder.Build()).SendToAll();

		auto hud = GetHUD();
		if (hud !is null)
		{
			ivec2 extraStatsFromItems = m_record.modifiersItems.StatsAdd(this);
			ivec2 extraStats = g_allModifiers.StatsAdd(this);

			float maxHealth = m_record.MaxHealth() + extraStats.x;
			float maxMana = m_record.MaxMana() + extraStats.y;

			hud.m_wBarHealth.m_valueExtra = 1.0f - (extraStatsFromItems.x / maxHealth);
			hud.m_wBarMana.m_valueExtra = 1.0f - (extraStatsFromItems.y / maxMana);
		}
	}

	void AddItem(ActorItem@ item) override
	{
		PlayerBase::AddItem(item);

		(Network::Message("PlayerGiveItem") << item.id).SendToAll();
		cast<Campaign>(g_gameMode).m_townLocal.FoundItem(item);

		item.inUse = true;
	}

	void Jump(vec2 dir)
	{
	}

	bool IsHusk() override { return false; }

	float GetDamageMul(AttackRangeType rangeType)
	{
		return 1;
	}

	float GetDamageMulTarget(bool melee, UnitPtr target) override
	{
		return 1;
	}

	void PlayerShot()
	{
		m_nextHitMul = 1;
	}
	
	void DamagedActor(Actor@ actor, DamageInfo di)
	{
		auto eb = cast<CompositeActorBehavior>(actor);
		if (!(eb !is null && eb.m_enemyType == "construct"))
		{
			float ls = g_allModifiers.Lifesteal(this, actor, (di.Weapon != 1), di.Crit);
			ls *= g_allModifiers.AllHealthGainScale(this);

			if (ls > 0)
			{
				ivec2 stats = g_allModifiers.StatsAdd(this);
				float maxHealth = m_record.MaxHealth() + stats.x;
				int stealHealth = roll_round(di.Damage * ls);
				if (m_record.hp * maxHealth + stealHealth > maxHealth)
					stealHealth = int(maxHealth - m_record.hp * maxHealth);
				m_record.hp = min(1.f, m_record.hp + stealHealth / maxHealth);

				Stats::Add("lifesteal-amount", stealHealth, m_record);

				PlayEffect(m_fxLifesteal, xy(m_unit.GetPosition()) + vec2(0, 1));
			}
		}

		if (di.Damage > 0)
		{
			Stats::Add("damage-dealt", di.Damage, m_record);
			Stats::Max("damage-dealt-max", di.Damage, m_record);
			
			if (m_returningDamage)
				Stats::Add("damage-returned", di.Damage, m_record);

			Stats::Add("damage-dealt-physical", di.PhysicalDamage, m_record);
			Stats::Add("damage-dealt-magical", di.MagicalDamage, m_record);
		}
	}

	DamageInfo DamageActor(Actor@ actor, DamageInfo di)
	{
		ivec2 dmgPowerV = g_allModifiers.DamagePower(this, actor);
		float dmgMul = 1;

		int crit;
		int dmgPower;
		vec2 armorIg;
		ivec2 dmgAddV;
		
		if (di.Weapon == 1)
		{
			dmgPower = dmgPowerV.x;
			dmgMul *= g_allModifiers.DamageMul(this, actor).x;
			crit = g_allModifiers.Crit(this, actor, false);
			armorIg = g_allModifiers.ArmorIgnore(this, actor, false);
			dmgAddV = g_allModifiers.AttackDamageAdd(this, actor);
			g_allModifiers.TriggerEffects(this, actor, Modifiers::EffectTrigger::Hit);
		}
		else
		{
			dmgPower = dmgPowerV.y;
			dmgMul *= g_allModifiers.DamageMul(this, actor).y;
			crit = g_allModifiers.Crit(this, actor, true);
			armorIg = g_allModifiers.ArmorIgnore(this, actor, true);
			g_allModifiers.TriggerEffects(this, actor, Modifiers::EffectTrigger::SpellHit);
		}
		
		if (crit > 0)
		{
			Stats::Add("crit-count", 1, m_record);
			dmgMul *= (2.0f + (g_allModifiers.CritMul(this, actor, di.Weapon != 1) - 1.0f)) * crit;
		}
		
		di.PhysicalDamage = damage_round((di.PhysicalDamage * ((50.0 + dmgPower) / 50.0) + dmgAddV.x) * dmgMul);
		di.MagicalDamage = damage_round((di.MagicalDamage * ((50.0 + dmgPower) / 50.0) + dmgAddV.y) * dmgMul);
		di.Crit = crit;
		di.ArmorMul = armorIg;
		
		if (crit > 0)
			g_allModifiers.TriggerEffects(this, actor, Modifiers::EffectTrigger::CriticalHit);
		
		return di;
	}
	
	void NetShareExperience(int experience)
	{
		float xpReward = float(experience - m_record.level * 3);
		xpReward *= m_buffs.ExperienceMul();
		xpReward *= Tweak::ExperienceScale;

		float expMul = g_allModifiers.ExpMul(this, null) * g_mpExpScale;

		int xpr = int(xpReward * expMul);
		if (xpr > 0)
			m_record.GiveExperience(xpr);
	}

	void PlayerKilled(PlayerRecord@ player)
	{
	}
	
	vec2 GetComboBars()
	{
		float amnt = m_comboCount / 10.0;
		if (amnt >= 1.0f)
			return vec2(amnt, m_comboTime / 2000.0);

		return vec2(amnt, m_comboTime / 1000.0);
	}
	
	void KilledActor(Actor@ killed, DamageInfo di) override
	{
		auto enemy = cast<CompositeActorBehavior>(killed);
	
		Stats::Add("enemies-killed", 1, m_record);
		if (enemy !is null && enemy.m_enemyType != "")
			Stats::Add(enemy.m_enemyType + "-killed", 1, m_record);
		
		cast<Campaign>(g_gameMode).m_townLocal.KilledEnemy(killed.m_unit.GetUnitProducer());
		g_allModifiers.TriggerEffects(this, killed, Modifiers::EffectTrigger::Kill);
		
		//TODO: Cache flag?
		if (g_flags.IsSet("unlock_combo"))
		{
			m_comboCount++;

			Stats::Max("best-combo", m_comboCount, m_record);

			vec2 combo = GetComboBars();
			if (combo.x >= 1.0f)
				m_comboTime = 2000;
			else
				m_comboTime = 1000;
		}

		if (enemy !is null && enemy.m_expReward > 0)
		{
			int xp = int(enemy.m_expReward * (1.0f + g_ngp * 0.4f) + 30 * g_ngp);
			(Network::Message("PlayerShareExperience") << xp).SendToAll();
			
			float xpReward = float(xp - m_record.level * 3);
			xpReward *= m_buffs.ExperienceMul();
			xpReward *= Tweak::ExperienceScale;

			float expMul = g_allModifiers.ExpMul(this, killed) * g_mpExpScale;

			int xpr = int(xpReward * expMul);
			if (xpr > 0)
				m_record.GiveExperience(xpr);
		}
	}

	bool CanGiveArmor(int amt, ArmorDef@ def, bool replace)
	{
		return false;
	}

	bool GiveArmor(int amt, ArmorDef@ def, bool replace)
	{
		return false;
	}

	void Kill(Actor@ killer, uint weapon) override
	{
		OnDeath(DamageInfo(0, killer, 1, false, true, weapon), m_lastDirection);
		Actor::Kill(killer, weapon);
	}
	
	bool ApplyBuff(ActorBuff@ buff) override
	{ 
		if (BlockBuff(buff, m_record.armorDef, m_record.armor))
			return false;
	
		return PlayerBase::ApplyBuff(buff);
	}
	
	void GiveMana(int mana)
	{
		ivec2 stats = g_allModifiers.StatsAdd(this);
		
		AddFloatingGive(mana, FloatingTextType::PlayerAmmo);
		m_record.mana = clamp(m_record.mana + float(mana) / float(m_record.MaxMana() + stats.y), 0.0f, 1.0f);

		//TODO: Netsync
	}

	void TakeMana(int mana)
	{
		ivec2 stats = g_allModifiers.StatsAdd(this);

		AddFloatingGive(-mana, FloatingTextType::PlayerAmmo);
		m_record.mana = clamp(m_record.mana - float(mana) / float(m_record.MaxMana() + stats.y), 0.0f, 1.0f);

		//TODO: Netsync
	}

	int GetHealAmount(int amount)
	{
		return int(amount * g_allModifiers.AllHealthGainScale(this));
	}

	void Heal(int amount) override
	{
		int healAmnt = GetHealAmount(amount);
		NetHeal(healAmnt);
		m_lastSentHP = m_record.hp;
		(Network::Message("PlayerHealed") << healAmnt << m_record.hp).SendToAll();
		Stats::Add("amount-healed", healAmnt, m_record);
	}
	
	void SoulLinkKill(PlayerHusk@ killer)
	{
		OnDeath(DamageInfo(killer, 1, 1, false, true, 0), m_lastDirection);
		Actor::Kill(killer, 0);
	}
	
	void SoulLinkDamage(int dmg)
	{
	/*
		if (cvar_god || m_record.IsDead() || dmg <= 0)
			return;

		int maxHp = m_record.MaxHealth();
		
		m_record.hp -= float(dmg) / float(maxHp);
		AddFloatingHurt(dmg, 0, FloatingTextType::PlayerHurt);
		m_dmgColor = vec4(1, 0, 0, 1);
		
		Stats::Add("damage-taken", dmg, m_record);
		Stats::Max("damage-taken-max", dmg, m_record);

		if (m_record.CurrentHealth() <= 0)
			OnDeath(DamageInfo(null, dmg, 0, false, true, 0), m_lastDirection);
		else
		{
			if (m_gore !is null)
				m_gore.OnHit(float(dmg) / float(maxHp), xy(m_unit.GetPosition()), m_dirAngle);

			dictionary params = { { "damage", float(dmg) } };
			PlaySound3D(m_hurtSound, m_unit, params);
		}
	*/
	}
	
	int Damage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		if (cvar_god || m_record.IsDead())
			return 0;

		int maxHp = m_record.MaxHealth();		
		vec2 armor(m_record.Armor(), m_record.Resistance());
		ivec2 block;
		float dmgTakenMul = 1.0f;

		if (dmg.DamageType != 0)
		{
			if (g_allModifiers.Evasion(this, dmg.Attacker))
			{
				Stats::Add("evade-amount", 1, m_record);
				g_allModifiers.TriggerEffects(this, dmg.Attacker, Modifiers::EffectTrigger::Evade);
				m_dmgColor = vec4(0, 0, 0, 2.0);
				return 0;
			}

			armor += g_allModifiers.ArmorAdd(this, dmg.Attacker);
			block += g_allModifiers.DamageBlock(this, dmg.Attacker);
			maxHp += g_allModifiers.StatsAdd(this).x;

			if (block.x + block.y > 0)
				Stats::Add("damage-blocked", block.x + block.y, m_record);

			if (dmg.PhysicalDamage > 0)
				dmg.PhysicalDamage = max(0, dmg.PhysicalDamage - block.x);
			if (dmg.MagicalDamage > 0)
				dmg.MagicalDamage = max(0, dmg.MagicalDamage - block.y);
			
			float hc = 1.0f; //lerp(1.0f, 0.8f, m_record.GetHandicap());
			dmgTakenMul = hc * g_allModifiers.DamageTakenMul(this, dmg) * m_buffs.DamageTakenMul() * (1.0f + g_ngp * 1.4f);
		}
		
		int dmgAmnt = ApplyArmor(dmg, m_buffs.ArmorMul() * armor * dmg.ArmorMul, dmgTakenMul);
		if (dmgAmnt > 0)
		{
			if (!dmg.CanKill && m_record.CurrentHealth() - dmgAmnt <= 0)
				dmgAmnt = 0;
			
			bool evadable = dmg.Melee && dmg.Attacker !is null && !dmg.Attacker.IsDead();
			
			m_returningDamage = true;
			g_allModifiers.TriggerEffects(this, dmg.Attacker, Modifiers::EffectTrigger::Hurt);
			g_allModifiers.DamageTaken(this, dmg.Attacker, dmgAmnt);
			m_returningDamage = false;
		
			if (evadable && dmg.Attacker.IsDead())
			{
				g_allModifiers.TriggerEffects(this, dmg.Attacker, Modifiers::EffectTrigger::Evade);
				m_dmgColor = vec4(0, 0, 0, 2.0);
				return 0;
			}
			
			m_record.hp -= float(dmgAmnt) / float(maxHp);
			AddFloatingHurt(dmgAmnt, dmg.Crit, dmg.MagicalDamage > dmg.PhysicalDamage ? FloatingTextType::PlayerHurtMagical : FloatingTextType::PlayerHurt);
			m_dmgColor = vec4(1, 0, 0, 1);
			
			int manaFromDamage = g_allModifiers.ManaFromDamage(this, dmgAmnt);
			if (manaFromDamage > 0)
				this.GiveMana(manaFromDamage);

			Stats::Add("damage-taken", dmgAmnt, m_record);
			Stats::Max("damage-taken-max", dmgAmnt, m_record);
			

			//if (dmgAmnt > 5)
			//	MusicManager::AddTension(2.5);
			
			if (m_record.CurrentHealth() <= 0)
			{
				//dmg.Damage = dmgAmnt;
				//BroadcastNetDamage(dmg);
				OnDeath(dmg, dir);
				return dmgAmnt;
			}
			else
			{
				if (m_gore !is null)
					m_gore.OnHit(float(dmgAmnt) / float(maxHp), pos, atan(dir.y, dir.x));

				dictionary params = { { "damage", float(dmgAmnt) } };
				PlaySound3D(m_hurtSound, m_unit, params);
			}
		}
		else if (dmgAmnt < 0)
		{
			if (m_record.hp < 1.0)
			{
				Heal(-dmgAmnt);
				return -GetHealAmount(-dmgAmnt);
			}
			else
				return 0;
		}
		else
		{
			AddFloatingHurt(0, dmg.Crit, dmg.MagicalDamage > dmg.PhysicalDamage ? FloatingTextType::PlayerHurtMagical : FloatingTextType::PlayerHurt);
		}

		dmg.Damage = dmgAmnt;
		BroadcastNetDamage(dmg);
		return dmgAmnt;
	}

	void NetDamage(DamageInfo dmg, vec2 pos, vec2 dir) override
	{
		this.Damage(dmg, pos, dir);
	}

	void BroadcastNetDamage(DamageInfo di)
	{
		UnitPtr damager;
		if (di.Attacker !is null && di.Attacker.m_unit.IsDestroyed())
			damager = di.Attacker.m_unit;

		m_lastSentHP = m_record.hp;
		(Network::Message("PlayerDamaged") << di.DamageType << damager << di.Damage << m_record.hp << di.Weapon).SendToAll();
	}

	void OnDeath(DamageInfo di, vec2 dir) override
	{
		PlayerBase::OnDeath(di, dir);

		DisableModifiers();

		auto gm = cast<Campaign>(g_gameMode);

		Stats::Add("death-count", 1, m_record);

		if (cast<Town>(gm) is null)
			Stats::Add("floor-deaths-" + (gm.m_levelCount + 1), 1, m_record);

		int killerPeer = -1;
		
		auto plyKiller = cast<PlayerBase>(di.Attacker);
		if (plyKiller !is null)
			killerPeer = plyKiller.m_record.peer;
		
		m_record.deaths++;
		m_record.deathsTotal++;
		(Network::Message("PlayerDied") << killerPeer << int(di.DamageType) << int(di.Damage) << di.Melee << di.Weapon).SendToAll();

		PlayerRecord@ killerRecord;
		if (plyKiller !is null)
			@killerRecord = plyKiller.m_record;
		else if (di.Attacker !is null)
			cast<Campaign>(g_gameMode).m_townLocal.EnemyKilledPlayer(di.Attacker.m_unit.GetUnitProducer());	
			
		gm.PlayerDied(m_record, killerRecord, di);

		auto hud = GetHUD();
		if (hud !is null)
			hud.OnDeath();
	}

	bool IsDead() override { return !m_unit.IsValid() || m_record.IsDead(); }

	void OnNewTitle(Titles::Title@ title)
	{
		auto gm = cast<Campaign>(g_gameMode);
		gm.SavePlayer(m_record);

		dictionary paramsTitle = { { "title", Resources::GetString(title.m_name) } };
		gm.m_notifications.Add(Resources::GetString(".hud.newtitle.character", paramsTitle), ParseColorRGBA("#" + Tweak::NotificationColors_NewTitle + "FF"));

		RefreshModifiers();
	}

	void OnLevelUp(int levels)
	{
		(Network::Message("PlayerLevelUp")).SendToAll();

		auto hud = GetHUD();
		hud.PlayPickup();
		
		PlaySound3D(Resources::GetSoundEvent("event:/player/levelup"), m_unit);
		PlayEffect("effects/players/levelup.effect", m_unit);

		AddFloatingText(FloatingTextType::Pickup, Resources::GetString(".hud.levelup"), m_unit.GetPosition());

		m_record.hp = 1.0;
		m_record.mana = 1.0;

		Stats::Add("levels-gained", levels, m_record);
		Stats::Add("avg-levels-gained", levels, m_record);
		Stats::Max("max-level-" + m_record.charClass, m_record.level);
	}

	void WarnCooldown(Skills::Skill@ skill, int ms) override
	{
		if (skill.m_skillId == 0)
			return;
		
		AddFloatingText(FloatingTextType::EnemyImmortal, "[" + formatTime(ms / 1000.0f, true, false, false, false) + "]", m_unit.GetPosition());
		PlaySound3D(m_sndCooldown, m_unit.GetPosition());
	}

	bool SpendCost(int mana, int stamina, int health) override
	{
		ivec2 stats = g_allModifiers.StatsAdd(this);
		
		float manaCostMul = g_allModifiers.SpellCostMul(this);
		float manaCost = float(mana) / float(m_record.MaxMana() + stats.y) * manaCostMul;
	
		if (manaCost > 0)
		{
			if (m_record.mana < manaCost)
			{
				int diff = int(ceil((manaCost - m_record.mana) * float(m_record.MaxMana())));
				AddFloatingText(FloatingTextType::EnemyImmortal, "(-" + diff + ")", m_unit.GetPosition());
				PlaySound3D(m_sndNoMana, m_unit.GetPosition());
				return false;
			}

			m_record.mana -= manaCost;
			//m_record.stamina -= stamina;

			Stats::Add("spent-mana", int(mana * manaCostMul), m_record);
		}
		
		/*
		if (stamina > 0)
		{
			if (m_record.stamina < stamina)
			{
				AddFloatingText(FloatingTextType::EnemyImmortal, "Stamina!", m_unit.GetPosition());
				return false;
			}
		}
		*/
		
		return true; 
	}
	
	void Collide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther)
	{
		for (uint i = 0; i < m_skills.length(); i++)
			m_skills[i].OnCollide(unit, pos, normal, fxOther);
	}
	
	bool BlockProjectile(IProjectile@ proj) override
	{
		auto block = g_allModifiers.ProjectileBlock(this, proj);
		if (block)
		{
			auto pb = cast<ProjectileBase>(proj);
			vec3 pos;
			
			if (pb !is null)
				pos = pb.m_unit.GetPosition();
			else
				pos = m_unit.GetPosition();
			
			PlayEffect(m_fxBlockProjectile, xy(pos));
			PlaySound3D(m_sndBlockProjectile, pos);
			return true;
		}
	
		return false;
	}
	
	
	bool CheckSkillBlocked(Skills::Skill@ skill)
	{
		if (skill.IsBlocking())
		{
			for (uint i = 0; i < m_skills.length(); i++)
			{
				if (m_skills[i].IgnoreForBlock())
					continue;
			
				if (skill !is m_skills[i] && m_skills[i].IsActive())
					return true;
			}
		}
		else
		{
			for (uint i = 0; i < m_skills.length(); i++)
				if (skill !is m_skills[i] && m_skills[i].IsActive() && m_skills[i].IsBlocking())
					return true;
		}
		
		return false;
	}
	
	void CheckUseSkill(int dt, ButtonState &in btn, Skills::Skill@ skill, vec2 aimDir)
	{
		int targetSz = 0;
		auto targetMode = skill.GetTargetingMode(targetSz);
	
		if (CheckSkillBlocked(skill))
		{
			if (targetMode == Skills::TargetingMode::Channeling && skill.IsActive())
			{
				skill.Release(aimDir);
				skill.m_isActive = false;
			}
		
			return;
		}

		if (btn.Pressed)
		{
			if (targetMode == Skills::TargetingMode::Toggle)
			{
				if (!skill.m_isActive && skill.Activate(aimDir))
				{
					g_allModifiers.TriggerEffects(this, null, Modifiers::EffectTrigger::CastSpell);
					skill.m_isActive = true;
				}
				else if (skill.m_isActive)
				{
					skill.Deactivate();
					skill.m_isActive = false;
				}
			}
			else if (skill.Activate(aimDir) && skill !is m_skills[0])
				g_allModifiers.TriggerEffects(this, null, Modifiers::EffectTrigger::CastSpell);
		}
		
		if (targetMode == Skills::TargetingMode::Channeling)
		{
			if (btn.Down)
			{
				skill.Hold(dt, aimDir);
				skill.m_isActive = true;
			}

			if (btn.Released || (!btn.Down && skill.m_isActive))
			{
				skill.Release(aimDir);
				skill.m_isActive = false;
			}
		}
	}
	
	void Update(int dt) override
	{
		PlayerBase::Update(dt);
		/*
		auto cPos = m_unit.GetPosition();
		
		cPos.x = int(cPos.x + 0.5f);
		cPos.y = int(cPos.y + 0.5f);
		
		m_unit.SetPosition(cPos);
		*/
		
		
		bool confused = m_buffs.Confuse();
		auto input = GetInput();
		
		auto aimDir = input.AimDir;
		auto moveDir = input.MoveDir;
		if (confused)
		{
			aimDir *= -1;
			moveDir *= -1;
		}
		
		
		if (m_comboTime > 0)
		{
			m_comboTime -= dt;
			if (m_comboTime <= 0)
			{
				m_comboCount = 0;
				
				if (m_comboActive)
					PlaySound3D(Resources::GetSoundEvent("event:/player/combo/deactivate"), m_unit.GetPosition());
				else
					PlaySound3D(Resources::GetSoundEvent("event:/player/combo/failed"), m_unit.GetPosition());
			}
		}
		else
			m_comboCount = 0;
		
		m_comboActive = false;
		if (GetComboBars().x >= 1.0f)
		{
			this.ApplyBuff(ActorBuff(this, m_comboBuff, 1.0f, false, 0));
		
			float t = g_scene.GetTime() / 250.0;
			float st = 0.25;
			m_unit.Colorize(vec4(0.5,0,0.5, st), vec4(1,0,1, st), vec4(1,0.75,1,1));

			m_comboEffectsTime -= dt;
			if (m_comboEffectsTime <= 0)
			{
				m_comboEffectsTime += 1000;

				auto effects = g_allModifiers.ComboEffects(this);
				if (effects.length() > 0)
					ApplyEffects(effects, this, UnitPtr(), xy(m_unit.GetPosition()), aimDir, 1.0, false);
			}
			
			m_comboActive = true;
		}
		else
			m_unit.Colorize(m_buffs.m_color.m_dark, m_buffs.m_color.m_mid, m_buffs.m_color.m_bright);
			
		g_allModifiers.Update(this, dt);
		
		
		/*
		float xt = (sin(g_scene.GetTime() / 250.0) + 2.0) / 4.0;
		m_unit.Colorize(vec4(xt,xt,1, 1), vec4(0.25, 0.25, 1, xt), vec4(xt * 0.5, xt * 0.5, xt, 1));
		*/

		vec2 regen = (vec2(m_record.HealthRegen(), m_record.ManaRegen()) + g_allModifiers.RegenAdd(this)) * g_allModifiers.RegenMul(this);
		ivec2 stats = g_allModifiers.StatsAdd(this);
		
		m_effectParams.Set("hp_regen", (m_record.hp < 1.0f) ? regen.x : 0.f);
		m_effectParams.Set("mp_regen", (m_record.mana < 1.0f) ? regen.y : 0.f);

		m_record.hp = clamp(m_record.hp + dt / 1000.0f * (regen.x * g_allModifiers.AllHealthGainScale(this)) / (m_record.MaxHealth() + stats.x), 0.0f, 1.0f);
		m_record.mana = clamp(m_record.mana + dt / 1000.0f * regen.y / (m_record.MaxMana() + stats.y), 0.0f, 1.0f);

		
		if (abs(m_lastSentHP - m_record.hp) > 0.001)
		{
			m_lastSentHP = m_record.hp;
			(Network::Message("PlayerSyncHealth") << m_lastSentHP).SendToAll();
		}
		
		
		if (m_damageKillMulC > 0)
		{
			m_damageKillMulC -= dt;
			if (m_damageKillMulC <= 0)
			{
				m_damageKillMul -= Perks::DamageKillMultSub;
				if (m_damageKillMul <= Perks::DamageKillMultMin)
					m_damageKillMul = Perks::DamageKillMultMin;
				else
					m_damageKillMulC = Perks::DamageKillMPScaling();

				(Network::Message("PlayerPerkFrenzy") << m_damageKillMul << m_damageKillMulC).SendToAll();
			}
		}

		if (m_unstoppablePerkC > 0)
			m_unstoppablePerkC -= dt;

		if (m_blockDamageCooldown > 0)
		{
			m_blockDamageCooldown -= dt;
			if (m_blockDamageCooldown <= 0)
				PlayEffect(m_fxDamageBlockRecharged, m_unit.GetPosition);
		}

		auto baseGameMode = cast<BaseGameMode>(g_gameMode);

		HUD@ hud = GetHUD();
		bool freezeControls = IsDead() or baseGameMode.ShouldFreezeControls();
			
		
		int snapAngleCount = GetVarInt("g_movedir_snap");
		if (snapAngleCount > 0 && lengthsq(moveDir) > 0)
		{
			float snapAngle = TwoPI / float(snapAngleCount);
			float curAngle = atan(moveDir.y, moveDir.x);
			float snappedAngle = round(curAngle / snapAngle) * snapAngle;
			moveDir.x = cos(snappedAngle);
			moveDir.y = sin(snappedAngle);
		}

		if (!freezeControls)
		{
			if (!m_buffs.Disarm())
			{
				CheckUseSkill(dt, input.Attack4, m_skills[3], aimDir);
				CheckUseSkill(dt, input.Attack3, m_skills[2], aimDir);
				CheckUseSkill(dt, input.Attack2, m_skills[1], aimDir);
			
				if (input.Attack1.Down && !CheckSkillBlocked(m_skills[0]))
					m_skills[0].Activate(aimDir);
			}
		
			/*
			if (input.Attack2.Pressed)
				m_skills[1].Activate(aimDir);
			if (input.Attack3.Pressed)
				m_skills[2].Activate(aimDir);
			*/

			/*
			if (input.Attack2.Pressed)
			{
				auto buff = LoadActorBuff("items/buffs.sval:apothecarys-herbs");
				this.ApplyBuff(ActorBuff(this, buff, 1.0f, false, 0));
			}
			*/
			
			if (input.Potion.Pressed && (m_record.hp < 1.0 || m_record.mana < 1.0) && g_flags.IsSet("unlock_apothecary"))
			{
				float healAmnt = 50 * g_allModifiers.PotionHealMul(this);
				float manaAmnt = 50 * g_allModifiers.PotionManaMul(this);
				int charges = 1 + g_allModifiers.PotionCharges();

				if (charges > m_record.potionChargesUsed)
				{
					m_record.potionChargesUsed++;
					this.Damage(DamageInfo(0, this, int(healAmnt + 0.5f), false, true, 0), xy(m_unit.GetPosition()), moveDir);

					this.GiveMana(int(manaAmnt + 0.5f));

					PlaySound3D(Resources::GetSoundEvent("event:/player/drink_potion"), m_unit.GetPosition());
					Stats::Add("potion-charges-used", 1, m_record);
					g_allModifiers.TriggerEffects(this, null, Modifiers::EffectTrigger::DrinkPotion);
					
					Tutorial::RegisterAction("potion");
				}
			}

			if (input.Use.Pressed && !m_buffs.Disarm())
			{
				auto usable = GetTopUsable();
				if (usable !is null && usable.CanUse(this))
				{
					Tutorial::RegisterAction("use");
				
					UnitPtr unit = usable.GetUseUnit();
					UnitProducer@ prod = unit.GetUnitProducer();
					if (prod !is null && prod.GetNetSyncMode() == NetSyncMode::None)
						usable.Use(this);
					else if (Network::IsServer())
					{
						(Network::Message("UseUnit") << unit << m_unit).SendToAll();
						usable.Use(this);
					}
					else
						(Network::Message("UseUnitSecure") << unit).SendToHost();
				}
			}
		}
	
		PhysicsBody@ bdy = m_unit.GetPhysicsBody();
		vec2 dir = vec2(cos(m_dirAngle), sin(m_dirAngle));

		// If we have no physics body, we can't do much (player died)
		if (bdy is null)
			return;

		float moveSpeed = Tweak::PlayerSpeed;
		
		moveSpeed += g_allModifiers.MoveSpeedAdd(this);
		moveSpeed *= m_buffs.MoveSpeedMul();

		for (uint i = 0; i < m_skills.length(); i++)
		{
			float speedMod = m_skills[i].GetMoveSpeedMul();
			if (speedMod >= 1.0f || !m_comboActive)
				moveSpeed *= speedMod;
			else
				moveSpeed *= lerp(speedMod, 1.0, 0.5);
		}

		array<Tileset@>@ tilesets = g_scene.FetchTilesets(xy(m_unit.GetPosition()));
		for (int i = tilesets.length() - 1; i >= 0; i--)
		{
			auto tsd = tilesets[i].GetData();
			if (tsd is null)
				continue;

			SValue@ tilesetSpeed = tsd.GetDictionaryEntry("walk-speed");
			if (tilesetSpeed !is null && tilesetSpeed.GetType() == SValueType::Float)
			{
				moveSpeed *= tilesetSpeed.GetFloat();
				break;
			}
		}
		
		moveSpeed = min(moveSpeed, Tweak::PlayerSpeedMax);
		float minSpeed = m_buffs.MinSpeed();
		auto moveDirLen = length(moveDir);
		
		if (moveDirLen < minSpeed)
			moveDir = normalize((moveDirLen > 0) ? moveDir : aimDir) * minSpeed;

		moveDir = freezeControls ? vec2() : (moveDir * moveSpeed);
		
		for (uint i = 0; i < m_skills.length(); i++)
		{
			vec2 skillMoveDir = m_skills[i].GetMoveDir();
			if (skillMoveDir.x != 0 || skillMoveDir.y != 0)
			{
				moveDir = skillMoveDir;
				break;
			}
		}
		

		int distance = int(length(moveDir));
		if (distance > 0)
			Stats::Add("units-traveled", int(distance), m_record);
		
		bdy.SetLinearVelocity(moveDir);
		
		
		float facing = atan(aimDir.y, aimDir.x);
		SetAngle(facing);
		
		bool walking = (lengthsq(bdy.GetLinearVelocity()) > 0.1);
		
		string scene = walking ? m_walkAnim.GetSceneName(facing) : m_idleAnim.GetSceneName(facing);
		SetBodyAnim(scene, false);
		if (m_playerBobbing)
			m_unit.SetPositionZ(walking ? ((m_unit.GetUnitSceneTime() / 125) % 2) : 0);
			
		UpdateFootsteps(dt, false);
		
		int skillDt = int(g_allModifiers.SkillTimeMul(this) * dt);
		for (uint i = 0; i < m_skills.length(); i++)
			m_skills[i].Update(skillDt, walking);
		
		vec2 currDir = bdy.GetLinearVelocity();
		if (length(currDir) > 0.2)
			m_lastDirection = currDir;
		
		SendPlayerMove(dir);
	}
	
	void SendPlayerMove(vec2 dir, bool force = false)
	{
		auto pos = xy(m_unit.GetPosition());

		if (!force)
		{
			if (distsq(m_lastSentPos, pos) > 1 || distsq(m_lastSentDir, dir) > 0.01)
			{
				m_lastSentPos = pos;
				m_lastSentDir = dir;
				(Network::Message("PlayerMove") << pos << dir).SendToAll();
			}
		}
		else
		{
			m_lastSentPos = pos;
			m_lastSentDir = dir;
			(Network::Message("PlayerMoveForce") << pos << dir).SendToAll();
		}
	}

	bool PreRender(int idt)
	{
		if (m_unit.IsDestroyed())
			return true;

		return false;
	}
}


void SetNoClipCVar(bool val)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
		
	ply.m_unit.SetShouldCollide(!val);
}

void SetGodmodeCVar(bool val)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
		
	ply.cvar_god = val;
}


void GiveRandomItems(Player@ ply, ActorItemQuality quality, int num)
{
	for (int i = 0; i < num; i++)
	{
		auto item = g_items.TakeRandomItem(quality);
		if (item is null)
			return;
			
		ply.AddItem(item);
	}
}

void GiveItemsCFunc(cvar_t@ arg0, cvar_t@ arg1, cvar_t@ arg2, cvar_t@ arg3)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
	
	GiveRandomItems(ply, ActorItemQuality::Common, arg0.GetInt());
	GiveRandomItems(ply, ActorItemQuality::Uncommon, arg1.GetInt());
	GiveRandomItems(ply, ActorItemQuality::Rare, arg2.GetInt());
	GiveRandomItems(ply, ActorItemQuality::Legendary, arg3.GetInt());

	ply.RefreshModifiers();
}

void GiveItemCFunc(cvar_t@ arg0)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
	
	auto item = g_items.TakeItem(arg0.GetString());
	if (item is null)
	{
		print("No item '" + arg0.GetString() + "' found");
		return;
	}
	
	ply.AddItem(item);
	ply.RefreshModifiers();
}

void ClearItemsCfunc()
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;

	ply.m_record.items.removeRange(0, ply.m_record.items.length());
	ply.RefreshModifiers();
}

void GiveExperienceCFunc(cvar_t@ arg0)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
		
	ply.m_record.GiveExperience(arg0.GetInt());
}

void GiveHealthCFunc(cvar_t@ arg0)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
		
	ply.Damage(DamageInfo(0, ply, arg0.GetInt(), false, false, 0), vec2(), vec2());
}

void GiveManaCFunc(cvar_t@ arg0)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;

	ply.GiveMana(arg0.GetInt());
}

void GiveArmorCFunc(cvar_t@ arg0)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
		
	ply.GiveArmor(arg0.GetInt(), null, false);
}

void GiveKeyCFunc(cvar_t@ arg0)
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;

	ply.m_record.keys[arg0.GetInt()] += 1;
}

void LevelupCFunc(cvar_t@ arg0)
{
	auto record = GetLocalPlayerRecord();
	int levels = arg0.GetInt();

	for (int i = 0; i < levels; i++)
	{
		int level = record.level;
		int xp = record.LevelExperience(level) - record.LevelExperience(level - 1);
		record.GiveExperience(xp);
	}
}

void KillCFunc()
{
	auto ply = GetLocalPlayer();
	if (ply is null)
		return;
		
	ply.Kill(null, 0);
}

void KillAllCFunc()
{
	auto enemies = g_scene.FetchAllActorsWithOtherTeam(g_team_player);

	for (uint i = 0; i < enemies.length(); i++)
	{
		Actor@ a = cast<Actor>(enemies[i].GetScriptBehavior());
		if (a.IsTargetable())
			a.Kill(null, 0);
	}
}

void ReviveCFunc()
{
	auto record = GetLocalPlayerRecord();
	if (record is null)
		return;

	record.corpse.NetRevive(record);
}

void ListEnemiesCFunc()
{
	auto enemies = g_scene.FetchAllActorsWithOtherTeam(g_team_player);

	for (uint i = 0; i < enemies.length(); i++)
	{
		print(enemies[i].GetDebugName());
	}
}

void ListModifiersCFunc()
{
	print("Dumping all modifiers:");
	g_allModifiers.DumpModifiers(1);
}

void GivePerkCFunc(cvar_t@ arg0)
{
	string id = arg0.GetString();
	GetLocalPlayerRecord().GivePerk(id);
}

void SetFlagCFunc(cvar_t@ arg0, cvar_t@ arg1, cvar_t@ arg2)
{
	string flag = arg0.GetString();
	bool value = arg1.GetBool();
	bool persistent = arg2.GetBool();
	
	if (!value)
		g_flags.Delete(flag);
	else
		g_flags.Set(flag, persistent ? FlagState::Run : FlagState::Level);
	
	(Network::Message("SyncFlag") << flag << value << persistent).SendToAll();
}

void GiveGoldCFunc(cvar_t@ arg0)
{
	int amount = arg0.GetInt();
	cast<Campaign>(g_gameMode).m_townLocal.m_gold += amount;
}

void GiveOreCFunc(cvar_t@ arg0)
{
	int amount = arg0.GetInt();
	cast<Campaign>(g_gameMode).m_townLocal.m_ore += amount;
}

void GiveSkillpointsCFunc(cvar_t@ arg0)
{
	int amount = arg0.GetInt();
	GetLocalPlayerRecord().skillPoints += amount;
}
