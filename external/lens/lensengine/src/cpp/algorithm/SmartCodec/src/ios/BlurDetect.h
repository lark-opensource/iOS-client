//
//  BlurDetect.h
//  Pods
//
//  Created by bytedance on 2022/5/24.
//

#ifndef BlurDetect_h
#define BlurDetect_h

#import <Foundation/Foundation.h>
#import "VFMetalContext.h"
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@protocol MTLTexture, MTLBuffer, MTLComputeCommandEncoder, MTLComputePipelineState;

@interface BlurDection : NSObject
@property (nonatomic, strong) VFMetalContext *context;

@property (nonatomic, strong) MPSImageLaplacian *laplacianFilter;
@property (nonatomic, strong) MPSImageStatisticsMeanAndVariance *calcMeanVarFilter;
@property (nonatomic, strong) id<MTLTexture> laplacianTexture;
@property (nonatomic, strong) id<MTLTexture> meanVarTexture;

- (instancetype)create:(VFMetalContext *)context;

- (void)initVideoFeatureWithWidth:(int)width height:(int)height;

-(float) process:(id<MTLTexture>)inTexture;
-(float) process:(id<MTLTexture>)inTexture outTexture:(id<MTLTexture>)outTexture;

//-(float) process:(id<MTLTexture>)outTexture;

@end

#endif /* BlurDetect_h */
