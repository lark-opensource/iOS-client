//
//  CAKAlbumPreviewPageBottomView.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by yuanchang on 2021/1/14.
//

#import <UIKit/UIKit.h>
#import "CAKAlbumListViewConfig.h"

@interface CAKAlbumPreviewPageBottomView : UIView

@property (nonatomic, strong, nullable) UIView *selectPhotoView;
@property (nonatomic, strong, nullable) UIButton *nextButton;
@property (nonatomic, strong, nullable) UILabel *selectHintLabel;
@property (nonatomic, strong, nullable) UIImageView *unCheckImageView;
@property (nonatomic, strong, nullable) UILabel *numberLabel;
@property (nonatomic, strong, nullable) UIImageView *numberBackGroundImageView;

- (instancetype _Nonnull)initWithSelectedIconStyle:(CAKAlbumAssetsSelectedIconStyle)iconStyle enableRepeatSelect:(BOOL)enableRepeatSelect;

@end
