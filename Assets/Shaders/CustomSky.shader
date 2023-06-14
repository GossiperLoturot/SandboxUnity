// 天球の下半分をシームレスに表示するよう変更
// 太陽が水面下の場合のレンダーパスを追加
// 星空を描写するようレンダーパスを追加

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Custom/Procedual Sky" {
Properties
{
	[KeywordEnum(None, Simple, High Quality)] _SunDisk ("Sun", Int) = 2
	_SunSize ("Sun Size", Range(0, 1)) = 0.04
	_SunSizeConvergence ("Sun Size Convergence", Range(1,10)) = 5

	_AtmosphereThickness ("Atmosphere Thickness", Range(0,5)) = 1
	_SkyTint ("Sky Tint", Color) = (0.5, 0.5, 0.5, 1)
	_Exposure("Exposure", Float) = 6
	_LuminanceMultiply ("Luminance Multiply", Range(0, 2)) = 0.75
	_LuminanceShift ("Luminance Shift", Range(-2, 2)) = 0

    _FallbackAtmosphereThickness ("Fallback Atmosphere Thickness", Range(0,5)) = 1
	_FallbackSkyTint ("Fallback Sky Tint", Color) = (0.5, 0.5, 0.5, 1)
	_FallbackExposure("Fallback Exposure", Float) = 0.02
	_FallbackLuminanceMultiply ("Fallback Luminance Multiply", Range(0, 2)) = 1
	_FallbackLuminanceShift ("Fallback Luminance Shift", Range(-2, 2)) = 0

	_StarDistribScale ("Star Distribution Scale", Range(0, 100)) = 16
	_StarDistribSharpness ("Star Distribution Power", Range(1, 100)) = 6.2
	_StarScale ("Star Scale", Range(0, 1000)) = 45
	_StarSharpness ("Star Sharpness", Range(1, 1000)) = 600
	_StarLuminance ("Star Luminance", Range(0, 10)) = 4
}
SubShader
{
	Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
	Cull Off ZWrite Off

	Pass
	{

		CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        #pragma multi_compile_local _SUNDISK_NONE _SUNDISK_SIMPLE _SUNDISK_HIGH_QUALITY

        uniform float _Exposure;     // HDR exposure
        uniform float _SunSize;
        uniform float _SunSizeConvergence;
        uniform float3 _SkyTint;
        uniform float _AtmosphereThickness;
		uniform float _LuminanceMultiply;
        uniform float _LuminanceShift;

    #if defined(UNITY_COLORSPACE_GAMMA)
        #define GAMMA 2
        #define COLOR_2_GAMMA(color) color
        #define COLOR_2_LINEAR(color) color*color
        #define LINEAR_2_OUTPUT(color) sqrt(color)
    #else
        #define GAMMA 2.2
        // HACK: to get gfx-tests in Gamma mode to agree until UNITY_ACTIVE_COLORSPACE_IS_GAMMA is working properly
        #define COLOR_2_GAMMA(color) ((unity_ColorSpaceDouble.r>2.0) ? pow(color,1.0/GAMMA) : color)
        #define COLOR_2_LINEAR(color) color
        #define LINEAR_2_LINEAR(color) color
    #endif

        // RGB wavelengths
        // .35 (.62=158), .43 (.68=174), .525 (.75=190)
        static const float3 kDefaultScatteringWavelength = float3(.65, .57, .475);
        static const float3 kVariableRangeForScatteringWavelength = float3(.15, .15, .15);

        #define OUTER_RADIUS 1.025
        static const float kOuterRadius = OUTER_RADIUS;
        static const float kOuterRadius2 = OUTER_RADIUS*OUTER_RADIUS;
        static const float kInnerRadius = 1.0;
        static const float kInnerRadius2 = 1.0;

        static const float kCameraHeight = 0.0001;

        #define kRAYLEIGH (lerp(0.0, 0.0025, pow(_AtmosphereThickness,2.5)))      // Rayleigh constant
        #define kMIE 0.0010             // Mie constant
        #define kSUN_BRIGHTNESS 20.0    // Sun brightness

        #define kMAX_SCATTER 50.0 // Maximum scattering value, to prevent math overflows on Adrenos

        static const half kHDSundiskIntensityFactor = 15.0;
        static const half kSimpleSundiskIntensityFactor = 27.0;

        static const half kSunScale = 400.0 * kSUN_BRIGHTNESS;
        static const float kKmESun = kMIE * kSUN_BRIGHTNESS;
        static const float kKm4PI = kMIE * 4.0 * 3.14159265;
        static const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
        static const float kScaleDepth = 0.25;
        static const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
        static const float kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH

        #define MIE_G (-0.990)
        #define MIE_G2 0.9801

        // fine tuning of performance. You can override defines here if you want some specific setup
        // or keep as is and allow later code to set it according to target api

        // if set vprog will output color in final color space (instead of linear always)
        // in case of rendering in gamma mode that means that we will do lerps in gamma mode too, so there will be tiny difference around horizon
        // #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0

        // sun disk rendering:
        // no sun disk - the fastest option
        #define SKYBOX_SUNDISK_NONE 0
        // simplistic sun disk - without mie phase function
        #define SKYBOX_SUNDISK_SIMPLE 1
        // full calculation - uses mie phase function
        #define SKYBOX_SUNDISK_HQ 2

        // uncomment this line and change SKYBOX_SUNDISK_SIMPLE to override material settings
        // #define SKYBOX_SUNDISK SKYBOX_SUNDISK_SIMPLE

    #ifndef SKYBOX_SUNDISK
        #if defined(_SUNDISK_NONE)
            #define SKYBOX_SUNDISK SKYBOX_SUNDISK_NONE
        #elif defined(_SUNDISK_SIMPLE)
            #define SKYBOX_SUNDISK SKYBOX_SUNDISK_SIMPLE
        #else
            #define SKYBOX_SUNDISK SKYBOX_SUNDISK_HQ
        #endif
    #endif

    #ifndef SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
        #if defined(SHADER_API_MOBILE)
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 1
        #else
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0
        #endif
    #endif

        // Calculates the Rayleigh phase function
        half getRayleighPhase(half eyeCos2)
        {
            return 0.75 + 0.75*eyeCos2;
        }
        half getRayleighPhase(half3 light, half3 ray)
        {
            half eyeCos = dot(light, ray);
            return getRayleighPhase(eyeCos * eyeCos);
        }


        struct appdata_t
        {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4  pos             : SV_POSITION;

        #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            // for HQ sun disk, we need vertex itself to calculate ray-dir per-pixel
            float3  vertex          : TEXCOORD0;
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            half3   rayDir          : TEXCOORD0;
        #endif

            // calculate sky colors in vprog
            half3   skyColor        : TEXCOORD1;

        #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
            half3   sunColor        : TEXCOORD2;
        #endif

            UNITY_VERTEX_OUTPUT_STEREO
        };


        float scale(float inCos)
        {
            float x = 1.0 - inCos;
            return 0.25 * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
        }

        v2f vert (appdata_t v)
        {
            v2f OUT;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);

            float3 kSkyTintInGammaSpace = COLOR_2_GAMMA(_SkyTint); // convert tint from Linear back to Gamma
            float3 kScatteringWavelength = lerp (
                kDefaultScatteringWavelength-kVariableRangeForScatteringWavelength,
                kDefaultScatteringWavelength+kVariableRangeForScatteringWavelength,
                half3(1,1,1) - kSkyTintInGammaSpace); // using Tint in sRGB gamma allows for more visually linear interpolation and to keep (.5) at (128, gray in sRGB) point
            float3 kInvWavelength = 1.0 / pow(kScatteringWavelength, 4);

            float kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
            float kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;

            float3 cameraPos = float3(0,kInnerRadius + kCameraHeight,0);    // The camera's current position

            // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
			float3 eyeRay = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
			eyeRay.y = max(0, eyeRay.y);
            eyeRay.z += 0.001;
			eyeRay = normalize(eyeRay);

			// Sky
			// Calculate the length of the "atmosphere"
			float far = sqrt(kOuterRadius2 + kInnerRadius2 * eyeRay.y * eyeRay.y - kInnerRadius2) - kInnerRadius * eyeRay.y;

			float3 pos = cameraPos + far * eyeRay;

			// Calculate the ray's starting position, then calculate its scattering offset
			float height = kInnerRadius + kCameraHeight;
			float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
			float startAngle = dot(eyeRay, cameraPos) / height;
			float startOffset = depth*scale(startAngle);


			// Initialize the scattering loop variables
			float sampleLength = far / kSamples;
			float scaledLength = sampleLength * kScale;
			float3 sampleRay = eyeRay * sampleLength;
			float3 samplePoint = cameraPos + sampleRay * 0.5;

			// Now loop through the sample rays
			float3 frontColor = float3(0.0, 0.0, 0.0);
			// Weird workaround: WP8 and desktop FL_9_3 do not like the for loop here
			// (but an almost identical loop is perfectly fine in the ground calculations below)
			// Just unrolling this manually seems to make everything fine again.
//          for(int i=0; i<int(kSamples); i++)
			{
				float height = length(samplePoint);
				float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
				float lightAngle = dot(_WorldSpaceLightPos0.xyz, samplePoint) / height;
				float cameraAngle = dot(eyeRay, samplePoint) / height;
				float scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
				float3 attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));

				frontColor += attenuate * (depth * scaledLength);
				samplePoint += sampleRay;
			}
			{
				float height = length(samplePoint);
				float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
				float lightAngle = dot(_WorldSpaceLightPos0.xyz, samplePoint) / height;
				float cameraAngle = dot(eyeRay, samplePoint) / height;
				float scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
				float3 attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));

				frontColor += attenuate * (depth * scaledLength);
				samplePoint += sampleRay;
			}



			// Finally, scale the Mie and Rayleigh colors and set up the varying variables for the pixel shader
			half3 cIn = frontColor * (kInvWavelength * kKrESun);
			half3 cOut = frontColor * kKmESun;

        #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            OUT.vertex          = -eyeRay;
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            OUT.rayDir          = half3(-eyeRay);
        #endif

            // if we want to calculate color in vprog:
            // 1. in case of linear: multiply by _Exposure in here (even in case of lerp it will be common multiplier, so we can skip mul in fshader)
            // 2. in case of gamma and SKYBOX_COLOR_IN_TARGET_COLOR_SPACE: do sqrt right away instead of doing that in fshader

            OUT.skyColor    = _Exposure * (cIn * getRayleighPhase(_WorldSpaceLightPos0.xyz, -eyeRay));

        #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
            // The sun should have a stable intensity in its course in the sky. Moreover it should match the highlight of a purely specular material.
            // This matching was done using the standard shader BRDF1 on the 5/31/2017
            // Finally we want the sun to be always bright even in LDR thus the normalization of the lightColor for low intensity.
            half lightColorIntensity = clamp(length(_LightColor0.xyz), 0.25, 1);
            #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
                OUT.sunColor    = kSimpleSundiskIntensityFactor * saturate(cOut * kSunScale) * _LightColor0.xyz / lightColorIntensity;
            #else // SKYBOX_SUNDISK_HQ
                OUT.sunColor    = kHDSundiskIntensityFactor * saturate(cOut) * _LightColor0.xyz / lightColorIntensity;
            #endif

        #endif

        #if defined(UNITY_COLORSPACE_GAMMA) && SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            OUT.skyColor    = sqrt(OUT.skyColor);
            #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
                OUT.sunColor= sqrt(OUT.sunColor);
            #endif
        #endif

            return OUT;
        }


        // Calculates the Mie phase function
        half getMiePhase(half eyeCos, half eyeCos2)
        {
            half temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
            temp = pow(temp, pow(_SunSize,0.65) * 10);
            temp = max(temp,1.0e-4); // prevent division by zero, esp. in half precision
            temp = 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;
            #if defined(UNITY_COLORSPACE_GAMMA) && SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
                temp = pow(temp, .454545);
            #endif
            return temp;
        }

        // Calculates the sun shape
        half calcSunAttenuation(half3 lightPos, half3 ray)
        {
        #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            half3 delta = lightPos - ray;
            half dist = length(delta);
            half spot = 1.0 - smoothstep(0.0, _SunSize, dist);
            return spot * spot;
        #else // SKYBOX_SUNDISK_HQ
            half focusedEyeCos = pow(saturate(dot(lightPos, ray)), _SunSizeConvergence);
            return getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos);
        #endif
        }

        half4 frag (v2f IN) : SV_Target
        {
            half3 col = half3(0.0, 0.0, 0.0);

        // if y > 1 [eyeRay.y < -SKY_GROUND_THRESHOLD] - ground
        // if y >= 0 and < 1 [eyeRay.y <= 0 and > -SKY_GROUND_THRESHOLD] - horizon
        // if y < 0 [eyeRay.y > 0] - sky
        #if SKYBOX_SUNDISK == SKYBOX_SUNDISK_HQ
            half3 ray = normalize(IN.vertex.xyz);
        #elif SKYBOX_SUNDISK == SKYBOX_SUNDISK_SIMPLE
            half3 ray = IN.rayDir.xyz;
        #endif

            // if we did precalculate color in vprog: just do lerp between them
            col = IN.skyColor * _LuminanceMultiply + _LuminanceShift;

        #if SKYBOX_SUNDISK != SKYBOX_SUNDISK_NONE
            col += IN.sunColor * calcSunAttenuation(_WorldSpaceLightPos0.xyz, -ray);
        #endif

        #if defined(UNITY_COLORSPACE_GAMMA) && !SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            col = LINEAR_2_OUTPUT(col);
        #endif

            return half4(col,1.0);

        }
        ENDCG
	}

    Pass
	{
		Blend One One

		CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        uniform float _FallbackExposure;     // HDR exposure
        uniform float3 _FallbackSkyTint;
        uniform float _FallbackAtmosphereThickness;
		uniform float _FallbackLuminanceMultiply;
        uniform float _FallbackLuminanceShift;

    #if defined(UNITY_COLORSPACE_GAMMA)
        #define GAMMA 2
        #define COLOR_2_GAMMA(color) color
        #define COLOR_2_LINEAR(color) color*color
        #define LINEAR_2_OUTPUT(color) sqrt(color)
    #else
        #define GAMMA 2.2
        // HACK: to get gfx-tests in Gamma mode to agree until UNITY_ACTIVE_COLORSPACE_IS_GAMMA is working properly
        #define COLOR_2_GAMMA(color) ((unity_ColorSpaceDouble.r>2.0) ? pow(color,1.0/GAMMA) : color)
        #define COLOR_2_LINEAR(color) color
        #define LINEAR_2_LINEAR(color) color
    #endif

        // RGB wavelengths
        // .35 (.62=158), .43 (.68=174), .525 (.75=190)
        static const float3 kDefaultScatteringWavelength = float3(.65, .57, .475);
        static const float3 kVariableRangeForScatteringWavelength = float3(.15, .15, .15);

        #define OUTER_RADIUS 1.025
        static const float kOuterRadius = OUTER_RADIUS;
        static const float kOuterRadius2 = OUTER_RADIUS*OUTER_RADIUS;
        static const float kInnerRadius = 1.0;
        static const float kInnerRadius2 = 1.0;

        static const float kCameraHeight = 0.0001;

        #define kRAYLEIGH (lerp(0.0, 0.0025, pow(_FallbackAtmosphereThickness,2.5)))      // Rayleigh constant
        #define kMIE 0.0010             // Mie constant
        #define kSUN_BRIGHTNESS 20.0    // Sun brightness

        #define kMAX_SCATTER 50.0 // Maximum scattering value, to prevent math overflows on Adrenos

        static const float kKmESun = kMIE * kSUN_BRIGHTNESS;
        static const float kKm4PI = kMIE * 4.0 * 3.14159265;
        static const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
        static const float kScaleDepth = 0.25;
        static const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
        static const float kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH

        // fine tuning of performance. You can override defines here if you want some specific setup
        // or keep as is and allow later code to set it according to target api

        // if set vprog will output color in final color space (instead of linear always)
        // in case of rendering in gamma mode that means that we will do lerps in gamma mode too, so there will be tiny difference around horizon
        // #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0

    #ifndef SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
        #if defined(SHADER_API_MOBILE)
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 1
        #else
            #define SKYBOX_COLOR_IN_TARGET_COLOR_SPACE 0
        #endif
    #endif

        // Calculates the Rayleigh phase function
        half getRayleighPhase(half eyeCos2)
        {
            return 0.75 + 0.75*eyeCos2;
        }
        half getRayleighPhase(half3 light, half3 ray)
        {
            half eyeCos = dot(light, ray);
            return getRayleighPhase(eyeCos * eyeCos);
        }


        struct appdata_t
        {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4  pos             : SV_POSITION;

            // calculate sky colors in vprog
            half3   skyColor        : TEXCOORD1;

            UNITY_VERTEX_OUTPUT_STEREO
        };


        float scale(float inCos)
        {
            float x = 1.0 - inCos;
            return 0.25 * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
        }

        v2f vert (appdata_t v)
        {
            v2f OUT;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
            OUT.pos = UnityObjectToClipPos(v.vertex);

            float3 kSkyTintInGammaSpace = COLOR_2_GAMMA(_FallbackSkyTint); // convert tint from Linear back to Gamma
            float3 kScatteringWavelength = lerp (
                kDefaultScatteringWavelength-kVariableRangeForScatteringWavelength,
                kDefaultScatteringWavelength+kVariableRangeForScatteringWavelength,
                half3(1,1,1) - kSkyTintInGammaSpace); // using Tint in sRGB gamma allows for more visually linear interpolation and to keep (.5) at (128, gray in sRGB) point
            float3 kInvWavelength = 1.0 / pow(kScatteringWavelength, 4);

            float kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
            float kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;

            float3 cameraPos = float3(0,kInnerRadius + kCameraHeight,0);    // The camera's current position
            float3 lightPos = float3(0,1,0); // 近似的な値

            // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
			float3 eyeRay = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
			eyeRay.y = max(0, eyeRay.y);
            eyeRay.z += 0.001;
			eyeRay = normalize(eyeRay);

			// Sky
			// Calculate the length of the "atmosphere"
			float far = sqrt(kOuterRadius2 + kInnerRadius2 * eyeRay.y * eyeRay.y - kInnerRadius2) - kInnerRadius * eyeRay.y;

			float3 pos = cameraPos + far * eyeRay;

			// Calculate the ray's starting position, then calculate its scattering offset
			float height = kInnerRadius + kCameraHeight;
			float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
			float startAngle = dot(eyeRay, cameraPos) / height;
			float startOffset = depth*scale(startAngle);


			// Initialize the scattering loop variables
			float sampleLength = far / kSamples;
			float scaledLength = sampleLength * kScale;
			float3 sampleRay = eyeRay * sampleLength;
			float3 samplePoint = cameraPos + sampleRay * 0.5;

			// Now loop through the sample rays
			float3 frontColor = float3(0.0, 0.0, 0.0);
			// Weird workaround: WP8 and desktop FL_9_3 do not like the for loop here
			// (but an almost identical loop is perfectly fine in the ground calculations below)
			// Just unrolling this manually seems to make everything fine again.
//          for(int i=0; i<int(kSamples); i++)
			{
				float height = length(samplePoint);
				float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
				float lightAngle = dot(lightPos, samplePoint) / height;
				float cameraAngle = dot(eyeRay, samplePoint) / height;
				float scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
				float3 attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));

				frontColor += attenuate * (depth * scaledLength);
				samplePoint += sampleRay;
			}
			{
				float height = length(samplePoint);
				float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
				float lightAngle = dot(lightPos, samplePoint) / height;
				float cameraAngle = dot(eyeRay, samplePoint) / height;
				float scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
				float3 attenuate = exp(-clamp(scatter, 0.0, kMAX_SCATTER) * (kInvWavelength * kKr4PI + kKm4PI));

				frontColor += attenuate * (depth * scaledLength);
				samplePoint += sampleRay;
			}



			// Finally, scale the Mie and Rayleigh colors and set up the varying variables for the pixel shader
			half3 cIn = frontColor * (kInvWavelength * kKrESun);
			half3 cOut = frontColor * kKmESun;

            // if we want to calculate color in vprog:
            // 1. in case of linear: multiply by _Exposure in here (even in case of lerp it will be common multiplier, so we can skip mul in fshader)
            // 2. in case of gamma and SKYBOX_COLOR_IN_TARGET_COLOR_SPACE: do sqrt right away instead of doing that in fshader

            OUT.skyColor    = _FallbackExposure * (cIn * getRayleighPhase(lightPos, -eyeRay));

        #if defined(UNITY_COLORSPACE_GAMMA) && SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            OUT.skyColor    = sqrt(OUT.skyColor);
        #endif

            return OUT;
        }


        half4 frag (v2f IN) : SV_Target
        {
            half3 col = half3(0.0, 0.0, 0.0);

            // if we did precalculate color in vprog: just do lerp between them
            col = IN.skyColor * _FallbackLuminanceMultiply + _FallbackLuminanceShift;

        #if defined(UNITY_COLORSPACE_GAMMA) && !SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
            col = LINEAR_2_OUTPUT(col);
        #endif

            return half4(col,1.0);

        }
        ENDCG
	}
	
	Pass
	{
		Blend One One
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		#include "Noise.cginc"
	
		uniform float4x4 _RotateMatrix;
		uniform float _StarDistribScale;
		uniform float _StarDistribSharpness;
		uniform float _StarScale;
		uniform float _StarSharpness;
		uniform float _StarLuminance;

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float4 pos : TEXCOORD0;
		};

		v2f vert (float4 vertex : POSITION)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(vertex);
			o.pos = vertex;
			return o;
		}

		fixed4 frag (v2f i) : SV_Target
		{
			float3 position = mul(i.pos, _RotateMatrix);
			float n0 = pow(gradNoise(position * _StarDistribScale) * 0.5 + 0.5, _StarDistribSharpness);
			float n1 = pow(1 - cellularNoise(position * _StarScale), _StarSharpness);
			return max(0, n0 * n1 * _StarLuminance);
		}
		ENDCG
	}
}

Fallback Off
}