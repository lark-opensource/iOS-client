//
//  ACCMusicSelectTabView.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/6/30.
//

#import "ACCMusicSelectTabView.h"

#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "UIDevice+ACCAdditions.h"

@interface ACCMusicSelectTabView ()

@property (nonatomic, assign) ACCSelectMusicTabType selectedIndex;
@property (nonatomic, strong) UIView *bottomLineView;

@property (nonatomic, strong) UIButton *hotmusicButton;//发现
@property (nonatomic, strong) UILabel *hotmusicLabel;
@property (nonatomic, strong) UIView *firstVerticalLineView;
@property (nonatomic, strong) UIButton *collectButton;//收藏
@property (nonatomic, strong) UILabel *collectionLabel;
@property (nonatomic, strong) UIView *secondVerticalLineView;
@property (nonatomic, strong) UIButton *localAudioButton;//本地
@property (nonatomic, strong) UILabel *localAudioLabel;

@end

@implementation ACCMusicSelectTabView

@synthesize tabCompletion = _tabCompletion;
@synthesize tabShouldSelect = _tabShouldSelect;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        [self setUpUI];
    }
    return self;
}

#pragma mark - ACCSelectMusicTabProtocol

- (void)showBottomLineView:(BOOL)show
{
    self.bottomLineView.hidden = !show;
}

- (ACCSelectMusicTabType)selectedTabType
{
    return self.selectedIndex;
}
- (void)forceSwitchSelectedType:(ACCSelectMusicTabType)selectedType{
    [self p_selectTabImplAt:selectedType];
}

#pragma mark - block interface

- (BOOL)shouldSelectTabAtIndex:(NSUInteger)index
{
    if (self.tabShouldSelect) {
        return self.tabShouldSelect(index);
    } else {
        return YES;
    }
}

- (void)commitSelectedIndexChange:(ACCSelectMusicTabType)selectedIndex
{
    self.selectedIndex = selectedIndex;
    ACCBLOCK_INVOKE(self.tabCompletion, selectedIndex);
}

#pragma mark - setUI

- (void)setUpUI
{
    //hot
    self.hotmusicButton = [[UIButton alloc] init];
    self.hotmusicButton.frame = CGRectZero;
    [self.hotmusicButton addTarget:self action:@selector(hotmusicButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.hotmusicButton];
    self.hotmusicLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.hotmusicLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
    self.hotmusicLabel.text = @"发现";
    self.hotmusicLabel.font = [ACCFont() systemFontOfSize:16.0 weight:ACCFontWeightMedium];
    self.hotmusicLabel.textAlignment = NSTextAlignmentCenter;
    [self.hotmusicButton addSubview:self.hotmusicLabel];
    self.hotmusicButton.accessibilityLabel = @"发现";
    
    //collect
    self.collectButton = [[UIButton alloc] init];
    self.collectButton.frame = CGRectZero;
    [self.collectButton addTarget:self action:@selector(collectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.collectButton];
    self.collectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.collectionLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    self.collectionLabel.text = @"收藏";
    self.collectionLabel.font = [ACCFont() systemFontOfSize:16.f];
    self.collectionLabel.textAlignment = NSTextAlignmentCenter;
    [self.collectButton addSubview:self.collectionLabel];
    self.collectButton.accessibilityLabel = @"收藏";
    
    //local
    self.localAudioButton = [[UIButton alloc] init];
    self.localAudioButton.frame = CGRectZero;
    [self.localAudioButton addTarget:self action:@selector(localAudioButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.localAudioButton];
    self.localAudioLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.localAudioLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    self.localAudioLabel.text = @"本地";
    self.localAudioLabel.font = [ACCFont() systemFontOfSize:16.f];
    self.localAudioLabel.textAlignment = NSTextAlignmentCenter;
    [self.localAudioButton addSubview:self.localAudioLabel];
    self.localAudioButton.accessibilityLabel = @"本地";
    
    //line
    self.firstVerticalLineView = [[UIView alloc] initWithFrame:CGRectZero];
    self.firstVerticalLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary);
    [self addSubview:self.firstVerticalLineView];
    
    self.secondVerticalLineView = [[UIView alloc] initWithFrame:CGRectZero];
    self.secondVerticalLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary);
    [self addSubview:self.secondVerticalLineView];
    
    CGFloat tabHeight = self.bounds.size.height;
    CGFloat tabWidth = self.bounds.size.width;
    self.bottomLineView = [[UIView alloc] init];
    self.bottomLineView.frame = CGRectMake(0, tabHeight - [UIDevice acc_onePixel], tabWidth, [UIDevice acc_onePixel]);
    self.bottomLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLinePrimary);
    self.bottomLineView.hidden = YES;
    [self addSubview:self.bottomLineView];
    
    [self makeConstraints];
}

