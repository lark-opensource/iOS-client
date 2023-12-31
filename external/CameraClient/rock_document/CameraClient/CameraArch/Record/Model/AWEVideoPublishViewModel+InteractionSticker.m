//
//  AWEVideoPublishViewModel+InteractionSticker.m
//  Pods
//
//  Created by chengfei xiao on 2019/3/31.
//

#import "AWERepoStickerModel.h"
#import "AWEVideoPublishViewModel+InteractionSticker.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <objc/runtime.h>
#import "ACCRepoStickerModel+InteractionSticker.h"

@interface AWEVideoPublishViewModel ()

@end


@implementation AWEVideoPublishViewModel (InteractionSticker)

#pragma mark - public methods

- (void)startRecordStickerLocationsWithSticker:(IESEffectModel *)sticker
{
    [self.repoSticker startRecordStickerLocationsWithSticker:sticker];
}

- (void)appendStickerLocation:(NSString *)locationStr //json array string
                          pts:(CGFloat)pts
{
    [self.repoSticker appendStickerLocation:locationStr pts:pts];
}

- (void)endRecordStickerLocations
{
    [self.repoSticker endRecordStickerLocations];
}

- (void)removeLastSegmentStickerLocations
{
    [self.repoSticker removeLastSegmentStickerLocations];
}

- (void)removeAllSegmentStickerLocations
{
    [self.repoSticker removeAllSegmentStickerLocations];
}


#pragma mark - metadata

- (NSString *)prepareExtraMetaInfoForComposer
{
    return [self.repoSticker prepareExtraMetaInfoForComposer];
}

#pragma mark - draft logic
//按片段保存草稿，因为恢复回来可能用户会一段段的删；
- (NSString * _Nullable)getInteractionProps
{
    return [self.repoSticker getInteractionProps];
}

- (void)recoverWithDraftInteractionProps:(NSString *)interactionProps
{
    [self.repoSticker recoverWithDraftInteractionProps:interactionProps];
}

@end
