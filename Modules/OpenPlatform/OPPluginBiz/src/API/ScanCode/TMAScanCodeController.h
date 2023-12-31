//
//  TMAScanCodeController.h
//  OPPluginBiz
//
//  Created by muhuai on 2017/12/20.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMABaseViewController.h"

/**
 * 扫码类型
 */
typedef NS_OPTIONS(NSInteger, BDPScanCodeType) {
    BDPScanCodeTypeUnknow       = 0,
    BDPScanCodeTypeBarCode      = 1,   // 一维码
    BDPScanCodeTypeQRCode       = 1 << 1,   // 二维码
    BDPScanCodeTypeDatamatrix   = 1 << 2,   // Data Matrix 码
    BDPScanCodeTypePDF417       = 1 << 3,   // PDF417 码
};

typedef enum : NSUInteger {
    TMAScanCodeTypeUnknow,
    TMAScanCodeTypeQRCode,
    TMAScanCodeTypeBarCode,
    TMAScanCodeTypePDF147,
    TMAScanCodeTypeDataMatrix
} TMAScanCodeType;

@class TMAScanCodeController;

/// 扫码控制器代理协议
@protocol TMAScanCodeControllerProtocol<NSObject>
- (void)scanCodeController:(TMAScanCodeController *)controller didDetectCode:(NSString *)code type:(TMAScanCodeType)type;
- (void)didDismissScanCodeController:(TMAScanCodeController *)controller;
@end

/// 扫码控制器
@interface TMAScanCodeController: EMABaseViewController

/// 扫码控制器代理
@property (nonatomic, weak) id<TMAScanCodeControllerProtocol> delegate;

- (instancetype)initWithScanType:(BDPScanCodeType)scanType
                  onlyFromCamera:(BOOL)onlyFromCamera
                    barCodeInput:(BOOL)barCodeInput;

@end
