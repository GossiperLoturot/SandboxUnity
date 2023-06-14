Shader "Custom/Distance Fog" {
Properties
{
	_MainTex ("Base (RGB)", 2D) = "black" {}
	_Density ("Density", Range(0, 1)) = 0.01
}
SubShader
{
	ZTest Always Cull Off ZWrite Off Fog { Mode Off }

	Pass
	{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		#include "UnityCG.cginc"

		uniform float _Density;
		uniform sampler2D _Fog;
		uniform sampler2D _MainTex;
		uniform sampler2D_float _CameraDepthTexture;

		struct appdata_fog
		{
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
		};

		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};
		
		v2f vert (appdata_fog v)
		{
			v2f o;
			v.vertex.z = 0.1;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord.xy;
			return o;
		}

		float4 frag (v2f i) : SV_Target {
			half4 fogColor = tex2D(_Fog, i.uv);
			half4 sceneColor = tex2D(_MainTex, i.uv);
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
			float fog = _Density * length(LinearEyeDepth(depth));
			fog = exp2(- fog * fog);
			if (depth == 0) fog = 1;
			return lerp(fogColor, sceneColor, fog);
		}
		ENDCG
	}
}

Fallback Off
}