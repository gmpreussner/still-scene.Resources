//RWTexture2D<float4> outputTexture : register(u0);
Texture2D<float4> InputTexture : register(t0);
sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float4 MultiplyR;
    float4 MultiplyG;
    float4 MultiplyB;
    float4 MultiplyA;
    float4 Add;
}


cbuffer TimeConstants : register(b1)
{
    float globalTime;
    float time;
    float runTime;
    float beatTime;
}

struct vsOutput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
};


float4 psMain(vsOutput psInput) : SV_TARGET
{
    //uint width, height;
    //outputTexture.GetDimensions(width, height);

    //float2 uv = (float2)i.xy/ float2(width - 1, height - 1);

    float2 uv = psInput.texCoord;
    float4 c = InputTexture.SampleLevel(texSampler, uv, 0.0);

    float4 col = InputTexture.Sample(texSampler, psInput.texCoord);

    // float r = col.r * MultiplyR. 
    //         + col.g * MultiplyG 
    //         + col.b * MultiplyB 

    float r = dot(col, float4(MultiplyR.r, MultiplyG.r, MultiplyB.r, MultiplyA.r)) + Add.r;
    float g = dot(col, float4(MultiplyR.g, MultiplyG.g, MultiplyB.g, MultiplyA.g)) + Add.g;
    float b = dot(col, float4(MultiplyR.b, MultiplyG.b, MultiplyB.b, MultiplyA.b)) + Add.b;
    float a = dot(col, float4(MultiplyR.a, MultiplyG.a, MultiplyB.a, MultiplyA.a)) + Add.a;

    // float r = dot(col, MultiplyR) + Add.r;
    // float g = dot(col, MultiplyG) + Add.g;
    // float b = dot(col, MultiplyB) + Add.b;
    // float a = clamp( dot(col, MultiplyA) + Add.a, 0,1);
    return float4(r,g,b, clamp(a,0.0001,1));   
    // c.rgb = clamp(c.rgb, 0.000001,1000);
    // c.a = clamp(a,0,1);    
    // return c; 
}
