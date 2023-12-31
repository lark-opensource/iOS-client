//
//  AWECollectionStickerPickerController.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import <UIKit/UIKit.h>
#import "AWECollectionStickerPickerModel.h"
#import <EffectPlatformSDK/IESEffectModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWECollectionStickerPickerControllerDelegate;

/**
 * 聚合道具选择面板
 */
@interface AWECollectionStickerPickerController : UIViewController

@property (nonatomic, weak) id<AWECollectionStickerPickerControllerDelegate> delegate;

@property (nonatomic, strong, readonly) AWECollectionStickerPickerModel *model;
@property (nonatomic, strong, readonly) NSIndexPath *selectedIndexPath;

- (instancetype)initWithStickers:(NSArray<IESEffectModel *> *)stickers currentSticker:(IESEffectModel * _Nullable)currentSticker;

- (instancetype)init NS_UNAVAILABLE;

@end

@protocol AWECollectionStickerPickerControllerDelegate <NSObject>

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller
                       willDisplaySticker:(IESEffectModel *)sticker
                              atIndexPath:(NSIndexPath *)indexPath;

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller
                        willSelectSticker:(IESEffectModel *)sticker
                              atIndexPath:(NSIndexPath *)indexPath;

- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller didSelectSticker:(IESEffectModel *)sticker;

@optional
- (void)collectionStickerPickerController:(AWECollectionStickerPickerController *)controller didFailedLoadSticker:(IESEffectModel *)sticker error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
