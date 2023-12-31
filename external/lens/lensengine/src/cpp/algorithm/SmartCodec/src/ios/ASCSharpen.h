//
//  ASCSharpen.h
//  Pods
//
//  Created by bytedance on 2022/5/20.
//

#ifndef ASCSharpen_h
#define ASCSharpen_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import "VFMetalContext.h"

@protocol MTLTexture, MTLBuffer, MTLComputeCommandEncoder, MTLComputePipelineState;


@interface ASCSharpenFilter :NSObject

@property (nonatomic, assign) float enhance;
@property (nonatomic, assign) int width;
@property (nonatomic, assign) int height;
@property (nonatomic, assign) bool bProcessYuv;
- (void)initWithWidth:(int)width height:(int)height enhRatio:(float) enhRatio;
- (instancetype)create:(VFMetalContext *)context bProcessYuv:(bool)bProcessYuv;
-(void) process:(id<MTLTexture>)inTexture outTexture:(id<MTLTexture>)outTexture;
-(void)Release;
@end

#endif /* ASCSharpen_h */
