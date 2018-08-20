Shader "ZhaiZhuoTao/Water/FakingLiquidShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        [NoScaleOffset]_FlowMap("Flow Map(RG)",2D)="white"{}
        _UJump("U Jump",Range(-0.25,0.25)) = 0.25
        _VJump("V Jump",Range(-0.25,0.25)) = 0.25
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
        sampler2D _FlowMap;
		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
        float _UJump,_VJump;
		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)
        float3 FlowUVW(float2 uv,float2 flowVector,float2 jump,float time,bool flowB){
            float phaseOffset = flowB? 0.5:0;
            float progress = frac(time + phaseOffset);
            float3 uvw;
            uvw.xy = uv - flowVector * progress + phaseOffset;
            uvw.xy += (time - progress) * jump;
            uvw.z = 1 - abs(1-2*progress);
            return uvw;
        }
		void surf (Input IN, inout SurfaceOutputStandard o) {
            float2 flowVector = tex2D(_FlowMap,IN.uv_MainTex).rg *2 -1;
            float noise = tex2D(_FlowMap,IN.uv_MainTex).a;
            float time = _Time.y * noise;
            float2 jump = float2(_UJump,_VJump);
            float3 uvwA = FlowUVW(IN.uv_MainTex,flowVector,jump,time,false);
            float3 uvwB = FlowUVW(IN.uv_MainTex,flowVector,jump,time,true);
            fixed4 texA = tex2D(_MainTex,uvwA.xy)*uvwA.z;
            fixed4 texB = tex2D(_MainTex,uvwB.xy)*uvwB.z;
			// Albedo comes from a texture tinted by color
			fixed4 c = (texA + texB) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
