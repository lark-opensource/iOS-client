//
//  ACCCameraControlProtocolD.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/8/19.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCCameraControlProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraControlProtocolD <ACCCameraControlProtocol>

@property (nonatomic, assign) BOOL enableMultiZoomCapability;

- (void)startAudioCaptureWithReason:(NSString *)reason;
- (void)stopAudioCaptureWithReason:(NSString *)reason;

@end

NS_ASSUME_NONNULL_END
