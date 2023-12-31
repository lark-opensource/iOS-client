//
//  AWEStickerPickerCollectionViewCell.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <UIKit/UIKit.h>
#import <CameraClient/AWEStickerCategoryModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerPickerCollectionViewCell;

@protocol AWEStickerPickerCollectionViewCellDelegate <NSObject>

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
                       didSelectSticker:(IESEffectModel *)sticker
                               category:(AWEStickerCategoryModel *)category
                              indexPath:(NSIndexPath *)indexPath;

- (BOOL)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell isStickerSelected:(IESEffectModel *)sticker;

@optional
- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
                     willDisplaySticker:(IESEffectModel *)sticker
                              indexPath:(NSIndexPath *)indexPath;

- (void)stickerPickerCollectionViewCell:(AWEStickerPickerCollectionViewCell *)cell
            scrollViewWillBeginDragging:(UIScrollView *)scrollView;

@end

typedef NS_ENUM(NSUInteger, AWEStickerPickerCollectionViewCellStatus) {
    AWEStickerPickerCollectionViewCellStatusDefault = 0,
    AWEStickerPickerCollectionViewCellStatusLoading = 1,
    AWEStickerPickerCollectionViewCellStatusError = 2,
};

/**
 * 道具面板分页Cell
 */
@interface AWEStickerPickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UICollectionView *stickerCollectionView;

@property (nonatomic, strong, nullable) AWEStickerCategoryModel *categoryModel;

@property (nonatomic, weak) id<AWEStickerPickerCollectionViewCellDelegate> delegate;

@property (nonatomic, strong, class) Class stickerCellClass;

+ (NSString *)identifier;

- (void)updateUIConfig:(id<AWEStickerPickerEffectUIConfigurationProtocol>)config;

- (void)updateStatus:(AWEStickerPickerCollectionViewCellStatus)status;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
