//
//  ACCShootSameStickerHandlerFactory.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/18.
//

#import <Foundation/Foundation.h>

#import "ACCShootSameStickerModel.h"
#import "ACCStickerHandler.h"
#import "ACCShootSameStickerHandlerProtocol.h"
#import "ACCShootSameStickerConfigDelegation.h"

@class AWEVideoPublishViewModel;
@class ACCShootSameStickerModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCShootSameStickerHandlerFactoryProtocol <NSObject>

- (nullable ACCStickerHandler<ACCShootSameStickerHandlerProtocol> *)createHandlerWithStickerModel:(AWEVideoPublishViewModel *)publishModel
                                                                            shootSameStickerModel:(ACCShootSameStickerModel *)shootSameStickerModel
                                                                                 configDelegation:(id<ACCShootSameStickerConfigDelegation>)configDelegation;

- (void)fillPublishModelWithStickerModel:(AWEVideoPublishViewModel *)publisModel
                   shootSameStickerModel:(ACCShootSameStickerModel *)shootSameStickerModel;

@end

@interface ACCShootSameStickerHandlerFactory : NSObject

+ (nullable id<ACCShootSameStickerHandlerFactoryProtocol>)factoryWithType:(AWEInteractionStickerType)stickerType;

@end

NS_ASSUME_NONNULL_END
