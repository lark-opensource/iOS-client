//
//  ACCSegmentUIControl.m
//  Aweme
//
//  Created by Shichen Peng on 2021/11/1.
//

#import "ACCSegmentUIControl.h"

// CreativeKit
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>

// CreationKitInfra
#import <CreationKitInfra/UIView+ACCMasonry.h>

// CameraClient
#import <CameraClient/ACCTapicEngineProtocol.h>

#pragma mark - ACCLabelContainer

@interface ACCLabelContainer : UIView

@property UILabel *label;

@end

@implementation ACCLabelContainer

- (instancetype)init
{
    if (self = [super init]) {
        _label = [[UILabel alloc] init];
        [self addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews
{
    [self makeConstrant];
}

- (void)makeConstrant
{
    ACCMasMaker(_label, {
        make.center.equalTo(self);
    });
}
@end

#pragma mark - ACCSegmentSlideView

@interface ACCSegmentSlideView : UIView

@property (nonatomic, strong, nonnull) UIView *contentView;
@property (nonatomic, strong, nonnull) UIColor *sliderColor;
@property (nonatomic, assign) CGFloat sliderOffset;

@end

@implementation ACCSegmentSlideView

- (instancetype)init
{
    if (self = [super init]) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.contentView];
    ACCMasMaker(self.contentView, {
        make.left.top.equalTo(self).offset(self.sliderOffset);
        make.right.bottom.equalTo(self).offset(-self.sliderOffset);
    });
}

- (void)layoutSubviews
{
    self.contentView.layer.cornerRadius = (self.frame.size.height - self.sliderOffset * 2) / 2.0;
    ACCMasReMaker(self.contentView, {
        make.left.top.equalTo(self).offset(self.sliderOffset);
        make.right.bottom.equalTo(self).offset(-self.sliderOffset);
    });
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = self.sliderColor ?: [UIColor whiteColor];
        _contentView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.12].CGColor;
        _contentView.layer.shadowOpacity = 1.0f;
        _contentView.layer.shadowOffset = CGSizeMake(0, 2);
        _contentView.layer.shadowRadius = 2.0;
    }
    return _contentView;
}
@end

#pragma mark - ACCSegmentUIControl

@interface ACCSegmentUIControl ()

@property (strong, nonatomic) NSMutableArray *labels;
@property (strong, nonatomic) NSMutableArray *onTopLabels;
@property (strong, nonatomic) NSArray *tabNameList;

@property (strong, nonatomic) void (^handlerBlock)(NSUInteger index);
@property (strong, nonatomic) void (^willBePressedHandlerBlock)(NSUInteger index);

@property (strong, nonatomic) UIView *backgroundView;
@property (strong, nonatomic) ACCSegmentSlideView *sliderView;

@property (nonatomic) NSInteger selectedIndex;

@end

@implementation ACCSegmentUIControl


+ (instancetype)switchWithStringsArray:(NSArray *)strings
{
    return [[ACCSegmentUIControl alloc] initWithStringsArray:strings];
}

- (instancetype)initWithStringsArray:(NSArray *)contentList
{
    self = [super init];
    
    self.tabNameList = contentList;
    self.sliderOffset = 2.0f;
    self.font = [ACCFont() acc_boldSystemFontOfSize:13];
    
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.05];
    self.sliderColor = [UIColor whiteColor];
    self.labelTextColorInsideSlider = ACCDynamicResourceColor(ACCColorTextReverse);
    self.labelTextColorOutsideSlider = ACCDynamicResourceColor(ACCColorTextReverse3);
    
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = self.backgroundColor;
    self.backgroundView.userInteractionEnabled = YES;
    [self addSubview:self.backgroundView];
    
    self.labels = [[NSMutableArray alloc] init];
    
    for (int k = 0; k < [self.tabNameList count]; k++) {
        NSString *content = self.tabNameList[k];
        ACCLabelContainer *labelContainer = [self createBackLabelView:k content:content font:self.font];
        [self.backgroundView addSubview:labelContainer];
        [self.labels addObject:labelContainer];
        
        UITapGestureRecognizer *rec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleRecognizerTap:)];
        [labelContainer addGestureRecognizer:rec];
        labelContainer.userInteractionEnabled = YES;
    }
    
    [self addSubview:self.sliderView];
    
    self.onTopLabels = [[NSMutableArray alloc] init];
    
    for (NSString *content in self.tabNameList) {
        ACCLabelContainer *labelContainer = [self createFrontLabelView:content font:self.font];
        [self.sliderView addSubview:labelContainer];
        [self.onTopLabels addObject:labelContainer];
    }
    
    UIPanGestureRecognizer *sliderRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(slideHandler:)];
    [self.sliderView addGestureRecognizer:sliderRec];
    
    return self;
}

