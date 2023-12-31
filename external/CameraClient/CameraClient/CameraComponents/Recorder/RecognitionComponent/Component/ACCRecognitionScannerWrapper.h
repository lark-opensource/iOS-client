//
//  ACCRecognitionWrapper.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/16.
//

#import <Foundation/Foundation.h>

@protocol ACCCameraService;
@protocol ACCRecognitionService;
@class SSScanResult;
@class SSRecommendResult;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCRecognitionAutoScanBlock)(SSScanResult * _Nullable  result, NSError * _Nullable  error);
typedef BOOL(^ACCRecognitionAutoScanFilterBlock)(SSScanResult * _Nullable  result);
typedef void(^ACCRecognitionScanBlock)(SSRecommendResult * _Nullable  result, NSError * _Nullable  error);

@interface ACCRecognitionScannerWrapper : NSObject

/// outer
@property (nonatomic,   weak) id<ACCCameraService> cameraService;
@property (nonatomic,   weak) id<ACCRecognitionService> recognitionService;

- (void)scanForRecognizeWithMode:(NSString *)mode completion:(ACCRecognitionScanBlock)completion;
- (void)cancelRecognizeScanning;

- (BOOL)startAutoScanWithFliter:(ACCRecognitionAutoScanFilterBlock)filter completion:(ACCRecognitionAutoScanBlock)completion;
- (void)stopAutoScan;


@end

NS_ASSUME_NONNULL_END
