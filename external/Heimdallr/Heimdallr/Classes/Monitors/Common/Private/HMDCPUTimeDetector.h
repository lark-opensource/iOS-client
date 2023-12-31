//
//  HMDCPUTimeDetector.h
//  Pods
//
//  Created by bytedance on 2022/12/30.
//

#import <Foundation/Foundation.h>

@interface HMDCPUTimeDetector : NSObject

+ (instancetype)sharedDetector;
- (void)start;
- (void)stop;

@end


