Shader "Hidden/BakerBoyHLSL"
{
	SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }
    	HLSLINCLUDE

	    #pragma target 4.5
	    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

	    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
	    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
	    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
	    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
	    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
    	
	    
	    struct appdata {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float4 texcoord : TEXCOORD0;
			float4 texcoord1 : TEXCOORD1;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};

	    struct v2f
		{
			float4 vertex 	: SV_POSITION;
			float2 texcoord	: TEXCOORD0;
			float3 worldPos	: TEXCOORD1;
			float3x3 TBN	: TEXCOORD2;
		};

    	struct Attributes
		{
		    float4 positionOS   : POSITION;
		    float3 normalOS     : NORMAL;
		    float2 texcoord     : TEXCOORD0;
		    UNITY_VERTEX_INPUT_INSTANCE_ID
		};

		struct Varyings
		{
		    float2 uv           : TEXCOORD0;
		    float4 positionCS   : SV_POSITION;
		};

	 //    inline float3 UnityObjectToWorldDir( in float3 dir )
		// {
		//     return normalize(mul((float3x3)UNITY_MATRIX_M, dir));
		// }
		// inline float3 UnityObjectToWorldNormal( in float3 norm )
		// {
		// #ifdef UNITY_ASSUME_UNIFORM_SCALING
		//     return mul(UNITY_MATRIX_M, float4(dir, 0)).xyz;
		// #else
		//     // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
		//     return normalize(mul(norm, (float3x3)UNITY_MATRIX_I_M));
		// #endif
		// }

    	float _UseUV2;

		v2f vertWorld (appdata v)
		{
			v2f o = (v2f)0;

			o.vertex 	= TransformObjectToHClip(v.vertex);
			o.texcoord 	= v.texcoord;
			o.worldPos	= mul(UNITY_MATRIX_M, v.vertex).xyz;

			float3 worldNormal = TransformObjectToWorldNormal(v.normal);
			float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
			float  tangentSign = v.tangent.w * unity_WorldTransformParams.w;
			float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;

			o.TBN = transpose(float3x3(worldTangent, worldBinormal, worldNormal));

			return o;
		}
	    
		
	    v2f vertUV (appdata v)
		{
			v2f o = (v2f)0;

			#if _USE_UV2
			o.vertex 	= float4((v.texcoord1 * 2 - 1) * float2(1, -1), 0.5, 1);
			#else
			o.vertex 	= float4((v.texcoord * 2 - 1) * float2(1, -1), 0.5, 1);
			#endif
			o.texcoord 	= v.texcoord;
			
			// o.worldPos	= mul(UNITY_MATRIX_M, v.vertex);
			float3 world = mul(UNITY_MATRIX_M, v.vertex).xyz;
			o.worldPos = GetAbsolutePositionWS(world);
			
			// o.worldPos = TransformObjectToWorldDir(v.vertex.xyz);
			// o.worldPos = TransformObjectToWorld(v.vertex).xyz;
    		
			float3 worldNormal = TransformObjectToWorldNormal(v.normal);
    		// float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    		
			// float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			// float3 worldTangent = mul(UNITY_MATRIX_M, float4(v.tangent.xyz, 0)).xyz;
			// float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
			float  tangentSign = v.tangent.w * unity_WorldTransformParams.w;
			float3 worldBinormal = cross(worldNormal, worldTangent) * tangentSign;

			o.TBN = transpose(float3x3(worldTangent, worldBinormal, worldNormal));

			return o;
		}

	    float3 _LightDir;
		float _ShadowDepthBias;

		// UNITY_DECLARE_SHADOWMAP(_ShadowMap);
	    TEXTURE2D_SHADOW(_ShadowMap);
		float4x4 _WorldToShadow;
	    SAMPLER_CMP(sampler_ShadowMap);

		float GetAttenuation (float3 worldPos)
		{
			// float3 lightPos = mul(_WorldToShadow, float4(worldPos, 1.0)).xyz;
			float4 lightPos = mul(_WorldToShadow, float4(worldPos - _LightDir * _ShadowDepthBias, 1.0));
			// return UNITY_SAMPLE_SHADOW_PROJ(_ShadowMap, lightPos);
			return SAMPLE_TEXTURE2D_SHADOW(_ShadowMap, sampler_ShadowMap, lightPos.xyz / lightPos.w);
		}
	    

		sampler2D _PositionMap;
		sampler2D _WorldNormalMap;

	    ENDHLSL
        Pass
        {
            Name "PositionNormal"
			Cull Off
			ZWrite On
			ZTest LEqual

            HLSLPROGRAM
                #pragma vertex vertUV
				#pragma fragment fragPosition
				#pragma multi_compile _ _USE_UV2

				struct FragOut
				{
					float4 worldPosition : SV_Target0;
					float4 worldNormal : SV_Target1;
				};

				sampler2D _NormalMap;
				float _HasNormalMap;

				FragOut fragPosition (v2f i)
				{
					FragOut o;

					float3 tNormal = float3(0, 0, 1);
					if (_HasNormalMap == 1.0)
					{
						tNormal = UnpackNormalmapRGorAG(tex2D(_NormalMap, i.texcoord));
					}
						// tNormal = UnpackNormal(tex2D(_NormalMap, i.texcoord));

					o.worldPosition = float4(i.worldPos, 1);
					// o.worldPosition = i.worldPos;
					o.worldNormal = float4(normalize(mul(i.TBN, tNormal)), 1);

					return o;
				}
            ENDHLSL
        }
    	Pass
		{
			Name "Gather"
			Cull Off
			ZWrite On
			ZTest LEqual
			
			Blend One One

			HLSLPROGRAM
			#pragma vertex vertUV
			#pragma fragment fragGather
			#pragma multi_compile _ _USE_UV2

			struct FragOut
			{
				float4 occlusion : SV_Target0;
				float4 bentNormal : SV_Target1;
			};

			float _GatherAmount;

			FragOut fragGather (v2f i)
			{
				FragOut o;

				float3 worldPos = tex2D(_PositionMap, i.texcoord);
				float3 worldNormal = tex2D(_WorldNormalMap, i.texcoord);

				float  attenuation = GetAttenuation(worldPos);

				// float nDotL = dot(worldNormal, -_LightDir);
				// if (nDotL > 0)
				// 	attenuation *= nDotL;
					// attenuation *= 1;
				// else
				// 	attenuation = 1;

				attenuation *= max(0, dot(worldNormal, -_LightDir));
				// return float4(worldNormal, 1) * _GatherAmount;

				o.occlusion = float4(attenuation.xxx, 1) * _GatherAmount;
				o.bentNormal = float4(-_LightDir * lerp(1, attenuation, 0.9), 1) * _GatherAmount;

				return o;
			}
			ENDHLSL
		}
    	Pass
		{
			Name "PackNormal"
			Cull Off

			HLSLPROGRAM
			#pragma vertex vertUV
			#pragma fragment fragPackNormal
			#pragma multi_compile _ _USE_UV2

			float4 fragPackNormal (v2f i) : SV_Target
			{
				float4 normal = tex2D(_WorldNormalMap, i.texcoord);
				normal.xyz = normalize(mul(transpose(i.TBN), normal.xyz))*0.5+0.5;

				return normal;
			}
			ENDHLSL 
		}
//    	Pass
//		{
//			Name "ShadowTest"
//			ZWrite On
//			ZTest LEqual
//
//			HLSLPROGRAM
//			#pragma vertex ShadowPassVertex
//			#pragma fragment ShadowPassFragment
//
//			#include "Assets/BakerBoy/Shaders/Lib/URPShadowPass.hlsl"
//			ENDHLSL
//		}
    }
    Fallback Off
}
