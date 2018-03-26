namespace Modifiers
{
	class Combo : FilterModifier
	{
		array<IEffect@>@ m_effects;
		
		Combo(UnitPtr unit, SValue& params)
		{
			super(unit, params);
			
			@m_effects = LoadEffects(unit, params);
		}	

		bool Filter(PlayerBase@ player, Actor@ enemy) override { return player.m_comboActive; }
		array<IEffect@>@ ComboEffects(PlayerBase@ player) override { return m_effects; }
	}
}