//
//  CJPayPolicyEntryPluginImpl.h
//  Pods
//
//  Created by 利国卿 on 2022/2/21.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <BDPolicyKit/BDPrivacyCertProtocol.h>
#import <Photos/PHPhotoLibrary.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPolicyEntryPluginImpl : NSObject

// 剪切板敏感方法
- (void)pasteboardSetString:(NSString *)str withCert:(id<BDPrivacyCertProtocol>)cert error:(NSError **)error;

// 带BPEA证书调用BPEA接口
- (void)applicationOpenUrl:(NSURL *)url
                  withCert:(id<BDPrivacyCertProtocol>)cert
                   options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey,id> *)options
         completionHandler:(void (^)(BOOL, NSError *))completion;

- (void)requestAccessForMediaType:(AVMediaType)mediaType
                         withCert:(id<BDPrivacyCertProtocol>)cert
                completionHandler:(void (^)(BOOL, NSError *))handler;

- (void)startRunningWithCaptureSession:(AVCaptureSession *)session
                              withCert:(id<BDPrivacyCertProtocol>)cert
                                 error:(NSError **)error;

- (void)stopRunningWithCaptureSession:(AVCaptureSession *)session
                              withCert:(id<BDPrivacyCertProtocol>)cert
                                 error:(NSError **)error;

- (void)requestAlbumAuthorizationWithCert:(id<BDPrivacyCertProtocol>)cert
                        completionHandler:(void (^ _Nullable)(PHAuthorizationStatus status, NSError * _Nullable policyError))requestCompletionHandler;

@end

NS_ASSUME_NONNULL_END
