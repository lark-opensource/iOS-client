//
//  ACCEditFirstCreativeServiceProtocol.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/12/31.
//

#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditFirstCreativeServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *didTapChangeMusicViewSignal;

@end

NS_ASSUME_NONNULL_END
