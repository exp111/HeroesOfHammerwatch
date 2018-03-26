namespace Modifiers
{
	class EnemyTypeFilter : FilterModifier
	{
		string m_enemyType;
		
		EnemyTypeFilter(UnitPtr unit, SValue& params)
		{
			super(unit, params);
			
			m_enemyType = GetParamString(unit, params, "type", true);
		}	

		bool Filter(PlayerBase@ player, Actor@ enemy) override 
		{
			auto eb = cast<CompositeActorBehavior>(enemy);
			return eb !is null && eb.m_enemyType == m_enemyType;
		}
	}
}