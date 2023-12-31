//
//  CJPayLynxInfoView.m
//  Aweme
//
//  Created by 高航 on 2022/12/8.
//

#import "CJPayLynxInfoView.h"
#import "CJPayUIMacro.h"
@interface CJPayLynxInfoView()

@property (nonatomic, copy)NSArray<UIView *> *lynxItemList;

@end

@implementation CJPayLynxInfoView

- (instancetype)initWithLynxItem:(NSArray<UIView *> *)lynxItemList {
    self = [super init];
    if (self) {
        _lynxItemList = lynxItemList;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    __block UIView *lastView = nil;
    @CJWeakify(self)
    [self.lynxItemList enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        [self addSubview:obj];
        if (!lastView) {
            CJPayMasMaker(obj, {
                make.top.left.right.equalTo(self);
            });
        } else {
            CJPayMasMaker(obj, {
                make.top.equalTo(lastView.mas_bottom).offset(12);
                make.left.right.equalTo(self);
            });
        }
        lastView = obj;
    }];
    CJPayMasUpdate(lastView, {
        make.bottom.equalTo(self.mas_bottom);
    });
}

@end
