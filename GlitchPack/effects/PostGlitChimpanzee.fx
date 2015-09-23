//@author: vvvv group
//@help: this is a very basic template. use it to start writing your own effects. if you want effects with lighting start from one of the GouraudXXXX or PhongXXXX effects
//@tags:
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------


//original
float2 res;
float rand;
float val3 <string uiname="SlitVal"; float uimin=-.5; float uimax = .5;> = .1;
//float2 blur_vec <string uiname="blur_Vec"; float uimin = -.01; float uimax = .01;> = float2(.001, -.001);
float2 blur_vec <string uiname="blur_Vec";> = float2(.001, -.001);


//texture
texture Tex <string uiname="Texture";>;
texture getTex<string uiname="Control";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

sampler SampOff = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (getTex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = POINT;
};

//texture transformation marked with semantic TEXTUREMATRIX to achieve symmetric transformations
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

//the data structure: "vertexshader to pixelshader"
//used as output data with the VS function
//and as input data with the PS function
struct vs2ps
{
    float4 Pos  : POSITION;
    float2 TexCd : TEXCOORD0;
};

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

void vs2d(
	inout float4 vp:POSITION0,
	inout float2 uv:TEXCOORD0)
{
	vp.xy*=2;uv+=.5/res;
}


// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 gray(float4 col){
	const float4 lumcoeff = {.3, .59, .11, 0};
	return dot(col, lumcoeff);
}

float4 PS(vs2ps In): COLOR
{
    float4 col = tex2D(Samp, In.TexCd);
    return col;
}

float4 PS2(vs2ps In) :COLOR
{
	float4 offset = tex2D(SampOff, In.TexCd);
	float4 col = tex2D(Samp, float2(In.TexCd.x + offset.r, In.TexCd.y));
	return col;
}

//invert
float4 invert(vs2ps In) : COLOR
{
	float4 col = tex2D(Samp, In.TexCd);
	col.rgb = 1-col.rgb;
	return col;
}

float4 convergence(vs2ps In) : COLOR
{
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float4 col_r = tex2D(Samp, coord + float2(-35*rand, 0));
	float4 col_g = tex2D(Samp, coord + float2( 35*rand, 0));
	float4 col_b = tex2D(Samp, coord + float2(-7.5*rand, 0));
	col.r = col.r+col_r*max(1.0, sin(coord.y*1.2)*2.5)*rand;
	col.g = col.g+col_g*max(1.0, sin(coord.y*1.2)*2.5)*rand;
	col.b = col.b+col_b*max(1.0, sin(coord.y*1.2)*2.5)*rand;
	return col;
}

float4 slitScan(vs2ps In) : COLOR
{
	float pix_w = 1.0/res.x;
	float pix_h = 1.0/res.y;
	float slit_h = val3;
	float2 coord = float2(3.0+floor(In.TexCd.x / slit_h)*slit_h, In.TexCd.y);
	float4 col = tex2D(Samp, coord);
	return col;
}

float4 glow(vs2ps In) : COLOR
{
    float e = 2.718281828459045235360287471352;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	int blur_w = 8;
	float pi = 3.1415926535;
	float4 gws = {.0, .0, .0, 1.0};
	float weight;
	float k = 1.0;
	weight = 1.0/(float(blur_w)*2.0+1.0)/(float(blur_w)*2.0+1.0);
	for(int i=0; i<blur_w*blur_w; i++){
		gws = gws+tex2D(Samp, float2(coord.x+float(fmod(float(i),float(blur_w))), coord.y+float(i/blur_w)))*weight*1.3;
		gws = gws+tex2D(Samp, float2(coord.x-float(fmod(float(i),float(blur_w))), coord.y+float(i/blur_w)))*weight*1.3;
		gws = gws+tex2D(Samp, float2(coord.x+float(fmod(float(i),float(blur_w))), coord.y-float(i/blur_w)))*weight*1.3;
		gws = gws+tex2D(Samp, float2(coord.x-float(fmod(float(i),float(blur_w))), coord.y-float(i/blur_w)))*weight*1.3;
	}
	return col+gws;
}

