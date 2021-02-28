#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "point.hlsl"

cbuffer Params : register(b0)
{
    float4x4 TransformMatrix;
}


StructuredBuffer<Point> SourcePoints : t0;        
RWStructuredBuffer<Point> ResultPoints : u0;   


[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    SourcePoints.GetDimensions(numStructs, stride);
    if(i.x >= numStructs) {
        ResultPoints[i.x].w = 0 ;
        return;
    }

    ResultPoints[i.x].position = mul(float4(SourcePoints[i.x].position,1), TransformMatrix).xyz;

    // Transform rotation is kind of tricky. There might be more efficient ways to do this.
    float4 rotation = SourcePoints[i.x].rotation;

    float3 xDir = rotate_vector(float3(1,0,0), rotation);
    float3 rotatedXDir = normalize(mul(float4(xDir,0), TransformMatrix).xyz);

    float3 yDir = rotate_vector(float3(0, 1,0), rotation);
    float3 rotatedYDir = normalize(mul(float4(yDir,0), TransformMatrix).xyz);
    
    float3 crossXY = cross(rotatedXDir, rotatedYDir);
    float3x3 orientationDest= float3x3(
        rotatedXDir, 
        cross(crossXY, rotatedXDir), 
        crossXY );

    float4 newRotation = normalize(q_from_matrix(transpose(orientationDest)));

    ResultPoints[i.x].rotation = newRotation;
    ResultPoints[i.x].w = SourcePoints[i.x].w;
}

