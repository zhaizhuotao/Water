Shader "ZhaiZhuoTao/Water/FakingLiquidShader" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
        [NoScaleOffset]_FlowMap("Flow Map(RG)",2D)="white"{}
        [NoScaleOffset]_NormalMap("Normals",2D) = "bump"{}
        _Tiling ("Tiling", Float) = 1
        _Speed ("Speed",Float) = 1
        _GridResolution("Grid Resolution",Float) = 10
        _FlowStrength("FlowStrength",Float) = 1
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
        sampler2D _NormalMap;
        float _Tiling;
        float _Speed;
        float _FlowStrength;
        float _GridResolution;
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
        float2 DirectionalFlowUV(float2 uv,float3 flowVectorAndSpeed,float tiling,float time,out float2x2 rotation){
            float2 dir = normalize(flowVectorAndSpeed.xy);
            rotation = float2x2(dir.y,dir.x,-dir.x,dir.y);
            uv = mul(float2x2(dir.y,-dir.x,dir.x,dir.y),uv);
            uv.y -= time * 0.01;
            return uv * tiling;
        }
        float3 UnpackDerivativeHeight(float4 textureData)
        {
            float3 dh = textureData.agb;
            dh.xy = dh.xy * 2 - 1;
            return dh;
        }
        float3 FlowCell(float2 uv,float2 offset,float time)
        {
            float2 shift = 1 - offset;
            shift *= 0.5;
            offset *= 0.5;
            float2x2 derivRotation;
            float2 uvTiled = (floor(uv * _GridResolution + offset)+shift) / _GridResolution;
            float3 flow = tex2D(_FlowMap,uvTiled * 0.5).rgb;
            flow.xy = flow.xy * 2 -1;
            flow.z *= _FlowStrength;
            float2 uvFlow = DirectionalFlowUV(uv + offset,flow,_Tiling,time,derivRotation);
            float3 dh = UnpackDerivativeHeight(tex2D(_MainTex,uvFlow));
            dh.xy = mul(derivRotation,dh.xy);
            return dh;
        }
        float3 FlowGrid(float2 uv,float time)
        {
            float3 dhA = FlowCell(uv,float2(0,0),time);
            float3 dhB = FlowCell(uv,float2(1,0),time);
            float3 dhC = FlowCell(uv, float2(0, 1), time);
            float3 dhD = FlowCell(uv, float2(1, 1), time);
            float2 t = abs(2 * frac(uv * _GridResolution) - 1);
            float wA = (1 - t.x)*(1-t.y);
            float wB = t.x*(1-t.y);
            float wC = (1 - t.x)*t.y;
            float wD = t.x*t.y;
            return dhA * wA + dhB * wB + dhC * wC + dhD * wD;
        }
		void surf (Input IN, inout SurfaceOutputStandard o) 
        {
            float time = _Time.y * _Speed;
            float3 dh = FlowGrid(IN.uv_MainTex,time);
            fixed4 c = dh.z * dh.z * _Color;
			o.Albedo = c.rgb;
            o.Normal = normalize(float3(-dh.xy,1));
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
