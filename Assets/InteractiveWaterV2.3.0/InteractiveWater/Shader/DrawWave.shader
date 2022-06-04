/*
InteractiveWater v2.3.0 zlib license
----
Copyright (c) <2020> <らくとあいす>

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

   1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

   2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

   3. This notice may not be removed or altered from any source
   distribution.
*/

Shader "Custom/DrawWave" {
	Properties {
		_WaterColor ("Color", Color) = (0.1,0.1,0.2,1)
		_WaveTex ("Wave Texture", 2D) = "white" {}
		_WaveEffTex ("WaveEffectTex",2D) = "black" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_inverce ("inverce",Range(0,1)) = 0.0
		_Emission ("Emission",Range(0,1)) = 1.0
	}
	SubShader{
		Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 200
		stencil {
                Ref 1
                Comp Greater
                //Pass keep
       }
		CGPROGRAM

		#pragma surface surf Standard alpha addshadow fullforwardshadows
		#pragma target 3.0

		sampler2D _WaveTex;
		sampler2D _WaveEffTex;
		float4 _WaveTex_TexelSize;

		struct Input {
			float2 uv_WaveTex;
			float2 uv_WaveEffTex;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _WaterColor;
		half _inverce;
		half _CamSwitch;
		float _Emission;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed2 readuv;
			if(_inverce < 0.5){
				readuv = IN.uv_WaveTex;
			}
			else{//裏面用の処理
				readuv = fixed2(1.0 - IN.uv_WaveTex.x,IN.uv_WaveTex.y);
			}

			fixed4 wavecol = tex2D (_WaveTex, readuv);
			float waveh = wavecol.r;
			float waveh_b = wavecol.g;
			float effect = wavecol.b;
			float dh = length(waveh - waveh_b);
	
			o.Albedo = _WaterColor.rgb+fixed3(0.5,0.5,0.3)*saturate(waveh - 0.6);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = _WaterColor.a + 0.2*waveh + saturate(waveh - 0.7)*5.0*dh;
			o.Emission += _Emission*0.5*waveh*fixed3(dh,dh,dh)+saturate(waveh - 0.8)*2.0*dh;
			if(waveh>0.3&&dh>0.05) o.Emission += _Emission*(waveh-0.3)*(dh-0.05)*5.0*tex2D(_WaveEffTex,readuv*200.0);
			float pix = _WaveTex_TexelSize.x;

			float3 duv = float3(pix,pix, 0);
			float v1 = tex2D(_WaveTex, readuv - duv.xz).y;
			float v2 = tex2D(_WaveTex, readuv + duv.xz).y;
			float v3 = tex2D(_WaveTex, readuv - duv.zy).y;
			float v4 = tex2D(_WaveTex, readuv + duv.zy).y;
			o.Normal = normalize(float3(v1 - v2, v3 - v4, 0.3));
		}
		ENDCG
	}
	FallBack "Diffuse"
}
