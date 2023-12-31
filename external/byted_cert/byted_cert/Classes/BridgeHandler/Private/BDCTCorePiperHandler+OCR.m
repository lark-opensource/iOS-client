//
//  BytedCertCorePiperHandler+CertificationFlow.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/3/10.
//

#import "BDCTCorePiperHandler+OCR.h"
#import "BDCTImageManager.h"
#import "BytedCertWrapper.h"
#import "BDCTAPIService.h"
#import "BDCTLog.h"
#import "BDCTEventTracker.h"
#import "BDCTTakeOCRPhotoViewController.h"
#import "BytedCertManager+Private.h"
#import "UIViewController+BDCTAdditions.h"
#import "AVCaptureDevice+BDCTAdditions.h"


@implementation BDCTCorePiperHandler (OCR)

- (void)registerTakePhoto {
    [self registeJSBWithName:@"bytedcert.takePhoto" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        [self.imageManager selectImageWithParams:params.copy completion:^(NSDictionary *data) {
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:data error:nil], nil);
        }];
    }];
}

- (void)registerUploadPhoto {
    [self registeJSBWithName:@"bytedcert.uploadPhoto" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        NSString *type = params[@"type"];
        NSData *imageData = [self.imageManager getImageByType:type];
        [self.flow.apiService bytedCommonOCR:imageData type:type callback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:data error:nil], nil);
        }];
    }];
}

- (void)registerOCRV2 {
    [self registeJSBWithName:@"bytedcert.doOCR" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        [self.flow.apiService bytedOCRWithFrontImageData:[self.imageManager getImageByType:@"front"] backImageData:[self.imageManager getImageByType:@"back"] callback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:data error:nil], nil);
        }];
    }];
}

- (void)registerTakeOCRPhoto {
    [self registeJSBWithName:@"bytedcert.takeOCRPhoto" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        [AVCaptureDevice bdct_requestAccessForCameraWithSuccessBlock:^{
            [self.flow.eventTracker trackManualDetectionCameraPermit:YES];
            BDCTTakeOCRPhotoViewController *vc = [BDCTTakeOCRPhotoViewController viewControllerWithParams:params completion:^(NSDictionary *ocrResult) {
                callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:ocrResult error:nil], nil);
            }];
            if (!vc) {
                callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:@{@"status_code" : @(BytedCertErrorArgs)} error:nil], nil);
            } else {
                vc.flow = self.flow;
                BDCTDismissLoading;
                [[UIViewController bdct_topViewController] presentViewController:vc animated:YES completion:nil];
            }
        } failBlock:^{
            [self.flow.eventTracker trackManualDetectionCameraPermit:NO];
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:@{@"status_code" : @(BytedCertErrorCameraPermission)} error:nil], nil);
        }];
    }];
}

- (void)registerManualVerify {
    [self registeJSBWithName:@"bytedcert.manualVerify" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        NSData *frontImageData = [self.imageManager getImageByType:@"front"];
        NSData *holdImageData = [self.imageManager getImageByType:@"hold"];
        [self.flow.apiService bytedManualCheck:params frontImageData:frontImageData holdImageData:holdImageData callback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
            BDCTLogInfo(@"Func#registerManualVerify, %@\n", data);
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:data error:nil], nil);
        }];
    }];
}

- (void)registerPreManualVerify {
    [self registeJSBWithName:@"bytedcert.preManualCheck" handler:^(NSDictionary *_Nullable params, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        NSData *frontImageData = [self.imageManager getImageByType:@"front"];
        NSData *backImageData = [self.imageManager getImageByType:@"back"];
        if (frontImageData == nil || backImageData == nil) {
            callback(
                TTBridgeMsgSuccess, @{@"status_code" : @(BytedCertErrorArgs)}, nil);
            return;
        }
        [self.flow.apiService preManualCheckWithParams:params frontIDCardImageData:frontImageData backIDCardImageData:backImageData callback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
            BDCTLogInfo(@"Func#registerPreManualVerify, %@\n", data);
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:data error:nil], nil);
        }];
    }];
}

@end
