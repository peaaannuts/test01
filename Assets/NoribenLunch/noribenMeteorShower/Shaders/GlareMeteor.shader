Shader "Noriben/GlareMeteor"
{
	Properties
	{
		_Color("Color", Color) = (1, 0, 0, 1)
		_Opacity("Opacity", Range(0, 1)) = 0.5

		//半径
		_Radius("Radius", Range(0, 5)) = 0.5
		_RadiusCenter("RadiusCenter", Range(0, 5)) = 0.5
	}
	
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
			"RenderType"="Transparent"
		}
		
				LOD 100
		Cull Off
		ZWrite Off
		Blend One One
		
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD;
				float4 vertexColor : COLOR; //頂点カラー
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD;
				float4 vertexColor : COLOR; //頂点カラー
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			fixed4 _Color;
			fixed _Radius;
			float _Opacity;
			fixed _RadiusCenter;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertexColor = v.vertexColor;
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				
				float circle = 0.1 * _Radius / distance(i.uv, float2(0.5, 0.5));
				float centerCircle = 0.1 * _RadiusCenter / distance(i.uv, float2(0.5, 0.5));

				float clip = 1.0 - smoothstep(0.01, 0.5, distance(i.uv, float2(0.5, 0.5)));
				float centerClip = 1.0 - smoothstep(0.0001, 0.1, distance(i.uv, float2(0.5, 0.5)));

				float3 color = float3(circle, circle, circle) * _Color  * clip * _Opacity * i.vertexColor; 
				float3 centerColor = float3(centerCircle, centerCircle, centerCircle) * centerClip * i.vertexColor;
				color = saturate(color + centerColor);
				float4 Emissive = float4(float3(color), 1.0);
				//float4 Emissive = float4(float3(centerColor), 1.0);

				return Emissive;
				
				
			}
			
			ENDCG
		}
	}
}
			
