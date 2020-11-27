Shader "Hs/Day30Shader/_Demo_1"
{
    Properties
    {
		[HDR]_Color ("Color",COLOR) = (1,1,1,1)
        _MainTex ("Earth Texture", 2D) = "white" {}

		//_NoiseTex ("Noise Texture",2D) = "white"{}
		//_NoiseOffsetX ("Noise Sampler Offset X",RANGE(0,1)) = 0

		_LineCount ("Line Count(X&Y)",VECTOR) = (1,1,0,0)
		_Offset ("Line Offset",FLOAT) = 0
		_LineSize ("Line Length Size",RANGE(0,1)) = 0 
		_LineSpeed ("Line Move Speed",FLOAT) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#pragma vertex vert
            #pragma fragment frag

			struct Attributes
			{
				float4 positionOS : POSITION;
				float4 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				half4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			//=====================================================
			//Unity Shader Graph Simple Noise
			inline float Unity_SimpleNoise_RandomValue_float (float2 uv)
    {
        return frac(sin(dot(uv, float2(12.9898, 78.233)))*43758.5453);
    }
			inline float Unity_SimpleNnoise_Interpolate_float (float a, float b, float t)
    {
        return (1.0-t)*a + (t*b);
    }
			inline float Unity_SimpleNoise_ValueNoise_float (float2 uv)
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
        float amp = pow(0.5, float(3-0));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(1));
        amp = pow(0.5, float(3-1));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        freq = pow(2.0, float(2));
        amp = pow(0.5, float(3-2));
        t += Unity_SimpleNoise_ValueNoise_float(float2(UV.x*Scale/freq, UV.y*Scale/freq))*amp;

        Out = t;
    }
			//=====================================================

			float4 _Color;
			sampler2D _MainTex;
			//sampler2D _NoiseTex;
			//float _NoiseOffsetX;

			float4 _LineCount;
			float _Offset;
			float _LineSize;
			float _LineSpeed;

			float LineNoise(float2 uv,float4 _LineCount_XY,float _Offset,float _LineSize)
			{
				float _x = uv.x * _LineCount_XY.x;
				float _y = floor(uv.y * _LineCount_XY.y)/_LineCount_XY.y;

				// = tex2D(_NoiseTex,float2(_NoiseOffsetX,_y + 0.005)).r;
				float _noise;
				Unity_SimpleNoise_float(float2(0,_y),100,_noise);
				_y = _noise * _Offset + _Time.y * _LineSpeed;

				_LineSize = (1 - _LineSize) * 0.99;
				float _LineNoise = smoothstep(_LineSize,1, frac(_x - _y));

				return _LineNoise;
			}

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.positionCS = vertexInput.positionCS;

				output.color = _Color;
				output.uv = input.uv.xy;

				return output;
			}

            half4 frag (Varyings i) : SV_Target
            {
				half4 finalColor = tex2D(_MainTex,i.uv);
                return finalColor.a * i.color * LineNoise(i.uv,_LineCount,_Offset,_LineSize);
            }
            ENDHLSL
        }
    }
}
