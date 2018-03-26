namespace Modifiers
{
	class TriggerEffect : Modifier
	{
		bool m_enabled;
		float m_chance;
		array<IEffect@>@ m_effects;
		bool m_targetSelf;
		string m_fx;
		string m_selfFx;
		EffectTrigger m_trigger;
		uint m_timeout;
		uint64 m_timeoutLastFired;
		uint m_itemId;
	    uint m_modId;
		
		TriggerEffect(UnitPtr unit, SValue& params)
		{
			m_chance = GetParamFloat(unit, params, "chance", false, 10);
			@m_effects = LoadEffects(unit, params);
			m_targetSelf = GetParamBool(unit, params, "target-self", false, false);
			m_trigger = ParseEffectTrigger(GetParamString(unit, params, "trigger", true));
			m_fx = GetParamString(unit, params, "fx", false);
			m_selfFx = GetParamString(unit, params, "self-fx", false);
			m_timeout = GetParamInt(unit, params, "timeout", false);
			m_enabled = true;
		}
		
		void Initialize(uint itemId, uint modId) override
		{
			m_itemId = itemId;
			m_modId = modId;
		}
		
		void NetTrigger(PlayerBase@ player, UnitPtr target)
		{	
			if (!target.IsValid())
				return;
				
			if (player is null)
				return;

			vec2 targetPos = xy(target.GetPosition());
			vec2 dir = (target != player.m_unit) ? normalize(xy(target.GetPosition() - player.m_unit.GetPosition())) : vec2(cos(player.m_dirAngle), sin(player.m_dirAngle));
			
			ApplyEffects(m_effects, player, target, targetPos, dir, 1.0, true);
			
			if (m_selfFx != "")
			{
				dictionary ePs = { { 'angle', atan(dir.y, dir.x) } };
				PlayEffect(m_selfFx, xy(player.m_unit.GetPosition()), ePs);
			}
			if (m_fx != "")
			{		
				dictionary ePs = { { 'angle', atan(dir.y, dir.x) } };
				PlayEffect(m_fx, targetPos, ePs);
			}
		}
		
		void Trigger(PlayerBase@ player, UnitPtr target)
		{
			if (!m_enabled)
				return;
			
			if (!target.IsValid())
				return;

			vec2 targetPos = xy(target.GetPosition());
			vec2 dir = (target != player.m_unit) ? normalize(xy(target.GetPosition() - player.m_unit.GetPosition())) : vec2(cos(player.m_dirAngle), sin(player.m_dirAngle));
			
			ApplyEffects(m_effects, player, target, targetPos, dir, 1.0, false);
			
			if (m_selfFx != "")
			{
				dictionary ePs = { { 'angle', atan(dir.y, dir.x) } };
				PlayEffect(m_selfFx, xy(player.m_unit.GetPosition()), ePs);
			}
			if (m_fx != "")
			{		
				dictionary ePs = { { 'angle', atan(dir.y, dir.x) } };
				PlayEffect(m_fx, targetPos, ePs);
			}
			
			if (m_itemId != 0)
				(Network::Message("ModifierTriggerEffect") << m_itemId << m_modId << target).SendToAll();
		}
		
		void TriggerEffects(PlayerBase@ player, Actor@ enemy, EffectTrigger trigger) override
		{ 
			if (m_trigger != trigger)
				return;
		
			if (randf() > m_chance)
				return;

			if (m_timeout > 0)
			{
				uint64 tmNow = g_gameMode.m_gameTime;
				if (m_timeoutLastFired > 0 && tmNow - m_timeoutLastFired < m_timeout)
					return;
				
				m_timeoutLastFired = tmNow;
			}

			UnitPtr target;
			if (m_targetSelf)
				target = player.m_unit;
			else if (enemy !is null)
			{
				target = enemy.m_unit;
				if (!enemy.IsTargetable())
					return;
			}
			
			Trigger(player, target);
		}
	}
}