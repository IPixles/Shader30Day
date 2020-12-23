Shader "Hs/Day30Shader/TVScreenPattern"
{
    Properties
    {
		[HDR]_Color ("Color",COLOR) = (1,1,1,1)
        _MainTex ("Earth Texture", 2D) = "white" {}
		
		//Noise Offset 
		_NoiseMoveSpeed ("Noise Move Speed",RANGE(0,10)) = 2
		_NoiseStrength ("Noise Offset Strength",RANGE(0,1)) = 0.5
		_NoiseFlickerStr ("Noise Flicker Strength",RANGE(0,100)) = 50

		//Line Move
		_LineCount ("Line Mask Count",RANGE(0,100)) = 100
		_LineMovSpeed ("Line Move Speed",RANGE(0,100)) = 1
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

			//=====================================================
			//Line Move Function
			float LineMove(float2 _UV,float _Count,float _Speed)
			{
				//Line Count
				float temp = _UV.y * PI * 2 * _Count;
				//Move Speed
				temp += _Time.x * _Speed;
				temp = step(sin(temp),0.5);
				return temp;
			}
			//=====================================================

			//=====================================================
			//Noise Offset Function
			float2 NoiseOffset(float2 _UV,float _Speed,float _NoiseStrength,float _Flicker)
			{
				float temp;
				temp = _UV.y + _Time.y * _Speed;
				Unity_SimpleNoise_float(float2(0,temp),20,temp);
				temp -= 0.5;//视频中用了remap（Shadergraph），0-1映射至-0.5，0.5，相当于直接-0.5，无需用remap函数

				float flicker;
				Unity_SimpleNoise_float(float2(0,_Time.y),_Flicker,flicker);

				return float2(_UV.x +(temp * flicker) * _NoiseStrength,_UV.y);
			}
			//=====================================================

			float4 _Color;
			sampler2D _MainTex;

			float _LineCount;
			float _LineMovSpeed;

			float _NoiseMoveSpeed;
			float _NoiseFlickerStr;
			float _NoiseStrength;

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

				float2 _uv = NoiseOffset(i.uv,_NoiseMoveSpeed,_NoiseStrength,_NoiseFlickerStr);
				half4 finalColor = tex2D(_MainTex,_uv) * i.color;
				
				float lineNoise = LineMove(i.uv,_LineCount,_LineMovSpeed);

                return float4(finalColor.rgb * lineNoise,1);
            }
            ENDHLSL
        }
    }
}
