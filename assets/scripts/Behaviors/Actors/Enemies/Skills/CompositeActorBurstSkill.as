class CompositeActorBurstSkill : CompositeActorSkill
{
	int m_numBursts;
	int m_burstC;
	
	CompositeActorBurstSkill(UnitPtr unit, SValue& params)
	{
		super(unit, params);
	
		m_numBursts = GetParamInt(unit, params, "burst", true, 1);
		m_burstC = 0;
	}
	
	
	void NetUseSkill(int stage, SValue@ param) override
	{
		if (stage == 2)
		{
			stage = 0;
			m_burstC = m_numBursts;
		}
		
		if (stage == 0)
			m_burstC--;
		
		CompositeActorSkill::NetUseSkill(stage, param);
	}
	
	Actor@ GetTarget()
	{
		return m_behavior.m_target;
	}
	
	void NewBurstShot() {}
	
	void Update(int dt, bool isCasting) override
	{
		if (isCasting && IsCasting())
			isCasting = false;
	
		if (m_castC > 0)
		{
			vec2 dir = normalize(xy(GetTarget().m_unit.GetPosition() - m_unit.GetPosition()));
			m_behavior.m_movement.m_dir = atan(dir.y, dir.x);
		
			auto body = m_unit.GetPhysicsBody();
			if (body !is null)
				body.SetLinearVelocity(0, 0);
		
			m_castC -= dt;
			if (Network::IsServer() && m_castC <= 0 && m_burstC > 0)
			{
				m_burstC--;
				if (m_burstC <= 0)
				{
					if (m_charges > 0)
						m_charges--;

					m_cooldownC = m_cooldown;
				}
				else
					m_cooldownC = 0;
			}
		}
		
		if (m_cooldownC > 0)
		{
			m_cooldownC -= dt;
			return;
		}
		
		if (Network::IsServer())
		{
			if (m_cooldownC <= 0 && !isCasting && m_castC <= 0)
			{
				bool initial = false;

				if (m_burstC <= 0)
				{
					if (IsAvailable() && (!m_mustSee || CanSee(GetTarget().m_unit)))
					{
						m_burstC = m_numBursts;
						initial = true;
					}
					else
					{
						m_cooldownC = m_cooldown;
						return;
					}
				}

				if (!initial && !IsAvailable())
				{
					m_burstC = 0;
					return;
				}
					
				NewBurstShot();

				vec2 dir = xy(GetTarget().m_unit.GetPosition() - m_unit.GetPosition());
				if (dir.x != 0 || dir.y != 0)
					m_behavior.m_movement.m_dir = atan(dir.y, dir.x);

				m_cooldownC = 0;
				m_castPointC = m_castPoint;

				PlaySound3D(m_startSound, m_unit.GetPosition());
				
				m_castC = m_behavior.SetUnitScene(m_anims[m_currAnim].GetSceneName(m_behavior.m_movement.m_dir), true);
				m_currAnim = (m_currAnim + 1) % m_anims.get_length();
				
				
				if (m_startActions.length() > 0)
				{
					CalcAimDir();
					vec2 pos = FetchOffsetPos(m_unit, m_offset);
					SValue@ param = DoActions(m_startActions, m_behavior, GetTarget(), pos, m_skillAimDir);
					UnitHandler::NetSendUnitUseSkill(m_unit, m_id, initial ? 2 : 0, param);
				}
				else 
				{
					UnitHandler::NetSendUnitUseSkill(m_unit, m_id, initial ? 2 : 0);
					
					if (!m_goodAim)
						CalcAimDir();
				}
			}
			
			if (m_castPointC > 0)
			{
				m_castPointC -= dt;
				if (m_castPointC <= 0)
				{
					//if (IsAvailable())
					{
						PlaySound3D(m_sound, m_unit.GetPosition());

						if (m_goodAim)
							CalcAimDir();
						
						vec2 pos = FetchOffsetPos(m_unit, m_offset);
						SValue@ param = DoActions(m_actions, m_behavior, GetTarget(), pos, m_skillAimDir);
						UnitHandler::NetSendUnitUseSkill(m_unit, m_id, 1, param);
					}
				}
			}
		}

		for (uint i = 0; i < m_actions.length(); i++)
			m_actions[i].Update(dt, m_cooldownC);
	}
	
	
	bool IsCasting() override
	{
		return m_castC > 0 || m_burstC > 0;
	}
}