- (void)setPressedHandler:(void (^)(NSUInteger))handler
{
    self.handlerBlock = handler;
}

- (void)setWillBePressedHandler:(void (^)(NSUInteger))handler
{
    self.willBePressedHandlerBlock = handler;
}

- (void)layoutSubviews
{
    CGFloat height =  self.backgroundView.frame.size.height;
    self.backgroundView.layer.cornerRadius = height / 2.0;
    self.sliderView.layer.cornerRadius = height / 2.0;
    
    self.backgroundView.backgroundColor = self.backgroundColor;
    self.sliderView.backgroundColor = [UIColor clearColor];
    
    self.backgroundView.frame = [self convertRect:self.frame fromView:self.superview];
    
    CGFloat tabNum = [self.tabNameList count] ?: 1.0;
    CGFloat sliderWidth = self.backgroundView.frame.size.width / tabNum;
    
    self.sliderView.frame = CGRectMake(sliderWidth * self.selectedIndex, self.backgroundView.frame.origin.y, sliderWidth, self.frame.size.height);
    
    for (int i = 0; i < [self.labels count]; i++) {
        ACCLabelContainer *labelContainer = self.labels[i];
        labelContainer.frame = CGRectMake(i * sliderWidth, 0, sliderWidth, self.frame.size.height);
    }
    
    for (int j = 0; j < [self.onTopLabels count]; j++) {
        ACCLabelContainer *labelContainer = self.onTopLabels[j];
        labelContainer.frame = CGRectMake([self.sliderView convertPoint:CGPointMake(j * sliderWidth, 0) fromView:self.backgroundView].x, 0.0, sliderWidth, self.frame.size.height);
    }
}


#pragma  mark - Animation

- (void)forceSelectedIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index >= [self.tabNameList count] || index < 0) {
        return;
    }
    self.selectedIndex = index;
    if (animated) {
        [self animateChangeToIndex:index callHandler:YES];
    } else {
        [self changeToIndexWithoutAnimation:index callHandler:YES];
    }
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index >= [self.tabNameList count] || index < 0) {
        return;
    }
    self.selectedIndex = index;
    if (animated) {
        [self animateChangeToIndex:index callHandler:NO];
    } else {
        [self changeToIndexWithoutAnimation:index callHandler:NO];
    }
}

- (void)animateChangeToIndex:(NSUInteger)selectedIndex callHandler:(BOOL)callHandler
{
    if (self.willBePressedHandlerBlock) {
        self.willBePressedHandlerBlock(selectedIndex);
    }
    
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGFloat tabNum = [self.tabNameList count] ?: 1.0;
        CGFloat sliderWidth = self.frame.size.width / tabNum;
        CGRect oldFrame = self.sliderView.frame;
        CGRect newFrame = CGRectMake(sliderWidth * self.selectedIndex, self.backgroundView.frame.origin.y, sliderWidth, self.frame.size.height);
        CGRect offRect = CGRectMake(newFrame.origin.x - oldFrame.origin.x, newFrame.origin.y - oldFrame.origin.y, 0, 0);
        
        self.sliderView.frame = newFrame;
        [self updateFrontLabelView:offRect];
    } completion:^(BOOL finished) {
        if (callHandler) {
            [self handleTheBlockAtIndex:selectedIndex];
        }
    }];
}

