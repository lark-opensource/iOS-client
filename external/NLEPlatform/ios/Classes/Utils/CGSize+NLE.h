//
//  CGSize+NLE.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/3.
//

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

CGSize nle_limitMinSize(CGSize size ,CGSize minSize);

CGSize nle_limitMaxSize(CGSize size ,CGSize maxSize);

CGSize nle_CGSizeSafeValue(CGSize size);

NS_ASSUME_NONNULL_END
