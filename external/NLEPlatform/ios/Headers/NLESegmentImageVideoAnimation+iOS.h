//
//  NLESegmentImageVideoAnimation+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/5/24.
//

#import <Foundation/Foundation.h>
#import "NLESegmentVideoAnimation+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentImageVideoAnimation_OC : NLESegmentVideoAnimation_OC

- (CGFloat)beginScale;
- (void)setBeginScale:(CGFloat)beginScale;

- (CGFloat)endScale;
- (void)setEndScale:(CGFloat)endScale;

@end

NS_ASSUME_NONNULL_END
