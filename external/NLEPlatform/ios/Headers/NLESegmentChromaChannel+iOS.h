//
//  NLESegmentChromaChannel+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/25.
//

#ifndef NLESegmentChromaChannel_iOS_h
#define NLESegmentChromaChannel_iOS_h
#import <Foundation/Foundation.h>
#import "NLESegment+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentChromaChannel_OC : NLESegment_OC

/// 色度抠图
@property (nonatomic, strong, nullable) NLEResourceNode_OC *effectSDKChroma;

- (void)setColor:(uint32_t)color;
- (uint32_t)color;

- (void)setIntensity:(float)intensity;
- (float)intensity;

- (void)setShadow:(float)shadow;
- (float)shadow;

- (NLEResourceNode_OC *)getResource;
                                                        \
@end

NS_ASSUME_NONNULL_END

#endif /* NLESegmentChromaChannel_iOS_h */
