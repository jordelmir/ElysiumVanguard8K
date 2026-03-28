#include <metal_stdlib>
using namespace metal;

// ============================================================
// ProPlayer Elite v12.0 — GPU Rendering Pipeline
// Optimized for Apple M1 / Apple Silicon
// ============================================================

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

struct Uniforms {
    uint2 viewportSize;
    uint2 contentSize;
    uint gravityMode;
    uint renderingTier;
    float sharpnessWeight;
    float ambientIntensity;
    float2 offset;
    float time;
    float matrixIntensity;
};

// ============================================================
// MARK: - Vertex Shader (Gravity-Aware Scaling)
// ============================================================

vertex VertexOut videoVertexShader(uint vertexID [[vertex_id]],
                                   constant Uniforms &uniforms [[buffer(0)]]) {
    VertexOut out;
    
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    
    float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };
    
    float2 pos = positions[vertexID];
    float2 uv = texCoords[vertexID];
    
    float viewAspect = float(uniforms.viewportSize.x) / float(max(uniforms.viewportSize.y, 1u));
    float contentAspect = float(uniforms.contentSize.x) / float(max(uniforms.contentSize.y, 1u));
    
    if (uniforms.contentSize.x > 0 && uniforms.contentSize.y > 0) {
        uint mode = uniforms.gravityMode;
        
        if (mode == 0) {
            // FIT: Letterbox
            if (contentAspect > viewAspect) {
                pos.y *= viewAspect / contentAspect;
            } else {
                pos.x *= contentAspect / viewAspect;
            }
        }
        else if (mode == 1) {
            // FILL: Crop edges via UV
            if (contentAspect > viewAspect) {
                float scale = viewAspect / contentAspect;
                float off = (1.0 - scale) * 0.5;
                uv.x = off + uv.x * scale;
            } else {
                float scale = contentAspect / viewAspect;
                float off = (1.0 - scale) * 0.5;
                uv.y = off + uv.y * scale;
            }
        }
        else if (mode == 2) {
            // STRETCH: Full distortion fill — no adjustment
        }
        else if (mode == 3) {
            // SMART FILL: Max 15% crop
            float ratio = contentAspect / viewAspect;
            float maxCrop = 0.85;
            
            if (ratio > 1.0) {
                float cropRatio = max(1.0 / ratio, maxCrop);
                float off = (1.0 - cropRatio) * 0.5;
                uv.x = off + uv.x * cropRatio;
            } else if (ratio < 1.0) {
                float cropRatio = max(ratio, maxCrop);
                float off = (1.0 - cropRatio) * 0.5;
                uv.y = off + uv.y * cropRatio;
            }
        }
        else if (mode == 4) {
            // CUSTOM ZOOM
            pos += uniforms.offset;
        }
        else if (mode == 5) {
            // AMBIENT: Same as fit
            if (contentAspect > viewAspect) {
                pos.y *= viewAspect / contentAspect;
            } else {
                pos.x *= contentAspect / viewAspect;
            }
        }
    }
    
    out.position = float4(pos, 0.0, 1.0);
    out.textureCoordinate = uv;
    
    return out;
}

// ============================================================
// MARK: - Main Fragment Shader (Unified Pipeline with CAS)
// ============================================================

fragment float4 videoFragmentShader(VertexOut in [[stage_in]],
                                    texture2d<float, access::sample> videoTexture [[texture(0)]],
                                    constant Uniforms &uniforms [[buffer(0)]]) {
    constexpr sampler s(address::clamp_to_edge, mag_filter::linear, min_filter::linear);
    
    float2 uv = in.textureCoordinate;
    float4 color;
    
    // Apply CAS upscaling if rendering tier > 0
    if (uniforms.renderingTier > 0) {
        float2 texelSize = float2(1.0 / videoTexture.get_width(), 1.0 / videoTexture.get_height());
        
        float4 center = videoTexture.sample(s, uv);
        float4 top    = videoTexture.sample(s, uv + float2(0, -texelSize.y));
        float4 bottom = videoTexture.sample(s, uv + float2(0,  texelSize.y));
        float4 left   = videoTexture.sample(s, uv + float2(-texelSize.x, 0));
        float4 right  = videoTexture.sample(s, uv + float2( texelSize.x, 0));
        
        // Diagonal samples for better edge detection
        float4 tl = videoTexture.sample(s, uv + float2(-texelSize.x, -texelSize.y));
        float4 tr = videoTexture.sample(s, uv + float2( texelSize.x, -texelSize.y));
        float4 bl = videoTexture.sample(s, uv + float2(-texelSize.x,  texelSize.y));
        float4 br = videoTexture.sample(s, uv + float2( texelSize.x,  texelSize.y));
        
        // Local contrast range
        float4 minColor = min(min(min(min(top, bottom), min(left, right)), min(min(tl, tr), min(bl, br))), center);
        float4 maxColor = max(max(max(max(top, bottom), max(left, right)), max(max(tl, tr), max(bl, br))), center);
        
        // Edge-adaptive sharpening
        float4 contrast = maxColor - minColor;
        float edgeStrength = dot(contrast.rgb, float3(0.299, 0.587, 0.114));
        float adaptiveWeight = clamp(edgeStrength * 3.0, 0.1, 1.0);
        
        // Unsharp mask
        float4 blur = (top + bottom + left + right) * 0.25;
        float4 detail = center - blur;
        
        float strength = abs(uniforms.sharpnessWeight) * adaptiveWeight * 2.0;
        color = clamp(center + detail * strength, 0.0, 1.0);
    } else {
        color = videoTexture.sample(s, uv);
    }
    
    // Matrix rain overlay
    if (uniforms.matrixIntensity > 0.0) {
        float2 grid = float2(120.0, 60.0);
        float2 g_id = floor(uv * grid);
        
        float speed = sin(g_id.x * 23.4) * 0.5 + 0.8;
        float colTime = uniforms.time * speed + sin(g_id.x * 45.1);
        float brightness = fract(-uv.y * 3.0 + colTime);
        
        float trail = pow(brightness, 8.0);
        float3 green = float3(0.0, 1.0, 0.4);
        float3 white = float3(0.8, 1.0, 0.9);
        float3 matrix = mix(green, white, trail * 0.5) * trail * uniforms.matrixIntensity;
        
        color.rgb = mix(color.rgb, matrix, uniforms.matrixIntensity * 0.4);
    }
    
    return float4(color.rgb, 1.0);
}

// ============================================================
// MARK: - Gaussian Blur Kernel (Ambient Mode)
// ============================================================

kernel void gaussianBlurKernel(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               constant Uniforms &uniforms [[buffer(0)]],
                               uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    float4 accumulator = 0;
    int radius = 15;
    float weightSum = 0;
    
    for (int i = -radius; i <= radius; i++) {
        for (int j = -radius; j <= radius; j++) {
            float weight = exp(-(float(i*i + j*j)) / (2.0 * 64.0));
            uint2 sourcePos = uint2(
                clamp(int(gid.x * inTexture.get_width() / outTexture.get_width() + i), 0, int(inTexture.get_width()-1)),
                clamp(int(gid.y * inTexture.get_height() / outTexture.get_height() + j), 0, int(inTexture.get_height()-1))
            );
            accumulator += inTexture.read(sourcePos) * weight;
            weightSum += weight;
        }
    }
    
    outTexture.write(accumulator / weightSum * uniforms.ambientIntensity, gid);
}
