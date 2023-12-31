//
//  ACCPopupTableViewSegmentCollectionViewCell.m
//  Aweme
//
//  Created by Shichen Peng on 2021/11/1.
//

#import "ACCPopupTableViewSegmentCollectionViewCell.h"

// CreationKitInfra
#import <CreationKitInfra/UIView+ACCMasonry.h>

// CreativeKit
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

// CameraClient
#import <CameraClient/UIDevice+ACCAdditions.h>
#import <CameraClient/ACCSegmentUIControl.h>

static const CGFloat kHorizontalEdgePadding = 16.0f;
static const CGFloat kIconImageWidth = 20.0f;
static const CGFloat kTitleLabelLeftPadding = 12.0f;

@interface ACCPopupTableViewSegmentCollectionViewCell ()

@property (nonatomic, strong) id<ACCPopupTableViewDataItemProtocol>item;
@property (nonatomic, strong) UIImageView* iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) ACCSegmentUIControl *segmentControl;

@end

@implementation ACCPopupTableViewSegmentCollectionViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
        [self makeConstraint];
    }
    return self;
}

#pragma mark - ACCPopupTableViewCellProtocol

+ (CGFloat)cellHeight
{
    return 56.0;
}

- (void)updateWithItem:(id<ACCPopupTableViewDataItemProtocol>)item
{
    if (item.cellType != ACCPopupCellTypeSegment) {
        return;
    }
    self.item = item;
    self.iconImageView.image = item.iconImage;
    self.titleLabel.text = item.title;
    [self.segmentControl setPressedHandler:item.segmentActionBlockWrapper];
    [self.segmentControl selectIndex:item.index animated:NO];
}

- (void)onCellClicked
{
    
}

#pragma mark - UI Configure

- (void)setupUI
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.iconImageView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.lineView];
    [self.contentView addSubview:self.segmentControl];
}

- (void)makeConstraint
{
    ACCMasMaker(self.iconImageView, {
        make.left.equalTo(self.contentView).offset(kHorizontalEdgePadding);
        make.centerY.equalTo(self.contentView);
        make.width.height.equalTo(@(kIconImageWidth));
    });
    ACCMasMaker(self.titleLabel, {
        make.left.equalTo(self.iconImageView.mas_right).offset(kTitleLabelLeftPadding);
        make.right.lessThanOrEqualTo(self.segmentControl.mas_left);
        make.centerY.equalTo(self.contentView);
    });

    ACCMasMaker(self.segmentControl, {
        make.top.equalTo(self.contentView).offset(kTitleLabelLeftPadding);
        make.bottom.equalTo(self.contentView).offset(-kTitleLabelLeftPadding);
        make.right.equalTo(self.contentView.mas_right).offset(-kHorizontalEdgePadding);
        // 适配SE机型
        // Adjust narrow-screen device
        make.left.equalTo(self.titleLabel.mas_right).priorityMedium();
        make.width.lessThanOrEqualTo(@(152.f)).priorityHigh();
    });
    ACCMasMaker(self.lineView, {
        make.right.bottom.equalTo(self.contentView);
        make.left.equalTo(self.titleLabel);
        make.height.equalTo(@([UIDevice acc_onePixel]));
    });
}

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        _titleLabel.textColor = ACCDynamicResourceColor(ACCColorTextReverse);
        _titleLabel.numberOfLines = 1;
        _titleLabel.userInteractionEnabled = NO;
    }
    return _titleLabel;
}

- (UIView *)lineView
{
    if (!_lineView) {
        _lineView = [[UIView alloc] init];
        _lineView.backgroundColor =ACCDynamicResourceColor(ACCColorLineReverse2);    }
    return _lineView;
}

- (ACCSegmentUIControl *)segmentControl
{
    if (!_segmentControl) {
        _segmentControl = [ACCSegmentUIControl switchWithStringsArray:@[@"15", @"60", @"180"]];
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.8;
        _segmentControl.isAccessibilityElement = NO;
    }
    return _segmentControl;
}

@end
