#Shader的学习  
-  
##一、SnowTrack(雪跟踪)  
###前言  
这篇小文简单介绍一下如何在Unity中利用shader很简单的实现雪地效果。   
###01 雪地痕迹的效果  
实现雪地印痕的思路其实也很简单吗，既记录玩家移动过程中的位置，之后再根据这些数据修改雪地的mesh即可。   
###02 工程实现 
   ![](https://connect-cdn-china2.unity.com/p/images/2ede2343-4b9b-4a10-84af-33dbd784ab98_1372105_6f21566a9dabda3b.png)  
所以，很简单的，我们在unity中只需要一个玩家头顶上的正交相机和一个rendertexture就可以记录玩家的移动过程中的位置了。  
  
之后再shader文件中先用vs根据rendertexture的数据修改雪地mesh的相关顶点位置，同时为了更方便地实现光照效果，接下来使用surface shader,实现光照。  
  
全部代码如下所示：      

		Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_SnowTrackTex ("SnowTrackTex", 2D) = "white" {}
		_NormalMap ("NormalMap", 2D) = "bump" {}
		_SnowTrackFactor("SnowTrackFactor", float) = 0
	}

	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard addshadow fullforwardshadows vertex:vert

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		sampler2D _SnowTrackTex;
		sampler2D _NormalMap;

		float _SnowTrackFactor;

		struct Input {
			float2 uv_MainTex;
		};

		void vert(inout appdata_full vertex)
		{
			vertex.vertex.y -= tex2Dlod(_SnowTrackTex, float4(vertex.texcoord.xy, 0, 0)).r * _SnowTrackFactor;
		}


		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
 
###03 效果图 
![](https://connect-cdn-china2.unity.com/p/images/f608869a-6bb4-4f32-bac0-467b44426661_633433.gif)  
  
###04 demo地址  


##二、Stanford-Bunny-Fur-With-Unity（斯坦福兔子）  
###前言  
这篇小文简单介绍一下如何在Unity中利用shader很简单的实现毛皮效果。  
![](https://connect-cdn-china2.unity.com/p/images/8e8df8f0-9657-4e99-a35c-d4e4745ebcc4_QQ__20171123150603.png)
###01 斯坦福兔子和它的毛  
我相信对图形学感兴趣的一定经常会见到这个上镜率超高的兔子。  
![](https://connect-cdn-china2.unity.com/p/images/25254b0a-8517-4678-9d60-060ff83de15c_1372105_6f239ae85bdc89ae.jpg)    
关于它的典故各位可以看看[斯坦福兔子模型的来源和故事有哪些？](https://www.zhihu.com/question/59064928/answer/161403817)  
###02 工程实现  
接下来就开始我们对兔子的改造行动吧。  
1. 是否需要皮毛的网格数据呢？  
答案：是  
2. 皮毛的网格要根据什么来生成呢？
要生在兔子身上，所以兔子的原始网格信息提供了皮毛的网格信息。   
3. 那么具体要怎么做？  
很简单，Geometry Shader就是干这个的。而我们只需要根据兔子的网格信息，以每一个triangle为一个单位，在这个triangle上生成一个向外指的"金字塔" 就可以了。  
![](https://connect-cdn-china2.unity.com/p/images/087b7274-11b4-416a-ad28-6d4709e7cad6_1372105_c6f23c9e2926ca8d.png)   
也就是说，在原有triangle的基础上有新生成了3个指向外向triangle，形成毛皮的效果。  
代码如下：  
     
	 Shader "Unlit/aiting_Shader-s"
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
	};

	struct g2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		fixed4 col : COLOR;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;

	float _FurFactor;

	v2g vert(appdata_base v)
	{
		v2g o;
		o.vertex = v.vertex;
		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
		o.normal = v.normal;
		return o;
	}

	[maxvertexcount(9)]
	void geom(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
	{
		g2f o;

		float3 edgeA = IN[1].vertex - IN[0].vertex;
		float3 edgeB = IN[2].vertex - IN[0].vertex;
		float3 normalFace = normalize(cross(edgeA, edgeB));

		float3 centerPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;
		float2 centerTex = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;
		centerPos += float4(normalFace, 0) * _FurFactor;

		for (uint i = 0; i < 3; i++)
		{
			o.vertex = UnityObjectToClipPos(IN[i].vertex);
			o.uv = IN[i].uv;
			o.col = fixed4(0., 0., 0., 1.);

			tristream.Append(o);

			uint index = (i + 1) % 3;
			o.vertex = UnityObjectToClipPos(IN[index].vertex);
			o.uv = IN[index].uv;
			o.col = fixed4(0., 0., 0., 1.);

			tristream.Append(o);

			o.vertex = UnityObjectToClipPos(float4(centerPos, 1));
			o.uv = centerTex;
			o.col = fixed4(1.0, 1.0, 1.0, 1.);

			tristream.Append(o);

			tristream.RestartStrip();
		}
	}


	fixed4 frag(g2f i) : SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.uv) * i.col;
	return col;
	}
		ENDCG
	}
	}
    }
