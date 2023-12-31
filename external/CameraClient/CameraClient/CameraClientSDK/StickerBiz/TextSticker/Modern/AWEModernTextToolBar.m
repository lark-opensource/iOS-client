//
//  AWEModernTextToolBar.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/16.
//

#import "AWEModernTextToolBar.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import "AWEStoryColorChooseView.h"
#import "AWEStoryFontChooseView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import "ACCTextStickerRecommendToolBar.h"

@interface AWEModernTextToolBar ()

@property (nonatomic, strong) AWETextToolStackView *stackView;
@property (nonatomic, strong) AWEStoryFontChooseView *fontChooseView;
@property (nonatomic, strong) AWEStoryColorChooseView *colorChooseView;
@property (nonatomic, strong) ACCAnimatedButton *closeColorViewBtn;

@property (nonatomic, strong) ACCTextStickerRecommendToolBar *recommendToolBar;
@property (nonatomic, strong) ACCTextStickerRecommendLibView *libView;
@property (nonatomic, strong) UIView *barContentView;
@property (nonatomic, strong) UIView *colorContentView;

@property (nonatomic, assign) AWEModernTextRecommendMode mode;

@end

@implementation AWEModernTextToolBar

- (instancetype)initWithFrame:(CGRect)frame barItemIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
{
    if (self = [super initWithFrame:frame]) {
        [self p_setupWithBarItemWithIdentityList:itemIdentityList];
    }
    return self;
}

#pragma mark - setup
- (void)p_setupWithBarItemWithIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
{
    [self addSubview:self.barContentView];
    ACCMasMaker(self.barContentView, {
        make.height.equalTo(@56.f);
        make.left.right.bottom.equalTo(self);
    });
    
    BOOL hasBarItem = !ACC_isEmptyArray(itemIdentityList);
    if (hasBarItem) {
        [self p_setupBarStackViewWithIdentityList:itemIdentityList];
    }
    
    [self.barContentView addSubview:self.fontChooseView];
    ACCMasMaker(self.fontChooseView, {
        if (hasBarItem) {
            make.left.equalTo(self.stackView.mas_right).inset(14.f);
        } else {
            make.left.equalTo(self.barContentView);
        }
        make.right.equalTo(self.barContentView);
        make.centerY.equalTo(self.barContentView);
        make.height.mas_equalTo(52.f);
    });
    
    if (hasBarItem) {
        UIView *lineView = [UIView new];
        [self.barContentView addSubview:lineView];
        lineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineInverse);
        ACCMasMaker(lineView, {
            make.left.equalTo(self.stackView.mas_right).inset(6.f);
            make.centerY.equalTo(self.barContentView);
            make.size.mas_equalTo(CGSizeMake(1.f, 20.f));
        });
    }
    
    [self addSubview:self.colorContentView];
    ACCMasMaker(self.colorContentView, {
        make.height.mas_equalTo(52.f);
        make.right.left.bottom.equalTo(self);
    });
 
    [self.colorContentView addSubview:self.colorChooseView];
    ACCMasMaker(self.colorChooseView, {
        make.left.top.bottom.equalTo(self.colorContentView);
        make.right.equalTo(self.colorContentView).inset(48.f);
    });
    
    [self.colorContentView addSubview:self.closeColorViewBtn];
    ACCMasMaker(self.closeColorViewBtn, {
        make.right.equalTo(self.colorContentView);
        make.centerY.equalTo(self.colorContentView);
        make.size.mas_equalTo(CGSizeMake(48.f, 48.f));
    });
    
    [self updateColorViewShowStatus:NO];
}

- (void)configRecommendStyle:(AWEModernTextRecommendMode)mode
{
    _mode = mode;
    if (mode & AWEModernTextRecommendModeLib) {
        if (!self.libView) {
            ACCTextStickerRecommendLibView *libView = [[ACCTextStickerRecommendLibView alloc] init];
            libView.userInteractionEnabled = YES;
            [self addSubview:libView];
            self.libView = libView;
            ACCMasMaker(libView, {
                make.width.equalTo(@77.f);
                make.height.equalTo(@34.f);
                make.right.equalTo(self).offset(-12.f);
                make.top.equalTo(self);
            });
            [libView acc_addSingleTapRecognizerWithTarget:self action:@selector(clickOnLibView)];
        } else {
            self.libView.hidden = NO;
        }
    } else {
        self.libView.hidden = YES;
    }
    
    if (mode & AWEModernTextRecommendModeRecommend) {
        if (!self.recommendToolBar) {
            ACCTextStickerRecommendToolBar *recommendBar = [[ACCTextStickerRecommendToolBar alloc] init];
            [self addSubview:recommendBar];
            self.recommendToolBar = recommendBar;
            ACCMasMaker(recommendBar, {
                make.left.equalTo(self);
                if (self.libView) {
                    make.right.equalTo(self.libView.mas_left);
                } else {
                    make.right.equalTo(self);
                }
                make.height.equalTo(@34.f);
                make.top.equalTo(self);
            });
            
            @weakify(self);
            recommendBar.onTitleSelected = ^(NSString *title) {
                @strongify(self);
                ACCBLOCK_INVOKE(self.didSelectedTitleBlock, title);
            };
            recommendBar.onTitleExposured = ^(NSString *title) {
                @strongify(self);
                ACCBLOCK_INVOKE(self.didExposureTitleBlock, title);
            };
        } else {
            self.recommendToolBar.hidden = NO;
        }
    } else {
        self.recommendToolBar.hidden = YES;
    }
}

