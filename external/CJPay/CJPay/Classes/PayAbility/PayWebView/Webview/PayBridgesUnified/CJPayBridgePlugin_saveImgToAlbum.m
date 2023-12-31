//
//  CJPayBridgePlugin_saveImgToAlbum.m
//  Aweme
//
//  Created by shanghuaijun on 2023/4/27.
//

#import "CJPayBridgePlugin_saveImgToAlbum.h"
#import <TTBridgeUnify/TTBridgeRegister.h>
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import <Photos/PHPhotoLibrary.h>
#import <Photos/Photos.h>
#import "CJPayAlertUtil.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayBridgeBlockRegister.h"

@implementation CJPayBridgePlugin_saveImgToAlbum

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    [CJPayBridgeBlockRegister registerBridgeName:@"ttcjpay.saveImgToAlbum"
                                      engineType:TTBridgeRegisterAll
                                        authType:TTBridgeAuthProtected
                                         domains:nil
                               needBridgeCommand:YES
                                         handler:^(NSDictionary * _Nullable params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController * _Nullable controller, TTBridgeCommand * _Nullable command) {
        
        TTBridgePlugin *pluginSaveImgToAlbum = [CJPayBridgeBlockRegister associatedPluginsOnEngine:engine pluginClassName:NSStringFromClass(self)];
        if ([pluginSaveImgToAlbum isKindOfClass:CJPayBridgePlugin_saveImgToAlbum.class]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(CJPayBridgePlugin_saveImgToAlbum *)pluginSaveImgToAlbum saveImgToAlbumWithParam:params
                                                                                         callback:callback
                                                                                           engine:engine
                                                                                       controller:controller
                                                                                          command:command];
            });
        } else {
            TTBRIDGE_CALLBACK_FAILED_MSG(@"参数错误");
        }
    }];
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)saveImgToAlbumWithParam:(NSDictionary *)param
                       callback:(TTBridgeCallback)callback
                         engine:(id<TTBridgeEngine>)engine
                     controller:(UIViewController *)controller
                        command:(TTBridgeCommand *)command {
    NSString *dataURL = [param cj_stringValueForKey:@"dataURL"];
    
    if (!Check_ValidString(dataURL)) {
        // 走截屏处理
        UIImage *topVCSnapShotImg = [[UIViewController cj_topViewController].view btd_snapshotImage];
        NSData *topVCImgData = UIImagePNGRepresentation(topVCSnapShotImg);
        if (topVCImgData) {
            [self trySaveToAlbumWithData:topVCImgData
                                callback:callback
                                 command:command];
        } else {
            [self p_callBackFailWithMsg:@"snapshot image change to data fail" callback:callback];
        }
        return;
    }
    
    if (![dataURL hasPrefix:@"data:"]) {
        [self p_callBackFailWithMsg:@"dataURL error" callback:callback];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:dataURL];
    if (!url) {
        [self p_callBackFailWithMsg:@"dataURL error" callback:callback];
        return;
    }
    
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (!data) {
        [self p_callBackFailWithMsg:@"dataURL error" callback:callback];
        return;
    }
    
    [self trySaveToAlbumWithData:data
                        callback:callback
                         command:command];
}

- (void)trySaveToAlbumWithData:(NSData *)data
                      callback:(TTBridgeCallback)callback
                       command:(TTBridgeCommand *)command {
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusAuthorized) {
        [self saveToAlbumWithData:data
                         callback:callback];
    } else if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        [CJPayPrivacyMethodUtil requestAlbumAuthorizationWithPolicy:@"bpea-caijing_save_img_jsb_request_album_auth"
                                                      bridgeCommand:command
                                                  completionHandler:^(PHAuthorizationStatus status, NSError * _Nullable policyError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self p_isAuthorizedWithStatus:status]) {
                    [self saveToAlbumWithData:data
                                     callback:callback];
                } else {
                    [self p_callBackFailWithMsg:@"no access to album" callback:callback];
                }
            });
        }];
    } else {
        // 引导用户开权限
        [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"提示")
                                           content:CJPayLocalizedStr(@"相册权限被禁用，请在设置中打开相册权限")
                                    leftButtonDesc:CJPayLocalizedStr(@"取消")
                                   rightButtonDesc:CJPayLocalizedStr(@"去设置")
                                   leftActionBlock:^{
            CJPayLogInfo(@"用户放弃设置权限");
            [self p_callBackFailWithMsg:@"user cancel go settings" callback:callback];
        }
                                   rightActioBlock:^{
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            // 调用AppJump敏感方法，需走BPEA鉴权
            [CJPayPrivacyMethodUtil applicationOpenUrl:url
                                            withPolicy:@"bpea-caijing_save_img_jsb_go_settings"
                                         bridgeCommand:command
                                               options:@{}
                                     completionHandler:^(BOOL success, NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                      CJPayLogError(@"error in bpea-caijing_ocr_available_goto_setting");
                      [self p_callBackFailWithMsg:@"go settings bpea error" callback:callback];
                    }
                });
            }];
        } useVC:[UIViewController cj_topViewController]];
    }
}

- (BOOL)p_isAuthorizedWithStatus:(PHAuthorizationStatus)status {
    if (@available(iOS 14.0, *)) {
        return status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited;
    } else {
        return status == PHAuthorizationStatusAuthorized;
    }
}

- (void)saveToAlbumWithData:(NSData *)data
                   callback:(TTBridgeCallback)callback {
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *req = [PHAssetCreationRequest creationRequestForAsset];
        [req addResourceWithType:PHAssetResourceTypePhoto
                            data:data
                         options:nil];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                TTBRIDGE_CALLBACK_SUCCESS
                [CJToast toastText:CJPayLocalizedStr(@"已保存至相册") inWindow:[UIViewController cj_topViewController].cj_window];
            } else {
                [self p_callBackFailWithMsg:@"save data to album failed" callback:callback];
            }
        });
    }];
}

- (void)p_callBackFailWithMsg:(NSString *)msg
                     callback:(TTBridgeCallback)callback {
    TTBRIDGE_CALLBACK_FAILED_MSG(CJString(msg));
    [CJToast toastText:CJPayLocalizedStr(@"保存失败") inWindow:[UIViewController cj_topViewController].cj_window];
}
    
@end
