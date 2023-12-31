//
//  CJPayPrivacyMethodUtil.h
//  Pods
//
//  Created by 利国卿 on 2022/3/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/PHPhotoLibrary.h>
NS_ASSUME_NONNULL_BEGIN

@interface CJPayPrivacyMethodUtil : NSObject

// 剪切板敏感方法
// 写入剪切板
+ (void)pasteboardSetString:(NSString *)str
                 withPolicy:(NSString *)policy
              bridgeCommand:(nullable id)command
          completionBlock:(void (^)(NSError * _Nullable error))completion;

// 跳转App敏感方法
// 根据URL跳转App
+ (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
           completionBlock:(void (^)(NSError * _Nullable error))completion;

// 根据URL、options跳转App（iOS 10.0及以上可调用）
+ (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
         completionHandler:(void (^)(BOOL success, NSError * _Nullable error))completion;

+ (void)applicationOpenUrl:(NSURL *)url
                withPolicy:(NSString *)policy
             bridgeCommand:(nullable id)command
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
         completionHandler:(void (^)(BOOL success, NSError * _Nullable error))completion;

// 相机敏感方法
// 请求相机权限
+ (void)requestAccessForMediaType:(AVMediaType)mediaType
                       withPolicy:(NSString *)policy
                    bridgeCommand:(nullable id)command
                completionHandler:(void (^)(BOOL granted, NSError * _Nullable error))handler;



// 开始录制视频流
+ (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                            withPolicy:(NSString *)policy
                         bridgeCommand:(id)command
                       completionBlock:(void (^)(NSError * _Nullable error))completion;

// 结束录制视频流
+ (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                           withPolicy:(NSString *)policy
                        bridgeCommand:(id)command
                      completionBlock:(void (^)(NSError * _Nullable error))completion;

// 申请相册权限
+ (void)requestAlbumAuthorizationWithPolicy:(NSString *)policy
                              bridgeCommand:(id)command
                          completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler;

// 向线程中写入证书
+ (void)injectCert:(NSString *)certToken;

// 清除线程中的证书
+ (void)clearCert;

@end

NS_ASSUME_NONNULL_END
