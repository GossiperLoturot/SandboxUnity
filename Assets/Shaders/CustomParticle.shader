// ディザ法を用いてカットアウトを使用してアルファブレンディングを行う
// 光半透過ライティングを使用

Shader "Custom/Particle"
{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Albedo (RGB)", 2D) = "white" { }
		_InvFade ("Soft Particles Factor", Range(0, 1)) = 0.5
		_Near ("Camera Fade Near Factor", Range(0, 10)) = 2
		_InvDist ("Camera Fade Factor", Range(0, 10)) = 0.5

        _DiffuseTranslucentColor ("Diffuse Translucent Color", Color) = (1, 1, 1, 1)
		_ForwardTranslucentColor ("Forward Translucent Color", Color) = (1, 1, 1, 1)
		_DiffuseTranslucentMin ("Diffuse Translucent Min", Range(0, 1)) = 0.3183
		_ForwardTranslucentPower ("Forward Translucent Power", Range(0, 20)) = 1.0
	}
	SubShader
	{
		Tags { "Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="Opaque" "PreviewType"="Plane" }
		
		LOD 200

		CGPROGRAM

		#pragma surface surf Translucent vertex:vert
		#pragma target 3.5

		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"

		#pragma multi_compile_instancing

		uniform half4 _Color;
		uniform sampler2D _MainTex;

		uniform float _InvFade;
		uniform float _Near;
		uniform float _InvDist;

        uniform float3 _DiffuseTranslucentColor;
		uniform float3 _ForwardTranslucentColor;
		uniform float _DiffuseTranslucentMin;
		uniform float _ForwardTranslucentPower;

		uniform sampler2D_float _CameraDepthTexture;
		uniform sampler3D _DitherMaskLOD;

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
			float4 color : COLOR;

			float2 uv_MainTex;
			float4 screenPos;

			float4 projPos;
		};

		inline void vert (inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);

			o.projPos = ComputeScreenPos(UnityObjectToClipPos(v.vertex));
    		COMPUTE_EYEDEPTH(o.projPos.z);
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			half4 color = tex2D (_MainTex, IN.uv_MainTex) * _Color * IN.color;

			// soft particle
			color.a *= saturate(_InvFade * (LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.projPos))) - IN.projPos.z)) * saturate((IN.projPos.z - _Near) * _InvDist);

			// dither
			clip(tex3D(_DitherMaskLOD, float3(IN.screenPos.xy / IN.screenPos.w * _ScreenParams.xy * 0.25, color.a * 0.9375)).a - 0.01);

			o.Albedo = color.rgb;
		}
		ENDCG
	}
	Fallback Off
}
