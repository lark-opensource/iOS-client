//
//  AWEVideoPublishViewModel+InteractionSticker.h
//  Pods
//
//  Created by chengfei xiao on 2019/3/31.
//  道具转化需求 - https://sso.bytedance.com/cas/login?service=https%3A%2F%2Fwiki.bytedance.net%2Fpages%2Fviewpage.action%3FpageId%3D292930328
//  只支持拍摄，不支持上传

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>

@class IESEffectModel;
NS_ASSUME_NONNULL_BEGIN

@interface AWEVideoPublishViewModel (InteractionSticker)

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
