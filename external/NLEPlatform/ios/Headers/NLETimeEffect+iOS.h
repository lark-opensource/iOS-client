//
//  NLETimeEffect+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2021/2/19.
//

#ifndef NLETimeEffect_iOS_h
#define NLETimeEffect_iOS_h
#import <Foundation/Foundation.h>
#import "NLETimeSpaceNode+iOS.h"
#import "NLESegmentTimeEffect+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLETimeEffect_OC : NLETimeSpaceNode_OC

///时间特效片段
@property (nonatomic, strong) NLESegmentTimeEffect_OC* segmentEffect;

@end

NS_ASSUME_NONNULL_END

#endif /* NLETimeEffect_iOS_h */
