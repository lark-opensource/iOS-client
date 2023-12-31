//
//  UIImage+EMA.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/10/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "UIImage+EMA.h"
#import "UIImage+OP.h"

@implementation UIImage (EMA)

+ (UIImage *)ema_imageNamed:(NSString *)name {
    return [UIImage op_imageNamed:name];
}

- (UIImage *)ema_redraw {
    return [self op_redraw];
}

- (NSArray<CIQRCodeFeature *> *)ema_qrCodes {
    return [self op_qrCodes];
}

- (NSString *)ema_qrCode {
    return [self op_qrCode];
}

- (NSString *)ema_qrCodeNearPoint:(CGPoint)point {
    return [self op_qrCodeNearPoint:point];
}

@end
