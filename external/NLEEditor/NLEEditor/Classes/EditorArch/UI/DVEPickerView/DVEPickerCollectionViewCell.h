//
//  DVEPickerCollectionViewCell.h
//  CameraClient
//
//  Created by bytedance on 2020/4/26.
//

#import <UIKit/UIKit.h>
#import "DVEPickerUIConfigurationProtocol.h"
#import "DVEPickerViewModels.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEPickerCollectionViewCell;

@protocol DVEPickerCollectionViewCellDelegate <NSObject>

- (void)pickerCollectionViewCell:(DVEPickerCollectionViewCell *)cell
                       didSelect:(DVEEffectValue*)model
                               category:(id<DVEPickerCategoryModel>)category
                              indexPath:(NSIndexPath *)indexPath;

- (BOOL)pickerCollectionViewCell:(DVEPickerCollectionViewCell *)cell isSelected:(DVEEffectValue*)model;

@optional
- (void)pickerCollectionViewCell:(DVEPickerCollectionViewCell *)cell
                     willDisplay:(DVEEffectValue*)model
                              indexPath:(NSIndexPath *)indexPath;

- (void)pickerCollectionViewCell:(DVEPickerCollectionViewCell *)cell
              performDynamicSize:(UICollectionViewFlowLayout *)layout;

@end

typedef NS_ENUM(NSUInteger, DVEPickerCollectionViewCellStatus) {
    DVEPickerCollectionViewCellStatusDefault = 0,
    DVEPickerCollectionViewCellStatusLoading = 1,
    DVEPickerCollectionViewCellStatusError = 2,
};

/**
 * 道具面板分页Cell
 */
@interface DVEPickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UICollectionView *pickerCollectionView;

@property (nonatomic, strong, nullable) id<DVEPickerCategoryModel> categoryModel;

@property (nonatomic, weak) id<DVEPickerCollectionViewCellDelegate> delegate;

//@property (nonatomic, strong, class) Class cellClass;

+ (NSString *)identifier;

- (void)updateUIConfig:(id<DVEPickerEffectUIConfigurationProtocol>)config;

- (void)updateStatus:(DVEPickerCollectionViewCellStatus)status;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
