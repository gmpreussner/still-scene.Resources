Texture2D<float4> colorTexture : register(t0);
Texture2D<float> depthTexture : register(t1);
RWTexture2D<float4> outputTexture : register(u0);

sampler texSampler : register(s0);

cbuffer ParamConstants : register(b0)
{
    float Near;
    float Far;
    float FocusCenter;
    float FocusRange;
}


float getBlurSize(float depth, float focusPoint, float focusRange)
{
    float MAX_BLUR_SIZE = 20.0; 
	float coc = clamp((1.0 / focusPoint - 1.0 / depth)*focusRange, -1.0, 1.0);
	return abs(coc) * MAX_BLUR_SIZE;
    // float coc = clamp((abs(focusPoint - depth) - focusRange)/(2*focusRange), 0.0, 1.0);
	// return abs(coc) * MAX_BLUR_SIZE;
}

float3 depthOfField(float2 pixelSize, float2 texCoord, float focusPoint, float focusScale)
{
    float MAX_BLUR_SIZE = 20.0; 
    float GOLDEN_ANGLE = 2.39996323; 
    float RAD_SCALE = 2.5; // Smaller = nicer blur, larger = faster

	float centerDepth = depthTexture.SampleLevel(texSampler, texCoord, 0) * Far;
	float centerSize = getBlurSize(centerDepth, focusPoint, focusScale);
	float3 color = colorTexture.SampleLevel(texSampler, texCoord, 0).rgb;
	float tot = 1.0;
	float radius = RAD_SCALE;
	for (float ang = 0.0; radius < MAX_BLUR_SIZE; ang += GOLDEN_ANGLE)
	{
		float2 tc = texCoord + float2(cos(ang), sin(ang)) * pixelSize * radius;
		float3 sampleColor = colorTexture.SampleLevel(texSampler, tc, 0).rgb;
		float sampleDepth = depthTexture.SampleLevel(texSampler, tc, 0) * Far;
		float sampleSize = getBlurSize(sampleDepth, focusPoint, focusScale);
		if (sampleDepth > centerDepth)
			sampleSize = clamp(sampleSize, 0.0, centerSize*2.0);
		float m = smoothstep(radius-0.5, radius+0.5, sampleSize);
		color += lerp(color/tot, sampleColor, m);
		tot += 1.0;   
        radius += RAD_SCALE/radius;
	}
	return color /= tot;
}

[numthreads(16,16,1)]
void main(uint3 i : SV_DispatchThreadID)
{
    int width, height;
    colorTexture.GetDimensions(width, height);
    float2 pixelSize = 1.0 / float2(width, height);
    float3 color = depthOfField(pixelSize, (float2)i.xy*pixelSize, FocusCenter, FocusRange);
    outputTexture[i.xy] = float4(color, 1);
}

