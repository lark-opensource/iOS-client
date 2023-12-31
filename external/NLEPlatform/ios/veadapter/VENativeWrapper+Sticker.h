//
//  VENativeWrapper+Sticker.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/21.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Sticker)

/// 贴纸
/// @param changeInfos std::vector<SlotChangeInfo>
- (void)syncStickers:(std::vector<SlotChangeInfo> &)changeInfos;

/**
 根据slot ID获得sticker ID
 */
- (nullable NSString*)slotIdForSticker:(NSInteger)stickerId;

/**
 根据sticker ID获得slot ID
 */
- (NSInteger)stickerIdForSlot:(NSString*)slotName;


/*
 重新生成Sticker 和 slot 的映射关系，为了在移动贴纸的时候提高查找效率
 */
- (void)generateSlotAndStickerRelationshipWithOriginMap:(NSDictionary<NSString *, NSNumber *> *)originMap;

- (void)updateNewRelationForSticker:(IESInfoSticker *)newSticker
                      prevStickerId:(NSInteger)prevStickerId;

/// 为信息化贴纸设置userInfo
/// @param userInfo 贴纸需要的userInfo
/// @param slotName 所属的slotId
- (void)setUserInfo:(NSDictionary *)userInfo forStickerSlot:(NSString *)slotName;

/*
 获得全部信息化贴纸
 */
- (NSArray<IESInfoSticker *> *)getInfoStickers;

- (void)addStickerByUIImage:(UIImage *)image letterInfo:(NSString *)letterInfo duration:(CGFloat)duration;

- (BOOL)isAnimationSticker:(NSInteger)stickerId;

- (void)getStickerId:(NSInteger)stickerId props:(IESInfoStickerProps *)props;

- (void)startChangeStickerDuration:(NSInteger)stickerId;

- (void)stopChangeStickerDuration:(NSInteger)stickerId;

/*
 * Pin RestoreMode
 */
- (void)setInfoStickerRestoreMode:(VEInfoStickerRestoreMode)mode;

- (void)updateStickerAnimationForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot
                              oriSlot:(std::shared_ptr<cut::model::NLETrackSlot>)oriSlot;

- (void)removeAllStickerAnimationForSlot:(std::shared_ptr<cut::model::NLETrackSlot>)slot;

- (void)syncPinSticker:(std::vector<SlotChangeInfo> &)changeInfos;

- (NSDictionary *)userInfoForStickerSlot:(NSString*)slotName;

- (void)preparePin;

@end

NS_ASSUME_NONNULL_END
