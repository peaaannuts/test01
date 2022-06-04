Shader "Noriben/GlareTwinkle"
{
	Properties
	{
		_Color("Color", Color) = (1, 0, 0, 1)
		_Opacity("Opacity", Range(0, 1)) = 0.5

		//半径
		_Radius("Radius", Range(0, 5)) = 0.5
		_RadiusCenter("RadiusCenter", Range(0, 5)) = 0.5

		_flash ("Flash", Range(0,1)) = 1
		_flashspeed ("Flash speed", Range(0,64)) = 1
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
				float2 uv : TEXCOORD0;
				float4 vertexColor : COLOR; //頂点カラー
				float4 custom1 : TEXCOORD1; //custom vertex stream用
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD3;
				float4 vertexColor : COLOR; //頂点カラー
				float4 custom1 : TEXCOORD1; //custom vertex stream用
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			fixed4 _Color;
			float _Radius;
			float _Opacity;
			float _RadiusCenter;
			float _flash;
			float _flashspeed;
			
			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.vertexColor = v.vertexColor;
				o.custom1 = v.custom1;
				o.uv = v.uv.xy;
				return o;
			}

			//1D random
            float rand1d(float t)
            {
                return frac(sin(t) * 100000.);
            }
            
            //2D random
            float rand2d (float2 p) 
            { 
                return frac(sin(dot(p, fixed2(12.9898,78.233))) * 43758.5453);
            }

            //1D perlin noise
            float noise1d(float t)
            {
                float i = floor(t);
                float f = frac(t);
                return lerp(rand1d(i),rand1d(i + 1.), smoothstep(0., 1. , f));
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
				float3 centerColor = float3(centerCircle, centerCircle, centerCircle) * centerClip;

				//noise
				float particlePosRandom = i.custom1.y + i.custom1.z + i.custom1.w;
				float noise = noise1d(_Time.y * _flashspeed * particlePosRandom);
				noise = lerp(1., noise, i.custom1.x);
				noise = lerp(1., noise, _flash);

				color = pow(color, 1.1);
				centerColor = pow(centerColor, 1.2);

				color = saturate((color + centerColor) * noise * i.vertexColor.a);



				float4 Emissive = float4(color, 1.0);

				return Emissive;
				
				
			}
			
			ENDCG
		}
	}
}
			
