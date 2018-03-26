class PlayerBase : Actor
{
	AnimString@ m_idleAnim;
	AnimString@ m_walkAnim;
	AnimString@ m_dashAnim;

	vec2 m_dashDir;
	int m_dashTime;
	
	UnitProducer@ m_body;
	UnitScene@ m_aimLaser;
	CustomUnitScene@ m_unitScene;
	UnitScene@ m_markerFx;
	UnitScene@ m_frenzyFx;
	UnitScene@ m_rampageFx;
	UnitScene@ m_damageHpFx;
	GoreSpawner@ m_gore;
	
	SoundEvent@ m_hurtSound;
	SoundEvent@ m_deathSound;
	
	string m_bodySceneName;
	int m_bodySceneTimeOffset;
	
	PlayerRecord@ m_record;
	
	EffectParams@ m_effectParams;
	vec4 m_dmgColor;

	ActorFootsteps@ m_footsteps;
	ActorFootsteps@ m_footstepsDash;
	
	ActorBuffList m_buffs;

	float m_damageKillMul = 1.0;
	int m_damageKillMulC = 0;
	int m_rampageSpeedMulC;
	bool m_damageHpEffect;

	bool m_playerBobbing;
	bool m_charging;

	bool m_comboActive;

	array<Skills::Skill@> m_skills;

	PlayerBase(UnitPtr unit, SValue& params)
	{
		SetTeam("player", false);
		super(unit);
		
		@m_idleAnim = AnimString(GetParamString(unit, params, "anim-idle"));
		@m_walkAnim = AnimString(GetParamString(unit, params, "anim-walk"));
		@m_dashAnim = AnimString(GetParamString(unit, params, "anim-dash"));

		@m_unitScene = CustomUnitScene();
		
		@m_hurtSound = Resources::GetSoundEvent("event:/player/hurt");
		@m_deathSound = Resources::GetSoundEvent("event:/player/death");
		@m_markerFx = Resources::GetEffect("actors/players/marker.effect");
		@m_frenzyFx = Resources::GetEffect("actors/players/frenzy.effect");
		@m_rampageFx = Resources::GetEffect("actors/players/rampage.effect");
		@m_damageHpFx = Resources::GetEffect("actors/players/damagehp.effect");
		
		
		
		@m_effectParams = m_unit.CreateEffectParams();
		m_effectParams.Set("height", Tweak::PlayerCameraHeight);
		m_effectParams.Set("frenzy", 1.0f);
		
		m_dmgColor = vec4(0, 0, 0, 0);

%if !GFX_VFX_LOW
		auto svFootsteps = GetParamDictionary(unit, params, "footsteps", false);
		if (svFootsteps !is null)
			@m_footsteps = ActorFootsteps(unit, svFootsteps);
%endif

		auto svFootstepsDash = GetParamDictionary(unit, params, "footsteps-dash", false);
		if (svFootstepsDash !is null)
			@m_footstepsDash = ActorFootsteps(unit, svFootstepsDash);
			
		m_buffs.Initialize(this);

		m_playerBobbing = GetParamBool(unit, params, "bobbing", false, true);
		m_charging = false;
	}

	void LoadStats(SValue@ charFile)
	{
		auto statsData = charFile;
		m_record.classStats.base_health = GetParamFloat(m_unit, statsData, "base-health", false, 100);
		m_record.classStats.level_health = GetParamFloat(m_unit, statsData, "level-health", false, 0);
		m_record.classStats.base_health_regen = GetParamFloat(m_unit, statsData, "base-health-regen", false, 0);
		m_record.classStats.level_health_regen = GetParamFloat(m_unit, statsData, "level-health-regen", false, 0.05);
		
		m_record.classStats.base_mana = GetParamFloat(m_unit, statsData, "base-mana", false, 100);
		m_record.classStats.level_mana = GetParamFloat(m_unit, statsData, "level-mana", false, 0);
		m_record.classStats.base_mana_regen = GetParamFloat(m_unit, statsData, "base-mana-regen", false, 0.3);
		m_record.classStats.level_mana_regen = GetParamFloat(m_unit, statsData, "level-mana-regen", false, 0.15);
		
		m_record.classStats.base_armor = GetParamFloat(m_unit, statsData, "base-armor", false, 0);
		m_record.classStats.level_armor = GetParamFloat(m_unit, statsData, "level-armor", false, 0);
		m_record.classStats.base_resistance = GetParamFloat(m_unit, statsData, "base-resistance", false, 0);
		m_record.classStats.level_resistance = GetParamFloat(m_unit, statsData, "level-resistance", false, 0);
	}

	void AddItem(ActorItem@ item)
	{
		int numActiveBonusesBefore = 0;
		if (item.set !is null)
			numActiveBonusesBefore = item.set.tmpGetActiveBonuses();

		m_record.items.insertLast(item.id);
		RefreshModifiers();

		if (item.set !is null)
		{
			int numActiveBonusesAfter = item.set.tmpGetActiveBonuses();
			if (numActiveBonusesAfter > numActiveBonusesBefore && numActiveBonusesAfter == int(item.set.bonuses.length()))
			{
				print("New completed set: \"" + Resources::GetString(item.set.name) + "\"");
				Stats::Add("sets-completed", 1, m_record);
			}
		}
	}

	void RefreshSkills()
	{
		m_skills.removeRange(0, m_skills.length());

		auto charData = Resources::GetSValue("players/" + m_record.charClass + "/char.sval");
		LoadSkills(charData);
	}

	void RefreshModifiers()
	{
		m_record.RefreshModifiers();
	}

	void LoadSkills(SValue@ charFile)
	{
		array<SValue@>@ skillsArr = GetParamArray(m_unit, charFile, "skills", true);
		for (uint i = 0; i < skillsArr.length(); i++)
			m_skills.insertLast(LoadSkill(skillsArr[i].GetString(), i));
	}

	Skills::Skill@ LoadSkill(string path, int skillId)
	{
		auto skillData = Resources::GetSValue(path);
		auto iconArray = GetParamArray(m_unit, skillData, "icon", false);

		string skillName = GetParamString(m_unit, skillData, "name", false);
		
		Skills::Skill@ skill;
		int skillLevel = m_record.levelSkills[skillId];

		auto skillsArr = GetParamArray(m_unit, skillData, "skills", true);
		@skillData = skillsArr[min(skillsArr.length() - 1, skillLevel)];
		
		if (skillData is null || skillData.GetType() == SValueType::Null || skillData.GetType() == SValueType::Integer)
			@skill = Skills::NullSkill(m_unit);
		else
		{
			string c = GetParamString(m_unit, skillData, "class");
			@skill = cast<Skills::Skill>(InstantiateClass(c, m_unit, skillData));
		}	

		skill.Initialize(this, ScriptSprite(iconArray), skillId);
		skill.m_name = skillName;
		
		return skill;
	}
	
	int IconHeight() override { return -24; }
	bool IsTargetable() override { return true; }
	
	vec4 GetOverlayColor()
	{
		return m_dmgColor;
	}
	
	
	float m_dirAngle;
	void SetAngle(float angle)
	{
		m_effectParams.Set("angle", angle);
		m_dirAngle = angle;
		
		if (m_footsteps !is null)
			m_footsteps.m_facingDirection = angle;
		if (m_footstepsDash !is null)
			m_footstepsDash.m_facingDirection = angle;
	}
	
	void Initialize(PlayerRecord@ record)
	{
		@m_record = record;
		
		auto charData = Resources::GetSValue("players/" + m_record.charClass + "/char.sval");
		LoadSkills(charData);
		LoadStats(charData);

		m_record.RefreshPerkData();

		auto color = ParseColorRGBA("#" + GetPlayerColor(m_record.peer) + "ff");
		
		m_effectParams.Set("color_r", color.r);
		m_effectParams.Set("color_g", color.g);
		m_effectParams.Set("color_b", color.b);
		
		InitSkin(record.GetSkin());
		if (m_body is null)
			InitSkin("serious_sam");

		RefreshModifiers();
	}
	
	void Refresh()
	{
		Initialize(m_record);
	}
	
	void SetColor(int c, array<vec4> color)
	{
		m_unit.SetMultiColor(c, color[0], color[1], color[2]);
	}
	
	void InitSkin(string skin)
	{
		@m_body = Resources::GetUnitProducer("players/" + m_record.charClass + ".unit");
		@m_aimLaser = Resources::GetEffect("actors/players/aim_laser.effect");

		auto classColors = CharacterColors::GetClass(m_record.charClass);

		SetColor(0, classColors.m_skin[m_record.skinColor % classColors.m_skin.length()]);
		SetColor(1, classColors.m_1[m_record.color1 % classColors.m_1.length()]);
		SetColor(2, classColors.m_2[m_record.color2 % classColors.m_2.length()]);
		SetColor(3, classColors.m_3[m_record.color3 % classColors.m_3.length()]);

		@m_gore = LoadGore("actors/players/skins/" + skin + "/gore.sval");
	}
	
	bool ApplyBuff(ActorBuff@ buff) override
	{ 
		if (m_unit.IsDestroyed())
			return false;
	
		if (IsHusk() && !buff.m_husk)
			return false;

		m_buffs.Add(buff);
		return true;
	}
	
	int SetUnitScene(AnimString@ anim, bool resetScene)  override
	{
		auto sceneName = anim.GetSceneName(m_dirAngle);
		SetBodyAnim(sceneName, resetScene);
		return m_body.GetUnitScene(sceneName).Length();
	}
	
	void SetCharging(bool charging)
	{
		m_charging = charging;
		RefreshScene();
	}

	int RefreshScene()
	{
		if (IsDead())
			return 0; //TODO: Corpse scene?

		int time = 0;

		m_unitScene.Clear();
		m_unitScene.AddScene(m_unit.GetUnitScene((m_charging ? "shared-charge" : "shared")), m_bodySceneTimeOffset, vec2(), 0, 0);
		m_unitScene.AddScene(m_body.GetUnitScene(m_bodySceneName), m_bodySceneTimeOffset, vec2(), 0, 0);

		for (uint i = 0; i < m_skills.length(); i++)
			m_skills[i].RefreshScene(m_unitScene);

		if (m_record.local)
		{
			if (GetVarBool("g_local_player_marker"))
				m_unitScene.AddScene(m_markerFx, 0, vec2(), 0, 0);

			int laserSight = GetVarInt("g_laser_sight");
			if ((laserSight == -1 && GetInput().UsingGamepad) || laserSight == 1)
				m_unitScene.AddScene(m_aimLaser, 0, vec2(), 0, 0);
		}
		else
		{
			if (GetVarBool("g_player_markers"))
				m_unitScene.AddScene(m_markerFx, 0, vec2(), 0, 0);
		}

		if (m_damageKillMul > 1)
			m_unitScene.AddScene(m_frenzyFx, 0, vec2(), 0, 0);

		if (m_rampageSpeedMulC > 0)
			m_unitScene.AddScene(m_rampageFx, 0, vec2(), 0, 0);

		if (m_damageHpEffect)
			m_unitScene.AddScene(m_damageHpFx, 0, vec2(), 0, 0);

		BaseGameMode@ gm = cast<BaseGameMode>(g_gameMode);
		if (gm !is null)
			gm.RefreshPlayerScene(this, m_unitScene);

		m_unit.SetUnitScene(m_unitScene, false);
		return time;
	}

	void SetBodyAnim(string scene, bool resetTime)
	{
		m_bodySceneName = scene;

		if (resetTime)
			m_bodySceneTimeOffset = -m_unit.GetUnitSceneTime();

		RefreshScene();
	}

	void Destroyed()
	{
		for (uint i = 0; i < m_skills.length(); i++)
			m_skills[i].OnDestroy();
	
		m_buffs.Clear();
		@m_record.actor = null;
	}
	
	float GetHealth() override
	{
		return m_record.hp;
	}
	
	void OnDeath(DamageInfo di, vec2 dir)
	{
		if (m_record.IsDead())
			return;
			
		m_buffs.Clear();

		m_record.deadTime = g_scene.GetTime();
		PlaySound3D(m_deathSound, m_unit.GetPosition());

		if (m_gore !is null)
			m_gore.OnDeath(1.0f, xy(m_unit.GetPosition()), atan(dir.y, dir.x));

		auto corpse = Resources::GetUnitProducer("players/player_corpse.unit").Produce(g_scene, xyz(xy(m_unit.GetPosition()), 0));
		@m_record.corpse = cast<PlayerCorpse>(corpse.GetScriptBehavior());
		m_record.corpse.Initialize(m_record);
		
		m_unit.Destroy();
		m_unit = UnitPtr();
	}
	
	SValue@ Save()
	{
		return null;
	}

	void Update(int dt)
	{
		m_buffs.Update(dt);

		m_effectParams.Set("frenzy", m_damageKillMul);
	
		if (m_dmgColor.a > 0)
			m_dmgColor.a -= dt / 100.0;

		if (m_rampageSpeedMulC > 0)
			m_rampageSpeedMulC -= dt;
	}
	
	void UpdateFootsteps(int dt, bool dashing, bool force = false)
	{
		if (!dashing)
		{
			if (m_footsteps !is null)
				m_footsteps.Update(dt, force);
		}
		else
		{
			if (m_footstepsDash !is null)
				m_footstepsDash.Update(dt, force);
		}
	}

	void NetHeal(int amt) override
	{
		AddFloatingText(FloatingTextType::PlayerHealed, "" + amt, m_unit.GetPosition());
		m_dmgColor = vec4(0, 1, 0, 1);
		m_record.hp += float(amt) / float(m_record.MaxHealth());
	}
}