###03 效果图
  因此总共会生成9个顶点，三个新三角形共同组成一根毛。  
![](https://connect-cdn-china2.unity.com/p/images/ff6b9c23-8e8c-44a8-a40e-c88014b83edb_1372105_b9b414a85859453e.png)  
  
###04 demo地址  
  [https://github.com/chenjd/Stanford-Bunny-Fur-With-Unity](https://github.com/chenjd/Stanford-Bunny-Fur-With-Unity)


##三、Explosion and sand effect（爆炸和砂效果）   
###前言 
这篇文章继续沿用了同样来自斯坦福的另一个模型Armadillo，同样也使用了geometry shader来实现效果的表现。  
###01 凶恶的怪物和爆炸
当然，用之前的斯坦福兔子的模型做爆炸的效果也是可以的，但是考虑到要让一个那么可爱的模型变成沙砾总觉得不太好，所以长相自带怪物属性的模型Armadillo就成了一个不错的选择。  
![](https://connect-cdn-china2.unity.com/p/images/425e4536-76d9-409b-9a0a-606cb2099261_1372105_a153a5ae2a8fce1d.png)      

不过另一个让我选择Armadillo的原因其实是因为它的面数和顶点数相对来说更多，可以看到它有106289个顶点和212574个多边形组成，所以用来做爆炸成为沙砾的效果要更好。  
![](https://connect-cdn-china2.unity.com/p/images/9d74de70-f02e-4d5b-aa8c-1d253c75f609_1372105_aef84155ecf8b139.png)   
###02 工程实现    
 现在让我们把Armadillo的obj文件导入到Unity内，可以看到这个怪物已经站立在我们的场景内了。接下来我们就要利用geometry shader来实现我们想要的爆炸沙粒化的效果了。
![](https://connect-cdn-china2.unity.com/p/images/6c7675ac-dee1-45be-8e23-e413eda09792_1372105_e0f2d554102f2c29.png)    

之前提到Geometry Shader的时候，往往是利用它来生成更多新的顶点和多边形来实现我们期望的效果，例如利用它在GPU上生成草体，实现真实草的实时渲染。  

但是Geometry Shader不仅可以生成新的图元，同时它还可以减少顶点和多边形的输出，以实现一些有趣的效果，比如这篇小文章的例子，利用Geometry Shader来实现怪兽的爆炸和沙粒化效果。  
![](https://connect-cdn-china2.unity.com/p/images/fe6ca271-2c14-4478-930d-6045fc24c520_1372105_998db7d484bd4685.png)
 
  而我们要做的也很简单，就是在Geometry Shader内将输入的由3个顶点组成的三角形图元修改为只有一个顶点组成的点图元。而输出的这个点的坐标我们可以很简单的使用三角形的中心点坐标。    
  
 这样，组成怪兽的网格就由三角形图元变成了点图元，而且顶点数量也随之减少，至于怪物本身也变成了下面这个样子。  
![](https://connect-cdn-china2.unity.com/p/images/ea3470fa-b7af-4bf7-b9e2-4493f97e27e1_1372105_02f254f6b2661356.png)    
但是这个时候的模型是静止的，因此也看不出爆炸甚至是沙砾的效果。所以接下来我们就要让怪物的模型随着时间运动起来。
而一个大家都知道的运动学公式就可以用来实现这个效果：
![](https://connect-cdn-china2.unity.com/p/images/c5423ccc-be56-469c-a437-b39ba190d5d2_1372105_8aebee9bd63574b3.png)  

其中的S就是顶点的最新位置，v0和a的值可以作为一个uniform变量传入shader，运动方向可以是沿着三角形的法线方向，而t的来源则是Unity内置的变量_Time的y分量。
这样，需要的几个变量我们就有了：之后只要带入运动学公式就好了。  
  
代码如下：  
     
	using System.Collections;
	using System.Collections.Generic;
	using UnityEngine;

	public class Test : MonoBehaviour
	{

    public Material ExplosionMaterial;

    private bool isClicked;



    void Update()
    {
        if (this.isClicked || this.ExplosionMaterial == null)
        {
            return;
        }

        if (Input.GetMouseButton(0))
        {
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            RaycastHit Hit;
            if (Physics.Raycast(ray, out Hit))
            {
                MeshRenderer[] renderers = Hit.collider.GetComponentsInChildren<MeshRenderer>();
                this.ExplosionMaterial.SetFloat("_StartTime", Time.timeSinceLevelLoad);

                for (int i = 0; i < renderers.Length; i++)
                {
                    renderers[i].material = this.ExplosionMaterial;
                }
                this.isClicked = true;
            }
        }
    }
	}  
  
    
  
  

shader代码：  

	Shader "Unlit/aiting_shader-m"
	{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Speed("Speed", Float) = 10
		_AccelerationValue("AccelerationValue", Float) = 10
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
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
			};

			struct v2g
			{
				float2 uv : TEXCOORD0;
				float4 vertex : POSITION;
			};

			struct g2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;

			float _Speed;
			float _AccelerationValue;
			float _StartTime;
			
			v2g vert (appdata v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = v.uv;
				return o;
			}

			[maxvertexcount(1)]
			void geom(triangle v2g IN[3], inout PointStream<g2f> pointStream)
			{
				g2f o;

				float3 v1 = IN[1].vertex - IN[0].vertex;
				float3 v2 = IN[2].vertex - IN[0].vertex;

				float3 norm = normalize(cross(v1, v2));

				float3 tempPos = (IN[0].vertex + IN[1].vertex + IN[2].vertex) / 3;

				float realTime = _Time.y - _StartTime;
				tempPos += norm * (_Speed * realTime + .5 * _AccelerationValue * pow(realTime, 2));

				o.vertex = UnityObjectToClipPos(tempPos);

				o.uv = (IN[0].uv + IN[1].uv + IN[2].uv) / 3;

				pointStream.Append(o);
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				return col;
			}
			ENDCG
		}
	}
	}  
###03 效果图  

![](https://connect-cdn-china2.unity.com/p/images/446030d7-d8b7-4a41-bb3e-968c4e2c52cb_20171201232150.gif)  
  
###04 demo地址  

[https://github.com/chenjd/Unity-Miscellaneous-Shaders](https://github.com/chenjd/Unity-Miscellaneous-Shaders)  
  
##Unity-Boids-Behavior-on-GPGPU（海鸥群/鱼群）  
###前言  
在今年六月的Unity Europe 2017大会上unity的CTO Joachim Ante演示了未来unity新的编程特性--C#	Job系统，它提供了编写多线程代码的一种既简单又安全的方法。Joachim通过一个大规模群落行为仿真的演示，向我们展现了最新的Job系统是如何充分利用CPU多核架构的优势来提升性能的。  
![](https://connect-cdn-china2.unity.com/p/images/572da736-b90b-47c7-b87c-661a82d34296_5.gif)  
但是吸引我的并非是C# Job如何利用多线程实现性能的提升，相反，吸引我的是如何在现在还没有C# Job系统的Unity中实现类似的效果。
在Ante的session中，他的演示主要是利用多核CPU提高计算效率来实现大群体行为。那么我就来演示一下，如何利用GPU来实现类似的目标吧。利用GPU做一些非渲染的计算也被称为GPGPU——General-purpose computing on graphics processing units，图形处理器通用计算。  
###01 CPU的限制  
为何Joachim 要用这种大规模群落行为的仿真来宣传Unity的新系统呢？
其实相对来说复杂的并非逻辑，这里的关键词是“大规模”——在他的演示中，实现了20,000个boid的群体效果，而更牛逼的是帧率保持在了40fps上下。
事实上自然界中的这种群体行为并不罕见，例如大规模的鸟群，大规模的鱼群。  
![](https://connect-cdn-china2.unity.com/p/images/9a23de2e-0e39-409a-9dd7-652a21875304_wallpaper_of_a_flock_of_flying_birds_hd_bird_wallpapers.jpg)  
在搜集资料的时候，我还发现了一位优秀的水下摄影师、加利福尼亚海湾海洋计划总监octavio aburto的个人网站上的一些让人惊叹的作品。    
![](https://connect-cdn-china2.unity.com/p/images/2bf880a7-b388-43c0-9fe7-5cc84cd075f1_49df1e34044260.56de489a441af.jpg)
图片来自[OctavioAburto](http://octavioaburto.com/)  
而要在计算机上模拟出这种自然界的现象，乍看上去似乎十分复杂，但实际上却并非如此。
查阅资料，可以发现早在1986年就由Craig Reynolds提出了一个逻辑简单，而效果很赞的群体仿真模型——而作为这个群体内的个体的专有名词boid（bird-oid object，类鸟物）也是他提出的。
简单来说，一个群体内的个体包括3种基本的行为：  


- Separation：顾名思义，该个体用来规避周围个体的行为。  
<Center>![](https://connect-cdn-china2.unity.com/p/images/c39be0ed-c5b5-4680-b1fe-4e5b95dcbbb5_separation.gif)

- Alignment：作为一个群体，要有一个大致统一的前进方向。因此作为群体中的某个个体，可以根据自己周围的同伴的前进方向获取一个前进方向。  
  
<Center>![](https://connect-cdn-china2.unity.com/p/images/2f493ccc-6c95-41ae-ae69-3140e996f084_alignment.gif)  
-   Cohesion：同样，作为一个群体肯定要有一个向心力。否则队伍四散奔走就不好玩了，因此每个个体就可以根据自己周围同伴的位置信息获取一个向中心聚拢的方向。  
<Center>![](https://connect-cdn-china2.unity.com/p/images/03782ea7-1d2c-4974-93c0-b34b04772028_cohesion.gif)  
以上三种行为需要同时加以考虑，才有可能模拟出一个接近真实的效果。