// Based on Nimble.Drawing.ColorHSV
class ColorHSV
{
	float m_hue; // degrees, 0 - 360
	float m_saturation; // percentage, 0 - 100
	float m_value; // precentage 0 - 100

	ColorHSV() {}

	ColorHSV(float h, float s, float l)
	{
		m_hue = h;
		m_saturation = s;
		m_value = l;
	}

	ColorHSV(vec4 rgba)
	{
		FromRGB(rgba.x, rgba.y, rgba.z);
	}

	ColorHSV(vec3 rgb)
	{
		FromRGB(rgb.x, rgb.y, rgb.z);
	}

	void FromRGB(float r, float g, float b)
	{
		float minn = min(min(r, g), b);
		float maxx = max(max(r, g), b);
		float delta = maxx - minn;
		if (maxx != 0 && delta != 0)
		{
			m_saturation = (delta / maxx) * 100.0f;
			if (r == maxx)
				m_hue = (g - b) / delta;
			else
				m_hue = (g == maxx) ? (2 + (b - r) / delta) : (4 + (r - g) / delta);
		}
		m_hue *= 60;
		if (m_hue < 0)
			m_hue += 360;
		m_value = maxx * 100.0f;
	}

	vec3 ToColorRGB()
	{
		float r = 0, g = 0, b = 0;
		float h = m_hue % 360.0f;
		float s = m_saturation / 100.0f;
		float v = m_value / 100.0f;
		if (s == 0)
			r = g = b = v;
		else
		{
			float sPos = h / 60.0f;
			int sNum = int(floor(sPos));
			float fractional = sPos - float(sNum);
			float p = v * (1.0f - s);
			float q = v * (1.0f - s * fractional);
			float t = v * (1.0f - s * (1.0f - fractional));
			switch (sNum)
			{
				case 0: r = v; g = t; b = p; break;
				case 1: r = q; g = v; b = p; break;
				case 2: r = p; g = v; b = t; break;
				case 3: r = p; g = q; b = v; break;
				case 4: r = t; g = p; b = v; break;
				case 5: r = v; g = p; b = q; break;
			}
		}
		return vec3(r, g, b);
	}

	vec4 ToColorRGBA()
	{
		vec3 ret = ToColorRGB();
		return vec4(ret.x, ret.y, ret.z, 1.0f);
	}
}
