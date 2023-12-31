//
//  ACCMicrophoneViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/3/18.
//

#import <CreationKitArch/ACCRecorderViewModel.h>

#import "ACCMicrophoneService.h"

@class IESEffectModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCMicrophoneViewModel : ACCRecorderViewModel <ACCMicrophoneService>

@property (nonatomic, assign, readonly) BOOL shouldOpenAEC;
@property (nonatomic, strong, readonly) IESEffectModel *storedProp;

- (void)setUpSession;
- (void)trackClickMicButton;
- (void)setSupportedMode:(BOOL)isSupportedMode;
- (BOOL)shouldShowMicroBar;
- (void)updateAcousticAlgorithmConfig;

@end

NS_ASSUME_NONNULL_END
