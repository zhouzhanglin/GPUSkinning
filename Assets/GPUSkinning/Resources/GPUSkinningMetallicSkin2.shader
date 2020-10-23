Shader "GPUSkinning/GPUSkinning_Metallic_Skin2"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}
     
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
 
        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}
 
        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}
 
        _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" {}
 
        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}
 
        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}
     
        _DetailMask("Detail Mask", 2D) = "white" {}
 
        _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
        _DetailNormalMapScale("Scale", Float) = 1.0
        _DetailNormalMap("Normal Map", 2D) = "bump" {}
 
        [Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0
 
 
        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }
 
CGINCLUDE
    // You may define one of these to expressly specify it.
    // #define UNITY_BRDF_PBS BRDF1_Unity_PBS
    // #define UNITY_BRDF_PBS BRDF2_Unity_PBS
    // #define UNITY_BRDF_PBS BRDF3_Unity_PBS
 
    // You can reduce the time to compile by constraining the usage of eash features.
    // Corresponding shader_feature pragma should be disabled.
    // #define _NORMALMAP 1
    // #define _ALPHATEST_ON 1
    // #define _EMISSION 1
    // #define _METALLICGLOSSMAP 1
    // #define _DETAIL_MULX2 1
ENDCG
 
    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 300
 
        // It seems Blend command is getting overridden later
        // in the processing of  Surface shader.
        // Blend [_SrcBlend] [_DstBlend]
        ZWrite [_ZWrite]
 
    CGPROGRAM
        #pragma target 3.0
        // TEMPORARY: GLES2.0 temporarily disabled to prevent errors spam on devices without textureCubeLodEXT
        #pragma exclude_renderers gles
 
 
        #pragma shader_feature _NORMALMAP
        #pragma shader_feature _ALPHATEST_ON
        #pragma shader_feature _EMISSION
        #pragma shader_feature _METALLICGLOSSMAP
        #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        #pragma skip_variants _PARALLAXMAP _DETAIL_MULX2 _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
 
        // may not need these (not sure)
        // #pragma multi_compile_fwdbase
        // #pragma multi_compile_fog
 
        #pragma surface surf Standard vertex:myvert finalcolor:final fullforwardshadows // Opaque or Cutout
        // #pragma surface surf Standard vertex:vert finalcolor:final fullforwardshadows alpha:fade // Fade
        // #pragma surface surf Standard vertex:vert finalcolor:final fullforwardshadows alpha:premul // Transparent

		#pragma multi_compile_instancing
		#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF

        #include "Assets/GPUSkinning/Resources/GPUSkinningSurface.cginc"
		#include "Assets/GPUSkinning/Resources/GPUSkinningInclude.cginc"

        void myvert (inout appdata_vert v, out Input o) 
        {
		   UNITY_INITIALIZE_OUTPUT(Input,o);
		   o.texcoords.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0

		   // Skinning
		   {
				float4 normal = float4(v.normal, 0);
				float4 tangent = float4(v.tangent.xyz, 0);

				float4 pos = skin2(v.vertex, v.uv1, v.uv2);
				normal = skin2(normal, v.uv1, v.uv2);
				tangent = skin2(tangent, v.uv1, v.uv2);

				v.vertex = pos;
				v.normal = normal.xyz;
				v.tangent = float4(tangent.xyz, v.tangent.w);
		   }
		}
    ENDCG
 
        // For some reason SHADOWCASTER works. Not ShadowCaster.
        // UsePass "Standard/ShadowCaster"

        //=====================
        //投影的计算Pass，假阴影
		// Pass
		// {
		// 	Name "Shadow"

		// 	Stencil
		// 	{
		// 		Ref 0
		// 		Comp equal
		// 		Pass incrWrap
		// 		Fail keep
		// 		ZFail keep
		// 	}

		// 	Blend SrcAlpha OneMinusSrcAlpha
		// 	ZWrite Off
		// 	Cull back
		// 	Offset -1, 0

		// 	CGPROGRAM
		// 	#pragma vertex vert
		// 	#pragma fragment frag
		// 	#pragma multi_compile_instancing
		// 	#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF

		// 	#include "Lighting.cginc"
		//     #include "Assets/GPUSkinning/Resources/GPUSkinningInclude.cginc"

        //     struct appdata
        //     {
        //         float4 vertex : POSITION;
        //         float2 uv : TEXCOORD0;
        //         float4 uv2 : TEXCOORD1;
        //         float4 uv3 : TEXCOORD2;
        //         UNITY_VERTEX_INPUT_INSTANCE_ID
        //     };

		// 	struct v2f
		// 	{
		// 		float4 pos : SV_POSITION;
		// 	};

		// 	UNITY_INSTANCING_BUFFER_START(Prop)
		// 	UNITY_DEFINE_INSTANCED_PROP(float, _shadowY)
		// 	UNITY_INSTANCING_BUFFER_END(Prop)

		// 	inline float3 ShadowProjectPos(float4 vertPos)
		// 	{
		// 		float3 shadowPos;
		// 		float3 worldPos = mul(unity_ObjectToWorld, vertPos).xyz/vertPos.w;
		// 		float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

		// 		float y = UNITY_ACCESS_INSTANCED_PROP(Prop,_shadowY);
		// 		shadowPos.y = min(worldPos.y, y);
		// 		shadowPos.xz = worldPos.xz - lightDir.xz * max(0, worldPos.y - y) / lightDir.y;
		// 		return shadowPos;
		// 	}

		// 	v2f vert(appdata v)
		// 	{
		// 		UNITY_SETUP_INSTANCE_ID(v);
		// 		v2f o;
		// 		//通过skin2得到顶点在物体自身坐标系的位置信息
		// 		float4 position = skin2(v.vertex, v.uv2, v.uv3);
		// 		float3 shadowPos = ShadowProjectPos(position);
		// 		o.pos = UnityWorldToClipPos(shadowPos);
		// 		return o;
		// 	}

		// 	fixed4 frag(v2f i) : SV_Target
		// 	{
		// 		return fixed4(0,0,0,(1-_LightShadowData.x)*0.3);
		// 	}
		// 	ENDCG
		// }

        //实时阴影，真阴影
		pass 
		{
			Tags{ "LightMode" = "ShadowCaster" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			// #pragma multi_compile_shadowcaster

			#pragma multi_compile_instancing
			#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF

			#include "UnityCG.cginc"
			#include "Assets/GPUSkinning/Resources/GPUSkinningInclude.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
	
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos:SV_POSITION;
			};

			v2f vert(appdata v) 
			{
				UNITY_SETUP_INSTANCE_ID(v);

				v2f o;
				//通过skin2得到顶点在物体自身坐标系的位置信息
				v.vertex = skin2(v.vertex, v.texcoord1, v.texcoord2);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}

			float4 frag(v2f o) :SV_Target
			{
				SHADOW_CASTER_FRAGMENT(o)
			}

			ENDCG
		}



    }
    FallBack Off
    CustomEditor "GPUSkinningStandardShaderGUI"
}