//
//  HMDCrashFrameInfo.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashBinaryImage.h"
#import "HMDCrashEnvironmentBinaryImages.h"

@class HMDImageOpaqueLoader;

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashFrameInfo : NSObject

@property(nonatomic, assign) uint64_t addr;

@property(nonatomic, strong) HMDCrashBinaryImage *image;

@property(nonatomic, copy) NSString *symbolName;

@property(nonatomic, assign) uint64_t symbolAddress;

@property(nonatomic, assign) BOOL symbolicated;

+ (instancetype)frameInfoWithAddr:(uint64_t)addr
                      imageLoader:(HMDImageOpaqueLoader *)imageLoader;
@end

NS_ASSUME_NONNULL_END
