//
//  CJPayHalfPageBaseViewController+Biz.m
//  CJPay
//
//  Created by 王新华 on 10/10/19.
//

#import "CJPayHalfPageBaseViewController+Biz.h"
#import <objc/runtime.h>
#import "CJPayUIMacro.h"

@implementation CJPayHalfPageBaseViewController(Biz)

- (CJPayStateView *)stateView {
   CJPayStateView *curStateView = objc_getAssociatedObject(self, @selector(stateView));
    if (!curStateView) {
        curStateView = [CJPayStateView new];
        objc_setAssociatedObject(self, @selector(stateView), curStateView, OBJC_ASSOCIATION_RETAIN);
        [self.contentView insertSubview:curStateView atIndex:0];
        curStateView.hidden = YES;
        curStateView.delegate = self;
        CJPayMasMaker(curStateView, {
            make.top.mas_equalTo(self.contentView).offset(100);
            make.left.right.equalTo(self.contentView);
        });
    }
    return curStateView;
}

- (void)showState:(CJPayStateType)stateType {
    [self.stateView startState:stateType];
    [self.contentView bringSubviewToFront:self.stateView];
    self.stateView.hidden = stateType == CJPayStateTypeNone;
    if (!self.stateView.isHidden) {
        [self.view endEditing:YES];
    }
}

- (void)stateButtonClick:(NSString *)buttonName {
    CJPayLogInfo(@"子类重写");
}

@end
