//
//  ACCPopupTableViewBinarySwitchCell.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/28.
//

#import "ACCPopupTableViewBinarySwitchCell.h"

// CreationKitInfra
#import <CreationKitInfra/UIView+ACCMasonry.h>

// CreativeKit
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

// CameraClient
#import <CameraClient/UIDevice+ACCAdditions.h>
#import <CameraClient/ACCSwitchProtocol.h>


static const CGFloat kHorizontalEdgePadding = 16.0f;
static const CGFloat kIconImageWidth = 20.0f;
static const CGFloat kTitleLabelLeftPadding = 12.0f;
//static const CGFloat kTipButtonLeftPadding = 4.0f;

@interface ACCPopupTableViewBinarySwitchCell()

@property (nonatomic, strong) id<ACCPopupTableViewDataItemProtocol>item;
@property (nonatomic, strong) UIImageView* iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) id<ACCSwitchProtocol> switcher;
@property (nonatomic, copy) ACCSwitchChooseBlock actionBlock;

@end

@implementation ACCPopupTableViewBinarySwitchCell

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
    if (item.cellType != ACCPopupCellTypeSwitch) {
        return;
    }
    self.item = item;
    self.iconImageView.image = item.iconImage;
    self.titleLabel.text = item.title;
    self.switcher.switchStatusChangedBlock = item.switchActionBlockWrapper;
    [[self.switcher content] setOn:item.switchState];
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
    [self.contentView addSubview:self.switcherContent];
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
        make.right.lessThanOrEqualTo(self.switcherContent.mas_right).offset(-kTitleLabelLeftPadding - kIconImageWidth);
        make.centerY.equalTo(self.contentView);
    });

    ACCMasMaker(self.switcherContent, {
        make.right.equalTo(self.contentView.mas_right).offset(-kHorizontalEdgePadding);
        make.centerY.equalTo(self.contentView);
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

- (id<ACCSwitchProtocol>)switcher
{
    if (!_switcher) {
        _switcher = (id<ACCSwitchProtocol>)ACCSwitch();
        [_switcher content].transform = CGAffineTransformMakeScale(0.84, 0.8);
        [_switcher content].isAccessibilityElement = YES;
    }
    return _switcher;
}

- (UISwitch *)switcherContent
{
    return [self.switcher content];
}

@end
