//
//  UIImage+EMA.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/10/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "UIImage+OP.h"
#import "OPBundle.h"

@implementation UIImage (OP)

+ (UIImage *)op_imageNamed:(NSString *)name {
    __block UIImage *image = [UIImage imageNamed:name];
    if (image) {
        return image;
    }

    image = [UIImage imageNamed:name inBundle:OPBundle.bundle compatibleWithTraitCollection:nil];
    if (image) {
        return image;
    }

    NSDictionary<NSString *, NSString *> *bundles = @{
                              @"TTMicroAppAssetBundle": @"TMABundle"
                              };
    [bundles enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSBundle *bundle = [OPBundle bundleWithName:key inFramework:obj];
        if (bundle) {
            image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
            if (image) {
                *stop = YES;
            }
        }
    }];

    return image;
}

- (UIImage *)op_redraw {
    UIImage *image = self;
    CGFloat scale = UIScreen.mainScreen.scale;
    CGFloat hFactor = image.size.width / (CGRectGetWidth(UIScreen.mainScreen.bounds) * scale);
    CGFloat wFactor = image.size.height / (CGRectGetHeight(UIScreen.mainScreen.bounds) * scale);
    CGFloat factor = fmaxf(hFactor, wFactor);
    CGFloat newW = image.size.width / factor;
    CGFloat newH = image.size.height / factor;
    CGSize newSize = CGSizeMake(newW, newH);
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newW, newH)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (NSArray<CIQRCodeFeature *> *)op_qrCodes {
    if (self.size.width < 10 || self.size.height < 10) {
        return nil; // 高度或者宽度小于10的图片就没有必要识别了
    }
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:self.CGImage]];
    return features;
}

- (NSString *)op_qrCode {
    return self.op_qrCodes.firstObject.messageString;
}

- (NSString *)op_qrCodeNearPoint:(CGPoint)point {
    NSArray *features = self.op_qrCodes;
    CGFloat min_distance = CGFLOAT_MAX;
    NSString *result = nil;
    for (int index = 0; index < features.count; index ++) {
        CIQRCodeFeature *feature = [features objectAtIndex:index];

        // 只有一个二维码就免于计算直接返回
        if (features.count == 1) {
            result = feature.messageString;
            break;
        }

        // 优先判断点是否在某一个二维码的矩形区域内
        if (p_rectContain(feature.topLeft, feature.topRight, feature.bottomRight, feature.bottomLeft, CGPointMake(point.x, self.size.height-point.y))) {
            result = feature.messageString;
            break;
        }

        // 其次判断点到二维码中心的距离
        CGPoint featureCenter = CGPointMake((feature.topLeft.x + feature.topRight.x + feature.bottomLeft.x + feature.bottomRight.x)/4, self.size.height - (feature.topLeft.y + feature.topRight.y + feature.bottomLeft.y + feature.bottomRight.y)/4);
        CGFloat distance = sqrt(pow(featureCenter.x - point.x, 2) + pow(featureCenter.y - point.y, 2));
        if (distance < min_distance) {
            min_distance = distance;
            result = feature.messageString;
        }
    }
    return result;
}

static inline bool p_rectContain(CGPoint p1, CGPoint p2, CGPoint p3, CGPoint p4, CGPoint p)
{
    if (p_multiply(p, p1, p2) * p_multiply(p, p4, p3) <= 0
        && p_multiply(p, p4, p1) * p_multiply(p, p3, p2) <= 0) {
        return true;
    }
    return false;
}

static inline double p_multiply(CGPoint p1, CGPoint p2, CGPoint p0)
{
    return ((p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y));
}

@end
