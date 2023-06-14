// 光半透過ライティングを使用
// 頂点が風になびくように

Shader "Custom/Branch"
{
	Properties
	{
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Cutout ("Alpha Threshold", Range(0, 1)) = 0.5
		[Normal] _Normal ("Normal", 2D) = "bump" {}
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0.0

		_Wind ("Wind", 2D) = "black" {}
		_WindScale ("Wind Scale", Range(0, 1)) = 0.5
		_WindOffsetByTime ("Wind Offset By Time", Vector) = (0.1, 0.1, 0, 0)

		_DiffuseTranslucentColor ("Diffuse Translucent Color", Color) = (1, 1, 1, 1)
		_ForwardTranslucentColor ("Forward Translucent Color", Color) = (1, 1, 1, 1)
		_DiffuseTranslucentMin ("Diffuse Translucent Min", Range(0, 1)) = 0.3183
		_ForwardTranslucentPower ("Forward Translucent Power", Range(0, 8)) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }

		Cull Off

		CGPROGRAM
		#pragma surface surf Translucent alphatest:_Cutout vertex:vert addshadow
		#pragma target 3.0

		#include "UnityPBSLighting.cginc"

		uniform sampler2D _MainTex;
		uniform sampler2D _Wind;
		uniform float4 _Wind_ST;
		uniform half _WindScale;
		uniform float4 _WindOffsetByTime;
		uniform sampler2D _Normal;
		uniform float _Glossiness;
		uniform float _Metallic;
		uniform half3 _DiffuseTranslucentColor;
		uniform half3 _ForwardTranslucentColor;
		uniform half _DiffuseTranslucentMin;
		uniform half _ForwardTranslucentPower;

		float4 LightingTranslucent(SurfaceOutputStandard s, float3 viewDir, UnityGI gi)
		{
			float4 pbr = LightingStandard(s, viewDir, gi);

			float3 diffuseTranslucency = 
				gi.light.color.rgb * s.Albedo.rgb * _DiffuseTranslucentColor 
				* max(_DiffuseTranslucentMin, dot(gi.light.dir, -s.Normal));

			float3 forwardTranslucency = 
				gi.light.color.rgb * s.Albedo.rgb * _ForwardTranslucentColor
				* pow(max(0.0, dot(-gi.light.dir, viewDir)), _ForwardTranslucentPower);

			pbr.rgb = pbr.rgb + diffuseTranslucency + forwardTranslucency;

			return pbr;
		}

		void LightingTranslucent_GI (SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
		{
			LightingStandard_GI(s, data, gi);
		}

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_Normal;
		};

		void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			float3 position = mul(unity_ObjectToWorld, v.vertex);

			half3 wind = tex2Dlod(_Wind, float4(position.xz * _Wind_ST.xy + _Wind_ST.zw + _Time.xx * _WindOffsetByTime.xy, 0.0, 0.0)).xyz;
			v.vertex.xyz += v.texcoord.y * wind * _WindScale;
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			half4 color = tex2D(_MainTex, IN.uv_MainTex);

			o.Albedo = color.rgb;
			o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_MainTex));
			o.Smoothness = _Glossiness;
			o.Metallic = _Metallic;
			o.Alpha = color.a;
		}
		ENDCG
	}
	FallBack Off
}