- (void)makeConstraints
{
    CGFloat lineHeight = 15;
    CGFloat lineWidth = [UIDevice acc_onePixel];
    CGFloat tabButtonWidth = (self.bounds.size.width - 2 * lineWidth)/3;
    CGFloat tabButtonHeight = self.bounds.size.height - [UIDevice acc_onePixel]; // 减去bottomLine
    
    //从左到右依次依赖布局 如需新增button 修改tabButtonWidth的值即可
    ACCMasMaker(self.hotmusicButton, {
        make.top.equalTo(self);
        make.left.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(tabButtonWidth, tabButtonHeight));
    });
    ACCMasMaker(self.hotmusicLabel, {
        make.center.equalTo(self.hotmusicButton);
        make.size.equalTo(self.hotmusicButton);
    });
    
    ACCMasMaker(self.firstVerticalLineView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self.hotmusicButton.mas_right);
        make.size.mas_equalTo(CGSizeMake([UIDevice acc_onePixel], lineHeight));
    });
    
    ACCMasMaker(self.collectButton, {
        make.top.equalTo(self);
        make.left.equalTo(self.firstVerticalLineView.mas_right);
        make.size.mas_equalTo(CGSizeMake(tabButtonWidth, tabButtonHeight));
    });
    ACCMasMaker(self.collectionLabel, {
        make.center.equalTo(self.collectButton);
        make.size.equalTo(self.collectButton);
    });
    
    ACCMasMaker(self.secondVerticalLineView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self.collectButton.mas_right);
        make.size.mas_equalTo(CGSizeMake([UIDevice acc_onePixel], lineHeight));
    });
    
    ACCMasMaker(self.localAudioButton, {
        make.top.equalTo(self);
        make.left.equalTo(self.secondVerticalLineView.mas_right);
        make.size.mas_equalTo(CGSizeMake(tabButtonWidth, tabButtonHeight));
    });
    ACCMasMaker(self.localAudioLabel, {
        make.center.equalTo(self.localAudioButton);
        make.size.equalTo(self.localAudioButton);
    });
}

#pragma mark - action

- (void)hotmusicButtonClicked:(UIButton *)sender
{
    if (self.selectedIndex == ACCSelectMusicTabTypeHot || [self shouldSelectTabAtIndex:ACCSelectMusicTabTypeHot] == NO) {
        return;
    }
    [self p_selectTabImplAt:ACCSelectMusicTabTypeHot];
}

- (void)collectButtonClicked:(UIButton *)sender {
    if (self.selectedIndex == ACCSelectMusicTabTypeCollect || [self shouldSelectTabAtIndex:ACCSelectMusicTabTypeCollect] == NO) {
        return;
    }
    [self p_selectTabImplAt:ACCSelectMusicTabTypeCollect];
}

- (void)localAudioButtonClicked:(UIButton *)sender {
    if (self.selectedIndex == ACCSelectMusicTabTypeLocal || [self shouldSelectTabAtIndex:ACCSelectMusicTabTypeLocal] == NO) {
        return;
    }
    [self p_selectTabImplAt:ACCSelectMusicTabTypeLocal];
}

- (void)p_selectTabImplAt:(ACCSelectMusicTabType)type
{
    self.hotmusicLabel.font = [ACCFont() systemFontOfSize:16.f];
    self.hotmusicLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    self.collectionLabel.font = [ACCFont() systemFontOfSize:16.f];
    self.collectionLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    self.localAudioLabel.font = [ACCFont() systemFontOfSize:16.f];
    self.localAudioLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    switch (type) {
        case ACCSelectMusicTabTypeHot:
            self.hotmusicLabel.font = [ACCFont() systemFontOfSize:16.f weight:ACCFontWeightMedium];
            self.hotmusicLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
            break;
        case ACCSelectMusicTabTypeCollect:
            self.collectionLabel.font = [ACCFont() systemFontOfSize:16.f weight:ACCFontWeightMedium];
            self.collectionLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
            break;
        case ACCSelectMusicTabTypeLocal:
            self.localAudioLabel.font = [ACCFont() systemFontOfSize:16.f weight:ACCFontWeightMedium];
            self.localAudioLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        default:
            break;
    }
    [self commitSelectedIndexChange:type];
}

#pragma mark - getter


@end


