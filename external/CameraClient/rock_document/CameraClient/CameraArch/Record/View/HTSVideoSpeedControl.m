//
//  HTSVideoSpeedControl.m
//  Pods
//
//  Created by 何海 on 16/8/11.
//
//

#import "HTSVideoSpeedControl.h"
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCLanguageProtocol.h>

static const NSInteger defaultIndex = 2;

@interface HTSVideoSpeedControl ()

@property (nonatomic, strong) UIView *indicatorLayer;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic, copy) NSArray *titlesArray;
@property (nonatomic, strong) NSMutableArray *titleBtnArray;

@end

@implementation HTSVideoSpeedControl

@dynamic selectedSpeed;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

// 初始化的时候改变一下
- (void)commonInit
{
    _titlesArray = [self speedControlTitles];
    NSString *selectedTitle = _titlesArray[2];
    _selectedIndex = defaultIndex;
    self.layer.cornerRadius = 2;
    self.clipsToBounds = YES;
    self.backgroundColor = ACCResourceColor(ACCUIColorConstIconTertiary);
    _titleBtnArray = [NSMutableArray array];
    for (NSUInteger i = 0; i < _titlesArray.count; i++) {
        NSString *title = [_titlesArray objectAtIndex:i];
        UIButton *titleButton = [UIButton new];
        titleButton.backgroundColor = [UIColor clearColor];
        [titleButton setTitle:title forState:UIControlStateNormal];
        [titleButton setTitleColor:ACCResourceColor(ACCUIColorConstBGContainer4) forState:UIControlStateNormal];
        titleButton.titleLabel.font = [ACCFont() acc_boldSystemFontOfSize:15];
        [titleButton addTarget:self action:@selector(speedButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        titleButton.tag = i;
        if ([title isEqualToString:selectedTitle]) {
            [titleButton setTitleColor:ACCResourceColor(ACCUIColorConstTextPrimary2) forState:UIControlStateNormal];
        }
        titleButton.isAccessibilityElement = YES;
        titleButton.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", _selectedIndex == i ? @"已选中" : @"未选中", title];
        titleButton.accessibilityTraits = UIAccessibilityTraitButton;
        [self addSubview:titleButton];
        [_titleBtnArray addObject:titleButton];
    }
    [self insertSubview:self.indicatorLayer atIndex:0];
}

- (NSArray <NSString *> *)speedControlTitles
{
    return  @[
        ACCLocalizedCurrentString(@"com_mig_epic"),
        ACCLocalizedCurrentString(@"com_mig_slow"),
        ACCLocalizedCurrentString(@"com_mig_norm"),
        ACCLocalizedCurrentString(@"com_mig_fast"),
        ACCLocalizedCurrentString(@"com_mig_lapse")
    ];
}

- (void)selectSpeedByCode:(HTSVideoSpeed)speed
{
    NSUInteger indexForSpeed = HTSIndexForSpeed(speed);
    UIButton *btn = [self.titleBtnArray objectAtIndex:indexForSpeed];
    
    NSUInteger index = btn.tag;
    if (index == NSNotFound) {
        return;
    }
    
    UIButton *selectedBtn = self.titleBtnArray[self.selectedIndex];
    if (index == self.selectedIndex) {
        return;
    }
    selectedBtn.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",
                                      @"未选中",
                                      [self.titlesArray objectAtIndex:_selectedIndex]];
    _selectedIndex = index;
    btn.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",
                              @"已选中",
                              [self.titlesArray objectAtIndex:_selectedIndex]];
    self.indicatorLayer.frame = btn.frame;
    [btn setTitleColor:ACCResourceColor(ACCUIColorConstTextPrimary2) forState:UIControlStateNormal];
    [selectedBtn setTitleColor:ACCResourceColor(ACCUIColorConstBGContainer4) forState:UIControlStateNormal];
}

- (void)speedButtonClick:(UIButton *)btn {
    NSUInteger index = btn.tag;
    if (index == NSNotFound) {
        return;
    }
    
    HTSVideoSpeed newSpeed = HTSSpeedForIndex(index);
    
    BOOL shouldSelect = YES;
    if ([self.delegate respondsToSelector:@selector(speedControl:shouldSelectSpeed:)]) {
        shouldSelect = [self.delegate speedControl:self shouldSelectSpeed:newSpeed];
    }
    
    if (!shouldSelect) {
        return;
    }
    
    UIButton *selectedBtn = self.titleBtnArray[self.selectedIndex];
    if (index == self.selectedIndex) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(speedControl:didSelectedIndex:oldIndex:)]) {
        [self.delegate speedControl:self didSelectedIndex:index oldIndex:self.selectedIndex];
    }
    
    selectedBtn.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",
                                      @"未选中",
                                      [self.titlesArray objectAtIndex:self.selectedIndex]];
    self.selectedIndex = index;
    btn.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",
                              @"已选中",
                              [self.titlesArray objectAtIndex:self.selectedIndex]];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.indicatorLayer.frame = btn.frame;
    } completion:nil];
    [UIView transitionWithView:btn
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState
                    animations:^{
                        [btn setTitleColor:ACCResourceColor(ACCUIColorConstTextPrimary2) forState:UIControlStateNormal];
                    }
                    completion:nil];
    [UIView transitionWithView:selectedBtn
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction |UIViewAnimationOptionBeginFromCurrentState
                    animations:^{
                        [selectedBtn setTitleColor:ACCResourceColor(ACCUIColorConstBGContainer4) forState:UIControlStateNormal];
                    }
                    completion:nil];
    
    NSArray *events = @[@"slowest",@"slower",@"normal",@"faster",@"fastest"];
    if (_selectedIndex >= 0 && _selectedIndex < events.count) {
        [ACCTracker() trackEvent:events[_selectedIndex]
                                          label:self.sourcePage
                                          value:nil
                                          extra:nil
                                     attributes:self.referExtra];
        
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.referExtra];
        referExtra[@"speed_mode"] = events[_selectedIndex];
        [ACCTracker() trackEvent:@"choose_speed_mode" params:referExtra needStagingFlag:NO];
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    NSString *key = NSStringFromSelector(@selector(selectedSpeed));
    [self willChangeValueForKey:key];
    _selectedIndex = selectedIndex;
    [self didChangeValueForKey:key];
}

- (HTSVideoSpeed)selectedSpeed
{
    return HTSSpeedForIndex(self.selectedIndex);
}

+ (HTSVideoSpeed)defaultSelectedSpeed
{
    return HTSSpeedForIndex(defaultIndex);
}

- (UIView *)indicatorLayer {
    if (!_indicatorLayer) {
        _indicatorLayer = [UIView new];
        _indicatorLayer.layer.cornerRadius = 2;
        _indicatorLayer.clipsToBounds = YES;
        _indicatorLayer.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer4);
    }
    return _indicatorLayer;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    for (NSUInteger i = 0; i < self.titleBtnArray.count; i++) {
        UIButton *btn = [self.titleBtnArray objectAtIndex:i];
        btn.frame = CGRectMake(round(i * self.bounds.size.width / 5), 0, round(self.bounds.size.width / 5), self.bounds.size.height);
    }
    self.indicatorLayer.frame = CGRectMake(round(self.selectedIndex * self.bounds.size.width / 5), 0, round(self.bounds.size.width / 5), self.bounds.size.height);
}

@end
