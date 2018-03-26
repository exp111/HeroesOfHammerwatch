class PlayerCorpse : IUsable
{
	UnitPtr m_unit;
	PlayerRecord@ m_record;
	CustomUnitScene@ m_unitScene;
	EffectParams@ m_effectParams;

	PlayerCorpse(UnitPtr unit, SValue& params)
	{
		m_unit = unit;
		@m_unitScene = CustomUnitScene();
		@m_effectParams = m_unit.CreateEffectParams();
	}

	void Initialize(PlayerRecord@ record)
	{
		@m_record = record;
		
		m_unitScene.Clear();
		m_unitScene.AddScene(m_unit.GetCurrentUnitScene(), 0, vec2(), 0, 0);
		auto body = Resources::GetUnitProducer("players/" + m_record.charClass + ".unit");
		m_unitScene.AddScene(body.GetUnitScene("death"), 0, vec2(), 0, 0);
		m_unit.SetUnitScene(m_unitScene, true);

		auto classColors = CharacterColors::GetClass(m_record.charClass);
		SetColor(0, classColors.m_skin[m_record.skinColor % classColors.m_skin.length()]);
		SetColor(1, classColors.m_1[m_record.color1 % classColors.m_1.length()]);
		SetColor(2, classColors.m_2[m_record.color2 % classColors.m_2.length()]);
		SetColor(3, classColors.m_3[m_record.color3 % classColors.m_3.length()]);
		
		auto color = ParseColorRGBA("#" + GetPlayerColor(m_record.peer) + "ff");
		m_effectParams.Set("color_r", color.r);
		m_effectParams.Set("color_g", color.g);
		m_effectParams.Set("color_b", color.b);
	}
	
	void SetColor(int c, array<vec4> color)
	{
		m_unit.SetMultiColor(c, color[0], color[1], color[2]);
	}

	void NetUse(PlayerHusk@ player) { }
	UnitPtr GetUseUnit() { return m_unit; }
	bool CanUse(PlayerBase@ player) { return true; }
	UsableIcon GetIcon(Player@ player) { return UsableIcon::Revive; }

	void Use(PlayerBase@ player) 
	{
		(Network::Message("ReviveCorpse") << m_record.peer).SendToAll();
		NetRevive(GetLocalPlayerRecord());
	}
	
	void NetRevive(PlayerRecord@ reviver)
	{
		auto gm = cast<BaseGameMode>(g_gameMode);
		if (m_record.local)
			gm.StopSpectating();

		// Reviver is ourselves when using revive cheat
		if (reviver !is m_record)
		{
			int soulLinkOrigin = reviver.soulLinkedBy;
			if (soulLinkOrigin == -1)
				soulLinkOrigin = reviver.peer;

			m_record.soulLinks.insertLast(reviver.peer);
			m_record.soulLinkedBy = soulLinkOrigin;

			reviver.soulLinks.insertLast(m_record.peer);
			reviver.soulLinkedBy = soulLinkOrigin;
			reviver.hp *= 0.5;
		}

		SValueBuilder builder;
		builder.PushString(Resources::GetString(".menu.lobby.chat.revive", { 
			{ "reviver", "\\c" + GetPlayerColor(reviver.peer) + gm.GetPlayerDisplayName(reviver) + "\\d" },
			{ "revivee", "\\c" + GetPlayerColor(m_record.peer) + gm.GetPlayerDisplayName(m_record) + "\\d" }
		}));
		
		SendSystemMessage("AddChat", builder.Build());

		vec3 pos = m_unit.GetPosition();

		AddFloatingText(FloatingTextType::Pickup, Resources::GetString(".misc.soulslinked"), pos);
		PlayEffect("effects/players/revive.effect", xy(pos));

		m_record.hp = 0.5;
		m_record.mana = 0.5;
	
		if (Network::IsServer())
		{
			for (uint i = 0; i < g_players.length(); i++)
			{
				if (m_record !is g_players[i])
					continue;

				g_gameMode.SpawnPlayer(i, xy(pos));
			}
		}
		
		m_unit.Destroy();
	}
	
	void Destroyed()
	{
		if (m_record.corpse is this)
			@m_record.corpse = null;
	}
	
	void Collide(UnitPtr unit, vec2 pos, vec2 normal, Fixture@ fxSelf, Fixture@ fxOther)
	{
		auto player = cast<Player>(unit.GetScriptBehavior());
		if (player is null)
			return;

		player.AddUsable(this);
	}

	void EndCollision(UnitPtr unit, Fixture@ fxSelf, Fixture@ fxOther)
	{
		auto player = cast<Player>(unit.GetScriptBehavior());
		if (player is null)
			return;

		player.RemoveUsable(this);
	}
}