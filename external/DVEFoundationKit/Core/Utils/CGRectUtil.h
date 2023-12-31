//
//  CGRectUtil.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/16.
//

#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <math.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_STATIC_INLINE CGFloat DVEDistanceForTwoPoint(CGPoint p1, CGPoint p2)
{
    return sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

FOUNDATION_STATIC_INLINE CGPoint DVEAddDyForPoint(CGPoint p, CGFloat dy)
{
    CGFloat x = p.x;
    CGFloat y = p.y;
    y += dy;
    return CGPointMake(x, y);
}

FOUNDATION_STATIC_INLINE CGPoint DVEAddDxForPoint(CGPoint p, CGFloat dx)
{
    CGFloat x = p.x;
    CGFloat y = p.y;
    x += dx;
    return CGPointMake(x, y);
}

FOUNDATION_STATIC_INLINE CGPoint DVECGRectGetCenter(CGRect rect)
{
    return CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
}

FOUNDATION_STATIC_INLINE BOOL DVECGRectIsNaN(CGRect rect) {
    return isnan(rect.size.width) || isnan(rect.size.height) || isnan(rect.origin.x) || isnan(rect.origin.y);
}

//根据aspectRatio调整区域Rect
FOUNDATION_EXTERN CGRect DVEMakeRectWithAspectRatioOutsideRect(CGSize aspectRatio, CGRect boundingRect);

// 将原始size等比例放大或缩小，以致达到最小程度包含minSize
FOUNDATION_EXTERN CGSize DVECGSizeSacleAspectFitToMinSize(CGSize originSize, CGSize minSize);

// 将原始size等比例放大或缩小，以致达到最小程度缩进maxSize
FOUNDATION_EXTERN CGSize DVECGSizeSacleAspectFitToMaxSize(CGSize originSize, CGSize maxSize);

// 将原始sizesize等比例放大或缩小，最大程度塞进rect,返回塞进去之后的frame
FOUNDATION_EXTERN CGRect DVECGSizeScaleAspectFitInRect(CGSize originSize, CGRect rect);

// 以长边为参考，争取最大的压缩进limitSize,如果长边都达不到litmitSize, 则保持originSize大小
FOUNDATION_EXTERN CGSize DVECGSizeLimitMaxSize(CGSize originSize, CGSize limitSize);

// 以短边做参考，争取最小的包含limitSize,如果短边都无法包含，则保持originSize大小
FOUNDATION_EXTERN CGSize DVECGSizeLimitMinSize(CGSize originSize, CGSize limitSize);

NS_ASSUME_NONNULL_END