- (void)changeToIndexWithoutAnimation:(NSUInteger)selectedIndex callHandler:(BOOL)callHandler
{
    if (self.willBePressedHandlerBlock) {
        self.willBePressedHandlerBlock(selectedIndex);
    }
    
    CGFloat tabNum = [self.tabNameList count] ?: 1.0;
    CGFloat sliderWidth = self.frame.size.width / tabNum;
    CGRect oldFrame = self.sliderView.frame;
    CGRect newFrame = CGRectMake(sliderWidth * self.selectedIndex, self.backgroundView.frame.origin.y, sliderWidth, self.frame.size.height);
    CGRect offRect = CGRectMake(newFrame.origin.x - oldFrame.origin.x, newFrame.origin.y - oldFrame.origin.y, 0, 0);
    self.sliderView.frame = newFrame;
    [self updateFrontLabelView:offRect];

    if (callHandler) {
        [self handleTheBlockAtIndex:selectedIndex];
    }
}

- (void)handleRecognizerTap:(UITapGestureRecognizer *)rec
{
    if (![rec.view isKindOfClass:ACCLabelContainer.class]) {
        return;
    }
    ACCLabelContainer *view = (ACCLabelContainer *)rec.view;
    self.selectedIndex = view.label.tag;
    [self animateChangeToIndex:self.selectedIndex callHandler:YES];
}

- (void)slideHandler:(UIPanGestureRecognizer *)rec
{
    if (self.continuousSlidingMode) {
        [self continuousSlider:rec];
    } else {
        [self discreteSlider:rec];
    }
}

- (void)discreteSlider:(UIPanGestureRecognizer *)rec
{
    if (rec.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [rec translationInView:rec.view];
        
        if (fabs(translation.x) > self.sliderView.frame.size.width * 0.7) {
            NSMutableArray *distances = [[NSMutableArray alloc] init];
            for (int i = 0; i < [self.tabNameList count]; i++) {
                CGFloat possibleX = i * self.sliderView.frame.size.width;
                CGFloat distance = possibleX - self.sliderView.frame.origin.x;
                [distances addObject:@(fabs(distance))];
            }
            NSNumber *num = [distances valueForKeyPath:@"@min.doubleValue"];
            NSInteger index = [distances indexOfObject:num];
            if (translation.x < 0 ) {
                index = index - 1;
            } else if (translation.x > 0) {
                index = index + 1;
            }
            [self forceSelectedIndex:index animated:YES];
            [rec setTranslation:CGPointZero inView:rec.view];
        }
    }
}

- (void)continuousSlider:(UIPanGestureRecognizer *)rec
{
    if (rec.state == UIGestureRecognizerStateChanged) {
        
        CGRect oldFrame = self.sliderView.frame;
        
        CGFloat minPos = 0;
        CGFloat maxPos = self.frame.size.width - self.sliderView.frame.size.width;
        
        CGPoint center = rec.view.center;
        CGPoint translation = [rec translationInView:rec.view];
        
        center = CGPointMake(center.x + translation.x, center.y);
        rec.view.center = center;
        [rec setTranslation:CGPointZero inView:rec.view];
        
        if (self.sliderView.frame.origin.x < minPos) {
            self.sliderView.frame = CGRectMake(minPos, self.sliderView.frame.origin.y, self.sliderView.frame.size.width, self.sliderView.frame.size.height);
        } else if (self.sliderView.frame.origin.x > maxPos) {
            self.sliderView.frame = CGRectMake(maxPos, self.sliderView.frame.origin.y, self.sliderView.frame.size.width, self.sliderView.frame.size.height);
        }
        CGRect newFrame = self.sliderView.frame;
        CGRect offRect = CGRectMake(newFrame.origin.x - oldFrame.origin.x, newFrame.origin.y - oldFrame.origin.y, 0, 0);
        [self updateFrontLabelView:offRect];
    } else if (rec.state == UIGestureRecognizerStateEnded ||
               rec.state == UIGestureRecognizerStateCancelled ||
               rec.state == UIGestureRecognizerStateFailed) {
        [self moveToSuitablePlace];
    }
}

#pragma mark - Private

