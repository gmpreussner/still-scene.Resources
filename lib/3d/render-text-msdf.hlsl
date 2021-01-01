
static const float3 Quad[] = 
{
  float3(0, -1, 0),
  float3( 1, -1, 0), 
  float3( 1,  0, 0), 
  float3( 1,  0, 0), 
  float3(0,  0, 0), 
  float3(0, -1, 0), 

};

static const float4 UV[] = 
{ 
    //    min  max
     //   U V  U V
  float4( 1, 0, 0, 1), 
  float4( 0, 0, 1, 1), 
  float4( 0, 1, 1, 0), 
  float4( 0, 1, 1, 0), 
  float4( 1, 1, 0, 0), 
  float4( 1, 0, 0, 1), 
};

cbuffer Transforms : register(b0)
{
    float4x4 CameraToClipSpace;
    float4x4 ClipSpaceToCamera;
    float4x4 WorldToCamera;
    float4x4 CameraToWorld;
    float4x4 WorldToClipSpace;
    float4x4 ClipSpaceToWorld;
    float4x4 ObjectToWorld;
    float4x4 WorldToObject;
    float4x4 ObjectToCamera;
    float4x4 ObjectToClipSpace;
};

cbuffer Params : register(b1)
{
    float4 Color;
    float4 Shadow;
    float3 Params;
};

struct GridEntry
{
    // float2 gridPos;
    // float2 charUv;
    // float highlight;
    // float3 __filldummy;
    //float2 size;
    //float2 __filldummy;

    float3 Position;
    float Size;
    float3 Orientation;
    float AspectRatio;
    float4 Color;
    float4 UvMinMax;
    float BirthTime;
    float Speed;
    uint Id;        
};

struct Output
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
};

StructuredBuffer<GridEntry> GridEntries : t0;
Texture2D<float4> fontTexture : register(t1);
sampler texSampler : register(s0);


Output vsMain(uint id: SV_VertexID)
{
    Output output;

    int vertexIndex = id % 6;
    int entryIndex = id / 6;
    float3 quadPos = Quad[vertexIndex];


    GridEntry entry = GridEntries[entryIndex];

    float3 posInObject = entry.Position;
    posInObject.xy += quadPos.xy * float2(entry.Size * entry.AspectRatio, entry.Size) ; //CellSize *  (1- CellPadding) * (1+overrideScale* OverrideScale) /2;

    float4 quadPosInWorld = mul(float4(posInObject.xyz,1), ObjectToWorld);
    
    //quadPosInWorld.xy += quadPos.xy * float2(entry.Size * entry.AspectRatio, entry.Size) ; //CellSize *  (1- CellPadding) * (1+overrideScale* OverrideScale) /2;
    
    float4 quadPosInCamera = mul(quadPosInWorld, WorldToCamera);
    output.position = mul(quadPosInCamera, CameraToClipSpace);
    //output.position.z = 0;
    //output.color = lerp(Color, HighlightColor, entry.highlight) * overrideBrightness;
    //output.texCoord = (entry.charUv + quadPos * float2(0.5, -0.5) + 0.5)/16;
    float4 uv = entry.UvMinMax * UV[vertexIndex];
    output.texCoord =  uv.xy + uv.zw;
    return output;
}


struct PsInput
{
    float4 position : SV_POSITION;
    float2 texCoord : TEXCOORD;
    float4 color : COLOR;
};

float median(float r, float g, float b) {
    return max(min(r, g), min(max(r, g), b));
}

float4 psMain(PsInput input) : SV_TARGET
{    
    //float2 msdfUnit = float2(1,1) * 1;// pxRange/float2(textureSize(msdf, 0));
    float3 smpl1 =  fontTexture.Sample(texSampler, input.texCoord).rgb;
    //float sigDist1 = median(smpl1.r, smpl1.g, smpl1.b) - 0.0001;
    //float opacity1 = smoothstep(0.0,0.9,sigDist1*sigDist1);

    int height, width;
    fontTexture.GetDimensions(width,height);

    // from https://github.com/Chlumsky/msdfgen/issues/22#issuecomment-234958005
    float dx = ddx( input.texCoord.x ) * width;
    float dy = ddy( input.texCoord.y ) * height;
    float toPixels = Params.x * rsqrt( dx * dx + dy * dy );
    float sigDist = median( smpl1.r, smpl1.g, smpl1.b ) - 0.5;
    float letterShape = clamp( sigDist * toPixels + 0.5, 0.0, 1.0 );


    if(Shadow.a < 0.02) {
        return float4(Color.rgb, letterShape * Color.a);
    }

    float glow = pow( smoothstep(0,1, sigDist + 0.3), 0.3);

    return float4(
        lerp(Shadow.rgb, Color.rgb, letterShape ),
        max( saturate(letterShape*2),glow * Shadow.a) * Color.a
    );
}
