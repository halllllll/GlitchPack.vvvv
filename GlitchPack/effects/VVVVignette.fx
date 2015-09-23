//@author: hal kawashima @hurafula
//@help: reference https://github.com/Saqoosha/BokehParticles
//@tags: glitch
//@credits:

// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------


float2 res;
float2 noiseTexSize;
float noiseAmount = 1.45;
float colorFilterAmount = 1;
float vignnetRad = 1;
float frameCount = 0;


//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
//noise tex( sonouchi kokode tukuru
texture Noise <string uiname="NoiseTex";>;
sampler n = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
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
	inout float4 pos : POSITION,
 	inout float2 uv : TEXCOORD0)
{
	pos.xy*=2;
	uv+=.5/res;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------
/*
float rand(float2 co){
	return frac(sin(dot(co.xy, float2(12.9898, 78.233)))*4375.5453);
}
*/

float4 gamma(float4 col){
	float gammaAmount = 1/2.2;
	float3 g = pow(col.rgb, gammaAmount);
	return float4(float3(g), col.a);
}

float4 vignnet(vs2ps In) : COLOR
{
	float4 col = tex2D(Samp, In.TexCd);
	const float4 redFilter = {1, 0, 0, 1};
	const float4 blueGreenFilter = {0, 1, .7, 1};

	float2 d = .5 -float2(In.TexCd);
	float distSQ = d.x * d.x + d.y * d.y;
	float invDistSQ = 1/distSQ;
	col.rgb -= distSQ / vignnetRad;
	col = saturate(col);
	
	//noise
	float2 noiseCoord = float2(frameCount*50+In.TexCd);
	noiseCoord = fmod(noiseCoord, noiseTexSize);
	float4 noiseCol = tex2D(n, noiseCoord);
	noiseCol = lerp(noiseCol, col, noiseAmount);
	
	//colFilter
	float4 redRecord = noiseCol * redFilter;
	float4 blueGreenRecord = noiseCol * blueGreenFilter;
	
	float4 redNegative = redRecord.r;
	float4 blueGreenNegative = ((blueGreenRecord.g+blueGreenRecord.b)/2);
	
	float4 redOut = redNegative * redFilter;
	float4 blueGreenOut = blueGreenNegative * blueGreenFilter;
	float4 result = redOut + blueGreenOut;
	
	result = lerp(noiseCol, result, colorFilterAmount);
	result.a = noiseCol.a;
	
	//gamma collection
	gamma(result);
	
	return result;
}

float4 PS(vs2ps In): COLOR
{
    float4 col = tex2D(Samp, In.TexCd);
    return col;
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
        PixelShader  = compile ps_2_0 vignnet();
    }
}

