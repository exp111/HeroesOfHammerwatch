class NotificationManager : IWidgetHoster
{
	Widget@ m_wList;
	Widget@ m_wTemplate;
	Widget@ m_wTemplateSubtext;

	array<Notification@> m_notifications;

	NotificationManager(GUIBuilder@ builder)
	{
		LoadWidget(builder, "gui/notifications.gui");

		@m_wList = m_widget.GetWidgetById("notifications");
		@m_wTemplate = m_widget.GetWidgetById("template");
		@m_wTemplateSubtext = m_widget.GetWidgetById("template-subtext");
	}

	void Update(int dt) override
	{
		for (uint i = 0; i < m_notifications.length(); i++)
		{
			auto notification = m_notifications[i];
			notification.Update(dt);
			if (notification.m_timeC <= 0)
				i--;
		}

		IWidgetHoster::Update(dt);
	}

	void Draw(SpriteBatch& sb, int idt) override
	{
		for (uint i = 0; i < m_notifications.length(); i++)
			m_notifications[i].PreDraw(idt);

		IWidgetHoster::Draw(sb, idt);
	}

	void UpdateTargets()
	{
		int currentY = 32;
		int spacing = 4;
		for (uint i = 0; i < m_notifications.length(); i++)
		{
			m_notifications[i].m_targetY = currentY;
			currentY += m_notifications[i].m_widget.m_height + spacing;
		}
	}

	Notification@ Add(string text, vec4 colorFrom = vec4(1, 0, 0, 1), vec4 colorTo = vec4(1, 1, 1, 1))
	{
		auto wNewNotification = m_wTemplate.Clone();
		wNewNotification.m_visible = true;
		wNewNotification.SetID("");

		Notification@ notif = Notification(this, wNewNotification, text);
		notif.m_startColor = colorFrom;
		notif.m_endColor = colorTo;
		@notif.m_wTemplateSubtext = m_wTemplateSubtext;
		m_notifications.insertAt(0, notif);

		UpdateTargets();

		m_wList.AddChild(wNewNotification);

		return notif;
	}

	void Remove(Notification@ notification)
	{
		int index = m_notifications.findByRef(notification);
		if (index == -1)
		{
			PrintError("Couldn't find index for notification to remove!");
			return;
		}
		m_notifications.removeAt(index);
		notification.m_widget.RemoveFromParent();
	}
}
