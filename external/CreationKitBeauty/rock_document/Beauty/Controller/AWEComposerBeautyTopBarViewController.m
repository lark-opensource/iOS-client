//
//  AWEComposerBeautyTopBarViewController.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/10/31.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitBeauty/AWEComposerBeautyTopBarViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyTopBarCollectionViewCell.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreationKitBeauty/AWEBeautyControlConstructor.h>
#import <CreationKitBeauty/ACCBeautyUIDefaultConfiguration.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import "CKBConfigKeyDefines.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>

@interface AWEComposerBeautyTopBarViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UIView *collectionViewContainerView;
@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *detailTitleContainerView;
@property (nonatomic, strong) UIView *subDetailTitleContainerView; // another detail view
@property (nonatomic, strong, readwrite) UILabel *detailTitleLabel;
@property (nonatomic, strong, readwrite) UILabel *subDetailTitleLabel;
@property (nonatomic, strong, readwrite) UIButton *resetButton;

@property (nonatomic, copy, readwrite) NSArray <NSString *> *titles;
@property (nonatomic, assign, readwrite) NSInteger selectedIndex;
@property (nonatomic, assign) CGFloat animationOffset;
@property (nonatomic, assign) NSTimeInterval animationDuration;
@property (nonatomic, assign) CGFloat resetButtonWidth;
@property (nonatomic, assign) BOOL detailTitleContainerDisplayed;
/// yellow dot showing config
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *flagDotShowConfig;
@property (nonatomic, strong, readwrite) id<ACCBeautyUIConfigProtocol> uiConfig;

@end

@implementation AWEComposerBeautyTopBarViewController

#pragma mark - LifeCycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles
{
    self = [super init];
    
    if (self) {
        _titles = titles;
        _animationOffset = 56.f;
        _flagDotShowConfig = [@{} mutableCopy];
        _itemHeight = 40.f;
        _uiConfig = [[ACCBeautyUIDefaultConfiguration alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    _resetButtonWidth = 76.0f;
    [self p_setupTabView];
    [self p_setupDetailTitleView];
    [self p_setupSubDetailTitleView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

        ACCMasReMaker(self.collectionViewContainerView, {
            make.edges.equalTo(self.view);
        });

        ACCMasReMaker(self.detailTitleContainerView, {
            make.top.bottom.width.equalTo(self.view);
            make.left.equalTo(self.view);
        });

        ACCMasReMaker(self.subDetailTitleContainerView, {
            make.top.bottom.width.equalTo(self.view);
            make.left.equalTo(self.view);
        });
}

#pragma mark - Getter

- (UIButton *)resetButton
{
    if (!_resetButton) {
        _resetButton = [AWEBeautyControlConstructor resetButton];
        _resetButton.layer.borderWidth = 0.f;
        _resetButton.layer.borderColor = [UIColor clearColor].CGColor;
        _resetButton.backgroundColor = [UIColor clearColor];
        [_resetButton addTarget:self action:@selector(p_handleReset) forControlEvents:UIControlEventTouchUpInside];

        if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
            [ACCAccessibility() enableAccessibility:_resetButton
                                             traits:UIAccessibilityTraitButton
                                              label:ACCLocalizedString(@"av_beauty_progress_reset", "reset")];
        }

        _resetButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-20, 0, -20, 0);

        if ([self.titles count] > [self maxTitleCountWithoutCompressing]) {
            UIView *separator = [[UIView alloc] init];
            separator.backgroundColor = ACCResourceColor(ACCColorConstLineInverse);
            [_resetButton addSubview:separator];
            ACCMasMaker(separator, {
                make.left.centerY.equalTo(_resetButton);
                make.width.equalTo(@0.5);
                make.height.equalTo(@16);
            });
        }
    }
    return _resetButton;
}

#pragma mark - Event Handler

- (void)p_handleBack
{
    [self.delegate composerBeautyTopBarDidTapBackButton];
}

- (void)p_handleReset
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyTopBarDidTapResetButton)]) {
        [self.delegate composerBeautyTopBarDidTapResetButton];
    }
}

- (void)p_handleSwitch:(BOOL)isOn isManually:(BOOL)isManually
{
    if ([self.delegate respondsToSelector:@selector(composerBeautyTopBarDidSwitch:isManually:)]) {
        [self.delegate composerBeautyTopBarDidSwitch:isOn isManually:isManually];
        [ACCCache() setBool:isOn forKey:@"kBeautyToggleIsOn"];
    }
}

