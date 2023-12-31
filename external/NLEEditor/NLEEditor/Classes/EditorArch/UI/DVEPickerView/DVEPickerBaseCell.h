//
//  DVEPickerBaseCell.h
//  CameraClient
//
//  Created by bytedance on 2020/7/26.
//

#import <UIKit/UIKit.h>
#import "DVEPickerViewModels.h"

NS_ASSUME_NONNULL_BEGIN

// The DVEPickerBaseCell class is provided as an abstract class for subclassing to define custom collection cell.
@interface DVEPickerBaseCell : UICollectionViewCell

// Override these methods to provide custom UI for a selected or highlighted state
@property (nonatomic, strong, nullable) DVEEffectValue* model;
@property (nonatomic, assign, readonly) BOOL stickerSelected;

/// 设置Cell选中状态
/// @param stickerSelected 选中态
/// @param animated 动画效果
- (void)setStickerSelected:(BOOL)stickerSelected animated:(BOOL)animated NS_REQUIRES_SUPER;

/// 刷新下载按钮状态
- (void)updateDownloadViewStatus;

/// 下载状态view
- (UIView *)downloadView;

/// 下载中view
- (UIView *)downloadingView;

/// 下载失败view
- (UIView *)downloadFailView;

/// 加载内容图片到指定view
/// @param imageView 中心view
-(void)loadImageInView:(UIImageView*)imageView;


@end

NS_ASSUME_NONNULL_END
