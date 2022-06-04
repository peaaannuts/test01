/*
InteractiveWater v2.2.0 zlib license
----
Copyright (c) <2019> <らくとあいす>

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
Shader "Custom/DrawSand" {
	Properties {
		_SandColor ("Color", Color) = (0.1,0.1,0.2,1)
		_MainTex ("Main Texture", 2D) = "white" {}
		_SandTex ("Sand Texture", 2D) = "white" {}
		_SandEffTex ("SandEffectTex",2D) = "black" {}
		_InterTex ("Inter Tex", 2D) = "white" {}
		_inverce ("inverce",Range(0,1)) = 0.0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Emission ("Emission",Range(0,1)) = 1.0

		_WaterTex ("WaterHeightMapTexture", 2D) = "white" {}
		_LightAngle ("LightAngle", Range(-180,180)) = 0.0
		_nraf ("rafrect", Range(1.0,3.0)) = 1.5
		_height ("WaterHeight", Range(0.0,10.0)) = 0.5
	}
	SubShader{
		Tags { "Queue" = "Transparent-1" "RenderType" = "Opaque"}
		LOD 200
		
		CGPROGRAM

		#pragma surface surf Standard alpha addshadow fullforwardshadows
		#pragma target 3.0

		sampler2D _SandTex;
		sampler2D _MainTex;
		sampler2D _SandEffTex;
		sampler2D _WaterTex;
		sampler2D _InterTex;
		half _inverce;
		float4 _SandTex_TexelSize;
		float4 _WaterTex_TexelSize;

		struct Input {
			float2 uv_SandTex;
			float2 uv_MainTex;
			float2 uv_SandEffTex;
			float2 uv_WaterTex;
			float2 uv_InterTex;
			float3 worldPos;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _SandColor;
		float _Emission;
		float _LightAngle;
		float _nraf;
		float _height;

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		float avecol(float4 col){
			return (col.r+col.g*0.9+col.b*0.9*0.9+col.a*0.9*0.9*0.9)/3.0;
		}

		float2 WaterAngle(float pix,float4 Height){//Height(h(r+dx),h(r-dx),h(r+dy),h(r-dy))
			float thetax = atan((Height.x - Height.y)/(2.0*pix));
			float thetay = atan((Height.z - Height.w)/(2.0*pix));
			return float2(thetax,thetay);
		}

		float2 RafPos(float2 p,float2 theta_W,float2 theta_L,float h,float r){
			float2 theta_I = theta_L + theta_W;
			float2 theta_R = asin(sin(theta_I)/r);
			float2 theta_O = theta_R - theta_W;
			float2 pos = p - h*tan(theta_O);
			return pos;
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed2 readuv;
			readuv = fixed2(IN.uv_SandTex.x,1.0 - IN.uv_SandTex.y);
			fixed4 sandcol = tex2D (_SandTex, readuv);
			float sandh = sandcol.r;

			//*************Caustics Simulation***************//
			//ref https://www.shadertoy.com/view/MttBRS, https://qiita.com/kaneta1992/items/1f8d145e862391f37a99
			float pi = 3.141592;
			float deg2rad = pi/180.0;
			float n1 = 1.0;
			float n2 = _nraf;
			float r = n2/n1;
			float h = _height*0.1;
			float pix = _WaterTex_TexelSize.x*7.0;
			float3 duv =float3(pix,pix,0); 

	        float h0= avecol(tex2D(_WaterTex,IN.uv_WaterTex));
			float hxp = avecol(tex2D(_WaterTex,IN.uv_WaterTex+duv.xz));
			float hxpp = avecol(tex2D(_WaterTex,IN.uv_WaterTex+2.0*duv.xz));
			float hxm = avecol(tex2D(_WaterTex,IN.uv_WaterTex-duv.xz));
			float hyp = avecol(tex2D(_WaterTex,IN.uv_WaterTex+duv.zy));
			float hypp = avecol(tex2D(_WaterTex,IN.uv_WaterTex+2.0*duv.zy));
			float hym = avecol(tex2D(_WaterTex,IN.uv_WaterTex-duv.zy));
			
			float2 theta_W = WaterAngle(pix,float4(hxp,hxm,hyp,hym));
			float2 theta_Wxp = WaterAngle(pix,float4(hxpp,h0,hyp,hym));
			float2 theta_Wyp = WaterAngle(pix,float4(hxp,hxm,hypp,h0));

			float2 theta_L = _LightAngle*deg2rad;
			float2 pos = RafPos(IN.uv_WaterTex,theta_W,theta_L,h,r);
			float2 posdx = RafPos(IN.uv_WaterTex+duv.xz,theta_Wxp,theta_L,h,r);
			float2 posdy = RafPos(IN.uv_WaterTex+duv.zy,theta_Wyp,theta_L,h,r);

			float lx = length(pos - posdx); 
			float ly = length(pos - posdy); 
			float S = tanh(pow((pix*pix)/(lx*ly),1.3))*pow(h0,0.6);			
			S -= length(tex2D(_InterTex,IN.uv_InterTex))*0.8;
			S = clamp(S,0,0.8);
			//****************************n***************//

			o.Albedo = (1.0-0.7*sandh)*tex2D(_MainTex,IN.uv_MainTex)+sandh*tex2D(_SandEffTex,IN.uv_SandEffTex);
		    o.Albedo += o.Albedo*0.2 + o.Albedo*S;
			//Emission = clamp(S-0.5,0,1);
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = 1.0;
			float pix2 = _SandTex_TexelSize.x;
			float3 duv2 = float3(pix2,pix2, 0);
			float v1 = tex2D(_SandTex, readuv - duv2.xz).y;
			float v2 = tex2D(_SandTex, readuv + duv2.xz).y;
			float v3 = tex2D(_SandTex, readuv - duv2.zy).y;
			float v4 = tex2D(_SandTex, readuv + duv2.zy).y;
			o.Normal = normalize(float3(v2 - v1, v4 - v3, 0.3));
		}
		ENDCG
	}
	FallBack "Diffuse"
}
