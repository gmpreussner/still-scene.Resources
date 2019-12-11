
static const float3 Quad[] = 
{
  float3(-1, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  1, 0), 
  float3( 1,  1, 0), 
  float3(-1,  1, 0), 
  float3(-1, -1, 0), 
};


cbuffer Transforms : register(b0)
{
    float4x4 clipSpaceTcamera;
    float4x4 cameraTclipSpace;
    float4x4 cameraTworld;
    float4x4 worldTcamera;
    float4x4 clipSpaceTworld;
    float4x4 worldTclipSpace;
    float4x4 worldTobject;
    float4x4 objectTworld;
    float4x4 cameraTobject;
    float4x4 clipSpaceTobject;
};

cbuffer Params : register(b1)
{
    float4 Color;
    float Width;
    float Height;
};


struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

Texture2D<float4> inputTexture : register(t0);
sampler texSampler : register(s0);

vsOutput vsMain(uint id: SV_VertexID)
{
    vsOutput output;
    float4 quadPos = float4(Quad[id], 1) ;
    output.texCoord = quadPos.xy*float2(0.5, -0.5) - 0.5;
    float4 worldPquad = mul(worldTobject, quadPos * float4(Width,Height,1,1));
    float4 camPquad = mul(cameraTworld, worldPquad);
    output.position = mul(clipSpaceTcamera, camPquad); //todo: check why using clipSpaceTobject directly doesn't work
    return output; 
}


float4 psMain(vsOutput input) : SV_TARGET
{
    float4 c = inputTexture.Sample(texSampler, input.texCoord);
    return float4(1,1,1,1) * Color *c;
}