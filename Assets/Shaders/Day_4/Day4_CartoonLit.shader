Shader "Hs/Day30Shader/CartoonLit"
{
    Properties
    {
		_Color ("Base Color",COLOR) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
		[HDR]_SpecularColor ("Specular Color",COLOR) = (1,1,1,1)
		_Gloss ("Gloss",RANGE(4,1000)) = 20

		_RimAmount ("Rim Amount",RANGE(0.01,1)) = 0.5
		_RimTheshold ("Rim Theshold",RANGE(0,1)) = 0.5
		[HDR]_RimColor ("Rim Color",COLOR) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			//包含Lighting相关
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#pragma vertex vert
            #pragma fragment frag

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				half4 color : COLOR;
				float3 WorldSpaceNormal : NORMAL;
				float2 uv : TEXCOORD0;
				float3 WorldSpaceViewDir : TEXCOORD1;
			};

			float4 _Color;
			sampler2D _MainTex;
			float _Gloss;
			float4 _SpecularColor;
			
			float _RimAmount;
			float _RimTheshold;
			float4 _RimColor;

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.positionCS = vertexInput.positionCS;

				output.color = _Color;
				output.uv = input.uv.xy;

				output.WorldSpaceNormal = mul(input.normal,(float3x3)UNITY_MATRIX_I_M);
				output.WorldSpaceViewDir = _WorldSpaceCameraPos.xyz - mul(GetObjectToWorldMatrix(), float4(input.positionOS.xyz, 1.0)).xyz;
				
				return output;
			}

            half4 frag (Varyings i) : SV_Target
            {
				//获取光照信息
				Light lit = GetMainLight();

				//光照计算
				float3 lightDir = normalize(lit.direction);
				float3 norDir = normalize(i.WorldSpaceNormal);
				float3 viewDir = normalize(i.WorldSpaceViewDir);
				float3 halfDir = normalize(lightDir + viewDir);//半角向量
				//Ambient
				float3 _Ambient = saturate(UNITY_LIGHTMODEL_AMBIENT.rgb * 2);
				//Diffuse 
				//float3 _Diffuse = max(0,dot(norDir,lightDir)) * lit.color.rgb * i.color.rgb;
				float3 _Diffuse = step(0,dot(norDir,lightDir)) * lit.color.rgb * i.color.rgb;
				//Specular 
				float3 _Specular = pow(max(0,dot(halfDir,norDir)),_Gloss) * _SpecularColor.rgb;
				_Specular = smoothstep(0.4,0.6,_Specular);

				//Rim
				float _Fresnel = 1 - dot(viewDir,norDir);
				float _Rim = _Fresnel * pow(max(dot(norDir,lightDir),0),_RimTheshold);
				_Rim = smoothstep(_RimAmount - 0.01,_RimAmount + 0.01,_Rim);
		
				half4 finalColor = tex2D(_MainTex,i.uv);
				finalColor.rgb *= _Ambient + _Diffuse + _Specular + _Rim * _RimColor.rgb;

                return finalColor;
            }
            ENDHLSL
        }
    }
}
