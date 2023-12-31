//
//  CJPayHybridPolicyEntryPlugin.h
//  Pods
//
//  Created by 利国卿 on 2022/7/18.
//

#ifndef CJPayHybridPolicyEntryPlugin_h
#define CJPayHybridPolicyEntryPlugin_h

#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayHybridPolicyEntryPlugin <NSObject>

// 剪切板敏感方法
- (void)pasteboardSetString:(NSString *)str
              bridgeCommand:(id)command
                 withPolicy:(NSString *)policy
                      error:(NSError **)error;

// App跳转敏感方法（带前端上下文信息）
- (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
             bridgeCommand:(id)command
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
         completionHandler:(void (^ __nullable)(BOOL success, NSError *error))completion;

// 相机权限敏感方法（带前端上下文信息）
- (void)requestAccessForMediaType:(AVMediaType)mediaType
                       withPolicy:(NSString *)policy
                    bridgeCommand:(id)command
                completionHandler:(void (^)(BOOL granted, NSError *error))handler;

- (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                            withPolicy:(NSString *)policy
                         bridgeCommand:(id)command
                                 error:(NSError **)error;

- (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                           withPolicy:(NSString *)policy
                        bridgeCommand:(id)command
                                error:(NSError **)error;

// 请求相册权限
- (void)requestAlbumAuthorizationWithPolicy:(NSString *)policy
                              bridgeCommand:(id)command
                          completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler;

@end

NS_ASSUME_NONNULL_END
#endif /* CJPayHybridPolicyEntryPlugin_h */
