#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

// Generates a full-screen quad implicitly without passing a vertex buffer.
vertex VertexOut videoVertexShader(uint vertexID [[vertex_id]]) {
    VertexOut out;
    
    // Quad vertices: (x, y)
    float2 positions[6] = {
        float2(-1.0, -1.0), // Bottom-Left
        float2( 1.0, -1.0), // Bottom-Right
        float2(-1.0,  1.0), // Top-Left
        float2(-1.0,  1.0), // Top-Left
        float2( 1.0, -1.0), // Bottom-Right
        float2( 1.0,  1.0)  // Top-Right
    };
    
    // Texture coordinates (0,0 is top-left in Metal textures typically for video, wait, bottom-left? 
    // CoreVideo usually defines 0,0 at top-left. Let's map it.
    float2 texCoords[6] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(0.0, 0.0),
        float2(1.0, 1.0),
        float2(1.0, 0.0)
    };

    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.textureCoordinate = texCoords[vertexID];
    
    return out;
}

fragment float4 videoFragmentShader(VertexOut in [[stage_in]],
                                    texture2d<float, access::sample> videoTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear,
                                     min_filter::linear,
                                     mipmap_filter::none,
                                     address::clamp_to_edge);
                                     
    // Basic linear sampling (placeholder for Lanczos/Bicubic scaling implementation)
    // Future: Add debanding dither here.
    float4 color = videoTexture.sample(textureSampler, in.textureCoordinate);
    return color;
}