- (void)moveToSuitablePlace
{
    NSMutableArray *distances = [[NSMutableArray alloc] init];
    for (int i = 0; i < [self.tabNameList count]; i++) {
        CGFloat possibleX = i * self.sliderView.frame.size.width;
        CGFloat distance = possibleX - self.sliderView.frame.origin.x;
        [distances addObject:@(fabs(distance))];
    }
    
    NSNumber *num = [distances valueForKeyPath:@"@min.doubleValue"];
    NSInteger index = [distances indexOfObject:num];
    
    if (self.willBePressedHandlerBlock) {
        self.willBePressedHandlerBlock(index);
    }
    
    CGFloat tabNum = [self.tabNameList count] ?: 1;
    CGFloat sliderWidth = self.frame.size.width / tabNum;
    CGFloat desiredX = sliderWidth * index;
    
    if (self.sliderView.frame.origin.x != desiredX) {
        CGRect evenOlderFrame = self.sliderView.frame;
        CGFloat distance = desiredX - self.sliderView.frame.origin.x;
        CGFloat time = fabs(distance / 500);
        
        [UIView animateWithDuration:time animations:^{
            self.sliderView.frame = CGRectMake(desiredX, self.sliderView.frame.origin.y, self.sliderView.frame.size.width, self.sliderView.frame.size.height);
            CGRect newFrame = self.sliderView.frame;
            CGRect offRect = CGRectMake(newFrame.origin.x - evenOlderFrame.origin.x, newFrame.origin.y - evenOlderFrame.origin.y, 0, 0);
            [self updateFrontLabelView:offRect];
        } completion:^(BOOL finished) {
            self.selectedIndex = index;
            [self handleTheBlockAtIndex:self.selectedIndex];
        }];
    } else {
        self.selectedIndex = index;
        [self handleTheBlockAtIndex:self.selectedIndex];
    }
}

- (void)handleTheBlockAtIndex:(NSInteger)index
{
    if (self.handlerBlock) {
        self.handlerBlock(index);
    }
    [ACCTapicEngine() triggerWithType:ACCHapticTypeSelected];
}

- (void)updateFrontLabelView:(CGRect)rec
{
    for (int i = 0; i < [self.onTopLabels count]; i++) {
        ACCLabelContainer *label = self.onTopLabels[i];
        label.frame = CGRectMake(label.frame.origin.x - rec.origin.x, label.frame.origin.y - rec.origin.y, label.frame.size.width, label.frame.size.height);
        if (i != self.selectedIndex) {
            label.hidden = YES;
        } else {
            label.hidden = NO;
        }
    }
}

- (ACCSegmentSlideView *)sliderView
{
    if (!_sliderView) {
        _sliderView = [[ACCSegmentSlideView alloc] init];
        _sliderView.sliderColor = self.sliderColor;
        _sliderView.sliderOffset = self.sliderOffset;
        _sliderView.backgroundColor = [UIColor clearColor];
    }
    return _sliderView;
}

- (ACCLabelContainer *)createBackLabelView:(NSInteger)tag content:(NSString *)content font:(UIFont *)font
{
    ACCLabelContainer *labelContainer = [[ACCLabelContainer alloc] init];
    labelContainer.label.tag = tag;
    labelContainer.label.text = content;
    if (font) {
        labelContainer.label.font = font;
    }
    labelContainer.label.adjustsFontSizeToFitWidth = YES;
    labelContainer.label.textAlignment = NSTextAlignmentCenter;
    labelContainer.label.textColor = self.labelTextColorOutsideSlider;
    labelContainer.isAccessibilityElement = YES;
    labelContainer.accessibilityLabel = labelContainer.label.text;
    return labelContainer;
}

- (ACCLabelContainer *)createFrontLabelView:(NSString *)content font:(UIFont *)font
{
    ACCLabelContainer *labelContainer = [[ACCLabelContainer alloc] init];
    labelContainer.label.text = content;
    if (font) {
        labelContainer.label.font = font;
    }
    labelContainer.label.adjustsFontSizeToFitWidth = YES;
    labelContainer.label.textAlignment = NSTextAlignmentCenter;
    labelContainer.label.textColor = self.labelTextColorInsideSlider;
    labelContainer.label.isAccessibilityElement = NO;
    return labelContainer;
}

@end
