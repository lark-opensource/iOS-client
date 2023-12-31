//
//  CJPayDynamicLayoutView.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2023/4/22.
//

#import "CJPayDynamicLayoutView.h"
#import "CJPayDynamicLayoutModel.h"
#import "CJPayUIMacro.h"

@interface CJPayDynamicLayoutView ()

@property (nonatomic, assign) CGRect lastFrame; //上一次动态化布局的frame
@property (nonatomic, strong) NSMutableArray<UIView *> *dynamicViews; //参与动态布局的UI组件

@end

@implementation CJPayDynamicLayoutView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.axis = UILayoutConstraintAxisVertical;
        self.distribution = UIStackViewDistributionFillProportionally;
        self.spacing = 0;
    }
    return self;
}

// 根据视图列表contentViews构造动态布局stackView
- (void)updateWithContentViews:(NSArray<UIView *> *)contentViews isLayoutInstantly:(BOOL)layoutInstantly{
    if (!Check_ValidArray(contentViews)) {
        return;
    }
    [self cj_removeAllSubViews];
    [self.dynamicViews removeAllObjects];
    [contentViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //根据obj.cj_dynamicLayoutModel决定其在动态布局stackView上所占的size
        UIView *contentView = [self p_createStackContentView:obj];
        [self addArrangedSubview:contentView];
        [self.dynamicViews btd_addObject:obj];
    }];
    
    if (layoutInstantly) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

// 在stackView底部新增参与动态布局的UI组件
- (void)addDynamicLayoutSubview:(UIView *)view {
    [self removeDynamicLayoutSubview:view];
    CJPayDynamicLayoutModel *layoutModel = view.cj_dynamicLayoutModel;
    if (!layoutModel) {
        layoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:0 bottomMargin:0 leftMargin:0 rightMargin:0];
    }
    UIView *contentView = [self p_createStackContentView:view];
    [self addArrangedSubview:contentView];
    [self.dynamicViews btd_addObject:view];
}

// 在stackView指定位置插入参与动态布局的UI组件
- (void)insertDynamicLayoutSubview:(UIView *)view atIndex:(NSUInteger)stackIndex {
    
    NSUInteger insertIndex = stackIndex;
    if (stackIndex > self.arrangedSubviews.count - 1) {
        [self addDynamicLayoutSubview:view];
        return;
    } else if (stackIndex < 0) {
        insertIndex = 0;
    }
    
    [self removeDynamicLayoutSubview:view];
    CJPayDynamicLayoutModel *layoutModel = view.cj_dynamicLayoutModel;
    if (!layoutModel) {
        layoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:0 bottomMargin:0 leftMargin:0 rightMargin:0];;
    }
    
    UIView *contentView = [self p_createStackContentView:view];
    [self insertArrangedSubview:contentView atIndex:insertIndex];
    [self.dynamicViews btd_addObject:view];
}

// 根据cj_dynamicLayoutModel创建此view所占用的布局空间
- (UIView *)p_createStackContentView:(UIView *)view {
    CJPayDynamicLayoutModel *layoutModel = view.cj_dynamicLayoutModel;
    if (!layoutModel) {
        layoutModel = [[CJPayDynamicLayoutModel alloc] initModelWithTopMargin:0 bottomMargin:0 leftMargin:0 rightMargin:0];
    }
    
    UIView *contentView = [UIView new];
    contentView.backgroundColor = [UIColor clearColor];
    [contentView addSubview:view];
    CJPayMasMaker(view, {
        make.top.equalTo(contentView).offset(layoutModel.topMargin);
        make.bottom.equalTo(contentView).offset(-layoutModel.bottomMargin);
        if (layoutModel.useCenterX) {
            make.centerX.equalTo(contentView);
            make.left.greaterThanOrEqualTo(contentView).offset(layoutModel.leftMargin);
            make.right.lessThanOrEqualTo(contentView).offset(-layoutModel.rightMargin);
        } else {
            make.left.equalTo(contentView).offset(layoutModel.leftMargin);
            make.right.equalTo(contentView).offset(-layoutModel.rightMargin);
        }
        if (layoutModel.forceHeight > 0) {
            make.height.mas_equalTo(layoutModel.forceHeight);
        }
        if (layoutModel.forceWidth > 0) {
            make.width.mas_equalTo(layoutModel.forceWidth);
        }
    });
    contentView.hidden = view.isHidden;
    return contentView;
}

// 移除参与动态布局的subview
- (void)removeDynamicLayoutSubview:(UIView *)view {
    [self.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj == view || obj == view.superview) {
            [self removeArrangedSubview:obj];
            [obj removeFromSuperview];
            if (view.superview) {
                [view removeFromSuperview];
            }
            [self.dynamicViews removeObject:view];
            *stop = YES;
        }
    }];
}

// 变更参与动态布局的subview的显隐状态
- (void)setDynamicLayoutSubviewHiddenStatus:(NSArray<UIView *> *)subviews {
    [subviews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *superview = obj.superview;
        if ([self.arrangedSubviews containsObject:superview]) {
            // 如果实际UI组件包了一层contentView作为superView，那么需调整其superView的显隐状态（UIStackView只关心直接subview的显隐态）
            superview.hidden = obj.isHidden;
        }
    }];
}

#pragma mark - Override
- (void)layoutSubviews {
    [super layoutSubviews];
    BOOL isBoundsChanged = !CGRectEqualToRect(self.frame, self.lastFrame);
    BOOL isNewFrameZero = CGRectIsEmpty(self.frame);
    if (!CGRectIsEmpty(self.lastFrame) && CGRectIsEmpty(self.frame)) {
        CJPayLogAssert(YES, @"动态布局frame为空，responseVC=%@", CJString([[self cj_responseViewController] cj_trackerName]));
    }
    // 动态布局视图发生变化时，将新布局的frame告知代理
    if (isBoundsChanged && !isNewFrameZero) {
        self.lastFrame = self.frame;
        // layoutStackView的frame发生变化时告知代理
        if ([self.delegate respondsToSelector:@selector(dynamicViewFrameChange:)]) {
            [self.delegate dynamicViewFrameChange:self.frame];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    __block UIView *view = [super hitTest:point withEvent:event];
    if (view.superview == self && Check_ValidArray(view.subviews) && [self.dynamicViews containsObject:[view.subviews firstObject]]) {
        
        UIView *dynamicSubview = [view.subviews firstObject];
        [dynamicSubview.cj_dynamicLayoutModel.clickViews enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGPoint temPoint = [obj convertPoint:point fromView:self];
            
            BOOL canRespondHit = !obj.isHidden && obj.isUserInteractionEnabled && obj.alpha >= 0.1;
            if (canRespondHit && CGRectContainsPoint(obj.bounds, temPoint)) {
                view = obj;
                *stop = YES;
            }
        }];
    }
    return view;
}

#pragma mark - lazy init
- (NSMutableArray<UIView *> *)dynamicViews {
    if (!_dynamicViews) {
        _dynamicViews = [NSMutableArray new];
    }
    return _dynamicViews;
}
@end
