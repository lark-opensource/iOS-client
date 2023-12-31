//
//  ACCInfoStickerViewModel.h
//  Pods
//
//  Created by liyingpeng on 2020/7/30.
//

#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreativeKitSticker/ACCStickerContainerProtocol.h>
#import "ACCInfoStickerServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel, ACCAnimatedDateStickerViewModel, AWEVideoPublishViewModel;
@protocol ACCStickerProtocol,
ACCChallengeModelProtocol,
ACCModelFactoryServiceProtocol;

@interface ACCInfoStickerViewModel : NSObject<ACCInfoStickerServiceProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong) id<ACCModelFactoryServiceProtocol> factoryService;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *cacheStickerChallengeNameDict;
@property (nonatomic, strong, nullable) ACCAnimatedDateStickerViewModel *dateStickerViewModel;

- (void)configChallengeInfo:(IESEffectModel *)sticker;
- (void)fillChallengeDetailWithChallenge:(id<ACCChallengeModelProtocol>)challenge;
- (nullable NSArray <id<ACCChallengeModelProtocol>> *)currentBindChallenges;

- (void)finishAddingStickerWithContext:(ACCAddInfoStickerContext *)context;

@end

NS_ASSUME_NONNULL_END
