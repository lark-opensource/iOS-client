//
//  CJPayRetainVoucherListView.m
//  Pods
//
//  Created by youerwei on 2022/2/7.
//

#import "CJPayRetainVoucherListView.h"
#import "CJPayRetainVoucherView.h"
#import "CJPayRetainVoucherV3View.h"
#import "CJPayRetainMsgModel.h"
#import "CJPayUIMacro.h"

@interface CJPayRetainVoucherListView ()

@end

@implementation CJPayRetainVoucherListView

- (void)updateWithRetainMsgModels:(NSArray<CJPayRetainMsgModel *> *)retainMsgModels
                     vourcherType:(CJPayRetainVoucherType)vourcherType {
    __block UIView *lastView = nil;
    @CJWeakify(self)
    [retainMsgModels enumerateObjectsUsingBlock:^(CJPayRetainMsgModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        if (![obj isKindOfClass:CJPayRetainMsgModel.class]) {
            return;
        }
        __block UIView *vourcherView;
        if (vourcherType == CJPayRetainVoucherTypeV3) {
            CJPayRetainVoucherV3View *vourcherV3View = [CJPayRetainVoucherV3View new];
            [vourcherV3View updateWithRetainMsgModel:obj];
            vourcherView = vourcherV3View;
        } else {
            CJPayRetainVoucherView *vourcherV2View = [CJPayRetainVoucherView new];
            [vourcherV2View updateWithRetainMsgModel:obj];
            vourcherView = vourcherV2View;
        }
        [self addSubview:vourcherView];
        CJPayMasMaker(vourcherView, {
            if (lastView) {
                make.top.equalTo(lastView.mas_bottom).offset(8);
            } else {
                make.top.equalTo(self);
            }
            make.left.right.equalTo(self);
            make.height.mas_equalTo(64);
        })
        lastView = vourcherView;
    }];
    
    if (!lastView) {
        return;
    }
    
    CJPayMasMaker(lastView, {
        make.bottom.equalTo(self);
    })
}

@end
