
#include "hash-functions.hlsl"
#include "noise-functions.hlsl"
#include "particle.hlsl"

cbuffer CountConstants : register(b0)
{
    int4 bufferCount;
}

cbuffer Transforms : register(b1)
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

struct Vertex
{
    float3 position;
    int id;
    float3 normal;
    float normalizedFaceArea;
    float2 texCoord;
    float cdf;
    float dummy;
};

uint wang_hash(in out uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed *= 9;
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}


StructuredBuffer<Vertex> PointCloud : s0;

RWStructuredBuffer<Particle> Particles : u0;
ConsumeStructuredBuffer<ParticleIndex> DeadParticles : u1;

[numthreads(160,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    uint numStructs, stride;
    PointCloud.GetDimensions(numStructs, stride);
    if (i.x >= (uint)bufferCount.x)// || i.x >= numStructs)
        return; // no particles available

    uint rng_state = i.x;
    float xi1 = float(wang_hash(rng_state)) * (1.0 / 4294967296.0);
    float xi2 = float(wang_hash(rng_state)) * (1.0 / 4294967296.0);

    uint index = i.x * 3 % numStructs;
    Vertex v0 = PointCloud[index];
    Vertex v1 = PointCloud[index + 1];
    Vertex v2 = PointCloud[index + 2];
    float xi1Sqrt = sqrt(xi1);
    float u = 1.0 - xi1Sqrt;
    float v = xi2 * xi1Sqrt; 
    float w = 1.0 - u - v;
    float3 pos = v0.position * u + v1.position * v + v2.position * w;

    ParticleIndex pi = DeadParticles.Consume();
    Particle particle = Particles[pi.index];

    particle.position = pos * 50;
    particle.emitterId = 2;//p.id;
    particle.lifetime = 1.0;
    particle.size = float2(5, 5);
    particle.velocity = v0.normal*10;
    particle.color = float4(v0.texCoord, 0, 1);

    Particles[pi.index] = particle;
}
