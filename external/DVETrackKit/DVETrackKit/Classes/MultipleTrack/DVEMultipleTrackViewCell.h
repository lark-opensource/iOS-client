//
//  DVEMultipleTrackViewCell.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <UIKit/UIKit.h>
#import "DVEMultipleTrackViewCellViewModel.h"
#import "DVESegmentClipView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackViewCell : UICollectionViewCell

@property (nonatomic, strong) DVEMultipleTrackViewCellViewModel *viewModel;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, assign) BOOL enabledCornerRadius;

- (void)setupUI;

- (void)clipPanBegin;

- (void)clipPanChangedAtPosition:(DVESegmentClipViewPanPosition)position offset:(CGFloat)offset;

- (void)clipPanEnd;

- (void)updateFrame;

- (void)updateUIIfNeeded;

@end

NS_ASSUME_NONNULL_END
