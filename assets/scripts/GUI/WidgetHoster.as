class WidgetMouseEvt
{
	Widget@ m_widget;
	vec2 m_pos;
	bool m_force;

	WidgetMouseEvt(Widget@ w, vec2 p, bool f = false)
	{
		@m_widget = w;
		m_pos = p;
		m_force = f;
	}
}

class IWidgetHoster
{
	Widget@ m_widget;

	string m_filenameDef;

	bool m_firstUpdate;
	vec3 m_lastMousePos;
	bool m_mouseUsed;
	bool m_forceFocus;
	bool m_forcingFocus;

	int m_idt;

	bool m_hasLayout;

	array<WidgetMouseEvt@> m_queueMouseEnter;
	array<WidgetMouseEvt@> m_queueMouseLeave;

	bool BlocksLower()
	{
		return false;
	}

	GUIDef@ LoadWidget(GUIBuilder@ b, string filename)
	{
		m_filenameDef = filename;
		GUIDef@ def = Resources::GetGUIDef(filename);
		if (def is null)
		{
			PrintError("GUI Definition is null for: '" + filename + "'");
			return null;
		}
		@m_widget = cast<Widget>(b.BuildGUI(def, this));
		return def;
	}

	GUIDef@ AddGuiResource(GUIBuilder@ b, string filename)
	{
		return m_widget.AddResource(b, filename);
	}

	void DoLayout()
	{
%PROFILE_START DoLayout
		m_widget.DoLayout(vec2(), vec2(g_gameMode.m_wndWidth, g_gameMode.m_wndHeight));
		m_hasLayout = true;
%PROFILE_STOP
	}

	void Update(int dt)
	{
%PROFILE_START Widget Update
		m_widget.Update(dt);
%PROFILE_STOP

		DoLayout();

%PROFILE_START MouseStuff
		// First run all mouse leave events
		while (m_queueMouseLeave.length() > 0)
		{
			auto evt = m_queueMouseLeave[0];
			m_queueMouseLeave.removeAt(0);
			evt.m_widget.OnMouseLeave(evt.m_pos);
		}

		// ..and then all mouse enter events, to have a proper order
		while (m_queueMouseEnter.length() > 0)
		{
			auto evt = m_queueMouseEnter[0];
			m_queueMouseEnter.removeAt(0);
			evt.m_widget.OnMouseEnter(evt.m_pos, evt.m_force);
		}
%PROFILE_STOP
	}

	void Draw(SpriteBatch& sb, int idt)
	{
		if (!m_hasLayout)
			DoLayout();

		m_idt = idt;
		m_widget.Draw(sb);
	}

	void UpdateInput(vec2 origin, vec2 parentSz, vec3 mousePos)
	{
		if (!m_firstUpdate)
		{
			m_lastMousePos = mousePos;
			m_firstUpdate = true;
		}

		m_forcingFocus = false;
		m_mouseUsed = m_forceFocus || distsq(mousePos, m_lastMousePos) > 0;
		m_lastMousePos = mousePos;

		if (m_forceFocus)
		{
			m_forcingFocus = true;
			m_forceFocus = false;
		}

		m_widget.UpdateInput(origin, parentSz, mousePos);
	}

	void OnFunc(Widget@ sender, string name) { }
}
