//
//  CJPayHybridPolicyEntryPluginImpl.m
//  Pods
//
//  Created by 利国卿 on 2022/7/18.
//

#import "CJPayHybridPolicyEntryPluginImpl.h"
#import "CJPayHybridPolicyEntryPlugin.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import <AVFoundation/AVFoundation.h>
#import <BDPolicyKit/BDTokenCert.h>
#import <BDPolicyKit/BDHybridTokenCert.h>

#import "CJPayPolicyEntryPluginImpl.h"
#import <TTBridgeUnify/TTBridgeCommand.h>
#import <IESSecurityPlugins/TTBridgeCommand+BPEAContext.h>

@interface CJPayHybridPolicyEntryPluginImpl ()<CJPayHybridPolicyEntryPlugin>

@property (nonatomic, strong)CJPayPolicyEntryPluginImpl *basePluginImpl;

@end

@implementation CJPayHybridPolicyEntryPluginImpl

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayHybridPolicyEntryPlugin);
});

#pragma mark CJPayHybridPolicyEntryPlugin

// 剪切板敏感方法
- (void)pasteboardSetString:(NSString *)str
              bridgeCommand:(id)command
                 withPolicy:(NSString *)policy
                      error:(NSError **)error {
    id<BDPrivacyCertProtocol> cert = [self p_getTokenCert:policy bridgeCommand:command];
    [self.basePluginImpl pasteboardSetString:str withCert:cert error:error];
}

// 跳转APP敏感方法
- (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
             bridgeCommand:(id)command
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey,id> *)options
         completionHandler:(void (^)(BOOL, NSError *))completion {
    
    id<BDPrivacyCertProtocol> cert = [self p_getTokenCert:policy bridgeCommand:command];
    [self.basePluginImpl applicationOpenUrl:url withCert:cert options:options completionHandler:completion];
}

// 相机敏感方法
- (void)requestAccessForMediaType:(AVMediaType)mediaType
                       withPolicy:(NSString *)policy
                    bridgeCommand:(id)command
                completionHandler:(void (^)(BOOL, NSError *))handler {
    
    
    id<BDPrivacyCertProtocol> cert = [self p_getTokenCert:policy bridgeCommand:command];
    [self.basePluginImpl requestAccessForMediaType:mediaType withCert:cert completionHandler:handler];
}

- (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                            withPolicy:(NSString *)policy
                         bridgeCommand:(id)command
                                 error:(NSError **)error {
    
       
    id<BDPrivacyCertProtocol> cert = [self p_getTokenCert:policy bridgeCommand:command];
    [self.basePluginImpl startRunningWithCaptureSession:session withCert:cert error:error];
}

- (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                           withPolicy:(NSString *)policy
                        bridgeCommand:(id)command
                                error:(NSError *__autoreleasing *)error {
    
    id<BDPrivacyCertProtocol> cert = [self p_getTokenCert:policy bridgeCommand:command];
    [self.basePluginImpl stopRunningWithCaptureSession:session withCert:cert error:error];
}

// 请求相册权限
- (void)requestAlbumAuthorizationWithPolicy:(NSString *)policy
                              bridgeCommand:(id)command
                          completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler {
    id<BDPrivacyCertProtocol> cert = [self p_getTokenCert:policy bridgeCommand:command];
    [self.basePluginImpl requestAlbumAuthorizationWithCert:cert
                                         completionHandler:requestCompletionHandler];
}

#pragma mark - privacy method
// 生成跨端敏感方法BPEA证书
- (id<BDPrivacyCertProtocol>)p_getTokenCert:(NSString *)policy bridgeCommand:(id)command{

    NSAssert(Check_ValidString(policy), @"policy is invalid");
    NSAssert(command, @"command is invalid");
    
    // BPEA鉴权token
    id<BDPrivacyCertProtocol> cert;
    if ([command isKindOfClass:TTBridgeCommand.class]) {
        TTBridgeCommand *bridgeCommand = (TTBridgeCommand *)command;
        cert = BDHybridTokenCert.create.token(policy).updatePage(bridgeCommand.bpea_pageContext).updateAPI(bridgeCommand.bpea_apiContext);
    } else {
        cert = BDTokenCert.create.token(policy);
    }
    return cert;
}

- (CJPayPolicyEntryPluginImpl *)basePluginImpl {
    if (!_basePluginImpl) {
        _basePluginImpl = [CJPayPolicyEntryPluginImpl new];
    }
    return _basePluginImpl;
}

@end
