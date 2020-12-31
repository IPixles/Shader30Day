Shader "Hs/Day30Shader/Lava"
{
    Properties
    {
		[HDR]_Color ("Wave Color",COLOR) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
		
		_GradientNoiseScale ("Warp Scale",RANGE(0,100)) = 4
		_MoveSpeed ("Wave Move Speed",FLOAT) = 1
		_LerpStrength ("Wave Lerp Strength",RANGE(0,1)) = 0.06
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

			//将挪用Unity ShaderGraph 函数整合至hlsl文件，并Include
			#include "Assets/Shaders/UnityShaderGraphFunctions.hlsl"

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

			float4 _Color;
			sampler2D _MainTex;

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.positionCS = vertexInput.positionCS;

				output.color = _Color;
				output.uv = input.uv.xy;
				return output;
			}

			float _GradientNoiseScale;
			float _MoveSpeed;
			float _LerpStrength;

            half4 frag (Varyings i) : SV_Target
            {
				float g_Noise;
				Unity_GradientNoise_float(i.uv,_GradientNoiseScale,g_Noise);

				float w_Speed = _Time.y * _MoveSpeed + g_Noise;

				//Unity_Remap_float(w_Speed, float2(-1,1), float2(-0.58,0.58), w_Speed);

				half4 col1 = tex2D(_MainTex,i.uv + w_Speed);
				half4 col2 = tex2D(_MainTex,i.uv + w_Speed + float2(-0.7,0));

				float _lerp_Speed = abs(sin(_Time.y * _LerpStrength));

				half4 finalColor = lerp(col1,col2,_lerp_Speed) * i.color;

                return float4(finalColor.rgb,1);
            }
            ENDHLSL
        }
    }
}
