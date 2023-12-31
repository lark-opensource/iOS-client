//
//   NLEEffect+iOS.h
//   NLEPlatform
//
//   Created  by bytedance on 2021/4/14.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    
#ifndef NLEEffect_iOS_h
#define NLEEffect_iOS_h
 
#import <Foundation/Foundation.h>
#import "NLETimeSpaceNode+iOS.h"
#import "NLESegmentEffect+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEEffect_OC : NLETimeSpaceNode_OC
///特效片段
@property (nonatomic, strong) NLESegmentEffect_OC* segmentEffect;

@end

NS_ASSUME_NONNULL_END

#endif /* NLEEffect_iOS_h */
