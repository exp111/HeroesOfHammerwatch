namespace UnitHandler
{
	void NetSendUnitDamaged(UnitPtr unit, int dmg, vec2 pos, vec2 dir, Actor@ attacker)
	{
		if (!unit.IsValid())
			return;
			
		auto localPlayer = cast<Player>(attacker);
		if (localPlayer is null)
			(Network::Message("UnitDamaged") << unit << dmg << pos << dir).SendToAll();
		else
			(Network::Message("UnitDamagedBySelf") << unit << dmg << pos << dir).SendToAll();
	}

	void NetSendUnitUseSkill(UnitPtr unit, int skillId, int stage = 0, SValue@ param = null)
	{
		if (stage == 0)
		{
			if (param !is null)
				(Network::Message("UnitUseSkillParam") << unit << skillId << xy(unit.GetPosition()) << param).SendToAll();
			else
				(Network::Message("UnitUseSkill") << unit << skillId << xy(unit.GetPosition())).SendToAll();
		}
		else	
		{
			if (param !is null)
				(Network::Message("UnitUseSSkillParam") << unit << skillId << stage << xy(unit.GetPosition()) << param).SendToAll();
			else
				(Network::Message("UnitUseSSkill") << unit << skillId << stage << xy(unit.GetPosition())).SendToAll();
		}	
	}
	
	Actor@ GetActor(uint unitId)
	{
		if (unitId == 0)
			return null;
	
		UnitPtr unit = g_scene.GetUnit(unitId);
		if (!unit.IsValid())
		{
			PrintError("Couldn't find unit " + unitId);
			return null;
		}
		
		if (unit.IsDestroyed())
			return null;
	
		ref@ behavior = unit.GetScriptBehavior();
		if (behavior is null)
		{
			PrintError("Unit " + unitId + " (" + unit.GetDebugName() + ") has no behavior");
			return null;
		}
		
		Actor@ actor = cast<Actor>(behavior);
		if (actor is null)
		{
			PrintError("Unit " + unitId + " (" + unit.GetDebugName() + ") is not an actor");
			return null;
		}
	
		return actor;
	}


	Actor@ GetActor(UnitPtr unit)
	{
		if (unit.IsDestroyed())
			return null;
	
		ref@ behavior = unit.GetScriptBehavior();
		if (behavior is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") has no behavior");
			return null;
		}
		
		Actor@ actor = cast<Actor>(behavior);
		if (actor is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not an actor");
			return null;
		}
	
		return actor;
	}
	
	

	Pickup@ GetPickup(UnitPtr unit)
	{
		if (unit.IsDestroyed())
			return null;
	
		ref@ behavior = unit.GetScriptBehavior();
		if (behavior is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") has no behavior");
			return null;
		}

		Pickup@ pickup = cast<Pickup>(behavior);
		if (pickup is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not a pickup");
			return null;
		}

		return pickup;
	}

	void UnitTeleported(UnitPtr unit, vec2 pos)
	{
		unit.SetPosition(xyz(pos));
	}

	void UnitDestroyed(UnitPtr unit)
	{
		unit.Destroy();
	}
	
	void UnitHealed(UnitPtr unit, int amount)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;

		actor.NetHeal(amount);
	}
	
	void UnitKilled(UnitPtr unit, UnitPtr attacker, int dmg, vec2 dir, uint weapon)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;
		
		if (attacker.IsValid())
		{
			Actor@ actorAttacker = GetActor(attacker);
			actor.NetKill(actorAttacker, dmg, dir, weapon);

			PlayerHusk@ playerAttacker = cast<PlayerHusk>(actorAttacker);
			if (playerAttacker !is null)
			{
				playerAttacker.m_record.kills++;
				playerAttacker.m_record.killsTotal++;
			}
		}
		else
			actor.NetKill(null, dmg, dir, weapon);
	}
		
	void UnitTarget(UnitPtr unit, UnitPtr target)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;
			
		if (target.IsValid())
		{
			Actor@ t = GetActor(target);
			//print("Target set to: " + t.m_unit.GetDebugName() + " (" + unit.GetId() + " -> " + target.GetId() + ")");
			actor.NetSetTarget(t);
		}
		else
		{
			actor.NetSetTarget(null);
			//print("Target set to: null (" + unit.GetId() + " -> 0)");
		}
	}
	
	void UnitUseSSkillParam(UnitPtr unit, int skillId, int stage, vec2 pos, SValue@ param)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;
			
		actor.NetUseSkill(skillId, stage, pos, param);
	}
	
	void UnitUseSSkill(UnitPtr unit, int skillId, int stage, vec2 pos)
	{
		UnitUseSSkillParam(unit, skillId, stage, pos, null);
	}
	
	void UnitUseSkillParam(UnitPtr unit, int skillId, vec2 pos, SValue@ param)
	{
		UnitUseSSkillParam(unit, skillId, 0, pos, param);
	}
	
	void UnitUseSkill(UnitPtr unit, int skillId, vec2 pos)
	{
		UnitUseSSkillParam(unit, skillId, 0, pos, null);
	}

	void SpawnUnit(int unitId, uint producerHash, vec2 pos)
	{
		UnitProducer@ prod = Resources::GetUnitProducer(producerHash);
		if (prod is null)
		{
			PrintError("Unknown unit producer '" + producerHash + "'");
			return;
		}

		prod.Produce(g_scene, xyz(pos), unitId);
	}


	void UnitDamaged(uint8 peer, UnitPtr unit, int damage, vec2 pos, vec2 dir)
	{
		if (damage == 0)
			PrintError("Damage to unit " + unit.GetId() + " is 0 damage?");

		auto b = cast<IDamageTaker>(unit.GetScriptBehavior());
		if (b is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type IDamageTaker");
			return;
		}

		DamageInfo di;
		di.Damage = damage;
		b.NetDamage(di, pos, dir);
	}
	
	void UnitDamagedBySelf(uint8 peer, UnitPtr unit, int damage, vec2 pos, vec2 dir)
	{
		if (damage == 0)
			PrintError("Damage to unit " + unit.GetId() + " is 0 damage?");

		auto b = cast<IDamageTaker>(unit.GetScriptBehavior());
		if (b is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type IDamageTaker");
			return;
		}

		DamageInfo di;
		@di.Attacker = PlayerHandler::GetPlayer(peer);
		di.Damage = damage;
		b.NetDamage(di, pos, dir);
	}

	void UnitDelayedBreakable(uint8 peer, UnitPtr unit)
	{
		DelayedBreakable@ breakable = cast<DelayedBreakable>(unit.GetScriptBehavior());
		if (breakable is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type DelayedBreakable");
			return;
		}

		breakable.DamageEffects();
	}
	
	
	void UnitBuffed(uint8 peer, UnitPtr unit, UnitPtr ownerUnit, uint buffHash, float intensity, uint weapon)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;

		Actor@ owner = null;
		if (ownerUnit.IsValid())
			@owner = GetActor(ownerUnit);
	
		auto aBuffDef = LoadActorBuff(buffHash);
		if (aBuffDef is null)
			return;
		
		actor.ApplyBuff(ActorBuff(owner, aBuffDef, intensity, true, weapon));
	}

	void UnitPicked(UnitPtr unit, UnitPtr picker)
	{
		auto pickup = GetPickup(unit);
		if (pickup is null)
			return;

		pickup.NetPicked(picker);
	}
	
	void UnitPickSecure(uint8 peer, UnitPtr unit, UnitPtr picker)
	{
		if (!Network::IsServer())
			return;

		auto pickup = GetPickup(unit);
		if (pickup is null)
			return;

		if (pickup.NetPicked(picker))
			(Network::Message("UnitPicked") << unit << picker).SendToAll();
	}
	
	void UnitPickCallback(UnitPtr unit, UnitPtr picker)
	{
		auto pickup = GetPickup(unit);
		if (pickup is null)
			return;

		pickup.CallbackPicked(picker);
	}

	void UnitMovementChargeBegin(UnitPtr unit, vec2 pos, float dir)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;

		auto b = cast<CompositeActorBehavior>(actor);
		if (b is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type CompositeActorBehavior");
			return;
		}

		auto charge = cast<ChargeMovement>(b.m_movement);
		if (charge is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") does not have a movement of type ChargeMovement");
			return;
		}

		charge.m_dir = dir;
		charge.BeginCharging();
		actor.m_unit.SetPosition(xyz(pos), true);
	}

	void UnitMovementChargeLook(UnitPtr unit, vec2 pos)
	{
		Actor@ actor = GetActor(unit);
		if (actor is null)
			return;

		auto b = cast<CompositeActorBehavior>(actor);
		if (b is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type CompositeActorBehavior");
			return;
		}

		auto charge = cast<ChargeMovement>(b.m_movement);
		if (charge is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") does not have a movement of type ChargeMovement");
			return;
		}

		actor.m_unit.SetPosition(xyz(pos), true);
		charge.BeginLooking();
	}

	void UnitMovementBossLichTarget(UnitPtr unit, UnitPtr targetUnit)
	{
		auto lich = cast<BossLich>(unit.GetScriptBehavior());
		if (lich is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type BossLich");
			return;
		}

		auto target = cast<WorldScript::BossLichNode>(targetUnit.GetScriptBehavior());
		if (target is null)
		{
			PrintError("Unit " + targetUnit.GetId() + " (" + targetUnit.GetDebugName() + ") is not of type BossLichNode");
			return;
		}

		auto movement = cast<BossLichMovement>(lich.m_movement);
		if (movement is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") does not have a movement of type BossLichMovement");
			return;
		}

		movement.SetTargetNode(target);
	}

	void UnitEyeBossWispsAdded(UnitPtr unit, SValue@ params)
	{
		auto boss = cast<BossEye>(unit.GetScriptBehavior());
		if (boss is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type BossEye");
			return;
		}

		boss.NetAddWisps(params);
	}

	void UnitEyeBossWispsSync(UnitPtr unit, SValue@ params)
	{
		auto boss = cast<BossEye>(unit.GetScriptBehavior());
		if (boss is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type BossEye");
			return;
		}

		boss.NetWispSync(params);
	}

	void UnitBombExploded(UnitPtr unit, SValue@ param)
	{
		auto bomb = cast<BombBehavior>(unit.GetScriptBehavior());
		if (bomb is null)
		{
			PrintError("Unit " + unit.GetId() + " (" + unit.GetDebugName() + ") is not of type BombBehavior");
			return;
		}

		bomb.NetDoExplode(param);
	}

	void SpawnLoot(SValue@ param)
	{
		LootDef::NetSpawnLoot(param);
	}

	void SetOwnedUnit(UnitPtr ownedUnit, UnitPtr ownerUnit, float intensity)
	{
		Actor@ owner = GetActor(ownerUnit);
		if (owner is null)
			return;

		auto owned = cast<IOwnedUnit>(ownedUnit.GetScriptBehavior());
		if (owned is null)
		{
			PrintError("Unit " + ownedUnit.GetId() + " (" + ownedUnit.GetDebugName() + ") is not of type IOwnedUnit");
			return;
		}

		owned.Initialize(owner, intensity, true);
	}

	void PlayEffect(uint eHash, vec2 pos)
	{
		::PlayEffect(Resources::GetEffect(eHash), pos);
	}
}
