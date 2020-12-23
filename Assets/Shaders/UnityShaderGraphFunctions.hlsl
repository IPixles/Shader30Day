#ifndef SHADERGRAPH_FUNCTION_INCLUDED
#define SHADERGRAPH_FUNCTION_INCLUDED

//=====================================================
//Unity ShaderGraph Simple Noise
inline float Unity_SimpleNoise_RandomValue_float(float2 uv)
{
	return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
}
inline float Unity_SimpleNnoise_Interpolate_float(float a, float b, float t)
{
	return (1.0 - t) * a + (t * b);
}
inline float Unity_SimpleNoise_ValueNoise_float(float2 uv)
{
	float2 i = floor(uv);
	float2 f = frac(uv);
	f = f * f * (3.0 - 2.0 * f);

	uv = abs(frac(uv) - 0.5);
	float2 c0 = i + float2(0.0, 0.0);
	float2 c1 = i + float2(1.0, 0.0);
	float2 c2 = i + float2(0.0, 1.0);
	float2 c3 = i + float2(1.0, 1.0);
	float r0 = Unity_SimpleNoise_RandomValue_float(c0);
	float r1 = Unity_SimpleNoise_RandomValue_float(c1);
	float r2 = Unity_SimpleNoise_RandomValue_float(c2);
	float r3 = Unity_SimpleNoise_RandomValue_float(c3);

	float bottomOfGrid = Unity_SimpleNnoise_Interpolate_float(r0, r1, f.x);
	float topOfGrid = Unity_SimpleNnoise_Interpolate_float(r2, r3, f.x);
	float t = Unity_SimpleNnoise_Interpolate_float(bottomOfGrid, topOfGrid, f.y);
	return t;
}
void Unity_SimpleNoise_float(float2 UV, float Scale, out float Out)
{
	float t = 0.0;

	float freq = pow(2.0, float(0));
	float amp = pow(0.5, float(3 - 0));
	t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;

	freq = pow(2.0, float(1));
	amp = pow(0.5, float(3 - 1));
	t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;

	freq = pow(2.0, float(2));
	amp = pow(0.5, float(3 - 2));
	t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;

	Out = t;
}
//=====================================================

//=====================================================
//Unity ShaderGraph GradientNoise
float2 Unity_GradientNoise_Dir_float(float2 p)
{
	// Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
	p = p % 289;
	float x = (34 * p.x + 1) * p.x % 289 + p.y;
	x = (34 * x + 1) * x % 289;
	x = frac(x / 41) * 2 - 1;
	return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}
void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
{
	float2 p = UV * Scale;
	float2 ip = floor(p);
	float2 fp = frac(p);
	float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
	float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
	float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
	float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
	fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
	Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
}
//=====================================================

//=====================================================
//Unity ShaderGraph Remap
void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
{
    Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
}
//=====================================================

//=====================================================
//Unity UV  
//RadialShear
void Unity_RadialShear_float(float2 UV, float2 Center, float2 Strength, float2 Offset, out float2 Out)
    {
        float2 delta = UV - Center;
        float delta2 = dot(delta.xy, delta.xy);
        float2 delta_offset = delta2 * Strength;
        Out = UV + float2(delta.y, -delta.x) * delta_offset + Offset;
    }

//Twirl
void Unity_Twirl_float(float2 UV, float2 Center, float Strength, float2 Offset, out float2 Out)
    {
        float2 delta = UV - Center;
        float angle = Strength * length(delta);
        float x = cos(angle) * delta.x - sin(angle) * delta.y;
        float y = sin(angle) * delta.x + cos(angle) * delta.y;
        Out = float2(x + Center.x + Offset.x, y + Center.y + Offset.y);
    }
//=====================================================
#endif //SHADERGRAPH_FUNCTION_INCLUDED