float4 shaker (vs2ps In) : COLOR
{
	float pix_w = 1.0;
	float pix_h = 1.0;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float4 col_s[5], col_s2[5];
	
	blur_vec.x = clamp(blur_vec.x, -.01, .01);
	blur_vec.y = clamp(blur_vec.y, -.01, .01);
	
	for(int i=0; i<5; i++){
		col_s[i] = tex2D(Samp, coord + float2(-pix_w*float(i)*blur_vec.x, -pix_h*float(i)*blur_vec.y));
		col_s2[i] = tex2D(Samp, coord + float2(pix_w*float(i)*blur_vec.x, pix_h*float(i)*blur_vec.y));
	}
	col_s[0] = (col_s[0] + col_s[1] + col_s[2] + col_s[3] + col_s[4])/5.0;
	col_s2[0] = (col_s2[0] + col_s2[1] + col_s2[2] + col_s2[3] + col_s2[4])/5.0;
	col = (col_s[0] + col_s2[0])/2.0;
	return col;
}

// cutslider
float4 cutSlider(vs2ps In) : COLOR
{
	float pix_w = 1.0;
	float pix_h = 1.0;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float4 col_s = tex2D(Samp, coord+float2(floor(sin(coord.y/30.0*rand+rand*rand))*30.0 * rand, .0));
	col = col_s;
	return col;
}

//redraise
float4 redraise(vs2ps In) : COLOR
{
    float e = 2.718281828459045235360287471352;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float3 k = {.25, .2, .2};
	float3 max = {.8, 1.0, 1.0};
	float3 min = {.2, .0, .0};
	col.r = (1.0/(1+pow(e, (-k.r*((col.r*2)-1)*20)))*(max.r-min.r)+min.r);
	col.g = (1.0/(1+pow(e, (-k.g*((col.g*2)-1)*20)))*(max.g-min.g)+min.g);
	col.b = (1.0/(1+pow(e, (-k.b*((col.b*2)-1)*20)))*(max.b-min.b)+min.b);
	return col;
}

//greenraise
float4 greenraise(vs2ps In) : COLOR
{
    float e = 2.718281828459045235360287471352;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float3 k = {.2, .25, .2};
	float3 max = {1.0, .8, 1.0};
	float3 min = {.0, .2, .0};
	col.r = (1.0/(1.0+pow(e, (-k.r*((col.r*2.0)-1.0)*20.0)))*(max.r-min.r)+min.r);
	col.g = (1.0/(1.0+pow(e, (-k.g*((col.g*2.0)-1.0)*20.0)))*(max.g-min.g)+min.g);
	col.b = (1.0/(1.0+pow(e, (-k.b*((col.b*2.0)-1.0)*20.0)))*(max.b-min.b)+min.b);
	return col;
}

//redinvert
float4 redinvert(vs2ps In) : COLOR
{
    float e = 2.718281828459045235360287471352;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float3 k = {.4, .2, .2};
	float3 max = {0, 1.0, 1.0};
	float3 min = {1.0, .0, .0};
    col.r = (1.0/(1.0+pow(e,(-k.r*((col.r*2.0)-1.0)*20.0)))*(max.r-min.r)+min.r);
    col.g = (1.0/(1.0+pow(e,(-k.g*((col.g*2.0)-1.0)*20.0)))*(max.g-min.g)+min.g);
    col.b = (1.0/(1.0+pow(e,(-k.b*((col.b*2.0)-1.0)*20.0)))*(max.b-min.b)+min.b);
	return col;
}

