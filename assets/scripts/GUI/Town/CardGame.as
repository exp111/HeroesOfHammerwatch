class CardGame : ScriptWidgetHost
{
	TextWidget@ m_wStatus;

	TextWidget@ m_wStatusBattle;
	Widget@ m_wSubStatus;
	TextWidget@ m_wGoldFrom;
	TextWidget@ m_wGoldTo;

	ScalableSpriteButtonWidget@ m_wFlipButton;

	CheckBoxGroupWidget@ m_wLimits;

	TextWidget@ m_wDiff;

	SoundEvent@ m_sndLose;
	SoundEvent@ m_sndWin;
	SoundEvent@ m_sndFlip;

	int m_goldLimit = 100;

	ivec2 m_cardPlayer;
	ivec2 m_cardHouse;

	bool m_waitWin;
	int m_waitTime;

	bool m_cardsPlaced;
	int m_animateOutWaitTime;

	CardGame(SValue& sval)
	{
		super();
	}

	void Initialize() override
	{
		@m_wStatus = cast<TextWidget>(m_widget.GetWidgetById("status"));

		@m_wStatusBattle = cast<TextWidget>(m_widget.GetWidgetById("status-battle"));
		@m_wSubStatus = m_widget.GetWidgetById("substatus");
		@m_wGoldFrom = cast<TextWidget>(m_widget.GetWidgetById("your-x"));
		@m_wGoldTo = cast<TextWidget>(m_widget.GetWidgetById("became-y"));

		@m_wFlipButton = cast<ScalableSpriteButtonWidget>(m_widget.GetWidgetById("flip"));

		@m_wLimits = cast<CheckBoxGroupWidget>(m_widget.GetWidgetById("limits"));

		@m_wDiff = cast<TextWidget>(m_widget.GetWidgetById("diff"));

		@m_sndLose = Resources::GetSoundEvent("event:/ui/game-lose");
		@m_sndWin = Resources::GetSoundEvent("event:/ui/game-win");
		@m_sndFlip = Resources::GetSoundEvent("event:/ui/game-cardflip");

		auto wPortrait = cast<SpriteWidget>(m_widget.GetWidgetById("portrait"));
		if (wPortrait !is null)
		{
			auto record = GetLocalPlayerRecord();
			wPortrait.SetSprite(GetFaceSprite(record.charClass, record.face));
		}

		SetLimitButtons();
	}

	string GetCardName(ivec2 card)
	{
		if (card.y == 10)
			return Resources::GetString(".gambling.card.wildcard");
		else
			return Resources::GetString(".gambling.card." + (card.x + 1) + "." + (card.y + 1));
	}

	void DisableLimitButtons()
	{
		for (uint i = 0; i < m_wLimits.m_children.length(); i++)
		{
			auto w = cast<ScalableSpriteButtonWidget>(m_wLimits.m_children[i]);
			w.m_enabled = false;
		}
	}

	void SetLimitButtons()
	{
		auto gm = cast<Campaign>(g_gameMode);

		int leastValue = 0;

		for (uint i = 0; i < m_wLimits.m_children.length(); i++)
		{
			auto w = cast<ScalableSpriteButtonWidget>(m_wLimits.m_children[i]);
			int value = parseInt(w.m_value);
			w.m_enabled = (gm.m_townLocal.m_gold >= value);
			if (w.m_enabled)
				leastValue = value;
		}

		if (leastValue == 0)
			g_gameMode.ShowDialog("close", Resources::GetString(".town.cardgame.outofmoney." + (randi(5) + 1)), Resources::GetString(".menu.ok"), this);
		else
		{
			m_goldLimit = min(m_goldLimit, leastValue);
			m_wLimits.SetChecked("" + m_goldLimit);
		}
	}

	void AnimateCardsOut()
	{
		HideStatus();

		m_wDiff.m_visible = false;

		UnsetCard("card-house");
		UnsetCard("card-player");

		m_cardsPlaced = false;
		m_animateOutWaitTime = 750;
	}

	void HideStatus()
	{
		m_wStatus.m_visible = false;
		m_wStatusBattle.m_visible = false;
		m_wSubStatus.m_visible = false;
	}

	void SetStatus(bool win)
	{
		if (win)
		{
			m_wStatus.SetText(Resources::GetString(".town.cardgame.header.win"));
			m_wStatus.SetColor(tocolor(vec4(0, 1, 0, 1)));
		}
		else
		{
			m_wStatus.SetText(Resources::GetString(".town.cardgame.header.lose"));
			m_wStatus.SetColor(tocolor(vec4(1, 0, 0, 1)));
		}
		m_wStatus.m_visible = true;
	}

	void SetBattleStatus(ivec2 cardPlayer, ivec2 cardHouse)
	{
		string namePlayer = GetCardName(cardPlayer);
		string nameHouse = GetCardName(cardHouse);

		m_wStatusBattle.SetText(Resources::GetString(".town.cardgame.battlestatus", { { "player", namePlayer }, { "house", nameHouse } }));
		m_wStatusBattle.m_visible = true;
	}

	void SetGoldStatus(int fromGold, int toGold)
	{
		m_wGoldFrom.SetText(Resources::GetString(".town.cardgame.goldfrom", { { "num", fromGold } }));
		m_wGoldTo.SetText(Resources::GetString(".town.cardgame.goldto", { { "num", toGold } }));

		m_wSubStatus.m_visible = true;
	}

	vec4 GetCardFrame(ivec2 card)
	{
		vec4 ret;

		ret.z = 45;
		ret.w = 68;
		ret.x = card.y * ret.z;
		ret.y = card.x * ret.w;

		return ret;
	}

	ivec2 PullRandomCard()
	{
		RandomContext randomContext = RandomContext::CardGame100;
		switch (m_goldLimit) {
			case 100: randomContext = RandomContext::CardGame100; break;
			case 500: randomContext = RandomContext::CardGame500; break;
			case 1000: randomContext = RandomContext::CardGame1000; break;
			case 5000: randomContext = RandomContext::CardGame5000; break;
			case 10000: randomContext = RandomContext::CardGame10000; break;
			case 100000: randomContext = RandomContext::CardGame100000; break;
		}

		int cardRow = RandomBank::Int(randomContext, 4);
		int cardNum = RandomBank::Int(randomContext, 11);
		return ivec2(cardRow, cardNum);
	}

	bool IsValidCardCombination(ivec2 house, ivec2 player)
	{
		// Don't pull the same card
		if (house.x == player.x && house.y == player.y)
			return false;

		// Only pull 1 joker card
		if (house.y == 10 && player.y == 10)
			return false;

		return true;
	}

	void UnsetCard(string id)
	{
		auto wPlacedCard = m_widget.GetWidgetById(id);
		wPlacedCard.m_visible = false;

		auto wDeck = m_widget.GetWidgetById(id + "-deck");

		auto wCardAnimator = m_widget.GetWidgetById(id + "-animator-behind");
		wCardAnimator.m_visible = true;

		vec2 startPos = wPlacedCard.m_offset;
		vec2 endPos = wDeck.m_offset;
		endPos.y = startPos.y;

		wCardAnimator.Animate(WidgetVec2Animation("offset", startPos, endPos, 500));

		wCardAnimator.Animate(WidgetBoolAnimation("visible", false, 500));
	}

	void SetCard(string id, ivec2 card)
	{
		auto wCard = cast<SpriteWidget>(m_widget.GetWidgetById(id));
		if (wCard is null)
		{
			PrintError("Invalid widget ID: " + id);
			return;
		}

		if (card.y == 10)
			wCard.SetSprite("card-joker");
		else
		{
			auto texture = Resources::GetTexture2D("gui/cards.png");
			auto frame = GetCardFrame(card);
			wCard.SetSprite(ScriptSprite(texture, frame));
		}

		int animTime = m_waitTime - 100;
		int animDelay = 0;
		if (id != "card-player")
			animDelay = 100;

		wCard.Animate(WidgetBoolAnimation("visible", true, animTime + animDelay));

		auto wDeck = m_widget.GetWidgetById(id + "-deck");

		auto wCardAnimator = m_widget.GetWidgetById(id + "-animator");
		auto wCardAnimatorShadow = m_widget.GetWidgetById(id + "-animator-shadow");

		if (animDelay > 0)
		{
			wCardAnimator.Animate(WidgetBoolAnimation("visible", true, animDelay));
			wCardAnimatorShadow.Animate(WidgetBoolAnimation("visible", true, animDelay));
		}
		else
		{
			wCardAnimator.m_visible = true;
			wCardAnimatorShadow.m_visible = true;
		}

		vec2 startPos = wDeck.m_offset;
		vec2 endPos = wCard.m_offset;
		vec2 bezierPos = lerp(startPos, endPos, 0.5f) + vec2(0, -50);

		wCardAnimator.Animate(WidgetVec2BezierAnimation("offset", startPos, bezierPos, endPos, animTime, animDelay));
		wCardAnimator.Animate(WidgetBoolAnimation("visible", false, animTime + animDelay));

		vec2 shadowBezierPos = lerp(startPos, endPos, 0.5f) + vec2(20, -55);

		wCardAnimatorShadow.Animate(WidgetVec2BezierAnimation("offset", startPos, shadowBezierPos, endPos, animTime, animDelay));
		wCardAnimatorShadow.Animate(WidgetBoolAnimation("visible", false, animTime + animDelay));
	}

	void LoseCash()
	{
		auto gm = cast<Campaign>(g_gameMode);
		gm.m_townLocal.m_gold -= m_goldLimit;

		Stats::Add("gambling-gold-lost", m_goldLimit, GetLocalPlayerRecord());
	}

	void WinCash()
	{
		auto gm = cast<Campaign>(g_gameMode);
		gm.m_townLocal.m_gold += m_goldLimit;

		Stats::Add("gambling-gold-won", m_goldLimit, GetLocalPlayerRecord());
	}

	void Play()
	{
		m_wFlipButton.m_enabled = false;
		HideStatus();
		DisableLimitButtons();

		if (m_cardsPlaced)
		{
			AnimateCardsOut();
			return;
		}

		PlaySound2D(m_sndFlip);

		m_cardsPlaced = true;

		do
		{
			m_cardHouse = PullRandomCard();
			m_cardPlayer = PullRandomCard();
		} while (!IsValidCardCombination(m_cardHouse, m_cardPlayer));

		m_waitWin = (m_cardPlayer.y > m_cardHouse.y);
		m_waitTime = 750;

		SetCard("card-house", m_cardHouse);
		SetCard("card-player", m_cardPlayer);

		if (m_cardHouse.y == 10 || m_cardPlayer.y == 10)
			m_wDiff.SetText("*");
		else
		{
			int diff = m_cardPlayer.y - m_cardHouse.y;
			if (diff == 0)
				m_wDiff.SetText("-");
			else if (diff > 0)
				m_wDiff.SetText("+" + diff);
			else
				m_wDiff.SetText("" + diff);
		}

		if (m_waitWin)
			m_wDiff.SetColor(tocolor(vec4(0, 1, 0, 1)));
		else
			m_wDiff.SetColor(tocolor(vec4(1, 0, 0, 1)));

		m_wDiff.m_visible = false;
		m_wDiff.Animate(WidgetBoolAnimation("visible", true, m_waitTime));
	}

	bool ShouldFreezeControls() override { return true; }
	bool ShouldDisplayCursor() override { return true; }

	void Update(int dt) override
	{
		if (m_waitTime > 0)
		{
			m_waitTime -= dt;
			if (m_waitTime <= 0)
			{
				SetStatus(m_waitWin);
				SetBattleStatus(m_cardPlayer, m_cardHouse);

				if (m_waitWin)
				{
					PlaySound2D(m_sndWin);
					SetGoldStatus(m_goldLimit, m_goldLimit * 2);
					WinCash();
				}
				else
				{
					PlaySound2D(m_sndLose);
					SetGoldStatus(m_goldLimit, 0);
					LoseCash();
				}

				m_wFlipButton.m_enabled = true;

				SetLimitButtons();
			}
		}

		if (m_animateOutWaitTime > 0)
		{
			m_animateOutWaitTime -= dt;
			if (m_animateOutWaitTime <= 0)
				Play();
		}

		ScriptWidgetHost::Update(dt);
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "close")
			Stop();
		else if (name == "set-limit")
		{
			auto group = cast<CheckBoxGroupWidget>(sender);
			int goldLimit = parseInt(group.GetChecked().GetValue());

			auto gm = cast<Campaign>(g_gameMode);
			if (goldLimit > gm.m_townLocal.m_gold)
			{
				PrintError("Not enough gold!");
				return;
			}

			m_goldLimit = goldLimit;
		}
		else if (name == "play")
			Play();
	}
}
