//
//  ACCSocialStickerhandler.h
//  CameraClient-Pods-Aweme-CameraResource_base
//
//  Created by qiuhang on 2020/8/5.
//

#import <Foundation/Foundation.h>
#import "ACCStickerHandler.h"
#import "ACCStickerDataProvider.h"
#import "ACCSocialStickerView.h"
#import "ACCSocialStickerCommDefines.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import "ACCSocialStickerConfig.h"
#import <CreationKitArch/ACCStickerMigrationProtocol.h>

FOUNDATION_EXTERN NSString * const kSocialStickerUserInfoUniqueIdKey;
FOUNDATION_EXTERN NSString * const kSocialStickerUserInfoDraftJsonDataKey;

FOUNDATION_EXPORT

NS_ASSUME_NONNULL_BEGIN

@interface ACCSocialStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol>

ACCSocialStickerObjUsingCustomerInitOnly;
- (instancetype)initWithDataProvider:(id<ACCSocialStickerDataProvider>)dataProvider
                        publishModel:(AWEVideoPublishViewModel *)publishModel;

@property (nonatomic, copy) void (^onTimeSelect)(ACCSocialStickerView *);
@property (nonatomic, copy) void (^editViewOnStartEdit)(ACCSocialStickerType);
@property (nonatomic, copy) void (^editViewOnFinishEdit)(ACCSocialStickerType);
@property (nonatomic, copy, nullable) void (^onStickerApplySuccess)(void);

- (ACCSocialStickerView *)addSocialStickerWithModel:(nullable ACCSocialStickerModel *)model
                                      locationModel:(nullable AWEInteractionStickerLocationModel *)locationModel
                                   constructorBlock:(nullable void (^)(ACCSocialStickerConfig *))constructorBlock;

- (void)editTextStickerView:(ACCSocialStickerView *)stickerView;

- (void)addAutoAddedStickerViewArray:(NSArray<ACCSocialStickerView *> *)stickerViewArray;

- (void)addSocialStickerAndApplyWithModel:(ACCSocialStickerModel *)model
                            locationModel:(AWEInteractionStickerLocationModel *)locationModel
                    socialStickerUniqueId:(NSString *)socialStickerUniqueId;

@end

NS_ASSUME_NONNULL_END
