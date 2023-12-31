//
//  AWECaptionBottomOptimizedView.m
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2021/1/3.
//

#import "AWECaptionBottomOptimizedView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIButton+ACCAdditions.h>

CGFloat AWEAutoCaptionsFooterViewHeight = 333.0;
static CGFloat const kAWEAutoCaptionsFooterViewTitleHeigth = 52.0;
static CGFloat const kAWEAutoCaptionsFooterViewBodyHeight = 221.0;
static CGFloat const kAWEAutoCaptionsFooterViewBottomHeight = 60.0;

@interface AWECaptionBottomOptimizedView()

@property (nonatomic, strong) UIView *bottomSeparateLine;

@property (nonatomic, strong) UILabel *styleButtonLabel;
@property (nonatomic, strong) UILabel *editButtonLabel;
@property (nonatomic, strong) UILabel *deleteButtonLabel;

@end

@implementation AWECaptionBottomOptimizedView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    
    return self;
}

- (void)setupUI
{
    [super setupUI];

    // 设置background view的frame
    CGFloat offsetY = (AWEAutoCaptionsFooterViewHeight - AWEAutoCaptionsBottomViewHeigth) / 2.0;
    self.loadingBgView.acc_top = offsetY;
    self.retryBgView.acc_top = offsetY;
    self.emptyBgView.acc_top = offsetY;
    
    [self resetCaptionBackgroundView];
    [self resetStyleBackgroundView];
}

- (void)resetCaptionBackgroundView
{
    self.captionTitle.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, self.captionTitle.acc_height);
    self.captionTitle.textAlignment = NSTextAlignmentCenter;
    self.captionTitle.font = [ACCFont() systemFontOfSize:15.0 weight:ACCFontWeightMedium];
    
    [self.captionBgView addSubview:self.bottomSeparateLine];
    
    CGFloat iconWidth = 32.0;
    CGFloat iconDistance = 27.0;
    self.styleButton.frame = CGRectMake((ACC_SCREEN_WIDTH - iconWidth) / 2.0, self.bottomSeparateLine.acc_bottom + 6.5, iconWidth, iconWidth);
    self.editButton.frame = CGRectMake(self.styleButton.acc_left - iconDistance - iconWidth, self.bottomSeparateLine.acc_bottom + 6.5, iconWidth, iconWidth);
    self.deleteButton.frame = CGRectMake(self.styleButton.acc_right + iconDistance, self.bottomSeparateLine.acc_bottom + 6.5, iconWidth, iconWidth);
    
    CGFloat iconLabelWidth = iconWidth + iconDistance;
    CGFloat iconLabelHeight = 14.0;
    UILabel *styleButtonLabel = [self subtitleLabelWithFrame:CGRectMake(0, self.styleButton.acc_bottom + 2.0, iconLabelWidth, iconLabelHeight)];
    styleButtonLabel.acc_centerX = self.styleButton.acc_centerX;
    styleButtonLabel.text = @"样式";
    self.styleButtonLabel = styleButtonLabel;
    
    UILabel *editButtonLabel = [self subtitleLabelWithFrame:CGRectMake(0, self.styleButton.acc_bottom + 2.0, iconLabelWidth, iconLabelHeight)];
    editButtonLabel.acc_centerX = self.editButton.acc_centerX;
    editButtonLabel.text = @"编辑";
    self.editButtonLabel = editButtonLabel;
    
    UILabel *deleteButtonLabel = [self subtitleLabelWithFrame:CGRectMake(0, self.styleButton.acc_bottom + 2.0, iconLabelWidth, iconLabelHeight)];
    deleteButtonLabel.acc_centerX = self.deleteButton.acc_centerX;
    deleteButtonLabel.text = @"删除";
    self.deleteButtonLabel = deleteButtonLabel;
    
    [self.captionBgView addSubview:styleButtonLabel];
    [self.captionBgView addSubview:editButtonLabel];
    [self.captionBgView addSubview:deleteButtonLabel];
    
    self.backButton.acc_centerY = self.captionTitle.acc_centerY;
    self.saveButton.acc_centerY = self.captionTitle.acc_centerY;
    [self.captionBgView addSubview:self.backButton];
    [self.captionBgView addSubview:self.saveButton];
}

