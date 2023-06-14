Shader "Custom/Surface Shader"
{
	Properties
	{
		_BaseAlbedo ("Base Albedo", 2D) = "white" {}
		[Normal] _BaseNormal ("Base Normal", 2D) = "bump" {}
		_BaseGlossiness ("Base Smoothness", Range(0, 1)) = 0.5
		_BaseMetallic ("Base Metallic", Range(0, 1)) = 0.0

		_SoilAlbedo ("Soil Albedo", 2D) = "white" {}
		[Normal] _SoilNormal ("Soil Normal", 2D) = "bump" {}
		_SoilGlossiness ("Soil Smoothness", Range(0, 1)) = 0.5
		_SoilMetallic ("Soil Metallic", Range(0, 1)) = 0.0
		_SoilHeight ("Soil Height", 2D) = "black" {}
		_SoilThickness ("Soil Thickness", Range(0, 10)) = 0.5

		_GrassAlbedo ("Grass Albedo", 2D) = "white" {}
		[Normal] _GrassNormal ("Grass Normal", 2D) = "bump" {}
		_GrassGlossiness ("Grass Smoothness", Range(0, 1)) = 0.5
		_GrassMetallic ("Grass Metallic", Range(0, 1)) = 0.0
		_GrassHeight ("Grass Height", 2D) = "black" {}
		_GrassThickness ("Grass Thickness", Range(0, 10)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }

		CGPROGRAM
		#pragma surface surf Standard
		#pragma target 3.5

		struct Input
		{
			float2 uv_BaseAlbedo;
			float2 uv_BaseNormal;

			float2 uv_SoilAlbedo;
			float2 uv_SoilNormal;
			float2 uv_SoilHeight;

			float2 uv_GrassAlbedo;
			float2 uv_GrassNormal;
			float2 uv_GrassHeight;

			float4 color : COLOR;
			float3 worldPos;
		};
		
		uniform sampler2D _BaseAlbedo;
		uniform sampler2D _BaseNormal;
		uniform half _BaseGlossiness;
		uniform half _BaseMetallic;

		uniform sampler2D _SoilAlbedo;
		uniform sampler2D _SoilNormal;
		uniform half _SoilGlossiness;
		uniform half _SoilMetallic;
		uniform sampler2D _SoilHeight;
		uniform half _SoilThickness;

		uniform sampler2D _GrassAlbedo;
		uniform sampler2D _GrassNormal;
		uniform half _GrassGlossiness;
		uniform half _GrassMetallic;
		uniform sampler2D _GrassHeight;
		uniform half _GrassThickness;

		half3 lerpn(half3 n1, half3 n2, half t)
		{
			return normalize(float3(lerp(n1.xy / n1.z, n2.xy / n2.z, t), 1));
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			half soil = _SoilThickness * (1 - tex2D(_SoilHeight, IN.uv_SoilHeight)) < IN.color.g;
			half grass = _GrassThickness * (1 - tex2D(_GrassHeight, IN.uv_GrassHeight)) < IN.color.r;

			half4 color = tex2D(_BaseAlbedo, IN.uv_BaseAlbedo);
			color = lerp(color, tex2D(_SoilAlbedo, IN.uv_SoilAlbedo), soil);
			color = lerp(color, tex2D(_GrassAlbedo, IN.uv_GrassAlbedo), grass);

			half3 normal = UnpackNormal(tex2D(_BaseNormal, IN.uv_BaseNormal));
			normal = lerpn(normal, UnpackNormal(tex2D(_SoilNormal, IN.uv_SoilNormal)), soil);
			normal = lerpn(normal, UnpackNormal(tex2D(_GrassNormal, IN.uv_GrassNormal)), grass);

			half metalic = _BaseMetallic;
			metalic = lerp(metalic, _SoilMetallic, soil);
			metalic = lerp(metalic, _GrassMetallic, grass);

			half glossiness = _BaseGlossiness;
			glossiness = lerp(glossiness, _SoilGlossiness, soil);
			glossiness = lerp(glossiness, _GrassGlossiness, grass);

			o.Albedo = color;
			o.Normal = normal;
			o.Metallic = metalic;
			o.Smoothness = glossiness;
		}
		ENDCG
	}
	FallBack "Diffuse"
}