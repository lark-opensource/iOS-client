//
//  CJPayAlertSheetView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayAlertSheetView.h"
#import "CJPayAlertSheetAction.h"
#import "CJPayUIMacro.h"

@interface CJPayAlertSheetView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *cancelView;
@property (nonatomic, strong) UIView *topView;

@property (nonatomic, strong) NSMutableArray<CJPayAlertSheetAction *> *actions;

@property (nonatomic, strong) NSMutableArray<CJPayAlertSheetActionButton *> *buttons;
@property (nonatomic, strong) NSMutableArray<UIView *> *middleLines;

@property (nonatomic, assign) BOOL isAlwaysShow;

@end


@implementation CJPayAlertSheetView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [NSMutableArray new];
        _middleLines = [NSMutableArray new];
        _actions = [NSMutableArray new];
        _isAlwaysShow = NO;
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame isAlwaysShow:(BOOL)isAlwaysShow
{
    self = [super initWithFrame:frame];
    if (self) {
        _buttons = [NSMutableArray new];
        _middleLines = [NSMutableArray new];
        _actions = [NSMutableArray new];
        _isAlwaysShow = isAlwaysShow;
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.containerView];
    
    CJPayMasMaker(self.containerView, {
        make.left.equalTo(self).offset(8);
        make.right.equalTo(self).offset(-8);
        make.top.equalTo(self.mas_bottom);
        make.height.mas_equalTo(152);
    });
    
    self.backgroundColor = [UIColor cj_colorWithHexRGBA:@"0000004b"];
    self.containerView.backgroundColor = UIColor.clearColor;
    [self.containerView addSubview:self.topView];
    
    CJPayMasMaker(self.topView, {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo(self.containerView);
        make.height.mas_equalTo(100);
    });
    
    [self.containerView addSubview:self.cancelView];
    
    
    self.topView.layer.cornerRadius = 8;
    self.topView.layer.masksToBounds = YES;
    self.cancelView.layer.cornerRadius = 8;
    self.cancelView.layer.masksToBounds = YES;
    if(!_isAlwaysShow){
        [self cj_viewAddTarget:self
                        action:@selector(tapMask)
              forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)setupActionsUI {
    [self.cancelView cj_removeAllSubViews];
    [self.topView cj_removeAllSubViews];
    [self.buttons removeAllObjects];
    [self.middleLines removeAllObjects];

    [self.actions enumerateObjectsUsingBlock:^(CJPayAlertSheetAction *obj, NSUInteger idx, BOOL *stop) {
        CJPayAlertSheetActionButton *btn = [self createViewWithAction:obj];
        [self.buttons addObject:btn];
        if (idx == 0) {
            [self.cancelView addSubview:btn];
            CJPayMasMaker(btn, {
                make.left.right.equalTo(self.cancelView);
                make.top.equalTo(self.cancelView);
                make.height.mas_equalTo(50);
            });
        } else if (idx == 1) {
            [self.topView addSubview:btn];
            CJPayMasMaker(btn, {
                make.left.right.equalTo(self.topView);
                make.top.equalTo(self.topView);
                make.height.mas_equalTo(50);
            });
        } else {
            UIView *line = [self createMiddleLine];
            line.backgroundColor = UIColor.cj_e8e8e8ff;
            [self.middleLines addObject:line];
            
            [self.topView addSubview:line];
            CJPayMasMaker(line, {
                make.left.right.equalTo(self.topView);
                make.top.equalTo([self.buttons cj_objectAtIndex:idx-1].mas_bottom);
                make.height.mas_equalTo([UIDevice btd_onePixel]);
            });
            
            [self.topView addSubview:btn];
            CJPayMasMaker(btn, {
                make.left.right.equalTo(self.topView);
                make.top.equalTo(line.mas_bottom);
                make.height.mas_equalTo(50);
            });
        }
    }];
    
    CJPayMasMaker(self.cancelView, {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo([self.buttons lastObject].mas_bottom).offset(8);
        make.height.mas_offset(50);
    });

    [self.middleLines enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL *stop) {
        [self.topView bringSubviewToFront:obj];
    }];

    CGFloat margin = 8;
    CGFloat btnHeight = 50;
    CGFloat cancelHeight = btnHeight;
    CGFloat topHeight = ((NSInteger)self.buttons.count - 1) * btnHeight;
    
    CJPayMasUpdate(self.containerView, {
        make.height.mas_equalTo(margin * 2 + cancelHeight + topHeight + CJ_TabBarSafeBottomMargin);
    });
    
    CJPayMasUpdate(self.topView, {
        make.height.mas_equalTo(topHeight);
    });
    
}

- (CJPayAlertSheetActionButton *)createViewWithAction:(CJPayAlertSheetAction *)action {
    CJPayAlertSheetActionButton *button = [CJPayAlertSheetActionButton new];
    button.alertSheetAction = action;
    button.enabled = YES;
    button.backgroundColor = [UIColor whiteColor];
    [button setAttributedTitle:action.attributedTitle forState:UIControlStateNormal];
    [button addTarget:self action:@selector(actionButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)createMiddleLine {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor cj_colorWithHexString:@"e8e8e8"];
    return view;
}

- (void)actionButtonClicked:(CJPayAlertSheetActionButton *)sender {
    [self dismissWithCompletionBlock:^{
        if (sender.alertSheetAction.handler) {
            sender.alertSheetAction.handler(sender.alertSheetAction);
        }
    }];
}

- (void)showOnView:(UIView *)view {
    [self setupActionsUI];
    [view addSubview:self];
    CJPayMasMaker(self, {
        make.left.right.top.bottom.equalTo(view);
    });
    self.alpha = 0;
    
    [self layoutIfNeeded];

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
        CJPayMasReMaker(self.containerView, {
            make.left.equalTo(self).offset(8);
            make.right.equalTo(self).offset(-8);
            make.bottom.equalTo(self.mas_bottom);
            make.height.mas_equalTo(self.containerView.cj_height);
        });
        [self layoutIfNeeded];
    }];
}

- (void)dismissWithCompletionBlock:(nullable void(^)(void))completionBlock {
    CJ_DelayEnableView(self);
    self.alpha = 1;
    [UIView animateWithDuration:0.3 animations:^{
        CJPayMasReMaker(self.containerView, {
            make.left.equalTo(self).offset(8);
            make.right.equalTo(self).offset(-8);
            make.top.equalTo(self.mas_bottom);
            make.height.mas_equalTo(self.containerView.cj_height);
        });
        self.alpha = 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished && self.superview) {
            [self removeFromSuperview];
            CJ_CALL_BLOCK(completionBlock);
        }
    }];
}

- (void)addAction:(CJPayAlertSheetAction *)action {
    [self.actions addObject:action];
}

- (void)tapMask {
    @CJWeakify(self)
    [self dismissWithCompletionBlock:^{
        CJ_CALL_BLOCK(weak_self.cancelBlock);
    }];
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
    }
    return _containerView;
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.layer.cornerRadius = 8;
        _topView.backgroundColor = [UIColor whiteColor];
    }
    return _topView;
}

- (UIView *)cancelView {
    if (!_cancelView) {
        _cancelView = [UIView new];
        _cancelView.layer.cornerRadius = 8;
        _cancelView.backgroundColor = [UIColor whiteColor];
    }
    return _cancelView;
}

@end
