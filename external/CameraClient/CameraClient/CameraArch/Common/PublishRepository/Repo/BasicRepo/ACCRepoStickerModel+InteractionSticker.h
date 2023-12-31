//
//  ACCRepoStickerModel+InteractionSticker.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/11/30.
//

#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoStickerModel (InteractionSticker)

#pragma mark - record

- (void)startRecordStickerLocationsWithSticker:(IESEffectModel *)sticker;

- (void)appendStickerLocation:(NSString *)locationStr pts:(CGFloat)pts;

- (void)endRecordStickerLocations;

- (void)removeLastSegmentStickerLocations;

- (void)removeAllSegmentStickerLocations;

#pragma mark - metadata

- (NSString *)prepareExtraMetaInfoForComposer;

#pragma mark - draft logic

- (NSString * _Nullable)getInteractionProps;

- (void)recoverWithDraftInteractionProps:(NSString *)interactionProps;

@end

NS_ASSUME_NONNULL_END
