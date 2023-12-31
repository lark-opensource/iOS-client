//
//  NLEVideoMaskUtil.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/3.
//

#import <Foundation/Foundation.h>
#import "NLESequenceNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEVideoMaskUtil : NSObject

+ (CGSize)maskAspectSizeWith:(CGSize)videoSize maskSize:(CGSize)maskSize aspectRatio:(CGFloat)aspectRatio;

+ (NSString *)maskParamsWithMask:(const std::shared_ptr<cut::model::NLESegmentMask> &)segmentMask
                        cropSize:(CGSize)cropSize;

@end

NS_ASSUME_NONNULL_END
