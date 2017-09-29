//
//  ImageShaders.metal
//  Metal2D
//
//  Created by Kaz Yoshikawa on 12/22/15.
//
//

#include <metal_stdlib>
#include "MTIShaderTypes.h"

using namespace metal;
using namespace metalpetal;

vertex VertexOut passthroughVertexShader(
    const device VertexIn * vertices [[ buffer(0) ]],
	uint vid [[ vertex_id ]]
) {
	VertexOut outVertex;
	VertexIn inVertex = vertices[vid];
    outVertex.position = inVertex.position;
	outVertex.texcoords = inVertex.textureCoordinate;
	return outVertex;
}

fragment float4 passthroughFragmentShader(
	VertexOut vertexIn [[ stage_in ]],
	texture2d<float, access::sample> colorTexture [[ texture(0) ]],
	sampler colorSampler [[ sampler(0) ]]
) {
    return colorTexture.sample(colorSampler, vertexIn.texcoords);
}

fragment float4 colorInvert(
    VertexOut vertexIn [[ stage_in ]],
    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
    sampler colorSampler [[ sampler(0) ]]
) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float3 color = float3(1.0) - textureColor.rgb;
    return float4(color, textureColor.a);
}

fragment float4 saturationAdjust(
    VertexOut vertexIn [[ stage_in ]],
    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
    sampler colorSampler [[ sampler(0) ]],
    constant float & saturation [[ buffer(0) ]]
) {
    const float3 luminanceWeighting = float3(0.2125, 0.7154, 0.0721);
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    float luminance = dot(textureColor.rgb, luminanceWeighting);
    float3 greyScaleColor = float3(luminance);
    return float4(mix(greyScaleColor, textureColor.rgb, saturation), textureColor.a);
}

fragment float4 colorMatrixProjection(
                                 VertexOut vertexIn [[ stage_in ]],
                                 texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                 sampler colorSampler [[ sampler(0) ]],
                                 constant float4x4 & colorMatrix [[ buffer(0) ]]
                                 ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return textureColor * colorMatrix;
}

fragment float4 hardlightBlend(VertexOut vertexIn [[ stage_in ]],
                             texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                             sampler colorSampler [[ sampler(0) ]],
                             texture2d<float, access::sample> overlayTexture [[ texture(1) ]],
                             sampler overlaySampler [[ sampler(1) ]]
                             ) {
    float4 uCf = overlayTexture.sample(overlaySampler, vertexIn.texcoords);
    float4 uCb = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return hardLightBlend(uCb, uCf);
}

kernel void adjustExposure(
                           texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           constant float & exposure [[buffer(0)]],
                           uint2 gid [[thread_position_in_grid]]
                           ) {
    float4 inColor = inTexture.read(gid);
    float4 outColor = float4(inColor.rgb * pow(2.0, exposure), inColor.a);
    outTexture.write(outColor, gid);
}

vertex VertexOut multilayerCompositingVertexShader(
                                         const device VertexIn * vertices [[ buffer(0) ]],
                                         constant float4x4 & transformMatrix [[ buffer(1) ]],
                                         constant float4x4 & orthographicMatrix [[ buffer(2) ]],
                                         uint vid [[ vertex_id ]]
                                         ) {
    VertexOut outVertex;
    VertexIn inVertex = vertices[vid];
    outVertex.position = transformMatrix * inVertex.position * orthographicMatrix;
    outVertex.texcoords = inVertex.textureCoordinate;
    return outVertex;
}

fragment float4 multilayerCompositingFragmentShader(VertexOut vertexIn [[ stage_in ]],
                                                    float4 currentColor [[color(0)]],
                                                    constant float & opacity [[buffer(0)]],
                                                    texture2d<float, access::sample> colorTexture [[ texture(0) ]],
                                                    sampler colorSampler [[ sampler(0) ]]
                                                   ) {
    float4 textureColor = colorTexture.sample(colorSampler, vertexIn.texcoords);
    return currentColor + textureColor;
}
