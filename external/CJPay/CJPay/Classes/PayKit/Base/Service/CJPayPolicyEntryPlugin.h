//
//  CJPayPolicyEntryPlugin.h
//  Pods
//
//  Created by 利国卿 on 2022/2/21.
//

#ifndef CJPayPolicyEntryPlugin_h
#define CJPayPolicyEntryPlugin_h

#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayPolicyEntryPlugin <NSObject>

// 剪切板敏感方法
- (void)pasteboardSetString:(NSString *)str withPolicy:(NSString *)policy error:(NSError **)error;

// App跳转敏感方法
- (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
         completionHandler:(void (^ __nullable)(BOOL success, NSError *error))completion;

// 相机权限敏感方法
- (void)requestAccessForMediaType:(AVMediaType)mediaType
                       withPolicy:(NSString *)policy
                completionHandler:(void (^)(BOOL granted, NSError *error))handler;
- (void)startRunningWithCaptureSession:(AVCaptureSession *)session withPolicy:(NSString *)policy error:(NSError **)error;
- (void)stopRunningWithCaptureSession:(AVCaptureSession *)session withPolicy:(NSString *)policy error:(NSError **)error;
// 请求相册访问权限
- (void)requestAlbumAuthorizationWithPolicy:(NSString *)policy
                          completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler;
- (void)injectCert:(NSString *)certToken;
- (void)clearCert;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayPolicyEntryPlugin_h */
