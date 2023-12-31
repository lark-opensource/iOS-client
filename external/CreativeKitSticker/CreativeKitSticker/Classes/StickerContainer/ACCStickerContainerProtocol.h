//
//  ACCStickerContainerProtocol.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/7.
//

#import "ACCPlayerAdaptionContainerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerProtocol;
@protocol ACCStickerContentProtocol;

@class ACCStickerConfig;

typedef UIView<ACCStickerProtocol> * ACCStickerViewType;

@protocol ACCStickerContainerProtocol <ACCPlayerAdaptionContainerProtocol>

- (UIView *)containerView;

#pragma mark - Sticker Management

- (ACCStickerViewType)addStickerView:(UIView <ACCStickerContentProtocol> *)stickerView config:(__kindof ACCStickerConfig *)config;

- (void)removeStickerView:(UIView *)stickerView;
- (void)removeAllStickerViews;

- (void)selectStickerView:(UIView <ACCStickerProtocol> * _Nullable)stickerView withTapCenter:(CGPoint)tapCenter;

- (NSArray<ACCStickerViewType> *)allStickerViews;
- (NSArray<ACCStickerViewType> *)stickerViewsWithTypeId:(id)typeId;
- (NSArray<ACCStickerViewType> *)stickerViewsWithHierarchyId:(id)hierarchyId;
- (ACCStickerViewType)stickerViewWithContentView:(UIView *)contentView;

- (NSArray<ACCStickerViewType> *)subStickerViewsInGroup:(NSNumber *)groupId;

- (nullable NSString *)contextID;

@end

NS_ASSUME_NONNULL_END
