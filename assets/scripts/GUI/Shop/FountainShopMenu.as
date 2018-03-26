class FountainShopMenuContent : ShopMenuContent
{
	ScalableSpriteIconButtonWidget@ m_wButton;
	TextWidget@ m_wMessage;

	int m_resetTimeC;

	FountainShopMenuContent(ShopMenu@ shopMenu)
	{
		super(shopMenu);
	}

	string GetTitle() override
	{
		return Resources::GetString(".shop.fountain");
	}

	void OnShow() override
	{
		@m_wButton = cast<ScalableSpriteIconButtonWidget>(m_widget.GetWidgetById("button"));
		@m_wMessage = cast<TextWidget>(m_widget.GetWidgetById("message"));

		if (cast<Town>(g_gameMode) is null)
			m_wButton.m_enabled = false;
		else
		{
			m_wButton.m_enabled = CanAfford();
			UpdateButton();
		}
		UpdateMessage();
	}

	string GetGuiFilename() override
	{
		return "gui/shop/fountain.gui";
	}

	void Update(int dt) override
	{
		if (m_resetTimeC > 0)
		{
			m_resetTimeC -= dt;
			if (m_resetTimeC <= 0)
			{
				m_wButton.m_enabled = true;
				UpdateMessage();
			}
		}

		ShopMenuContent::Update(dt);
	}

	void UpdateButton()
	{
		m_wButton.SetText(utf8string(Resources::GetString(".misc.yes")).toUpper().plain() + " - " + GetCost());
		m_shopMenu.DoLayout();
	}

	void UpdateMessage()
	{
		m_wMessage.SetText(Resources::GetString(".fountain.question"));
		m_shopMenu.DoLayout();
	}

	int GetCost()
	{
		auto gm = cast<Town>(g_gameMode);
		return int(100 * pow(2, gm.m_usedFountain));
	}

	bool CanAfford()
	{
		auto gm = cast<Town>(g_gameMode);
		if (gm is null)
			return false;

		return gm.m_townLocal.m_gold >= GetCost();
	}

	void Buy()
	{
		if (!CanAfford())
			return;

		auto gm = cast<Town>(g_gameMode);
		if (gm is null)
			return;

		Stats::Add("fountain-used", 1);

		int numGood, numBad;
		FountainEffect effect = Fountain::RandomFountainEffects(numGood, numBad, gm.m_fountainEffects);
		
		if (numGood > 0 && numGood > numBad)
			Platform::Service.UnlockAchievement("fountain_good");

		gm.m_townLocal.m_gold -= GetCost();
		gm.m_fountainEffects = FountainEffect(gm.m_fountainEffects | effect);
		gm.m_usedFountain++;

		string message = "";
		     if (numGood == 1 && numBad == 0) message = Resources::GetString(".fountain.good");
		else if (numGood == 0 && numBad == 1) message = Resources::GetString(".fountain.bad");
		else if (numGood == 1 && numBad == 1) message = Resources::GetString(".fountain.something");
		else if (numGood == 2 && numBad == 0) message = Resources::GetString(".fountain.great");
		else if (numGood == 0 && numBad == 2) message = Resources::GetString(".fountain.horrible");
		else message = "??? " + numGood + ", " + numBad;

		print(message);

		m_wMessage.SetText(message);

		m_wButton.m_enabled = false;
		UpdateButton();

		m_resetTimeC = 1000;
	}

	void OnFunc(Widget@ sender, string name) override
	{
		if (name == "close")
			m_shopMenu.Close();
		else if (name == "buy")
			Buy();
	}
}
