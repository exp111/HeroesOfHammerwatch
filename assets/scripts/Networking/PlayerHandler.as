namespace PlayerHandler
{
	PlayerHusk@ GetPlayer(uint8 peer)
	{
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == peer)
			{
				if (g_players[i].actor is null)
					return null;
				
				if (g_players[i].local)
				{
					print("Player " + peer + " is not a husk on " + (Network::IsServer() ? "server" : "client"));
					return null;
				}
			
				return cast<PlayerHusk>(g_players[i].actor);
			}
		}
	
		return null;
	}
	
	PlayerRecord@ GetPlayerRecord(uint8 peer)
	{
		for (uint i = 0; i < g_players.length(); i++)
		{
			if (g_players[i].peer == peer)
				return g_players[i];
		}
	
		return null;
	}
	
	int GetPlayerIndex(uint8 peer)
	{
		for (uint i = 0; i < g_players.length(); i++)
			if (g_players[i].peer == peer)
				return i;
	
		return -1;
	}

	//NOTE: If first param is uint8, it will be peer id (always the host in this case)
	//      Not including an uint8 skips the peer id
	void SpawnPlayer(int plrId, vec2 pos, int unitId, int team)
	{
		int index = GetPlayerIndex(plrId);
	
		if (index == -1)
		{
			PrintError("Couldn't find player id " + plrId);
			return;
		}

		g_gameMode.SpawnPlayer(index, pos, unitId, team);
	}
	
	void SpawnPlayerCorpse(int plrId, vec2 pos)
	{
		int index = GetPlayerIndex(plrId);
	
		if (index == -1)
		{
			PrintError("Couldn't find player id " + plrId);
			return;
		}

		g_gameMode.SpawnPlayerCorpse(index, pos);
	}
	
		
	// TODO: Move to a gamemode network handler?
	void AttemptRespawn(uint8 peerId)
	{
		g_gameMode.AttemptRespawn(peerId);
	}
	
	void ResetPlayerHealthArmor(int plrId)
	{
		auto plr = GetPlayerRecord(plrId);
		if (plr !is null)
		{
			plr.hp = 1.0;
			plr.armor = 0;
		}
	}
	
	void PlayerMove(uint8 peer, vec2 pos, vec2 dir)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;
	
		plr.MovePlayer(pos, dir);
	}

	void PlayerMoveForce(uint8 peer, vec2 pos, vec2 dir)
	{
		PlayerMove(peer, pos, dir);
	}
	
	void PlayerDash(uint8 peer, int duration, vec2 dir)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.Dash(duration, dir);
	}

	void PlayerDashAbort(uint8 peer)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_dashTime = 0;
	}
	
	// Damage on local player
	void PlayerDamage(uint8 peer, int dmgType, int dmg)
	{
		Player@ player = GetLocalPlayer();
		if (player is null)
			return; // ???

		DamageInfo di;
		di.DamageType = uint8(dmgType);
		di.Damage = uint16(dmg);

		int iDamager = GetPlayerIndex(peer);
		if (iDamager != -1 && g_players[iDamager].actor !is null)
			@di.Attacker = g_players[iDamager].actor;

		player.NetDamage(di, xy(player.m_unit.GetPosition()), player.m_lastDirection);
	}

	// Other player reports that they were damaged
	void PlayerDamaged(uint8 peer, int dmgType, UnitPtr damager, int dmg, float hp, uint weapon)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		DamageInfo di;
		di.DamageType = uint8(dmgType);
		di.Damage = int16(dmg);
		di.Weapon = weapon;

		if (damager.IsValid())
			@di.Attacker = cast<Actor>(damager.GetScriptBehavior());

		plr.NetDamage(di, xy(plr.m_unit.GetPosition()), plr.m_dir);
		plr.m_record.hp = hp;
		
		auto local = GetLocalPlayerRecord();
		if (local !is null && !local.IsDead() && local.actor !is null)
		{
			for (uint i = 0; i < local.soulLinks.length(); i++)
				if (uint(local.soulLinks[i]) == peer)
					cast<Player>(local.actor).SoulLinkDamage(dmg);
		}		
	}

	void PlayerHealed(uint8 peer, int amnt, float hp)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.NetHeal(amnt);
		plr.m_record.hp = hp;
	}
	
	void HealPlayer(uint8 peer, int amnt)
	{
		auto plr = GetLocalPlayer();
		if (plr is null)
			return;
			
		plr.Heal(amnt);
	}
	
	void PlayerSyncArmor(uint8 peer, uint armorDefHash, int armor)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_record.armor = armor;
			
		auto armorDef = LoadArmorDef(armorDefHash);
		if (armorDef !is null)
			@plr.m_record.armorDef = armorDef;
	}
	
	void PlayerSyncHealth(uint8 peer, float hp)
	{
		auto plr = GetPlayerRecord(peer);
		
		if (plr is null)
			return;

		plr.hp = hp;
	}

	void PlayerDied(uint8 peer, int killerPeer, int damageType, int damageAmount, bool damageMelee, uint weapon)
	{
		auto plr = GetPlayer(peer);
		if (plr is null)
			return;
		
		DamageInfo di;
		
		auto killer = GetPlayerRecord(killerPeer);
		if (killer !is null)
			@di.Attacker = killer.actor;

		di.DamageType = uint8(damageType);
		di.Damage = int16(damageAmount);
		di.Melee = damageMelee;
		di.Weapon = weapon;
		
		plr.Kill(di);
		cast<BaseGameMode>(g_gameMode).PlayerDied(plr.m_record, killer, di);
		
		auto local = GetLocalPlayerRecord();
		if (local !is null && !local.IsDead() && local.actor !is null)
		{
			for (uint i = 0; i < local.soulLinks.length(); i++)
				if (uint(local.soulLinks[i]) == peer)
					cast<Player>(local.actor).SoulLinkKill(plr);
		}
	}
	
	void PlayerShareExperience(int experience)
	{
		Player@ player = GetLocalPlayer();
		if (player !is null)
			player.NetShareExperience(experience);
	}
	
	void PlayerSyncExperience(uint8 peer, int level, int experience)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_record.NetSyncExperience(level, experience);
	}
	
	void PlayerGivePerk(uint8 peer, int name)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_record.GivePerk(name);
	}

	void PlayerTakePerk(uint8 peer, int name)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_record.TakePerk(name);
	}

	void PlayerRespec(uint8 peer)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_record.perks.removeRange(0, plr.m_record.perks.length());
	}

	void PlayerPickups(uint8 peer, int num, int numTotal)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.m_record.pickups = num;
		plr.m_record.pickupsTotal = num;
	}

	void PlayerLevelUp(uint8 peer)
	{
		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		plr.OnLevelUp();
	}

	void ModifierTriggerEffect(uint8 peer, uint itemId, uint modId, UnitPtr target)
	{
		auto item = g_items.GetItem(itemId);
		if (item is null)
			return;

		auto mod = cast<Modifiers::TriggerEffect>(item.modifiers[modId]);
		if (mod is null)
			return;
		
		mod.NetTrigger(GetPlayer(peer), target);
	}
	
	void UseUnit(UnitPtr unit, UnitPtr user)
	{
		auto usable = cast<IUsable>(unit.GetScriptBehavior());
		if (usable is null)
			return;

		Player@ plrLocal = cast<Player>(user.GetScriptBehavior());
		if (plrLocal !is null)
		{
			usable.Use(plrLocal);
			return;
		}

		PlayerHusk@ plrHusk = cast<PlayerHusk>(user.GetScriptBehavior());
		if (plrHusk !is null)
			usable.NetUse(plrHusk);
	}

	void UseUnitSecure(uint8 peer, UnitPtr unit)
	{
		if (!Network::IsServer())
			return;

		PlayerHusk@ plr = GetPlayer(peer);
		if (plr is null)
			return;

		auto usable = cast<IUsable>(unit.GetScriptBehavior());
		if (usable is null)
			return;

		if (!usable.CanUse(plr))
			return;

		(Network::Message("UseUnit") << unit << plr.m_unit).SendToAll();
		usable.NetUse(plr);
	}

	void PlayerPerkActionBegin(uint8 peer, uint perkActionHash, UnitPtr unitOwner, vec2 pos, vec2 dir, float intensity)
	{
		if (!Network::IsServer())
			return;

		PerkAction@ action = PerkAction(perkActionHash);

		Actor@ owner = cast<Actor>(unitOwner.GetScriptBehavior());
		if (owner is null)
		{
			PrintError("Unit " + unitOwner.GetId() + " (" + unitOwner.GetDebugName() + ") is not an Actor");
			return;
		}

		action.Do(owner, intensity, pos, dir);
	}

	void PlayerPerkAction(uint8 peer, uint perkActionHash, UnitPtr unitOwner, vec2 pos, vec2 dir, SValue@ params)
	{
		PerkAction@ action = PerkAction(perkActionHash);

		Actor@ owner = cast<Actor>(unitOwner.GetScriptBehavior());
		if (owner is null)
		{
			PrintError("Unit " + unitOwner.GetId() + " (" + unitOwner.GetDebugName() + ") is not an Actor");
			return;
		}

		action.NetDo(params, owner, pos, dir);

		Player@ player = cast<Player>(owner);
		if (player !is null)
			player.m_enemyExplodePerkSwitch = false;
	}

	void PlayerPerkFrenzy(uint8 peer, float mul, int mulC)
	{
		PlayerHusk@ player = GetPlayer(peer);
		if (player is null)
			return;

		player.m_damageKillMul = mul;
		player.m_damageKillMulC = mulC;
	}

	void PlayerPerkRampage(uint8 peer, int mulC)
	{
		PlayerHusk@ player = GetPlayer(peer);
		if (player is null)
			return;

		player.m_rampageSpeedMulC = mulC;
	}

	void PlayerPerkDamageHp(uint8 peer, bool active)
	{
		PlayerHusk@ player = GetPlayer(peer);
		if (player is null)
			return;

		player.m_damageHpEffect = active;
	}

	void TakeFreeLife(int peer, int freeLives)
	{
		if (Network::IsServer())
			return;

		for (uint i = 0; i < g_players.length(); i++)
		{
			PlayerRecord@ plr = g_players[i];
			if (plr.peer == uint8(peer))
			{
				plr.freeLivesTaken = freeLives;
				print("Peer " + peer + " now has " + freeLives + " lives");
				return;
			}
		}

		PrintError("Peer " + peer + " was not found");
	}

	Skills::ActiveSkill@ GetPlayerSkill(uint8 peer, int id)
	{
		PlayerHusk@ player = GetPlayer(peer);
		if (player is null)
			return null;

		for (uint i = 0; i < player.m_skills.length(); i++)
		{
			auto skill = cast<Skills::ActiveSkill>(player.m_skills[i]);
			if (skill !is null && skill.m_skillId == uint(id))
				return skill;
		}

		return null;
	}

	void PlayerActiveSkillActivate(uint8 peer, int id, vec2 target)
	{
		auto skill = GetPlayerSkill(peer, id);
		if (skill is null)
			return;

		skill.NetActivate(target);
	}

	void PlayerActiveSkillDoActivate(uint8 peer, int id, vec2 target, SValue@ param)
	{
		auto skill = GetPlayerSkill(peer, id);
		if (skill is null)
			return;

		skill.NetDoActivate(param, target);
	}

	void PlayerActiveSkillDeactivate(uint8 peer, int id)
	{
		auto skill = GetPlayerSkill(peer, id);
		if (skill is null)
			return;

		skill.NetDeactivate();
	}

	void PlayerActiveSkillRelease(uint8 peer, int id, vec2 target)
	{
		auto skill = GetPlayerSkill(peer, id);
		if (skill is null)
			return;

		skill.NetRelease(target);
	}

	void PlayerGiveGold(uint8 peer, int amount)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		NetGiveGoldImpl(amount, player);
	}

	void PlayerGiveOre(uint8 peer, int amount)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		NetGiveOreImpl(amount, player);
	}

	void PlayerGiveKey(uint8 peer, int lock, int amount)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		NetGiveKeyImpl(lock, amount, player);
	}

	void PlayerGiveItem(uint8 peer, string id)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		auto item = g_items.GetItem(id);
		if (item is null)
		{
			PrintError("No such item with ID \"" + id + "\"");
			return;
		}

		GiveItemImpl(item, player, true);
	}

	void PlayerGiveUpgrade(uint8 peer, string id, int level)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		auto upgrade = Upgrades::GetShopUpgrade(id, player.m_record);
		if (upgrade is null)
		{
			PrintError("Couldn't find upgrade with id \"" + id + "\" to upgrade to level " + level);
			return;
		}

		auto step = upgrade.GetStep(level);
		if (step is null)
		{
			PrintError("Couldn't find upgrade step level " + level + " for upgrade with id \"" + id + "\"");
			return;
		}

		if (!step.ApplyNow(player.m_record))
		{
			PrintError("Step ApplyNow returned false for level " + level + " of upgrade with id \"" + id + "\"");
			return;
		}

		if (upgrade.ShouldRemember())
		{
			OwnedUpgrade@ ownedUpgrade = player.m_record.GetOwnedUpgrade(upgrade.m_id);
			if (ownedUpgrade !is null)
			{
				ownedUpgrade.m_level = step.m_level;
				@ownedUpgrade.m_step = step;
			}
			else
			{
				@ownedUpgrade = OwnedUpgrade();
				ownedUpgrade.m_id = upgrade.m_id;
				ownedUpgrade.m_level = step.m_level;
				@ownedUpgrade.m_step = step;
				player.m_record.upgrades.insertLast(ownedUpgrade);
			}
		}

		player.RefreshModifiers();
	}

	void ProximityTrapEnter(uint8 peer, UnitPtr unit)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		auto trap = cast<ProximityTrap>(unit.GetScriptBehavior());
		if (trap is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not a ProximityTrap");
			return;
		}

		trap.OnEnter(player);
	}

	void ProximityTrapExit(uint8 peer, UnitPtr unit)
	{
		auto player = GetPlayer(peer);
		if (player is null)
			return;

		auto trap = cast<ProximityTrap>(unit.GetScriptBehavior());
		if (trap is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not a ProximityTrap");
			return;
		}

		trap.OnExit(player);
	}

	void ReviveCorpse(uint8 peer, int plrId)
	{
		auto player = GetPlayerRecord(plrId);
		if (player is null)
			return;
			
		player.corpse.NetRevive(GetPlayerRecord(peer));
	}

	void PlayerTitleModifiers(uint8 peer, SValue@ params)
	{
		auto player = GetPlayerRecord(peer);
		if (player is null)
			return;

		g_classTitles.NetRefreshModifiers(player, params);
	}
}
