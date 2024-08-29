
#include <metal_stdlib>
using namespace metal;

kernel void fractalTextureShader(
    texture2d<half, access::write> outTexture [[texture(0)]],
    uint2 gid [[thread_position_in_grid]],
    constant float &time [[buffer(0)]])
{
    float2 texCoord = float2(gid) / float2(outTexture.get_width(), outTexture.get_height());
    float t = time * 0.1;

    float2 c = (texCoord * 1.75 - float2(1.05, 0.875)) * 2.0;
    float2 z = float2(sin(t * 0.3), cos(t * 0.3)) * 0.7;

    int iterations = 0;
    int max_iterations = 1000;
    for (int i = 0; i < max_iterations; i++) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        if (length(z) > 8.0) break;
        iterations++;
    }

    float smooth_iteration = float(iterations) + 1.0 - log(log(length(z))) / log(2.0);

    float3 color = 0.5 + 0.5 * cos(3.0 + smooth_iteration * 0.15 + float3(0.0, 0.6, 1.0) + t);

    float swirl = sin(texCoord.x * 50.0 + texCoord.y * 10.0 + t) * 0.1;
    color += float3(swirl);

    color = clamp(color, 0.0, 1.0);

    half alpha = length(texCoord - 0.5) < 0.5 ? 1.0h : 0.0h;

    outTexture.write(half4(half3(color), alpha), gid);
}
