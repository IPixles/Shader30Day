Shader "Hs/Day30Shader/Flag"
{
    Properties
    {
		_Color ("Base Color",COLOR) = (1,1,1,1)
		[HDR]_FireColor ("Fire Color",COLOR) = (1,1,1,1)
		_NoiseSpeed ("Fire Move Speed",RANGE(0,1)) = 0.1
		_DissovleClip ("Dissovle Clip",RANGE(0,1)) = 0.5
		_DissovleEdge ("Dissovle Edge",RANGE(0,1)) = 0.5
    }

	HLSLINCLUDE
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Assets/Shaders/UnityShaderGraphFunctions.hlsl"
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
		float2 uv : TEXCOORD0;
	};

	float4 _Color;

	Varyings vert(Attributes input)
	{
		Varyings output = (Varyings)0;
		VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
		output.positionCS = vertexInput.positionCS;

		output.color = _Color;
		output.uv = input.uv.xy;

		return output;
	}

	///
	float4 _FireColor;
	float _NoiseSpeed;
	float _DissovleClip;
	float _DissovleEdge;
	///

    half4 frag (Varyings i) : SV_Target
    {
		// Dissovle Var
		float _DisVar;
		float _ClipVar;
		Unity_Remap_float(_DissovleClip, float2(0,1), float2(0,1 + _DissovleEdge), _ClipVar);
		_DisVar = smoothstep(_DissovleClip - _DissovleEdge,_ClipVar,i.uv.y);

		//Dissovle Noise
		float _DisNoise;
		Unity_SimpleNoise_float(float2 (i.uv.x,i.uv.y - _Time.y*_NoiseSpeed), 60, _DisNoise);
		Unity_Remap_float(_DisNoise, float2(0,1), float2(-1,1), _DisNoise);
		_DisNoise += 1 - _DisVar;

		//Dissovle Color 
		float4 _DisCol = _FireColor * saturate((2 - _DisNoise) * _DisVar);

		half4 finalColor = i.color + _DisCol;
		clip(_DisNoise - _DisVar);
        return finalColor;
    }
	ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
			#pragma vertex vert
            #pragma fragment frag
            ENDHLSL
        }
    }
}