#pragma mark - UI - setup

- (void)p_setupTabView
{
    self.collectionViewContainerView = [[UIView alloc] init];
    [self.view addSubview:self.collectionViewContainerView];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    [self p_updateLayout:layout];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0.f;
    layout.minimumInteritemSpacing = 0.f;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.contentInset = UIEdgeInsetsZero;
    [self p_updateScrollEnabled];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor clearColor];
    
    [self.collectionView registerClass:[AWEComposerBeautyTopBarCollectionViewCell class] forCellWithReuseIdentifier:[AWEComposerBeautyTopBarCollectionViewCell identifier]];
    [self.collectionViewContainerView addSubview:self.collectionView];
    
    if (!self.hideResetButton) {
        [self.collectionViewContainerView addSubview:self.resetButton];
        ACCMasMaker(self.resetButton, {
            make.centerY.right.equalTo(self.collectionViewContainerView);
            make.width.equalTo(@(self.resetButtonWidth));
            make.height.equalTo(@28);
        });
    }
        
    ACCMasMaker(self.collectionView, {
        make.top.bottom.left.equalTo(self.collectionViewContainerView);
        if (!self.hideResetButton) {
            make.right.equalTo(self.resetButton.mas_left);
        } else {
            make.right.equalTo(self.collectionViewContainerView);
        }
    });
}

- (void)p_setupSubDetailTitleView
{
    self.subDetailTitleContainerView = [[UIView alloc] init];
    self.subDetailTitleContainerView.alpha = 0.f;
    [self.view addSubview:self.subDetailTitleContainerView];

    self.subDetailTitleLabel = [[UILabel alloc] init];
    self.subDetailTitleLabel.textColor = self.uiConfig.tbSelectedTitleColor;
    self.subDetailTitleLabel.font = [ACCFont() acc_systemFontOfSize:15];
    [self.subDetailTitleContainerView addSubview:self.subDetailTitleLabel];
    ACCMasMaker(self.subDetailTitleLabel, {
        make.center.equalTo(self.subDetailTitleContainerView);
    });
    if (self.uiConfig.headerStyle == ACCBeautyHeaderViewStylePlayBtn
        || self.uiConfig.headerStyle == ACCBeautyHeaderViewStyleReplaceIconWithText) {
        self.detailTitleLabel.alpha = 0.f;
    }

    // back button use the same action @selector
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:ACCResourceImage(@"ic_titlebar_back_white") forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(p_handleBack) forControlEvents:UIControlEventTouchUpInside];
    if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
        [ACCAccessibility() enableAccessibility:backButton
                                         traits:UIAccessibilityTraitButton
                                          label:ACCLocalizedString(@"back_confirm", @"back")];
    }
    [self.subDetailTitleContainerView addSubview:backButton];
    ACCMasMaker(backButton, {
        make.left.equalTo(self.subDetailTitleContainerView.mas_left).with.offset(16);
        make.top.equalTo(self.subDetailTitleContainerView.mas_top).with.offset(11);
        make.width.height.equalTo(@24);
    });
}

- (void)p_setupDetailTitleView
{
    self.detailTitleContainerView = [[UIView alloc] init];
    self.detailTitleContainerView.alpha = 0.f;
    [self.view addSubview:self.detailTitleContainerView];
    
    self.detailTitleLabel = [[UILabel alloc] init];
    self.detailTitleLabel.textColor = self.uiConfig.tbSelectedTitleColor;
    self.detailTitleLabel.font = [ACCFont() acc_systemFontOfSize:15];
    [self.detailTitleContainerView addSubview:self.detailTitleLabel];
    ACCMasMaker(self.detailTitleLabel, {
        make.center.equalTo(self.detailTitleContainerView);
    });
    if (self.uiConfig.headerStyle == ACCBeautyHeaderViewStylePlayBtn
        || self.uiConfig.headerStyle == ACCBeautyHeaderViewStyleReplaceIconWithText) {
        self.detailTitleLabel.alpha = 0.f;
    }
    
    UIButton *backButton = [[UIButton alloc] init];
    [backButton setImage:ACCResourceImage(@"ic_titlebar_back_white") forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(p_handleBack) forControlEvents:UIControlEventTouchUpInside];
    if ([ACCAccessibility() respondsToSelector:@selector(enableAccessibility:traits:label:)]) {
        [ACCAccessibility() enableAccessibility:backButton
                                         traits:UIAccessibilityTraitButton
                                          label:ACCLocalizedString(@"back_confirm", @"back")];
    }
    [self.detailTitleContainerView addSubview:backButton];
    ACCMasMaker(backButton, {
        make.left.equalTo(self.detailTitleContainerView.mas_left).with.offset(16);
        make.top.equalTo(self.detailTitleContainerView.mas_top).with.offset(11);
        make.width.height.equalTo(@24);
    });
}