- (void)resetStyleBackgroundView
{
    UIImage *img = ACCResourceImage(@"ic_camera_cancel");
    [self.styleCancelButton setImage:img forState:UIControlStateNormal];
    [self.styleCancelButton setImage:img forState:UIControlStateHighlighted];
    
    self.styleSeparateLine.hidden = YES;
    
    self.styleToolBar.acc_top = (AWEAutoCaptionsFooterViewHeight - self.styleToolBar.acc_height) / 2.0;
    self.styleCancelButton.acc_centerY = self.styleTitle.acc_centerY;
    self.styleSaveButton.acc_centerY = self.styleTitle.acc_centerY;
    [self.styleBgView addSubview:self.styleTitle];
}

#pragma mark - UI

- (UILabel *)subtitleLabelWithFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = ACCResourceColor(ACCColorConstTextInverse2);
    label.font = [ACCFont() systemFontOfSize:10.0 weight:ACCFontWeightRegular];
    
    return label;
}

- (UICollectionView *)createCaptionCollectionView
{
    AWECaptionScrollFlowLayout *layout = [[AWECaptionScrollFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.itemSize = CGSizeMake(ACC_SCREEN_WIDTH, kAWECaptionBottomTableViewCellHeight);
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    self.layout = layout;
    
    UICollectionView *captionCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 52.0, ACC_SCREEN_WIDTH, kAWEAutoCaptionsFooterViewBodyHeight) collectionViewLayout:layout];
    captionCollectionView.backgroundColor = [UIColor clearColor];
    captionCollectionView.showsVerticalScrollIndicator = NO;
    captionCollectionView.showsHorizontalScrollIndicator = NO;
    captionCollectionView.contentInset = UIEdgeInsetsMake(kAWECaptionBottomTableViewContentInsetTop, 0, self.acc_height - 52.0 - kAWECaptionBottomTableViewContentInsetTop - kAWECaptionBottomTableViewCellHeight, 0);
    [captionCollectionView registerClass:[AWECaptionCollectionViewCell class] forCellWithReuseIdentifier:[AWECaptionCollectionViewCell identifier]];
    
    return captionCollectionView;
}

#pragma mark - Getter

- (UILabel *)styleTitle
{
    if (!_styleTitle) {
        _styleTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, kAWEAutoCaptionsFooterViewTitleHeigth)];
        _styleTitle.textAlignment = NSTextAlignmentCenter;
        _styleTitle.textColor = ACCResourceColor(ACCColorConstTextInverse2);
        _styleTitle.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _styleTitle.text = @"样式设置";
    }
    return _styleTitle;
}

- (UIView *)bottomSeparateLine
{
    if (!_bottomSeparateLine) {
        CGFloat offsetY = self.bounds.size.height - kAWEAutoCaptionsFooterViewBottomHeight - ACC_IPHONE_X_BOTTOM_OFFSET;
        _bottomSeparateLine = [[UIView alloc] initWithFrame:CGRectMake(0, offsetY, ACC_SCREEN_WIDTH, 1.0 / ACC_SCREEN_SCALE)];
        _bottomSeparateLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    }
    
    return _bottomSeparateLine;
}

- (ACCAnimatedButton *)backButton
{
    if (!_backButton) {
        UIImage *img = ACCResourceImage(@"icon_edit_bar_cancel");
        _backButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(16, 14, 24, 24)];
        _backButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_backButton setImage:img forState:UIControlStateNormal];
        [_backButton setImage:img forState:UIControlStateHighlighted];
    }
    return _backButton;
}

- (ACCAnimatedButton *)saveButton
{
    if (!_saveButton) {
        UIImage *img = ACCResourceImage(@"icon_edit_bar_done");
        _saveButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 40, 14, 24, 24)];
        _saveButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, -20, -20, -20);
        [_saveButton setImage:img forState:UIControlStateNormal];
        [_saveButton setImage:img forState:UIControlStateHighlighted];
    }
    return _saveButton;
}

@end
