//
//  TMAVideoRateSelectionView.m
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/8/23.
//

#import "TMAVideoRateSelectionView.h"
#import <Masonry/Masonry.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>

@implementation TMAVideoGradientView

+ (Class)layerClass {
    return CAGradientLayer.class;
}

- (CAGradientLayer *)gradientLayer {
    return (CAGradientLayer *)self.layer;
}

@end

@interface TMAVideoRateSelectionView ()

@property (nonatomic, copy) NSArray<UIButton *> *rateButtons;
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, copy) NSArray<NSNumber *> *selections;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation TMAVideoRateSelectionView

- (instancetype)initWithSelections:(NSArray<NSNumber *> *)selections currentSelection:(nullable NSNumber *)currentSelection {
    self = [super init];
    if (self) {
        _selections = selections;
        _selectedIndex = currentSelection ? [selections indexOfObject:currentSelection] : -1;
        [self setupViews];
    }
    return self;
}

- (CGRect)untouchableArea {
    CGFloat leftEdge = self.containerView.btd_x - 24;
    return CGRectMake(leftEdge, 0, self.btd_width - leftEdge, self.btd_height);
}

- (void)setupViews {
    self.gradientLayer.colors = @[(__bridge id)UIColor.clearColor.CGColor, (__bridge id)UIColor.blackColor.CGColor];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 0);
    
    CGFloat containerHeight = self.selections.count * 28 + (self.selections.count - 1) * 16;
    UIView *container = [[UIView alloc] init];
    [self addSubview:container];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.mas_safeAreaLayoutGuideRight).mas_offset(-24);
        make.centerY.mas_equalTo(self);
        make.width.mas_equalTo(60);
        make.height.mas_equalTo(containerHeight);
    }];
    self.containerView = container;
    
    NSMutableArray<UIButton *> *rateButtons = [NSMutableArray arrayWithCapacity:self.selections.count];
    [self.selections enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *btn = [[UIButton alloc] init];
        btn.layer.cornerRadius = 6;
        btn.layer.masksToBounds = YES;
        btn.layer.borderColor = [UIColor btd_colorWithHexString:@"#F8F9FA" alpha:0.5].CGColor;
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn setTitleColor:[UIColor btd_colorWithHexString:@"#F0F0F0"] forState:UIControlStateNormal];
        [btn setTitle:[NSString stringWithFormat:@"%@x", obj] forState:UIControlStateNormal];
        btn.tag = idx;
        [btn addTarget:self action:@selector(onRateButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.containerView addSubview:btn];
        CGFloat topOffset = idx * (28 + 16);
        [btn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.mas_equalTo(self.containerView);
            make.top.mas_equalTo(self.containerView).mas_offset(topOffset);
            make.height.mas_equalTo(28);
        }];
        [rateButtons btd_addObject:btn];
    }];
    self.rateButtons = rateButtons.copy;

    if (self.selectedIndex != NSNotFound && self.selectedIndex >= 0) {
        [self selectTargetButton];
    }
}

- (void)selectTargetButton {
    [self.rateButtons btd_forEach:^(UIButton * _Nonnull btn) {
        btn.layer.borderWidth = 0;
    }];
    UIButton *targetButton = [self.rateButtons btd_objectAtIndex:self.selectedIndex];
    targetButton.layer.borderWidth = 1;
}

- (void)onRateButtonClicked:(UIButton *)btn {
    if (btn.tag == self.selectedIndex) {
        return;
    }
    
    NSNumber *currentSpeed = [self.selections btd_objectAtIndex:btn.tag];
    !self.tapAction ?: self.tapAction(currentSpeed.floatValue);
    self.selectedIndex = btn.tag;
    [self selectTargetButton];
}

@end
