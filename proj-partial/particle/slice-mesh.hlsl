
#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "particle.hlsl"

// cbuffer CountConstants : register(b0)
// {
//     int4 bufferCount;
// };

cbuffer EmitParameter : register(b0)
{
    float3 Plane;
    float dummy;
    float3 PlanePos;
};

cbuffer TimeConstants : register(b1)
{
    float GlobalTime;
    float Time;
    float RunTime;
    float BeatTime;
    float LastFrameDuration;
}


cbuffer Transforms : register(b2)
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

struct Face
{
    float3 positions[3];
    float2 texCoords[3];
    float3 normals[3];
    int id;
    float normalizedFaceArea;
    float cdf;
};


StructuredBuffer<Face> PointCloud : t0;
RWStructuredBuffer<Face> SlicedData : u0;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    PointCloud.GetDimensions(numStructs, stride);
    if (i.x >= (uint)numStructs)
        return; 

    uint index = i.x;
    Face f = PointCloud[index];

    float np[3];
    np[0] = dot(Plane, f.positions[0] - PlanePos);
    np[1] = dot(Plane, f.positions[1] - PlanePos);
    np[2] = dot(Plane, f.positions[2] - PlanePos);
    if (np[0] < 0 && np[1] < 0 && np[2] < 0)
        return; // all points skipped

    if (np[0] > 0 && np[1] > 0 && np[2] > 0)
    {
        uint targetIndex = SlicedData.IncrementCounter();
        SlicedData[targetIndex] = f;
        return; // all points on 'right' side of the plane, just keep input triangle
    }

    if (np[0] > 0 && np[1] < 0 && np[2] < 0)
    {
        // one point 'in' two 'out', -> one tri
        float3 lDir = (f.positions[1] - f.positions[0]);
        float d = np[1] / dot(lDir, Plane);
        d = dot(PlanePos - f.positions[0], Plane) / dot(lDir, Plane);
        f.positions[1] = f.positions[0] + lDir*d;

        lDir = f.positions[2] - f.positions[0];
        d = dot(PlanePos - f.positions[0], Plane) / dot(lDir, Plane);
        f.positions[2] = f.positions[0] + lDir*d;;

        uint targetIndex = SlicedData.IncrementCounter();
        SlicedData[targetIndex] = f;
        return;
    }

    if (np[1] > 0 && np[0] < 0 && np[2] < 0)
    {
        // one point 'in' two 'out', -> one tri
        float3 lDir = (f.positions[0] - f.positions[1]);
        float d = np[0] / dot(lDir, Plane);
        d = dot(PlanePos - f.positions[1], Plane) / dot(lDir, Plane);
        f.positions[0] = f.positions[1] + lDir*d;

        lDir = f.positions[2] - f.positions[1];
        d = dot(PlanePos - f.positions[1], Plane) / dot(lDir, Plane);
        f.positions[2] = f.positions[1] + lDir*d;;

        uint targetIndex = SlicedData.IncrementCounter();
        SlicedData[targetIndex] = f;
        return;
    }

    if (np[2] > 0 && np[0] < 0 && np[1] < 0)
    {
        // one point 'in' two 'out', -> one tri
        float3 lDir = (f.positions[0] - f.positions[2]);
        float d = dot(PlanePos - f.positions[2], Plane) / dot(lDir, Plane);
        f.positions[0] = f.positions[2] + lDir*d;

        lDir = f.positions[1] - f.positions[2];
        d = dot(PlanePos - f.positions[2], Plane) / dot(lDir, Plane);
        f.positions[1] = f.positions[2] + lDir*d;;

        uint targetIndex = SlicedData.IncrementCounter();
        SlicedData[targetIndex] = f;
        return;
    }

    for (int ind = 0; ind < 3; ind++)
    {
        int i0 = ind;
        int i1 = (i0 + 1) % 3;
        int i2 = (i0 + 2) % 3;
        if (np[i0] < 0 && np[i1] > 0 && np[i2] > 0)
        {
            Face f1 = f;
            float3 lDir = (f.positions[i2] - f.positions[i0]);
            // float d = np[i2] / dot(lDir, Plane);
            float d = dot(PlanePos - f.positions[i0], Plane) / dot(lDir, Plane);
            float3 newP0To2 = f.positions[i0] + lDir*d;
            f1.positions[i0] = newP0To2;

            Face f2 = f;
            lDir = f.positions[i1] - f.positions[i0];
            // d = np[i1] / dot(lDir, Plane);
            d = dot(PlanePos - f.positions[i0], Plane) / dot(lDir, Plane);
            float3 newP0To1 = f.positions[i0] + lDir*d;
            f2.positions[i0] = newP0To1;
            f2.positions[i2] = newP0To2;

            uint targetIndex = SlicedData.IncrementCounter();
            SlicedData[targetIndex] = f1;
            targetIndex = SlicedData.IncrementCounter();
            SlicedData[targetIndex] = f2;
            return;
        }
    }

    // uint targetIndex = SlicedData.IncrementCounter();
    // SlicedData[targetIndex] = f;
}
