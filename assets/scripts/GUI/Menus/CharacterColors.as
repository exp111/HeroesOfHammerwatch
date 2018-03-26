namespace CharacterColors
{
	array<vec4> ParseColorList(SValue@ arr)
	{
		array<SValue@>@ colors = arr.GetArray();
		array<vec4> ret;
		for (uint i = 0; i < 3; i++)
			ret.insertLast(ParseColorRGBA(colors[i].GetString()));
		return ret;
	}

	class ClassColors
	{
		string m_id;

		array<array<vec4>> m_skin;
		array<array<vec4>> m_1;
		array<array<vec4>> m_2;
		array<array<vec4>> m_3;

		string m_name1;
		string m_name2;
		string m_name3;

		ClassColors(string id, SValue@ sv)
		{
			m_id = id;

			array<SValue@>@ arr = sv.GetArray();

			m_name1 = arr[0].GetDictionaryEntry("name").GetString();
			m_name2 = arr[1].GetDictionaryEntry("name").GetString();
			m_name3 = arr[2].GetDictionaryEntry("name").GetString();

			array<SValue@>@ arrColors = arr[0].GetDictionaryEntry("colors").GetArray();
			for (uint i = 0; i < arrColors.length(); i++)
				m_1.insertLast(ParseColorList(arrColors[i]));

			@arrColors = arr[1].GetDictionaryEntry("colors").GetArray();
			for (uint i = 0; i < arrColors.length(); i++)
				m_2.insertLast(ParseColorList(arrColors[i]));

			@arrColors = arr[2].GetDictionaryEntry("colors").GetArray();
			for (uint i = 0; i < arrColors.length(); i++)
				m_3.insertLast(ParseColorList(arrColors[i]));
		}
	}

	array<ClassColors@> g_classes;

	void LoadColors()
	{
		if (g_classes.length() > 0)
			return;

		auto sval = Resources::GetSValue("tweak/classcolors.sval");
		auto arrSkinColor = sval.GetDictionaryEntry("colors-skin").GetArray();

		dictionary dic = sval.GetDictionary();
		array<string> keys = dic.getKeys();
		string classPrefix = "class-";
		for (uint i = 0; i < keys.length(); i++)
		{
			if (keys[i].substr(0, classPrefix.length()) != classPrefix)
				continue;

			SValue@ svClass = sval.GetDictionaryEntry(keys[i]);
			string classId = keys[i].substr(classPrefix.length());

			auto colorsClass = ClassColors(classId, svClass);
			for (uint j = 0; j < arrSkinColor.length(); j++)
				colorsClass.m_skin.insertLast(ParseColorList(arrSkinColor[j]));
			g_classes.insertLast(colorsClass);
		}
	}

	ClassColors@ GetClass(string id)
	{
		for (uint i = 0; i < g_classes.length(); i++)
		{
			if (g_classes[i].m_id == id)
				return g_classes[i];
		}
		return null;
	}
}
