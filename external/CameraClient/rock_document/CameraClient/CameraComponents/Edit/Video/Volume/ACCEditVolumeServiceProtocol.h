//
//  ACCEditVolumeServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2020/12/30.
//

#import <CreationKitInfra/ACCRACWrapper.h>

#ifndef ACCEditVolumeServiceProtocol_h
#define ACCEditVolumeServiceProtocol_h

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditVolumeServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *checkMusicFeatureToastSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCEditVolumeServiceProtocol_h */
