
AppendStructuredBuffer<int> DeadParticles : u0;

[numthreads(64,1,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    // Entry e;
    // e.index = i.x;
    // e.squaredDistInCameraSpace = 999999.0;
    DeadParticles.Append(i.x);
}

