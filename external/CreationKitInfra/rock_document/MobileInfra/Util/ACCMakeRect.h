//
//  ACCMakeRect.h
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/10/28.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE CGRect ACCMakeRectWithAspectRatioOutsideRect(CGSize aspectRatio, CGRect boundingRect) {
    CGFloat ri = aspectRatio.width/aspectRatio.height;
    CGFloat rs = CGRectGetWidth(boundingRect)/CGRectGetHeight(boundingRect);
    if (isnan(ri) || isnan(rs) || isinf(ri) || isinf(rs)) {
        return CGRectNull;
    }
    CGRect rect = boundingRect;
    if (ri > rs) {
        CGFloat width = rect.size.width = CGRectGetHeight(boundingRect) * ri;
        rect.origin.x += 0.5 * (CGRectGetWidth(boundingRect) - width);
    } else {
        CGFloat height = rect.size.height = CGRectGetWidth(boundingRect) / ri;
        rect.origin.y += 0.5 * (CGRectGetHeight(boundingRect) - height);
    }
    return rect;
}

NS_ASSUME_NONNULL_END
