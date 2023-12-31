//
//  BytedCertWrapper.h
//  BytedCert
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//

#import "BytedCertWrapper.h"
#import "BDCTAPIService.h"
#import "FaceLiveViewController.h"
#import "BDCTImageManager.h"
#import "BDCTIndicatorView.h"
#import "BytedCertManager+Private.h"
#import "BDCTEventTracker.h"
#import "BDCTLocalization.h" // 内部使用活体检测调用的函数
#import "BDCTFaceVerificationFlow.h"
#import "FaceLiveUtils.h"
#import "BDCTStringConst.h"
#import "BDCTFaceVerificationFlow+Tracker.h"
#import "BDCTLog.h"
#import "BytedCertManager+OCR.h"

#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDAssert/BDAssert.h>

static BytedCertWrapper *_bytedCertInstance;


@interface BytedCertWrapper ()

@end


@implementation BytedCertWrapper

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bytedCertInstance = [[BytedCertWrapper alloc] init];
    });
    return _bytedCertInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _modelPathList = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BytedCertUIConfig *)uiConfig {
    return [BytedCertUIConfig sharedInstance];
}

- (void)setLanguage:(NSString *)language {
    [BytedCertManager setLanguage:language];
}

- (NSDictionary *)getSDKVersionInfo {
    return @{@"sdk_version" : (BytedCertManager.sdkVersion ?: @"")};
}

- (void)doFaceLivenessWithParams:(NSDictionary *_Nullable)params
                   shouldPresent:(BOOL (^_Nullable)(void))shouldPresent
                        callback:(BytedCertFaceLivenessResultBlock)callback {
    [self doFaceLivenessWithParams:params extraParams:nil shouldPresent:shouldPresent ignoreInit:NO callback:callback];
}

- (void)doFaceLivenessWithParams:(NSDictionary *)params
                     extraParams:(NSDictionary *)extraParams
                        callback:(BytedCertFaceLivenessResultBlock)callback {
    [self doFaceLivenessWithParams:params extraParams:extraParams shouldPresent:nil ignoreInit:NO callback:callback];
}

//internal uniform interface

- (void)doFaceLivenessWithParams:(NSDictionary *)params
                     extraParams:(NSDictionary *)extraParams
                   shouldPresent:(BOOL (^)(void))shouldPresent
                        callback:(BytedCertFaceLivenessResultBlock)callback {
    [self doFaceLivenessWithParams:params extraParams:extraParams shouldPresent:nil ignoreInit:NO callback:callback];
}

- (void)doFaceLivenessWithParams:(NSDictionary *_Nullable)params
                     extraParams:(NSDictionary *_Nullable)extraParams
                   shouldPresent:(BOOL (^_Nullable)(void))shouldPresent
                      ignoreInit:(BOOL)ignoreInit
                        callback:(BytedCertFaceLivenessResultBlock)callback {
    BytedCertParameter *parameter = [[BytedCertParameter alloc] initWithBaseParams:params identityParams:extraParams];
    if (BTD_isEmptyString(parameter.appId)) {
        parameter.appId = [params btd_stringValueForKey:BytedCertParamAppId];
    }
    [BytedCertManager.shareInstance p_beginFaceVerificationWithParameter:parameter fromViewController:nil forcePresent:[params btd_boolValueForKey:@"present_to_show"] suprtFlow:nil shouldBeginFaceVerification:shouldPresent completion:^(BytedCertError *_Nullable error, NSDictionary *_Nullable result) {
        !callback ?: callback(result, error);
    }];
}

/// 调起拍照功能
/// @param args 参数
/// @param callback 回调
- (void)invokeTakePhotoByCamera:(NSDictionary *)args
                       callback:(BytedcertSelectImageCompletionBlock)callback {
    [BytedCertManager takePhotoByCameraWithParams:args completion:callback];
}

/// 调起相册功能
/// @param args 参数
/// @param callback 回调
- (void)invokeTakePhotoByAlbum:(NSDictionary *)args
                      callback:(BytedcertSelectImageCompletionBlock)callback {
    [BytedCertManager selectImageByAlbumWithParams:args completion:callback];
}

/// 调起底部alert选择相册、拍照
/// @param args 参数
/// @param callback 回调
- (void)invokeTakePhotoAlert:(NSDictionary *)args
                    callback:(BytedcertSelectImageCompletionBlock)callback {
    [BytedCertManager getImageWithParams:args completion:callback];
}

- (void)doOCRWithType:(NSString *)type params:(NSDictionary *)params ignoreInit:(BOOL)ignoreInit callback:(BytedCertOCRResultBlock)callback {
    [BytedCertManager doOCRWithImageType:type params:params completion:callback];
}

@end
