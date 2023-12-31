//
//  CJPayNoNetworkContainerView.m
//  CJPay
//
//  Created by wangxinhua on 2020/6/7.
//

#import "CJPayNoNetworkContainerView.h"
#import "CJPayUIMacro.h"
#import "CJPayProtocolManager.h"
#import "CJPayErrorViewProtocol.h"
#import "UIView+CJTheme.h"

@interface CJPayNoNetworkContainerView()

@property (nonatomic, strong) CJPayNoNetworkView *defaultNoNetworkView;
@property (nonatomic, strong) UIView *configErrorView;

@end

@implementation CJPayNoNetworkContainerView

- (void)showStyle:(CJPayTheme)payTheme {
    // 优先使用宿主配置的主题样式
    CJ_DECLARE_ID_PROTOCOL(CJPayErrorViewProtocol);
    if (objectWithCJPayErrorViewProtocol && [objectWithCJPayErrorViewProtocol respondsToSelector:@selector(errorViewFor:edgeInsets:actionBlock:)]) {
        @CJWeakify(self)
        if (self.configErrorView && [self.subviews containsObject:self.configErrorView]) {
            return;
        }
        UIView *errorView = [objectWithCJPayErrorViewProtocol errorViewFor:[self p_errorViewStyleBy:payTheme] edgeInsets:self.edgeInsets  actionBlock:^(CJPayErrorViewAction action) {
            @CJStrongify(self)
            if (action == CJPayErrorViewActionRetry) {
                CJ_CALL_BLOCK(self.refreshBlock);
            }
        }];
        if (errorView) {
            errorView.frame = self.bounds;
            self.configErrorView = errorView;
            [self addSubview:errorView];
            CJPayMasMaker(errorView, {
                make.edges.equalTo(self);
            });
            return;
        }
    }
    [self cj_removeAllSubViews];
    // 如果上面自定义的errorView不可用，则走默认的主题样式
    CJPayNoNetworkView *defaultNoNetworkView = [CJPayNoNetworkView new];
    defaultNoNetworkView.titleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].titleColor;
    defaultNoNetworkView.subTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].subtitleColor;
    defaultNoNetworkView.backgroundColor =[CJPayLocalThemeStyle defaultThemeStyle].mainBackgroundColor;
    
    @CJWeakify(self)
    defaultNoNetworkView.refreshBlock = ^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.refreshBlock);
    };
    if (defaultNoNetworkView) {
        self.defaultNoNetworkView = defaultNoNetworkView;
        [self addSubview:defaultNoNetworkView];
        CJPayMasMaker(defaultNoNetworkView, {
            make.edges.equalTo(self);
        });
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.defaultNoNetworkView.titleLabel.textColor = localTheme.titleColor;
        self.defaultNoNetworkView.subTitleLabel.textColor = localTheme.subtitleColor;
        self.defaultNoNetworkView.backgroundColor = localTheme.mainBackgroundColor;
    }
}

- (CJPayErrorViewStyle)p_errorViewStyleBy:(CJPayTheme)theme {
    CJPayErrorViewStyle style = CJPayErrorViewStyleLight;
    switch (theme) {
        case kCJPayThemeStyleLight:
            style = CJPayErrorViewStyleLight;
            break;
        case kCJPayThemeStyleDark:
            style = CJPayErrorViewStyleDark;
            break;
            
        default:
            style = CJPayErrorViewStyleLight;
            break;
    }
    return style;
}

@end
