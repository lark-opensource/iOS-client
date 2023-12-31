//
//  ACCModernPOIStickerHandler.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCStickerMigrationProtocol.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import "ACCStickerHandler.h"
#import "ACCStickerDataProvider.h"
#import "ACCDraftResourceRecoverProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEInteractionStickerModel;

@interface ACCModernPOIStickerHandler : ACCStickerHandler <ACCStickerMigrationProtocol, ACCDraftResourceRecoverProtocol>

@property (nonatomic, weak) id<ACCPOIStickerDataProvider> dataProvider;
@property (nonatomic, copy) void(^onEditPoiInfo)(void);
@property (nonatomic, copy) void(^editViewOnStartEdit)(void);
@property (nonatomic, copy) void(^editViewOnFinishEdit)(void);
@property (nonatomic, copy, nullable) void(^onStickerApplySuccess)(void);

+ (BOOL)useModernPOIStickerStyle:(NSArray<AWEInteractionStickerModel *> *)interactionStickers;
- (void)addPOIStickerWithPOIModel:(ACCPOIStickerModel *)model;

@end

NS_ASSUME_NONNULL_END
