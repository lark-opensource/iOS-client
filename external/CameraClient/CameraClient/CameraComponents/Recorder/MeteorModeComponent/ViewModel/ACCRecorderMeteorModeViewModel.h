//
//  ACCRecorderMeteorModeViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/11.
//

#import "ACCRecorderMeteorModeServiceProtocol.h"

#import <CreationKitArch/ACCRecorderViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderMeteorModeViewModel : ACCRecorderViewModel <ACCRecorderMeteorModeServiceProtocol>

- (void)sendDidChangeMeteorModeSignal:(BOOL)isMeteorModeOn;

@end

NS_ASSUME_NONNULL_END
