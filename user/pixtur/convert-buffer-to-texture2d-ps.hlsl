
cbuffer Params : register(b0)
{
    // do we actually need parameters for this?
}

struct Pixel {
    float4 Color;
};

StructuredBuffer<Pixel> Pixels : t0;
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float Range;
    float Threshold;
    float TestParam;
}

cbuffer Resolution : register(b1)
{
    float TargetWidth;
    float TargetHeight;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};

float4 psMain(vsOutput psInput) : SV_TARGET
{
    int2 pixelAddress = psInput.texCoord* float2(TargetWidth, TargetHeight);
    
    Pixel p = Pixels[pixelAddress.x + pixelAddress.y * TargetWidth];
    return p.Color;
    return float4(psInput.texCoord, 0,1);
    return float4(TargetHeight/ (float)TargetWidth, 0,0,1);
}
