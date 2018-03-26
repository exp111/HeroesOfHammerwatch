enum RandomContext
{
	CardGame100,
	CardGame500,
	CardGame1000,
	CardGame5000,
	CardGame10000,
	CardGame100000,

	Fountain,

	NumContexts,
}

namespace RandomBank
{
	array<RandomSequence> g_randomSequences(int(RandomContext::NumContexts));

	int Int(RandomContext ctx, int max) { return g_randomSequences[int(ctx)].GetInt(max); }
	float Float(RandomContext ctx) { return g_randomSequences[int(ctx)].GetFloat(); }
	uint GetSeed(RandomContext ctx) { return g_randomSequences[int(ctx)].GetSeed(); }
	void SetSeed(RandomContext ctx, uint seed) { g_randomSequences[int(ctx)].SetSeed(seed); }
}
