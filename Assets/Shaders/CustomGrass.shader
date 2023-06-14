Shader "Custom/Grass" {
Properties
{
	[HDR] _Color0 ("Color 0", Color) = (1, 1, 1, 1)
	[HDR] _Color1 ("Color 1", Color) = (1, 1, 1, 1)
	_MainTex ("Texture", 2D) = "white" {}
	_Cutout ("Alpha Threshold", Range(0, 1)) = 0.5

	[Normal] _Normal ("Normal", 2D) = "bump" {}
	[Normal] _NodeNormal ("Node Normal", 2D) = "bump" {}
	_NodeNormalMix ("Node Normal Mix", Range(0, 1)) = 0.5

	_Glossiness ("Smoothness", Range(0, 1)) = 0.5
	_Metallic ("Metallic", Range(0, 1)) = 0.0

	_ContactScale ("Contact Scale", Range(0, 1)) = 0.9
	_ContactShift ("Contact Shift", Range(0, 1)) = 0.1

	_Wind ("Wind", 2D) = "black" {}
	_WindScale ("Wind Scale", Range(0, 1)) = 0.5
	_WindOffsetByTime ("Wind Offset By Time", Vector) = (0.1, 0.1, 0, 0)

	_Force ("Force", 2D) = "black" {}
	_ForceScale ("Force Scale", Range(0, 1)) = 0.5

	_ViewDistance ("View Distance", Vector) = (20, 24, 16, 20)
}
SubShader
{
	Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
	Cull Off

	CGPROGRAM
	#pragma surface surf Standard alphatest:_Cutout vertex:vert finalgbuffer:final
	#pragma target 3.0

	#include "Noise.cginc"

	uniform half4 _Color0;
	uniform half4 _Color1;
	uniform sampler2D _MainTex;
	uniform sampler2D _Normal;
	uniform sampler2D _NodeNormal;
	float4 _NodeNormal_ST;
	uniform half _NodeNormalMix;
	uniform float _Glossiness;
	uniform float _Metallic;

	uniform float _ContactScale;
	uniform float _ContactShift;

	uniform sampler2D _Wind;
	uniform float4 _Wind_ST;
	uniform half _WindScale;
	uniform float4 _WindOffsetByTime;

	uniform sampler2D _Force;
	uniform float4 _Force_ST;
	uniform half _ForceScale;

	uniform float4 _ViewDistance;

	struct Input
	{
		float2 uv_MainTex;
		float2 uv_Normal;
		float3 nodePosition;
		half colorGradient;
		float distance;
	};

	void vert (inout appdata_full v, out Input o)
	{
		UNITY_INITIALIZE_OUTPUT(Input, o);

		float3 position = mul(unity_ObjectToWorld, v.vertex);
		float3 nodePosition = mul(unity_ObjectToWorld, float4(v.texcoord1.xyz, 1));
		half softness = distance(position, nodePosition);

		half3 wind = tex2Dlod(_Wind, float4(position.xz * _Wind_ST.xy + _Wind_ST.zw + _Time.xx * _WindOffsetByTime.xy, 0.0, 0.0)).xyz;
		v.vertex.xyz += softness * wind * _WindScale;

		half3 force = tex2Dlod(_Force, float4(position.xz * _Force_ST.xy + _Force_ST.zw, 0.0, 0.0)).xyz;
		v.vertex.xyz += softness * force * _ForceScale;

		v.normal = lerp(v.normal, v.texcoord2.xyz, _NodeNormalMix);
		o.nodePosition = nodePosition;
		o.colorGradient = hash(float3(v.texcoord1.z, 0, 0));
		o.distance = distance(nodePosition, _WorldSpaceCameraPos);
	}

	half contact;

	void surf (Input IN, inout SurfaceOutputStandard o)
	{
		half4 color = lerp(_Color0, _Color1, IN.colorGradient) * tex2D(_MainTex, IN.uv_MainTex);
		color.a *= smoothstep(_ViewDistance.y, _ViewDistance.x, IN.distance);

		half3 n1 = UnpackNormal(tex2D(_Normal, IN.uv_Normal));
		half3 n2 = UnpackNormal(tex2D(_NodeNormal, IN.nodePosition.xz * _NodeNormal_ST.xy + _NodeNormal_ST.zw));
		half3 normal = normalize(float3(lerp(n1.xy / n1.z, n2.xy / n2.z, _NodeNormalMix), 1));

		o.Albedo = color.rgb;
		o.Normal = normal;
		o.Metallic = _Metallic;
		o.Smoothness = _Glossiness;
		o.Alpha = color.a;

		contact = tex2D(_MainTex, IN.uv_MainTex + _ContactShift) * _ContactScale;
		contact *= smoothstep(_ViewDistance.w, _ViewDistance.z, IN.distance);
	}

	void final (Input IN, SurfaceOutputStandard o, inout half4 outDiffuse, inout half4 outSpecSmoothness, inout half4 outNormal, inout half4 outEmission)
	{
		outNormal.a = 1.0 - contact;
	}
	ENDCG

	Pass
	{
		Tags { "LightMode"="ShadowCaster" }
		Cull Off

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma target 3.0

		#include "UnityCG.cginc"

		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform half _Cutout;

		uniform sampler2D _Wind;
		uniform float4 _Wind_ST;
		uniform half _WindScale;

		uniform sampler2D _Force;
		uniform float4 _Force_ST;
		uniform half _ForceScale;

		uniform float4 _ViewDistance;

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 texcoord0 : TEXCOORD0;
			float3 texcoord1 : TEXCOORD1;
		};

		struct v2f
		{
			V2F_SHADOW_CASTER;
			float2 uv : TEXCOORD0;
		};

		v2f vert (appdata v)
		{
			v2f o;

			float3 position = mul(unity_ObjectToWorld, v.vertex);
			float3 nodePosition = mul(unity_ObjectToWorld, float4(v.texcoord1, 1));
			half softness = distance(position, nodePosition);

			half3 wind = tex2Dlod(_Wind, float4(position.xz * _Wind_ST.xy + _Wind_ST.zw, 0.0, 0.0)).xyz;
			v.vertex.xyz += softness * wind * _WindScale;

			half3 force = tex2Dlod(_Force, float4(position.xz * _Force_ST.xy + _Force_ST.zw, 0.0, 0.0)).xyz;
			v.vertex.xyz += softness * force * _ForceScale;

			v.vertex *= distance(nodePosition, _WorldSpaceCameraPos) < _ViewDistance.z;
			
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			o.uv = TRANSFORM_TEX(v.texcoord0, _MainTex);
				
			return o;
		}

		float4 frag (v2f i) : SV_Target
		{
			clip(tex2D(_MainTex, i.uv).a - _Cutout);
			SHADOW_CASTER_FRAGMENT(i)
		}
		ENDCG
	}
}

Fallback Off
}