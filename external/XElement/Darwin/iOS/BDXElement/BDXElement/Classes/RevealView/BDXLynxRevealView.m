//
//  BDXLynxRevealView.m
//  BDXElement
//
//  Created by bytedance on 2020/10/26.
//

#import "BDXLynxRevealView.h"
#import <objc/runtime.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <Lynx/LynxTouchHandler.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/UIView+Lynx.h>

CGFloat kDeleteBtnWidth = 50;

@protocol BDXRevealViewDelegate <NSObject>

- (void)changeState:(NSDictionary *)info;

@end

@interface  BDXRevealView ()<UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<BDXRevealViewDelegate> delegate;
@property (nonatomic, strong) UIView* mainContentView;
@property (nonatomic, strong) UIView* optionView;
@property (nonatomic) BOOL shouldToRight;
@property (nonatomic, strong) NSLayoutConstraint* optionViewWidthConstraint;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

- (void)adjustOptionViewWitdh:(CGFloat)width;
- (void)hideOptionView:(void (^ __nullable)(BOOL finished))completion;

@end

@implementation BDXRevealView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if(gestureRecognizer == _panGesture || otherGestureRecognizer == _panGesture) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if(gestureRecognizer == _panGesture) {
        return YES;
    }
    if(gestureRecognizer == _tapGesture) {
        CGPoint tapPoint = [gestureRecognizer locationInView:self.mainContentView];
        if([self.mainContentView pointInside:tapPoint withEvent:nil]){
            return [self isNormalState] && self.optionViewWidthConstraint.constant != kDeleteBtnWidth;
        }
        tapPoint = [gestureRecognizer locationInView:self.optionView];
        if([self.optionView pointInside:tapPoint withEvent:nil]){
            self.optionViewWidthConstraint.constant = 0;
            return YES;
        }
        return NO;
    }
    return NO;
}

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (void)setupUI {
    _optionView = [[UIView alloc] init];
    [self addSubview:_optionView];
    _optionView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *optionViewRightConstraint = [NSLayoutConstraint constraintWithItem:_optionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    optionViewRightConstraint.active = YES;

    NSLayoutConstraint *optionViewTopConstraint = [NSLayoutConstraint constraintWithItem:_optionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    optionViewTopConstraint.active = YES;

    NSLayoutConstraint *optionViewBottomConstraint = [NSLayoutConstraint constraintWithItem:_optionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    optionViewBottomConstraint.active = YES;
    
    _optionViewWidthConstraint = [NSLayoutConstraint constraintWithItem:_optionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:0];
    _optionViewWidthConstraint.active = YES;
    
    _mainContentView = [[UIView alloc] init];
    [self addSubview:_mainContentView];
    _mainContentView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *mainContentViewRightConstraint = [NSLayoutConstraint constraintWithItem:_mainContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_optionView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    mainContentViewRightConstraint.active = YES;

    NSLayoutConstraint *mainContentViewTopConstraint = [NSLayoutConstraint constraintWithItem:_mainContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    mainContentViewTopConstraint.active = YES;

    NSLayoutConstraint *mainContentViewBottomConstraint = [NSLayoutConstraint constraintWithItem:_mainContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    mainContentViewBottomConstraint.active = YES;

    NSLayoutConstraint *mainContentViewWidthConstraint = [NSLayoutConstraint constraintWithItem:_mainContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    mainContentViewWidthConstraint.active = YES;
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _panGesture.delegate = self;
    [self addGestureRecognizer:_panGesture];
    
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handelTap:)];
    _tapGesture.delegate = self;
    [self addGestureRecognizer:_tapGesture];
}

- (void)adjustOptionViewWitdh:(CGFloat)width {
    if(_optionViewWidthConstraint == nil) {
        return;
    }
    _optionViewWidthConstraint.constant = width;
}

- (void)hideOptionView:(void (^ __nullable)(BOOL finished))completion {
    if(_optionViewWidthConstraint == nil) return;
    __weak typeof(self) weakself = self;
    weakself.optionViewWidthConstraint.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{
        [weakself layoutIfNeeded];
    } completion:^(BOOL finished) {
        if(completion != nil){
            completion(finished);
        }
        [weakself.delegate changeState:@{@"state":@"closed"}];
        weakself.optionViewWidthConstraint.constant = 0;
    }];
}

- (void)fullyExpandOptionView:(void (^ __nullable)(BOOL finished))completion {
    if(_optionViewWidthConstraint == nil) return;
    __weak typeof(self) weakself = self;
    weakself.optionViewWidthConstraint.constant = kDeleteBtnWidth;
    [UIView animateWithDuration:0.3 animations:^{
        [weakself layoutIfNeeded];
    } completion:^(BOOL finished) {
        if(completion != nil){
            completion(finished);
        }
        [weakself.delegate changeState:@{@"state":@"opened"}];
        weakself.optionViewWidthConstraint.constant = kDeleteBtnWidth;
    }];
}

- (void)handelTap:(UITapGestureRecognizer*)tapGesture {
    if(tapGesture.state == UIGestureRecognizerStateEnded){
    }
}

- (BOOL)isNormalState {
    return [self.mainContentView convertPoint:self.mainContentView.frame.origin toView:self].x >= 0;
}

- (void)handlePan:(UIPanGestureRecognizer *)panGesture {
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {
            if([self isNormalState]) {
                self.optionViewWidthConstraint.constant = 0;
            }
            self.shouldToRight = fabs(self.optionViewWidthConstraint.constant - kDeleteBtnWidth) < kDeleteBtnWidth * 0.05;
            CGPoint velocity = [panGesture velocityInView:self];
            if (fabs(velocity.y) > fabs(velocity.x) * 0.50) {
                panGesture.state = UIGestureRecognizerStateFailed;
                return;
            }
        }
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [panGesture translationInView:self];
            BOOL isToLeft = translation.x <= 0;
            
            if ((isToLeft && self.shouldToRight) || (!isToLeft && !self.shouldToRight)) {
                return;
            }
            CGFloat width = 0;
            if (isToLeft) {
                width = fabs(translation.x) < kDeleteBtnWidth ? fabs(translation.x) : kDeleteBtnWidth;
            } else {
                width = fabs(translation.x) < kDeleteBtnWidth ? kDeleteBtnWidth - fabs(translation.x) : 0;
            }

            [self adjustOptionViewWitdh:width];
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            if(self.optionViewWidthConstraint.constant < kDeleteBtnWidth * 0.50) {
                [self hideOptionView:nil];
            }else{
                [self fullyExpandOptionView:nil];
            }
        }
            break;
        default:
            break;
        
    }
}
@end

@interface BDXLynxRevealView ()<BDXRevealViewDelegate>

@property (nonatomic, strong) NSString* mode;
@property (nonatomic, strong) NSString* dragEdge;
@property (nonatomic, strong) BDXLynxRevealViewInnerView *innerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) BOOL hasDataChanged;

@end

@implementation BDXLynxRevealView

LYNX_REGISTER_UI("x-reveal-view")

- (BDXRevealView *)createView {
    BDXRevealView * view= [[BDXRevealView alloc] init];
    [view setupUI];
    view.delegate = self;
    return view;
}

- (void)insertChild:(LynxUI*)child atIndex:(NSInteger)index {
    [super didInsertChild:child atIndex:index];
    if([child isKindOfClass:[BDXLynxRevealViewInnerView class]]){
        self.innerView = (BDXLynxRevealViewInnerView *)child;//[child view];
    } else {
        self.contentView = [child view];
    }
    
    _hasDataChanged = YES;
}

- (void)layoutDidFinished {
    kDeleteBtnWidth = self.innerView.view.frame.size.width ?: kDeleteBtnWidth;
    self.view.optionView.frame = CGRectMake(self.view.bounds.size.width, 0, kDeleteBtnWidth, self.innerView.view.bounds.size.height);
    self.innerView.view.frame = self.innerView.view.bounds;
    self.view.mainContentView.frame = self.contentView.frame;
    self.contentView.frame = self.contentView.bounds;

    if (_hasDataChanged) {
        [self.view.optionView addSubview:self.innerView.view];
        [self.view.mainContentView addSubview:self.contentView];
        _hasDataChanged = NO;
    }
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    LynxUI* guard = nil;
    guard = [self hitTest:point withEvent:event onUIWithCustomLayout:self];
    point = [self.view convertPoint:point toView:guard.view];
    if (guard == nil) {
      // no new result
      return self;
    }
    return [guard hitTest:point withEvent:event];
}


- (LynxUI*)hitTest:(CGPoint)point withEvent:(UIEvent*)event onUIWithCustomLayout:(LynxUI*)ui {
  UIView* view = [ui.view hitTest:point withEvent:event];
  if (view == ui.view || !view) {
    return nil;
  }
  UIView* targetViewWithUI = view;
  while (view.superview != ui.view) {
    view = view.superview;
    if (view.lynxSign) {
      targetViewWithUI = view;
    }
  }
  for (LynxUI* child in ui.children) {
    if (child.view == targetViewWithUI) {
      return child;
    }
  }
  return nil;
}

# pragma mark - delegate
- (void)changeState:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"state" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}


LYNX_PROP_SETTER("mode", mode, NSString *) {
}

LYNX_UI_METHOD(toggleActive) {
  NSString *state = [params objectForKey:@"state"];
    if (state.length > 0) {
        if ([state isEqualToString:@"open"]) {
            [self.view fullyExpandOptionView:nil];
        } else if ([state isEqualToString:@"close"]) {
            [self.view hideOptionView:nil];
        }
    } else {
        if (self.view.optionViewWidthConstraint.constant > 1) {
            [self.view hideOptionView:nil];
        } else {
            [self.view fullyExpandOptionView:nil];
        }
    }
}

@end