#pragma mark - UI - config

- (CGFloat)p_rightInset
{
    return self.hideResetButton ? 0 : _resetButtonWidth;
}

- (NSInteger)maxTitleCountWithoutCompressing
{
    return 4;
}

- (void)p_updateLayout:(UICollectionViewFlowLayout *)layout
{
    CGFloat containerWidth = ACC_SCREEN_WIDTH - [self p_rightInset];
    CGFloat itemWidth = containerWidth / ([self maxTitleCountWithoutCompressing] + 0.5);
    if (self.autoAlignCenter) {
        if ([self.titles count] <= [self maxTitleCountWithoutCompressing]) {
            itemWidth = containerWidth / [self.titles count];
        }
    } else if ([self.titles count] == 1) {
        itemWidth = ACC_SCREEN_WIDTH;
    }
    layout.itemSize = CGSizeMake(itemWidth, _itemHeight);
}

- (void)p_updateScrollEnabled
{
    BOOL scrollEnabled = YES;

    CGFloat containerWidth = ACC_SCREEN_WIDTH - [self p_rightInset];
    CGFloat itemWidth = containerWidth / ([self maxTitleCountWithoutCompressing] + 0.5);
    if (!ACC_isEmptyArray(self.titles) && ([self.titles count] * itemWidth) <= containerWidth) {
        scrollEnabled = NO;
    }
    self.collectionView.scrollEnabled = scrollEnabled;
}

#pragma mark - UI - update

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)uiConfig {
    self.uiConfig = uiConfig;
}

- (void)updateWithTitles:(NSArray<NSString *> *)titles
{
    _titles = titles;
    UICollectionViewLayout *layout = self.collectionView.collectionViewLayout;
    if ([layout isKindOfClass:[UICollectionViewFlowLayout class]]) {
        [self p_updateLayout:(UICollectionViewFlowLayout *)layout];
    }
    [self p_updateScrollEnabled];
    [self.collectionView reloadData];
}

- (void)updateResetButtonToDisabled:(BOOL)disabled
{
    self.resetButton.enabled = !disabled;
}

#pragma mark - UI - Switch & Animation

- (void)selectItemAtIndex:(NSInteger)index
{
    if (index >= [self.titles count]) {
        return ;
    }
    self.selectedIndex = index;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)setResetButtonHidden:(BOOL)hidden
{
    _resetButton.hidden = hidden;
}

