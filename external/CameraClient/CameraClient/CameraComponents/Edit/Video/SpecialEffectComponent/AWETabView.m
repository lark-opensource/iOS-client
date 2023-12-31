//
//  AWETabView.m
//  Aweme
//
//  Created by hanxu on 2017/4/10.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWETabView.h"
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/NSNumber+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <pop/POPSpringAnimation.h>
#import <Masonry/View+MASAdditions.h>

static NSString *const AWETabViewShouldFixTabCount = @"awe.tab.view.should.fix.tab.count";

@interface AWEStudioNumButton : UIButton

@property(nonatomic,assign)NSInteger tabNum;

@end

@implementation AWEStudioNumButton

- (void)setHighlighted:(BOOL)highlighted
{
    
}

@end


@interface AWETabView ()
/**
 *  tabs上显示的名称
 */
@property(nonatomic, copy)NSArray *namesOfTabs;

/**
 *  装button子控件
 */
@property(nonatomic, strong)NSMutableArray *tabs;

/**
 *  装button对应的view子控件
 */
@property(nonatomic, strong)NSMutableArray *views;

@property(nonatomic, assign)NSInteger numberOfTabs;

@property(nonatomic, strong)AWEStudioNumButton *currentChooseTab;

@property (nonatomic, strong) UIView *topLineView;

@property (nonatomic, strong) UIView *tabContentView;

@property (nonatomic, strong) UIScrollView *buttonContentView;

@end

@implementation AWETabView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = ACCResourceColor(ACCUIColorConstIconPrimary);
        
        _tabContentView = [[UIView alloc] init];
        _tabContentView.backgroundColor = [UIColor clearColor];
        [self addSubview:_tabContentView];

        _buttonContentView = [[UIScrollView alloc] init];
        _buttonContentView.backgroundColor = [UIColor clearColor];
        _buttonContentView.showsVerticalScrollIndicator = NO;
        _buttonContentView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_buttonContentView];
    }
    return self;
}

- (void)setNamesOfTabs:(NSArray *)namesOfTabs views:(NSArray *)views {
    [self setNamesOfTabs:namesOfTabs views:views withStartIndex:0];
}

- (void)setNamesOfTabs:(NSArray *)namesOfTabs views:(NSArray *)views withStartIndex:(NSInteger)startIndex
{
    NSParameterAssert([namesOfTabs count] == [views count]);
    
    _namesOfTabs = namesOfTabs;
    [self.tabs removeAllObjects];
    for (UIView *subview in self.views) {
        [subview removeFromSuperview];
    }
    [self.views removeAllObjects];
    self.numberOfTabs = [namesOfTabs count];
    
    CGFloat totalHeight = self.frame.size.height;
    CGFloat totalWidth = self.frame.size.width;
    
    CGFloat btnWidth = totalWidth / self.numberOfTabs;
    if (self.numberOfTabs > 3) {
        btnWidth = totalWidth / 3.5;
    }
    CGFloat btnHeight = 52 + ACC_IPHONE_X_BOTTOM_OFFSET;
    
    CGFloat viewWidth = totalWidth;
    CGFloat viewHeight = totalHeight - btnHeight;
    
    self.tabContentView.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    self.buttonContentView.frame = CGRectMake(0, viewHeight, self.bounds.size.width, btnHeight);
    CGFloat buttonContentSizeWidth = 0;
    
    NSString *language = [ACCI18NConfig() currentLanguage];
    BOOL isUseCN = [language hasPrefix:@"zh"];
    
    for (int i = 0; i < self.numberOfTabs; ++i) {
        AWEStudioNumButton *btn = [[AWEStudioNumButton alloc]init];
        btn.tabNum = i;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 0, ACC_IPHONE_X_BOTTOM_OFFSET, 0);
        [btn setTitle:(NSString*)namesOfTabs[i] forState:UIControlStateNormal];
        [btn setBackgroundColor:ACCResourceColor(ACCColorBGCreation2)];
        [btn.titleLabel setFont:ACCResourceFont(ACCFontPrimary)];
        CGFloat widthFits = [btn sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)].width + 36;
        if (self.numberOfTabs <= 4 && self.numberOfTabs > 0) {
            widthFits = totalWidth / self.numberOfTabs;
        } else if (ACCBoolConfig(AWETabViewShouldFixTabCount) && isUseCN) {
            widthFits = totalWidth / 4.5;
        }
        CGFloat widthUsed = widthFits; // tab的宽度根据文字长短调整，两边加上15的边距
        btn.frame = CGRectMake(buttonContentSizeWidth, 0, widthUsed, btnHeight);
        buttonContentSizeWidth += widthUsed;
        [btn addTarget:self action:@selector(clickedTab:) forControlEvents:UIControlEventTouchUpInside];
        if (i != 0) {
            [self changeColor:btn color:ACCResourceColor(ACCUIColorConstTextTertiary4) font:ACCResourceFont(ACCFontPrimary)];
        }
        [self.tabs addObject:btn];
        [self.buttonContentView addSubview:btn];
        
        UIView *view = views[i];
        [self.views addObject:view];
        [self.tabContentView addSubview:view];
        view.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    }
    
    self.buttonContentView.contentSize = CGSizeMake(buttonContentSizeWidth, btnHeight);

    if (startIndex >= 0 && startIndex < self.tabs.count) {
        [self clickedTab:self.tabs[startIndex]];
    }

    [self addSubview:self.topLineView];
    ACCMasMaker(self.topLineView, {
        make.left.right.equalTo(self);
        make.height.equalTo(@(1 / [UIScreen mainScreen].scale));
        make.bottom.equalTo(self).offset(-btnHeight);
    });
}



