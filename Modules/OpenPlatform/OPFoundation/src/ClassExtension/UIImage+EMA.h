//
//  UIImage+EMA.h
//  EEMicroAppSDK
//
//  Created by houjihu on 2018/10/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (EMA)

+ (UIImage *)ema_imageNamed:(NSString *)name;

/// 重新绘制图片，避免图片过大会导致内存暴涨
- (UIImage *)ema_redraw;

/**
 *  识别图中二维码
 */
- (NSArray<CIQRCodeFeature *> *)ema_qrCodes;

/**
 *  识别图中二维码，返回可信度最高的二维码
 */
- (NSString *)ema_qrCode;

/**
 *  识别图中二维码
 *  如果有多个二维码，并且point在一个二维码内部，则返回该二维码
 *  如果有多个二维码，但point不在任何一个二维码内部，则返回中心离point最近的一个二维码
 */
- (NSString *)ema_qrCodeNearPoint:(CGPoint)point;

@end
