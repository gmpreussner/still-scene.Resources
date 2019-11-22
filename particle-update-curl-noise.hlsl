#include "particle.hlsl"
#include "noise-functions.hlsl"

cbuffer TimeConstants : register(b0)
{
    float globalTime;
    float time;
    float runTime;
    float dummy;
}

RWStructuredBuffer<Particle> Particles : u0;
RWStructuredBuffer<int> AliveParticles : u1;
AppendStructuredBuffer<int> DeadParticles : u2;
RWBuffer<uint> IndirectArgs : u3;

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    // Initialize the draw args using the first thread in the Dispatch call
    if (i.x == 0)
    {
        IndirectArgs[0] = 0;	// Number of primitives reset to zero
        IndirectArgs[1] = 1;	// Number of instances is always 1
        IndirectArgs[2] = 0;
        IndirectArgs[3] = 0;
    }

    // Wait after draw args are written so no other threads can write to them before they are initialized
    GroupMemoryBarrierWithGroupSync();

    float oldLifetime = Particles[i.x].lifetime;
    float newLifetime = oldLifetime - (1.0/60.0);

    if (newLifetime < 0.0)
    {
        if (oldLifetime >= 0.0)
            DeadParticles.Append(i.x);
    }
    else
    {
        uint index = AliveParticles.IncrementCounter();
        AliveParticles[index] = i.x;
        // float distToCenter = length(Particles[i.x].position);

        float v1 = Particles[i.x].velocity;
        float v2 = 5.0*curlNoise(Particles[i.x].position/145.0);

        Particles[i.x].velocity = lerp(v1, v2, 0.5);
        Particles[i.x].position += (1.0/60.)*Particles[i.x].velocity;

        uint originalValue;
        InterlockedAdd(IndirectArgs[0], 6, originalValue);
    }

    Particles[i.x].lifetime = newLifetime;
}

