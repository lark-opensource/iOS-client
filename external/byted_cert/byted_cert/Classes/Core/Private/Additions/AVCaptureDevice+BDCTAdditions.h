//
//  AVCaptureDevice+BDCTAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2022/2/6.
//

#import <AVFoundation/AVCaptureDevice.h>

NS_ASSUME_NONNULL_BEGIN


@interface AVCaptureDevice (BDCTAdditions)

+ (instancetype)bdct_frontCamera;

+ (instancetype)bdct_backCamera;

+ (BOOL)bdct_hasCameraPermission;

+ (void)bdct_requestAccessForCameraWithSuccessBlock:(void (^)(void))successBlock failBlock:(void (^)(void))failBlock;

+ (BOOL)bdct_hasAudioPermission;

+ (void)bdct_requestAccessForAudioWithSuccessBlock:(void (^)(void))successBlock failBlock:(void (^)(void))failBlock;

@end

NS_ASSUME_NONNULL_END
