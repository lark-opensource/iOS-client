//
//  CJPayPrivacyMethodUtil.m
//  Pods
//
//  Created by 利国卿 on 2022/3/3.
//

#import "CJPayPrivacyMethodUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayPolicyEntryPlugin.h"
#import "CJPayHybridPolicyEntryPlugin.h"

@implementation CJPayPrivacyMethodUtil

// 写入剪切板
+ (void)pasteboardSetString:(NSString *)str
                 withPolicy:(NSString *)policy
              bridgeCommand:(nullable id)command
            completionBlock:(void (^)(NSError * _Nullable))completion {
    NSError *error;
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) && command) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) pasteboardSetString:str bridgeCommand:command withPolicy:policy error:&error];
        CJ_CALL_BLOCK(completion, error);
    } else if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) pasteboardSetString:str withPolicy:policy error:&error];
        
        CJ_CALL_BLOCK(completion, error);
    } else {
        
        [UIPasteboard generalPasteboard].string = str;
        CJ_CALL_BLOCK(completion, nil);
    }
}

// 跳转App
+ (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
           completionBlock:(void (^)(NSError * _Nullable))completion {
    
    [self applicationOpenUrl:url
                  withPolicy:policy
                     options:@{}
           completionHandler:^(BOOL success, NSError * _Nullable error) {
        
        CJ_CALL_BLOCK(completion, error);
    }];
}

+ (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey,id> *)options
         completionHandler:(void (^)(BOOL, NSError * _Nullable))completion {
    
    [self applicationOpenUrl:url withPolicy:policy bridgeCommand:nil options:options completionHandler:completion];
}

+ (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
             bridgeCommand:(nullable id)command
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey,id> *)options
         completionHandler:(void (^)(BOOL, NSError * _Nullable))completion {
    
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) && command) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) applicationOpenUrl:url withPolicy:policy bridgeCommand:command options:options completionHandler:completion];
        
    } else if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) applicationOpenUrl:url withPolicy:policy options:options completionHandler:^(BOOL success, NSError *error) {
            
            CJ_CALL_BLOCK(completion, success, error);
        }];
    } else {
        if (@available(iOS 10.0, *)) {
            [[UIApplication sharedApplication] openURL:url options:options completionHandler:^(BOOL success) {
                CJ_CALL_BLOCK(completion, success, nil);
            }];
        } else {
            [[UIApplication sharedApplication] openURL:url];
            CJ_CALL_BLOCK(completion, YES, nil);
        }
    }
}

// 相机
+ (void)requestAccessForMediaType:(AVMediaType)mediaType
                       withPolicy:(NSString *)policy
                    bridgeCommand:(nullable id)command
                completionHandler:(void (^)(BOOL, NSError * _Nullable))handler {
    
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) && command) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) requestAccessForMediaType:mediaType withPolicy:policy bridgeCommand:command completionHandler:^(BOOL granted, NSError *error) {
            CJ_CALL_BLOCK(handler, granted, error);
        }];
    } else if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) requestAccessForMediaType:mediaType withPolicy:policy completionHandler:^(BOOL granted, NSError *error) {
            
            CJ_CALL_BLOCK(handler, granted, error);
        }];
    } else {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            CJ_CALL_BLOCK(handler, granted, nil);
        }];
    }
}

+ (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                            withPolicy:(NSString *)policy
                         bridgeCommand:(id)command
                       completionBlock:(void (^)(NSError * _Nullable))completion {
    
    NSError *error;
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) && command) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) startRunningWithCaptureSession:session withPolicy:policy bridgeCommand:command error:&error];
        
    } else if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) startRunningWithCaptureSession:session withPolicy:policy error:&error];
    } else {
        [session startRunning];
    }
    
    CJ_CALL_BLOCK(completion, error);
}

+ (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                           withPolicy:(NSString *)policy
                        bridgeCommand:(id)command
                      completionBlock:(void (^)(NSError * _Nullable))completion {
    
    NSError *error;
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) && command) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) stopRunningWithCaptureSession:session withPolicy:policy bridgeCommand:command error:&error];
        
    } else if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) stopRunningWithCaptureSession:session withPolicy:policy error:&error];
    } else {
        [session stopRunning];
    }
    
    CJ_CALL_BLOCK(completion, error);
}

// 申请相册权限
+ (void)requestAlbumAuthorizationWithPolicy:(NSString *)policy
                              bridgeCommand:(id)command
                          completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler {
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) && command) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayHybridPolicyEntryPlugin) requestAlbumAuthorizationWithPolicy:policy
                                                                                     bridgeCommand:command
                                                                                 completionHandler:requestCompletionHandler];
        
    } else if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) requestAlbumAuthorizationWithPolicy:policy
                                                                           completionHandler:requestCompletionHandler];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            CJ_CALL_BLOCK(requestCompletionHandler, status, nil);
        }];
    }
}

+ (void)injectCert:(NSString *)certToken
{
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) injectCert:certToken];
    }
}

+ (void)clearCert
{
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayPolicyEntryPlugin) clearCert];
    }
}

@end
