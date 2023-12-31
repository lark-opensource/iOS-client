//
//  CJPayPolicyEntryPluginImpl.m
//  Pods
//
//  Created by 利国卿 on 2022/2/21.
//

#import "CJPayPolicyEntryPluginImpl.h"
#import "CJPayPolicyEntryPlugin.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import <BDPolicyKit/BDTokenCert.h>
#import <BDPolicyKit/BDPasteboardPolicyEntry.h>
#import <BDPolicyKit/BDAppJumpPrivacyCertEntry.h>
#import <BDPolicyKit/BDCameraPrivacyCertEntry.h>
#import <BDPolicyKit/BDThreadCertEntry.h>
#import <BDPolicyKit/BDAlbumPrivacyCertEntry.h>

@interface CJPayPolicyEntryPluginImpl ()<CJPayPolicyEntryPlugin>

@end

@implementation CJPayPolicyEntryPluginImpl

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayPolicyEntryPlugin);
});

#pragma mark - CJPayPolicyEntryPlugin
// 写入剪切板
- (void)pasteboardSetString:(NSString *)str withPolicy:(NSString *)policy error:(NSError **)error {

    BDTokenCert *cert = [self p_getTokenCert:policy];

    [self pasteboardSetString:str withCert:cert error:error];

}

- (void)pasteboardSetString:(NSString *)str withCert:(id<BDPrivacyCertProtocol>)cert error:(NSError *__autoreleasing  _Nullable *)error {
    [BDPasteboardPolicyEntry setString:str withPolicy:cert error:error];
}

// 跳转APP
- (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey,id> *)options
         completionHandler:(void (^)(BOOL, NSError *))completion {
    
    BDTokenCert *cert = [self p_getTokenCert:policy];
    [self applicationOpenUrl:url withCert:cert options:options completionHandler:completion];
}

// 申请相机权限
- (void)requestAccessForMediaType:(AVMediaType)mediaType
                       withPolicy:(NSString *)policy 
                completionHandler:(void (^)(BOOL, NSError *))handler {
    
    BDTokenCert *cert = [self p_getTokenCert:policy];
    [self requestAccessForMediaType:mediaType withCert:cert completionHandler:handler];
}

// 启动视频流录制
- (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                            withPolicy:(NSString *)policy
                                 error:(NSError **)error {
    
    BDTokenCert *cert = [self p_getTokenCert:policy];
    [self startRunningWithCaptureSession:session withCert:cert error:error];
}

// 结束视频流录制
- (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                           withPolicy:(NSString *)policy
                                error:(NSError **)error {
    
    BDTokenCert *cert = [self p_getTokenCert:policy];
    [self stopRunningWithCaptureSession:session withCert:cert error:error];
}

// 请求相册权限
- (void)requestAlbumAuthorizationWithPolicy:(NSString *)policy
                          completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler {
    BDTokenCert *cert = [self p_getTokenCert:policy];
    [self requestAlbumAuthorizationWithCert:cert
                          completionHandler:requestCompletionHandler];
}

// 向线程中写入证书
- (void)injectCert:(NSString *)certToken {
    [BDThreadCertEntry injectCert:certToken];
}

// 清除线程中的证书
- (void)clearCert {
    [BDThreadCertEntry clearCert];
}

#pragma mark - call BPEA with cert

- (void)applicationOpenUrl:(NSURL *)url
                  withCert:(id<BDPrivacyCertProtocol>)cert
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey,id> *)options
         completionHandler:(void (^)(BOOL, NSError * _Nonnull))completion {
    
    if (@available(iOS 10.0, *)) {
        
        [BDAppJumpPrivacyCertEntry openURL:url withCert:cert options:options completionHandler:^(BOOL granted, NSError *policyError) {
            
            CJ_CALL_BLOCK(completion, granted, policyError);
        }];
    } else {
        NSError *error;
        [BDAppJumpPrivacyCertEntry openURL:url withCert:cert error:&error];
        
        CJ_CALL_BLOCK(completion, YES, error);
    }
}

- (void)requestAccessForMediaType:(AVMediaType)mediaType
                         withCert:(id<BDPrivacyCertProtocol>)cert
                completionHandler:(void (^)(BOOL, NSError * _Nonnull))handler {
    
    [BDCameraPrivacyCertEntry requestAccessCameraWithPrivacyCert:cert
                                               completionHandler:^(BOOL granted, NSError * _Nonnull policyError) {
        
        CJ_CALL_BLOCK(handler, granted, policyError);
    }];
}

- (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                              withCert:(id<BDPrivacyCertProtocol>)cert
                                 error:(NSError *__autoreleasing  _Nullable *)error {
    
    [BDCameraPrivacyCertEntry startRunningWithCaptureSession:session privacyCert:cert error:error];
}

- (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                             withCert:(id<BDPrivacyCertProtocol>)cert
                                error:(NSError *__autoreleasing  _Nullable *)error {
    
    [BDCameraPrivacyCertEntry stopRunningWithCaptureSession:session privacyCert:cert error:error];
}

- (void)requestAlbumAuthorizationWithCert:(id<BDPrivacyCertProtocol>)cert
                        completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler {
    if (@available(iOS 14.0, *)) {
        [BDAlbumPrivacyCertEntry requestAuthorizationForAccessLevel:PHAccessLevelReadWrite
                                                           withCert:cert
                                                  completionHandler:requestCompletionHandler];
    } else {
        [BDAlbumPrivacyCertEntry requestAuthorizationWithCert:cert
                                            completionHandler:requestCompletionHandler];
    }
}

#pragma mark - privacy method
// 生成客户端敏感方法BPEA证书
- (BDTokenCert *)p_getTokenCert:(NSString *)policy {

    CJPayLogAssert(Check_ValidString(policy), @"policy is invalid");
    
    BDTokenCert *cert = BDTokenCert.create.token(policy);
    return cert;
}

@end