- (void)setFlagDotHidden:(BOOL)hidden atIndex:(NSInteger)index
{
    NSString *title = self.titles[index];
    _flagDotShowConfig[title] = @(!hidden);
    AWEComposerBeautyTopBarCollectionViewCell *cell = (AWEComposerBeautyTopBarCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    [cell setFlagDotViewHidden:hidden];
}

/// NEW Animation
/// Collection --> Title --> SubTitle
/// Collection <-- Title <-- SubTitle
/// recover the position of Views to x == 0, after animation
- (void)showCollectionToTitleWithTitle:(NSString *)title duration:(NSTimeInterval)duration
{
    self.animationDuration = duration;
    self.detailTitleLabel.text = title;
    [self animateFromView:self.collectionViewContainerView toView:self.detailTitleContainerView duration:duration directionLeft:YES];
}


- (void)showTitleToSubTitleWithSubTitle:(NSString *)title duration:(NSTimeInterval)duration
{
    self.animationDuration = duration;
    self.subDetailTitleLabel.text = title;
    [self animateFromView:self.detailTitleContainerView toView:self.subDetailTitleContainerView duration:duration directionLeft:YES];
}

- (void)showSubTitleToTitleWithTitle:(NSString *)title duration:(NSTimeInterval)duration
{
    self.animationDuration = duration;
    self.detailTitleLabel.text = title;
    [self animateFromView:self.subDetailTitleContainerView toView:self.detailTitleContainerView duration:duration directionLeft:NO];
}

- (void)showTitleToCollectionWithDuration:(NSTimeInterval)duration
{
    [self animateFromView:self.detailTitleContainerView toView:self.collectionViewContainerView duration:duration directionLeft:NO];
}

- (void)animateFromView:(UIView *)fromView toView:(UIView *)toView duration:(NSTimeInterval)duration directionLeft:(BOOL)left
{
    CGFloat offset = left ? self.animationOffset : -self.animationOffset;
    fromView.userInteractionEnabled = NO;
    toView.userInteractionEnabled = NO;

    toView.frame = CGRectOffset(fromView.frame, offset, 0);

    [UIView animateWithDuration:duration animations:^{
        fromView.alpha = 0.f;
        fromView.frame = CGRectOffset(fromView.frame, -offset, 0);
        toView.alpha = 1.f;
        toView.frame = CGRectOffset(toView.frame, -offset, 0);
    } completion:^(BOOL finished) {
        fromView.frame = CGRectOffset(fromView.frame, offset, 0);
        toView.userInteractionEnabled = YES;
        self.detailTitleContainerDisplayed = YES;
    }];
}
/// END new Animation

- (void)showSubItemsWithTitle:(NSString *)title duration:(NSTimeInterval)duration
{
    self.animationDuration = duration;
    self.detailTitleLabel.text = title;
    self.collectionView.userInteractionEnabled = NO;
    self.detailTitleContainerView.userInteractionEnabled = NO;

    self.detailTitleContainerView.frame = CGRectOffset(self.detailTitleContainerView.frame, self.animationOffset, 0);
    [UIView animateWithDuration:duration animations:^{
        self.collectionViewContainerView.alpha = 0.f;
        self.collectionViewContainerView.frame = CGRectOffset(self.collectionViewContainerView.frame, -self.animationOffset, 0);
        self.detailTitleContainerView.frame = CGRectOffset(self.detailTitleContainerView.frame, -self.animationOffset, 0);
        self.detailTitleContainerView.alpha = 1.f;
    } completion:^(BOOL finished) {
        self.collectionViewContainerView.frame = CGRectOffset(self.collectionViewContainerView.frame, self.animationOffset, 0);
        self.detailTitleContainerView.userInteractionEnabled = YES;
        self.detailTitleContainerDisplayed = YES;
    }];
}


#pragma mark - UICollectionView - Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.selectedIndex) {
        return ;
    }
    AWEComposerBeautyTopBarCollectionViewCell *lastSelectedCell = (AWEComposerBeautyTopBarCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex inSection:0]];
    [lastSelectedCell updateWithUserSelected:NO];

    AWEComposerBeautyTopBarCollectionViewCell *selectedCell = (AWEComposerBeautyTopBarCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [selectedCell updateWithUserSelected:YES];

    self.selectedIndex = indexPath.row;

    [self.delegate composerBeautyTopBarDidSelectTabAtIndex:indexPath.row];
}

#pragma mark - UICollectionView - DataSource

- (NSInteger)numberOfSections
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.titles count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    AWEComposerBeautyTopBarCollectionViewCell *cell = (AWEComposerBeautyTopBarCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[AWEComposerBeautyTopBarCollectionViewCell identifier] forIndexPath:indexPath];
    if (indexPath.row >= [self.titles count]) {
        return cell;
    }
    cell.selectedTitleFont = self.uiConfig.tbSelectedTitleFont;
    cell.selectedTitleColor = self.uiConfig.tbSelectedTitleColor;
    cell.unselectedTitleFont = self.uiConfig.tbUnselectedTitleFont;
    cell.unselectedTitleColor = self.uiConfig.tbUnselectedTitleColor;
    cell.shouldShowUnderline = self.hideSelectUnderline ? NO : [self.titles count] > 1;
    NSString *title = self.titles[indexPath.row];
    BOOL selected = (self.selectedIndex == indexPath.row);
    [cell updateWithTitle:title selected:selected];
    [cell setFlagDotViewHidden:![_flagDotShowConfig[title] boolValue]];
    if (self.titles.count == 1) { // 只有一个 Tab 时隐藏 Tab
        [cell setHidden:YES];
    } else {
        [cell setHidden:NO];
    }

    return cell;
}

@end
