//
//  CGFloat+NLE.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/3.
//

#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN CGFloat nle_CGFloatInRange(CGFloat value, CGFloat minValue, CGFloat maxValue);

FOUNDATION_EXTERN CGFloat nle_CGFloatSafeValue(CGFloat value);

FOUNDATION_EXTERN CGFloat nle_CGFloatConvertClipXValue(CGFloat value);

FOUNDATION_EXTERN CGFloat nle_CGFloatConvertClipYValue(CGFloat value);

FOUNDATION_EXTERN CGFloat nle_CGFloatConvertVEXValue(CGFloat value);

FOUNDATION_EXTERN CGFloat nle_CGFloatConvertVEYValue(CGFloat value);

NS_ASSUME_NONNULL_END
