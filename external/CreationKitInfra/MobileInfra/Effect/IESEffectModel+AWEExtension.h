//
//  IESEffectModel+AWEExtension.h
//  AWEStudio
//
//  Created by liubing on 19/04/2018.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <EffectPlatformSDK/IESEffectModel.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

FOUNDATION_EXTERN NSString *const AWEColorFilterBiltinResourceName;

@interface IESEffectModel (AWEExtension)

@property (nonatomic, strong) NSString *builtinResource;
@property (nonatomic, strong) NSString *builtinIcon;
@property (nonatomic, readonly) NSString *resourcePath;
@property (nonatomic, strong) UIImage *acc_iconImage;
@property (nonatomic, readonly) NSString *pinyinName;
@property (nonatomic, readonly) BOOL isNormalFilter;
@property (nonatomic, readonly) BOOL needServerExcute;
@property (nonatomic, readonly) BOOL acc_needLocalAlgorithmExcute;

@property (nonatomic, assign) BOOL isEmptyFilter; // Indicates whether this is an empty filter implemented by providing zero intensity.

- (NSString *)filePathForCameraPosition:(AVCaptureDevicePosition)position;
+ (NSArray<IESEffectModel *> *)acc_builtinEffects;

@end
