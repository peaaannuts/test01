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

Shader "Unlit/WaveSimu"
{
	Properties
	{
		_ratio("Raion W:H",range(0,10)) = 1.0
		[Space(25)]
		_v ("velociy",Range (0,1)) = 0.5
		_k ("attenation",Range (0,1)) = 0.5
		_k2 ("attenation2",Range (0,1)) = 0.5
		[Space(25)]
		[MaterialToggle] _initnoise("Initialize with Constwave", Float) = 0
		_inten("Constwave Intensity",Range(0,1)) = 0.1
		_fine("Constwave Fineness",Range(0,1))=0.1
		_speed("Constwave Speed",Range(0,1))=0.1
		_octave("Constwave Otvaves",Range(1,10))=2.0
		[Space(25)]
		[NoScaleOffset] _InterTex("Interactive Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		LOD 100
		Pass
		{
			Name "Update"
			CGPROGRAM
		    #include "UnityCG.cginc"
		    #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag

			sampler2D _InterTex;

			float _v;
			float _k;
			float _k2;
			float _inverce;
			float _fine;
			float _inten;
			float _speed;
			float _octave;
			float _ratio;
			float _initnoise;
			
			float4 _Color;

			float2 random2(float2 st){
				st = float2( dot(st,float2(127.1,311.7)),
							   dot(st,float2(269.5,183.3)) );
				return -1.0 + 2.0*frac(sin(st)*(43758.5453123));
			}

		    float fade(float x1,float x2, float t){
				return (x2-x1)*(6.0*pow(t,5) - 15.0*pow(t,4) + 10.0*pow(t,3))+x1;
			}
	        //***********************************//
			//ref. https://github.com/edom18/PerlinNoiseSample

			float perlinNoise(float2 st) 
			{
				float2 p = floor(st);
				float2 f = frac(st);
				float2 u = f*f*(3.0-2.0*f);

				float v00 = random2(p+float2(0,0));
				float v10 = random2(p+float2(1,0));
				float v01 = random2(p+float2(0,1));
				float v11 = random2(p+float2(1,1));

				return fade( fade( dot( v00, f - float2(0,0) ), dot( v10, f - float2(1,0) ), u.x ),
							 fade( dot( v01, f - float2(0,1) ), dot( v11, f - float2(1,1) ), u.x ),  u.y)+0.5f;
			}

			float octaveNoise(float2 st,float octaves){
				float onoise = 1.0;
				float amp = 1.0;
				float freq = 1.0;
				float max = 0.0;
				for(int i=0;i<octaves;i++){
				    onoise+=perlinNoise(st*freq);
					freq*=2.0;
					max+=amp;
					amp*=0.5;
				}
				onoise = onoise/max;
				return onoise;
			}
		    //***********************************//

			float4 frag(v2f_customrendertexture i) : SV_Target
			{
				float2 uv = i.globalTexcoord;
				float size = _CustomRenderTextureHeight;
				float pix = 1.0/size;
				float x = uv.x;
				float y = uv.y;
				float v = _v*100/_CustomRenderTextureHeight;
				float k = _k*1.0;
				float k2 = 1.0 - _k2*0.1;
			    
				fixed3 col = fixed3(0,0,0);

				fixed3 pvcol = tex2D(_SelfTexture2D,float2(x,y));
				fixed3 pvcolxp = tex2D(_SelfTexture2D,float2(x+pix,y));
				fixed3 pvcolxm = tex2D(_SelfTexture2D,float2(x-pix,y));
				fixed3 pvcolyp = tex2D(_SelfTexture2D,float2(x,y+pix));
				fixed3 pvcolym = tex2D(_SelfTexture2D,float2(x,y-pix));
				
				float pv2u = pvcol.g;
				float pvu = pvcol.r;
				float pvuxp = pvcolxp.r;
				float pvuxm = pvcolxm.r;
				float pvuyp = pvcolyp.r; 
				float pvuym = pvcolym.r;
				
				float dt = 1.0/90.0;//Fixed dt
				float dx = pix*1.0;
				float dy = pix*1.0*_ratio;
				
				//BoundaryCondition
				if(x<pix) pvuxm = pvu;
			    if(x>1-pix) pvuxp = pvu;
			    if(y<pix) pvuym = pvu;
	            if(y>1-pix) pvuyp = pvu;
			
				//WaveEquation
				float u = 0.0;
				if(_Time.y<0.5){//InitialCondition
					if (_initnoise > 0.5) {
						u = 0.01*octaveNoise(uv*160.0*_fine + sin(_Time.y*3.0*_speed)*0.1 , _octave);
					}
					else u = 0.0;
				}
				else{
					u = (2*pvu - pv2u 
					  +((dt*dt*v*v)/(dx*dx))*(pvuxm-2*pvu+pvuxp)
					  +((dt*dt*v*v)/(dy*dy))*(pvuym-2*pvu+pvuyp))*k2
					  -k*dt*(pvu-pv2u);
				}
			    col = fixed3(u,pvcol.r,pvcol.g);
				float dh = length(pvcol.r - pvcol.g);
				col.r += length(tex2D(_InterTex,float2(x,y)));
				float noise = octaveNoise(uv*160.0*_fine + sin(_Time.y*20.0*_speed)*0.1 + float2(_Time.y*12.0*_speed, 0), _octave)-1.0;
				col.r += noise*0.001*_inten;//Add Noise
				return fixed4(col,col.b);
			}
			ENDCG
		}
	}
}