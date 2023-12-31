//
//  AWEPinStickerUtil.m
//  CameraClient
//
//  Created by resober on 2019/12/23.
//

#import "AWEPinStickerUtil.h"
#import <CreativeKit/ACCMacros.h>

@implementation AWEPinStickerUtil

+ (void)isTouchPointInStickerAreaWithPoint:(CGPoint)touchPoint
                               boundingBox:(CGRect)boundingBox
                             innerRectSize:(CGSize)innerRectSize
                                  rotation:(CGFloat)rotation
                                completion:(void(^)(BOOL contain, CGSize trueSize))completion {
    CGSize bboxSize = boundingBox.size;
    CGPoint origin = boundingBox.origin;
    CGFloat rotationInRadian = rotation * M_PI / 180.f;

    CGFloat h = bboxSize.height;
    CGFloat w = bboxSize.width;

    CGFloat rW = innerRectSize.width;
    CGFloat rH = innerRectSize.height;

    CGPoint A = CGPointMake(origin.x + rW * cosf(rotationInRadian), origin.y);
    CGPoint B = CGPointMake(origin.x + w, origin.y + rH * cosf(rotationInRadian));
    CGPoint C = CGPointMake(origin.x + rH * sinf(rotationInRadian), origin.y + h);
    CGPoint D = CGPointMake(origin.x, origin.y + rW * sinf(rotationInRadian));

    // 假设点中了贴纸的实际区域，再根据是否命中文档中淡青色区域来排除
    BOOL touched = YES;

    {
        // 左上角区域 y = kx + b
        CGFloat k = - fabs(A.y - D.y) / fabs(A.x - D.x);
        CGFloat b = A.y - k * A.x;
        // 将touchPoint.x代入，来判断
        CGFloat aimedY = k * touchPoint.x + b;
        if (touchPoint.y < aimedY) {
            touched = NO;
        }
    }
    if (touched){
        // 右上角区域 y = kx + b
        CGFloat k = (fabs(A.y - B.y) / fabs(A.x - B.x));
        CGFloat b = A.y - k * A.x;
        // 将touchPoint.x代入，来判断
        CGFloat aimedY = k * touchPoint.x + b;
        if (touchPoint.y < aimedY) {
            touched = NO;
        }
    }
    if (touched){
        // 右下角区域 y = kx + b
        CGFloat k = - fabs(B.y - C.y) / fabs(B.x - C.x);
        CGFloat b = B.y - k * B.x;
        // 将touchPoint.x代入，来判断
        CGFloat aimedY = k * touchPoint.x + b;
        if (touchPoint.y > aimedY) {
            touched = NO;
        }
    }
    if (touched){
        // 左下角区域 y = kx + b
        CGFloat k = fabs(C.y - D.y) / fabs(C.x - D.x);
        CGFloat b = D.y - k * D.x;
        // 将touchPoint.x代入，来判断
        CGFloat aimedY = k * touchPoint.x + b;
        if (touchPoint.y > aimedY) {
            touched = NO;
        }
    }
    ACCBLOCK_INVOKE(completion, touched, touched ? CGSizeMake(rW, rH) : CGSizeZero);
}

+ (BOOL)isValidRect:(CGRect)rect {
    if (isnan(rect.origin.x) || isnan(rect.origin.y) || isnan(rect.size.width) || isnan(rect.size.height)) {
        return NO;
    }
    return YES;
}

@end
