// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/geomety"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	_FurFactor("FurFactor", Range(0.01, 0.05)) = 0.02
	}
		SubShader
	{
		Tags{ "RenderType" = "Opaque" }
		LOD 100

		Pass
	{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma geometry geom

#include "UnityCG.cginc"

		struct appdata
	{
		float4 vertex : POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
	};

	struct v2g
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float2 uv : TEXCOORD0;
        float3 worldpostion  :TEXCOORD1; 
	};

	struct g2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		//fixed4 col : COLOR;
        float3 normal :NORMAL ; 

	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	float _FurFactor;

	v2g vert(appdata_base v)
	{
		v2g o;
		o.vertex =UnityObjectToClipPos(v.vertex);
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.normal = v.normal;
        o.worldpostion = mul(unity_ObjectToWorld, v.vertex).xyz ;
		return o;
	}

	[maxvertexcount(3)]
	void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
	{
		g2f o;

		float3 edgeA = IN[1].worldpostion - IN[0].worldpostion;
		float3 edgeB = IN[2].worldpostion - IN[0].worldpostion;
		float3 normalFace = normalize(cross(edgeA, edgeB));
        for (int i =0 ;i<3 ; i++)
        {
            o.normal = normalFace ;
            o.vertex =  IN[i].vertex ;
            o.uv = IN[i].uv ;

            tristream.Append(o);
        }

        
	
	}


	fixed4 frag(g2f i) : SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.uv) ;
        float3 lightdir =- _WorldSpaceLightPos0.xyz;
        float nol = dot (i.normal , normalize(lightdir)) ; 
        


	return col*nol;
	}
		ENDCG
	}
	}
}