//点击tab
- (void)clickedTab:(AWEStudioNumButton *) tab
{
    if(self.currentChooseTab == tab)return;

    if (self.shouldClickTabBlock && !self.shouldClickTabBlock(tab.tabNum)) {
        return;
    }
    
    // Scroll the tab to middle
    const CGFloat maxOffsetX = self.buttonContentView.contentSize.width - self.buttonContentView.bounds.size.width;
    if (maxOffsetX > 0) {
        const CGFloat centerX = tab.frame.origin.x + tab.frame.size.width/2.0;
        CGFloat contentOffsetX = centerX - self.buttonContentView.bounds.size.width/2.0;
        if (contentOffsetX < 0) {
            contentOffsetX = 0;
        } else if (contentOffsetX > maxOffsetX) {
            contentOffsetX = maxOffsetX;
        }
        [self.buttonContentView setContentOffset:CGPointMake(contentOffsetX, 0) animated:YES];
    }
    
    AWEStudioNumButton *oldTab = self.currentChooseTab;
    oldTab.selected = NO;
    self.currentChooseTab = tab;
    tab.selected = YES;
    
    [self changeColor:self.currentChooseTab color:ACCResourceColor(ACCUIColorConstTextInverse) font:ACCResourceFont(ACCFontPrimary)];
    [self changeColor:oldTab color:ACCResourceColor(ACCUIColorConstTextTertiary4) font:ACCResourceFont(ACCFontPrimary)];

    // 切换动画
    for (NSUInteger i = 0; i < self.numberOfTabs; ++i) {
        [[(UIView *)self.views[i] layer] removeAllAnimations];
    }
    for (NSUInteger i = 0; i < self.numberOfTabs; ++i) {
        if (i != tab.tabNum) {
            [self.views[i] setHidden:YES];
        } else {
            [self.views[i] setHidden:NO];
        }
    }
    CATransition *animation = [CATransition animation];
    animation.type = kCATransitionFade;
    [self.tabContentView.layer addAnimation:animation forKey:@"animation"];
    
    if(self.clickedTabBlock){
        self.clickedTabBlock(tab.tabNum);
    }
}

- (void)clickTabAtIndex:(NSInteger)index {
    if (index >=0 && index < self.tabs.count) {
        [self clickedTab:self.tabs[index]];
    }
}

- (void)changeColor:(UIButton *)btn color:(UIColor *)color font:(UIFont *)font {
    UILabel *label = btn.titleLabel;
    [UIView transitionWithView:label
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        label.font = font;
                        POPSpringAnimation *fontColorSpringAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLabelTextColor];
                        fontColorSpringAnimation.toValue = color;
                        [label pop_addAnimation:fontColorSpringAnimation forKey:@"labelColorAnimation"];
                    } completion:nil];
    
}

#pragma mark - 懒加载
- (UIView *)topLineView
{
    if (_topLineView == nil) {
        _topLineView = [[UIView alloc] init];
        _topLineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary2);
    }
    return _topLineView;
}

- (NSMutableArray *)tabs
{
    if(_tabs == nil){
        _tabs = [NSMutableArray array];
    }
    return _tabs;
}

- (NSMutableArray *)views
{
    if (_views == nil) {
        _views = [NSMutableArray array];
    }
    return _views;
}
@end
