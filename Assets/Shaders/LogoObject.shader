Shader "Custom/Logo Object"
{
	Properties
	{
		_BlueVertex ("Blue Vertex", Range(0, 1)) = 0.1
		_BlueScale ("Blue Scale", Range(0, 10)) = 2.0
		_BlueTime ("Blue Time", Range(0, 10)) = 2.0
		_BluePower ("Blue Power", Range(0, 10)) = 2.0
		_Blue0 ("Blue 0", Color) = (1, 1, 1, 1)
		_Blue1 ("Blue 1", Color) = (1, 1, 1, 1)
		_BluePostPower ("Blue Post Power", Range(0, 10)) = 2.0

		_OrangeVertex ("Orange Vertex", Range(0, 1)) = 0.1
		_OrangeScale ("Orange Scale", Range(0, 10)) = 2.0
		_OrangeTime ("Orange Time", Range(0, 10)) = 2.0
		_OrangePower ("Orange Power", Range(0, 10)) = 2.0
		_Orange0 ("Orange 0", Color) = (1, 1, 1, 1)
		_Orange1 ("Orange 1", Color) = (1, 1, 1, 1)
		_OrangePostPower ("Orange Post Power", Range(0, 10)) = 2.0
		
		_VertexPower ("Vertex Power", Range(0, 10)) = 2.0
		_BlendScale ("Blend Scale", Range(0, 10)) = 2.0
		_BlendTime ("Blend Time", Range(0, 10)) = 2.0
		_BlendPower ("Blend Power", Range(0, 10)) = 2.0
		_BlendOffset ("Blend Offset", Range(0, 1)) = 0.6
		_Intensity ("Intensity", Range(0, 10)) = 2.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Noise.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
			};

			float _BlueVertex;
			float _BlueScale;
			float _BlueTime;
			float _BluePower;
			float4 _Blue0;
			float4 _Blue1;
			float _BluePostPower;

			float _OrangeVertex;
			float _OrangeScale;
			float _OrangeTime;
			float _OrangePower;
			float4 _Orange0;
			float4 _Orange1;
			float _OrangePostPower;

			float _VertexPower;
			float _BlendScale;
			float _BlendTime;
			float _BlendPower;
			float _BlendOffset;
			float _Intensity;

			v2f vert (appdata v)
			{
				v2f o;

				float bn = gradNoise(v.vertex.xyz * _BlueScale + _Time.xxx * 2) * 0.5 + 0.5;
				bn *= _BlueVertex;
				float on = gradNoise(v.vertex.xyz * _OrangeScale * float3(0.25, 1, 0.25) + _Time.xxx * 2) * 0.5 + 0.5;
				on *= _OrangeVertex;
				float t = gradNoise(v.vertex.xyz * _BlendScale + 200 + _Time.xxx * _BlendTime) * 0.5 + 0.5;
				t = min(t * (1 - v.uv.y) + _BlendOffset, 1);
				float n = pow(lerp(bn, on, t), _VertexPower);

				v.vertex.xyz += v.normal.xyz * n;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.worldPos = v.vertex;

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float bn = gradNoise(i.worldPos.xyz * _BlueScale + _Time.xxx * _BlueTime) * 0.5 + 0.5;
				bn = pow(bn, _BluePower);
				float4 bc = lerp(_Blue0, _Blue1, bn);
				bc = pow(bc, _BluePostPower);

				float on = gradNoise(i.worldPos.xyz * _OrangeScale * float3(0.25, 1, 0.25) + 100 + _Time.xxx * _OrangeTime) * 0.5 + 0.5;
				on = pow(on, _OrangePower);
				float4 oc = lerp(_Orange0, _Orange1, on);
				oc = pow(oc, _OrangePostPower);

				float n = gradNoise(i.worldPos.xyz * _BlendScale + 200 + _Time.xxx * _BlendTime) * 0.5 + 0.5;
				n = min(n * (1 - i.uv.y) + _BlendOffset, 1);
				n = pow(n, _BlendPower);
				float4 c = lerp(bc, oc, n) * _Intensity;

				return c;
			}
			ENDCG
		}
	}
	Fallback Off
}