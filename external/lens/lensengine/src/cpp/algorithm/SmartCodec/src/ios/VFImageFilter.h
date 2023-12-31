//
//  VFImageKernels.h
//  Pods
//
//  Created by bytedance on 2022/5/20.
//

#ifndef VFImageFilter_h
#define VFImageFilter_h
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

@protocol MTLTexture, MTLBuffer, MTLComputeCommandEncoder, MTLComputePipelineState;
@class VFMetalContext;

@interface VFImageFilter : NSObject

@property (nonatomic, strong) VFMetalContext *context;
@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;
@property (nonatomic, strong) id<MTLComputePipelineState> pipeline;
@property (nonatomic, strong) NSArray *inTextures;
@property (nonatomic, strong) NSArray *outTextures;
@property (nonatomic, assign) MTLSize threadNum;

- (instancetype)initWithFunctionName:(NSString *)functionName context:(VFMetalContext *)context;

- (void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder;

- (void)applyFilterWithTextures;

- (void)applyFilterWithTextures:(bool)block;
- (void)applyFilterWithTextures:(bool)block height:(int)height width:(int)width commandBuffer:(id<MTLCommandBuffer>)commandBuffer commandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder enh:(float)enhRatio;
- (void)applyFilterWithTextures:(bool)block height:(int)height width:(int)width commandBuffer:(id<MTLCommandBuffer>)commandBuffer commandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder;

@end

#endif /* VFImageKernels_h */
