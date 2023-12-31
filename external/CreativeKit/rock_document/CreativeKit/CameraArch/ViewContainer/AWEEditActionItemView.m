//
//  AWEEditBottomActionItemView.m
//  Pods
//
//  Created by resober on 2019/5/8.
//

#import "AWEEditActionItemView.h"
#import "ACCAnimatedButton.h"
#import "ACCFontProtocol.h"
#import "ACCMacros.h"
#import "UIColor+CameraClientResource.h"
#import "UIImage+CameraClientResource.h"

const CGFloat AWEEditActionItemButtonSideLength = 40.f; ///< button side length
static const CGFloat kButtonAndLabelVerticalGap = -2.f;
static const CGFloat kLabelWidthOffset = 16.f;
static const CGFloat kLabelLineHeight = 10.f;
static const NSUInteger kLabelLineCnt = 2;

@interface AWEEditActionItemView ()
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIView *actionView;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
/// Accanimatedbutton will operate and transform will conflict when it is clicked, so add a button BGView to the button to change the transform
@property (nonatomic, strong) UIView *buttonBgView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) AWEEditAndPublishViewData *itemData;
@property (nonatomic, strong) AWEEditAndPublishViewActionContainerModel *container;
@end

@implementation AWEEditActionItemView
- (instancetype)initWithItemData:(AWEEditAndPublishViewData *)itemData {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.itemData = itemData;
        [self setupViews];
    }
    return self;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.superview) {
        _container.actionItemView = self;
    }
}

- (void)updateActionView:(UIView *)actionView
{
    if (actionView == _actionView) {
        return;
    }
    
    [_actionView removeGestureRecognizer:_tapRecognizer];
    [_actionView removeFromSuperview];
    [_button removeFromSuperview];
    
    _actionView = actionView;
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonClicked:)];
    [_actionView addGestureRecognizer:_tapRecognizer];
    [_buttonBgView addSubview:_actionView];
    _container.topView = _actionView;
    
    [self layoutIfNeeded];
}

- (void)setupViews {
    if (!_itemData) {
        return;
    }
    _enable = YES;
    AWEEditAndPublishViewActionContainerModel *container = [[AWEEditAndPublishViewActionContainerModel alloc] init];
    _buttonBgView = [UIView new];
    _buttonBgView.backgroundColor = [UIColor clearColor];
    [self addSubview:_buttonBgView];
    
    
    if (_itemData.buttonClass) {
        _button = [[_itemData.buttonClass alloc] init];
    } else {
        _button = [[ACCAnimatedButton alloc] init];
    }
    [_buttonBgView addSubview:_button];
    [_button setImage:ACCResourceImage(_itemData.imageName) ?: _itemData.image forState:UIControlStateNormal];
    [_button setImage:ACCResourceImage(_itemData.selectedImageName) ?: _itemData.selectedImage forState:UIControlStateSelected];
    [_button addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    container.topView = _button;
    
    
    _label = [[UILabel alloc] init];
    [self addSubview:_label];
    if ([ACCFont() respondsToSelector:@selector(acc_systemFontOfSize:weight:)]) {
        _label.font = [ACCFont() acc_systemFontOfSize:10 weight:ACCFontWeightMedium];
    } else {
        _label.font = [ACCFont() systemFontOfSize:10 weight:ACCFontWeightMedium];
    }
    _label.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    _label.textAlignment = NSTextAlignmentCenter;
    _label.layer.shadowColor = [ACCResourceColor(ACCUIColorConstBGInverse) colorWithAlphaComponent:0.2].CGColor;
    _label.layer.shadowOpacity = 1.0f;
    _label.layer.shadowOffset = CGSizeMake(0, 1);
    _label.layer.shadowRadius = 2;
    _label.numberOfLines = 2;
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
    pStyle.alignment = NSTextAlignmentCenter;
    pStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    _label.attributedText = [[NSAttributedString alloc] initWithString:_itemData.title ?: @"" attributes:@{NSParagraphStyleAttributeName: pStyle, NSFontAttributeName: _label.font}];
    container.bottomLabel = _label;
    _button.accessibilityLabel = _label.attributedText.string;
    _label.isAccessibilityElement = NO;
    
    
    container.data = _itemData;
    _container = container;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _buttonBgView.frame = CGRectMake((self.bounds.size.width - AWEEditActionItemButtonSideLength) / 2.f, 0, AWEEditActionItemButtonSideLength, AWEEditActionItemButtonSideLength);
    _button.frame = _buttonBgView.bounds;
    
    CGFloat labelWidth = self.bounds.size.width + kLabelWidthOffset;
    CGSize newSize = [_label sizeThatFits:CGSizeMake(labelWidth, kLabelLineHeight * kLabelLineCnt)];
    _label.frame = CGRectMake(CGRectGetMidX(_buttonBgView.frame) - labelWidth * 0.5,
                              _buttonBgView.frame.size.height +
                              _buttonBgView.frame.origin.y + kButtonAndLabelVerticalGap,
                              labelWidth,
                              newSize.height);
}

- (CGSize)intrinsicContentSize {
    CGFloat w = AWEEditActionItemButtonSideLength;
    CGFloat labelWidth = w + kLabelWidthOffset;
    CGSize newSize = [_label sizeThatFits:CGSizeMake(labelWidth, kLabelLineHeight * kLabelLineCnt)];
    CGFloat h = AWEEditActionItemButtonSideLength + kButtonAndLabelVerticalGap + newSize.height;
    return CGSizeMake(w, h);
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    self.button.alpha = enable ? 1 : 0.5;
    self.label.alpha = enable ? 1 : 0.5;
}

#pragma mark - Action

- (void)onButtonClicked:(id)sender {
    ACCBLOCK_INVOKE(self.itemViewDidClicked, self);
}

#pragma mark - HitTest

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *res = [super hitTest:point withEvent:event];
    
    if (res == self && _button.isUserInteractionEnabled && !_button.isHidden && _button.isEnabled && _button.alpha > 0.01) {
        return _button;
    }
    return res;
}

#pragma mark - Getter

- (NSString *)identifier
{
    return self.itemData.idStr;
}

@end
