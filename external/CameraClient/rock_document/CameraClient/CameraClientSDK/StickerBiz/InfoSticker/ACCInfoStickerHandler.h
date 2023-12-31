//
//  ACCInfoStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2020/11/16.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"
#import "ACCStickerDataProvider.h"
#import <CreationKitArch/ACCStickerMigrationProtocol.h>
#import "ACCInfoStickerConfig.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import "ACCEditTransitionServiceProtocol.h"

@class ACCImageAlbumStickerModel, IESThirdPartyStickerModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCInfoStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol>

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;

@property (nonatomic, copy) void(^recoveryImageAlbumSticker)(ACCStickerContainerView *containerView, ACCImageAlbumStickerModel *sticker);

@property (nonatomic, copy, nullable) void(^recoveryInfoSticker)(IESInfoSticker *sticker);

- (NSInteger)addInfoSticker:(IESEffectModel *)sticker
               stickerProps:(nullable IESInfoStickerProps *)stickerProps
        targetMaxEdgeNumber:(nullable NSNumber *)targetMaxEdgeNumber
                       path:(NSString *)path
                    tabName:(NSString *)tabName
        userInfoConstructor:(nullable void (^)(NSMutableDictionary *userInfo))userInfoConstructor
                constructor:(nullable void (^)(ACCInfoStickerConfig * _Nonnull config, CGSize size))constructor
               onCompletion:(nullable void (^)(void))completionBlock;

- (void)applyContainerSticker:(NSInteger)stickerId
                  effectModel:(nullable IESEffectModel *)effectModel
              thirdPartyModel:(nullable IESThirdPartyStickerModel *)thirdPartyModel
                 stickerProps:(nullable IESInfoStickerProps *)stickerProps
            configConstructor:(nullable void (^)(ACCInfoStickerConfig *config, CGSize size))constructor
                 onCompletion:(nullable void (^)(void))completionBlock;

- (void)recoveryOneInfoSticker:(IESInfoSticker *)oneInfoSticker
              stickerContainer:(ACCStickerContainerView *)stickerContainer
             configConstructor:(nullable void (^)(ACCInfoStickerConfig * _Nonnull, CGSize))constructor
                  onCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