- (void)p_setupBarStackViewWithIdentityList:(NSArray<AWETextStackViewItemIdentity> *)itemIdentityList
{
    self.stackView = [[AWETextToolStackView alloc] initWithBarItemIdentityList:itemIdentityList
                                                                  itemViewSize:CGSizeMake(44.f, 44.f)
                                                                   itemSpacing:0.f];
    [self.barContentView addSubview:self.stackView];
    ACCMasMaker(self.stackView, {
        make.left.equalTo(self.barContentView).offset(6.f);
        make.centerY.equalTo(self.barContentView);
    });
}

- (void)updateColorViewShowStatus:(BOOL)shouldShow
{
    _isShowingColorView = shouldShow;
    self.colorContentView.hidden = !shouldShow;
    self.barContentView.hidden = shouldShow;
}

- (void)setDidSelectedColorBlock:(void (^)(AWEStoryColor * _Nonnull, NSIndexPath * _Nonnull))didSelectedColorBlock
{
    self.colorChooseView.didSelectedColorBlock = didSelectedColorBlock;
}

- (AWEStoryColor *)selectedColor
{
    return self.colorChooseView.selectedColor;;
}

- (void)selectWithColor:(UIColor *)color
{
    [self.colorChooseView selectWithColor:color];
}

- (void)selectWithFontId:(NSString *)fontId
{
    [self.fontChooseView selectWithFontID:fontId];
}

- (void)setDidSelectedFontBlock:(void (^)(AWEStoryFontModel * _Nonnull, NSIndexPath * _Nonnull))didSelectedFontBlock
{
    self.fontChooseView.didSelectedFontBlock = didSelectedFontBlock;
}

#pragma mark - AWETextToolStackViewProtocol
- (void)registerItemConfigProvider:(AWETextStackViewItemConfigProvider)provider
                      clickHandler:(AWETextStackViewItemClickHandler)clickHandler
                   forItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    [self.stackView registerItemConfigProvider:provider clickHandler:clickHandler forItemIdentity:itemIdentity];
}

- (void)updateAllBarItems
{
    [self.stackView updateAllBarItems];
}

- (void)updateBarItemWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    [self.stackView updateBarItemWithItemIdentity:itemIdentity];
}

- (CGPoint)itemViewCenterOffsetWithItemIdentity:(AWETextStackViewItemIdentity)itemIdentity
{
    return [self.stackView itemViewCenterOffsetWithItemIdentity:itemIdentity];
}

- (void)p_closeColorViewBtnClickHander
{
    ACCBLOCK_INVOKE(self.didSelectedCloseColorViewBtnBlock);
}

#pragma mark - text recommend
- (void)updateWithRecommendTitles:(NSArray<ACCTextStickerRecommendItem *> *)titles
{
    if (self.mode & AWEModernTextRecommendModeRecommend) {
        [self.recommendToolBar updateWithTitles:titles];
    }
}

- (void)clickOnLibView
{
    ACCBLOCK_INVOKE(self.didCallTitleLibBlock);
}

#pragma mark - getter
- (UIView *)colorContentView
{
    if (!_colorContentView) {
        _colorContentView = [UIView new];
    }
    return _colorContentView;
}

- (UIView *)barContentView
{
    if (!_barContentView) {
        _barContentView = [UIView new];
    }
    return _barContentView;
}

- (AWEStoryFontChooseView *)fontChooseView
{
    if (!_fontChooseView) {
        _fontChooseView = [[AWEStoryFontChooseView alloc] init];
        _fontChooseView.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10);
        [_fontChooseView acc_edgeFading];
    }
    return _fontChooseView;
}

- (AWEStoryColorChooseView *)colorChooseView
{
    if (!_colorChooseView) {
        _colorChooseView = [[AWEStoryColorChooseView alloc] init];
        _colorChooseView.collectionView.contentInset = UIEdgeInsetsMake(0, 8, 0, 10);
        [_colorChooseView acc_edgeFading];
    }
    return _colorChooseView;
}

- (ACCAnimatedButton *)closeColorViewBtn
{
    if (!_closeColorViewBtn) {
        _closeColorViewBtn = [[ACCAnimatedButton alloc] init];
        _closeColorViewBtn.imageView.contentMode = UIViewContentModeCenter;
        [_closeColorViewBtn setImage:ACCResourceImage(@"icon_text_tool_bar_color_close") forState:UIControlStateNormal];
        [_closeColorViewBtn addTarget:self action:@selector(p_closeColorViewBtnClickHander) forControlEvents:UIControlEventTouchUpInside];
        
        _closeColorViewBtn.accessibilityLabel = @"关闭";
        _closeColorViewBtn.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _closeColorViewBtn;
}

#pragma mark - config
+ (CGFloat)barHeight:(AWEModernTextRecommendMode)style
{
    return style == AWEModernTextRecommendModeNone ? 56.f : 90.f;
}

@end