//blueinvert
float4 blueinvert(vs2ps In) : COLOR
{
    float e = 2.718281828459045235360287471352;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	float3 k = {.2, .2, .4};
	float3 max = {1, 1, 0};
	float3 min = {0, 0, 1};
    col.r = (1.0/(1.0+pow(e,(-k.r*((col.r*2.0)-1.0)*20.0)))*(max.r-min.r)+min.r);
    col.g = (1.0/(1.0+pow(e,(-k.g*((col.g*2.0)-1.0)*20.0)))*(max.g-min.g)+min.g);
    col.b = (1.0/(1.0+pow(e,(-k.b*((col.b*2.0)-1.0)*20.0)))*(max.b-min.b)+min.b);
	return col;
}

//highContrast
float4 hightContrast(vs2ps In ) : COLOR
{
    float3 e = 2.718281828459045235360287471352;
	float2 coord = In.TexCd;
	float4 col = tex2D(Samp, coord);
	
	float3 k = .8;
	float3 min = 0;
	float3 max = 1;
	col.r = (1/(1+pow(e, (-k.r*((col.r*2)-1)*20)))*(max.r-min.r)+min.r);
	col.g = (1/(1+pow(e, (-k.g*((col.r*2)-1)*20)))*(max.g-min.g)+min.g);
	col.b = (1/(1+pow(e, (-k.b*((col.r*2)-1)*20)))*(max.b-min.b)+min.b);
	return col;
}

//horizontalSlider
float4 H_slider(vs2ps In) : COLOR
{
	float4 offset = tex2D(SampOff, In.TexCd);
	float4 col = tex2D(Samp, float2(In.TexCd.x + offset.r, In.TexCd.y));
	return col;
}

//outline
float4 outLine(vs2ps In) : COLOR
{
	const float2 _pixsize = .003;
	const float threshold = .3;
	float2 offX = float2(_pixsize.x, 0);
	float2 offY = float2(0, _pixsize.y);
	
	float4 left = tex2D(Samp, In.TexCd - offX);
	float4 right = tex2D(Samp, In.TexCd + offX);
	float4 up = tex2D(Samp, In.TexCd - offY);
	float4 down = tex2D(Samp, In.TexCd + offY);
	
	if( (abs(gray(left).x - gray(right).x) > threshold)||(abs(gray(up).y - gray(down).y) > threshold) )
		return 1;
	else 
		return float4(0, 0, 0, 1);
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TSimpleShader
{
    pass P0
    {
        //Wrap0 = U;  // useful when mesh is round like a sphere
        VertexShader = compile vs_1_1 vs2d();
        PixelShader  = compile ps_2_0 PS();
    }
	//invert
	pass P1
	{
		VertexShader = compile vs_1_1 vs2d();
		PixelShader = compile ps_2_0 invert();
	}
	//convergence
	pass P2
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=BORDER;
		VertexShader = compile vs_1_1 vs2d();
		PixelShader = compile ps_2_0 convergence();
	}
	//shaker
	pass P3
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=BORDER;
		VertexShader = compile vs_1_1 vs2d();
		PixelShader = compile ps_2_0 shaker();
	}
	//slitScan
	pass P4
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_1_1 vs2d();
		PixelShader = compile ps_2_0 slitScan();
	}
	//grow
	//! shader model more 3
	/*
	pass P5
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 slitScan();
	
	}
	*/
	pass P5
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 cutSlider();
	}
	pass P6
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 redraise();
	}
	pass P7
	{
		AlphaBlendEnable = TRUE;
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 greenraise();
	}
	pass P8
	{
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 redinvert();
	}
	pass P9
	{
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 blueinvert();
	}
	pass P10
	{
		AddressU[0]=WRAP;
		AddressV[0]=CLAMP;
		VertexShader = compile vs_3_0 vs2d();
		PixelShader = compile ps_3_0 hightContrast();
	}
	pass P11
	{
		VertexShader = compile vs_2_0 vs2d();
		PixelShader = compile ps_3_0 H_slider();
	}
	pass P12
	{
		VertexShader = compile vs_2_0 vs2d();
		PixelShader = compile ps_3_0 outLine();
	}
}

