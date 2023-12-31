//
//  CJPayBridgePlugin_faceVerification.m
//  CJPay
//
//  Created by xiuyuanLee on 2020/11/16.
//

#import "CJPayBridgePlugin_faceVerification.h"
#import "CJPayProtocolManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayFaceRecogPlugin.h"

#import <TTBridgeUnify/TTBridgeRegister.h>

@implementation CJPayBridgePlugin_faceVerification

+ (void)registerBridge {
    TTRegisterBridgeMethod;
    
    TTRegisterAllBridge(TTClassBridgeMethod(CJPayBridgePlugin_faceVerification, faceVerification), @"ttcjpay.faceVerification");
}

+ (TTBridgeInstanceType)instanceType {
    return TTBridgeInstanceTypeAssociated;
}

- (void)faceVerificationWithParam:(NSDictionary *)param callback:(TTBridgeCallback)callback engine:(id<TTBridgeEngine>)engine controller:(UIViewController *)controller {
    
    NSString *faceTicket = [param cj_stringValueForKey:@"ticket"];
    
    CJ_DECLARE_ID_PROTOCOL(CJPayFaceLivenessProtocol);
    
    if (!objectWithCJPayFaceLivenessProtocol || ![objectWithCJPayFaceLivenessProtocol respondsToSelector:@selector(doFaceLivenessWith:extraParams:callback:)]) {
        CJ_CALL_BLOCK(callback, TTBridgeMsgFailed, @{@"code" : @(1),
                                                     @"errMsg" : @"调用活体检测失败"}, nil);
        return;
    }
    
    [objectWithCJPayFaceLivenessProtocol doFaceLivenessWith:param extraParams:[NSDictionary new] callback:^(NSDictionary * _Nullable data, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                // 活体检测成功
                NSDictionary *dataDic = [data cj_objectForKey:@"data"];
                
                // 异步上传活体视频
                [CJ_OBJECT_WITH_PROTOCOL(CJPayFaceRecogPlugin) asyncUploadFaceVideoWithAppId:@"NA202008272032554177543173"
                                                                                  merchantId:@"800010000160013"
                                                                                   videoPath:[dataDic cj_stringValueForKey:@"video_path"]];
                
                NSString *ticket = Check_ValidString(faceTicket) ? faceTicket : [dataDic cj_stringValueForKey:@"ticket"];
                NSData *sdkData = [dataDic cj_objectForKey:@"sdk_data"];
                NSString *sdkDataStr = @"";
                if (sdkData) {
                    sdkDataStr = [[NSString alloc] initWithData:sdkData encoding:NSUTF8StringEncoding];
                }
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code" : @(0),
                                                                  @"errMsg" : @"success",
                                                                  @"ticket" : CJString(ticket),
                                                                  @"faceData" : CJString(sdkDataStr)}, nil);
                });
            } else {
                NSString *code = [error.userInfo cj_stringValueForKey:@"errorCode"];
                NSString *msg = [error.userInfo cj_stringValueForKey:@"errorMessage"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    CJ_CALL_BLOCK(callback, TTBridgeMsgSuccess, @{@"code" : @([code integerValue]),
                                                                 @"errMsg" : CJString(msg)}, nil);
                });
            }
        });
    }];
}


@end
