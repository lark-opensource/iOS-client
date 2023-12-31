//
//  ACCSelectTemplateServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/3/2.
//

#ifndef ACCSelectTemplateServiceProtocol_h
#define ACCSelectTemplateServiceProtocol_h

#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSelectTemplateServiceProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *didRemoveLyricStickerSignal;
@property (nonatomic, strong, readonly) RACSignal *recoverLyricStickerSignal;

@property (nonatomic, strong, readonly) RACSignal *didRemoveMusicSignal;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCSelectTemplateServiceProtocol */
