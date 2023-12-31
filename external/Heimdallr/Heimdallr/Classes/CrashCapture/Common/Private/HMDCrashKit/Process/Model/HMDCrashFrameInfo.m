//
//  HMDCrashFrameInfo.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashFrameInfo.h"
#import "HMDCrashEnvironmentBinaryImages.h"

@implementation HMDCrashFrameInfo

+ (instancetype)frameInfoWithAddr:(uint64_t)addr
                      imageLoader:(HMDImageOpaqueLoader *)imageLoader
{
    HMDCrashFrameInfo *frame = [[HMDCrashFrameInfo alloc] init];
    frame.addr = addr;
    HMDCrashBinaryImage *image = [imageLoader imageForAddress:addr];
    frame.image = image;
    return frame;
}

@end
