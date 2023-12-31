//
//  CAKAlbumCategorylistCell.h
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2020/7/27.
//

#import <UIKit/UIKit.h>

@class CAKAlbumModel;

@interface CAKAlbumCategorylistCell : UITableViewCell

@property (nonatomic, strong, readonly, nullable) UILabel *titleLabel;

- (void)configCellWithAlbumModel:(CAKAlbumModel * _Nonnull)albumModel;
- (void)configBlackBackgroundStyle;

@end
