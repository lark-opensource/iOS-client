//
//  ACCRecorderMeteorModeServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/11.
//

#ifndef ACCRecorderMeteorModeServiceProtocol_h
#define ACCRecorderMeteorModeServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecorderMeteorModeServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *didChangeMeteorModeSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCRecorderMeteorModeServiceProtocol_h */
