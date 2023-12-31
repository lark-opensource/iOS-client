//
//  CJPayCombineLimitViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/15.
//

#import "CJPayCombineLimitViewController.h"

#import "CJPayBytePayBalanceLimitView.h"
#import "CJPayUIMacro.h"
#import "CJPayCombinePayLimitModel.h"

@interface CJPayCombineLimitViewController ()

@property (nonatomic, strong) CJPayBytePayBalanceLimitView *combineLimitView;

@property (nonatomic, strong) CJPayCombinePayLimitModel *limitModel;

@property (nonatomic, copy) void(^actionBlock)(BOOL isClose);

@end

@implementation CJPayCombineLimitViewController

+ (instancetype)createWithModel:(id)model actionBlock:(nonnull void (^)(BOOL))actionBlock {
    if (![model isKindOfClass:CJPayCombinePayLimitModel.class]) {
        return [CJPayCombineLimitViewController new];
    }
    
    return [[CJPayCombineLimitViewController alloc] initWithLimitModel:model actionBlock:actionBlock];
}

- (instancetype)initWithLimitModel:(CJPayCombinePayLimitModel *)limitModel actionBlock:(void (^)(BOOL isClose))block{
    self = [super init];
    if (self) {
        self.limitModel = limitModel;
        self.actionBlock = block;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI {
    [self.containerView addSubview:self.combineLimitView];
    self.containerView.layer.cornerRadius = 12;
    
    CGFloat curWindowWidth = [UIApplication btd_mainWindow].cj_size.width;
    CJPayMasMaker(self.combineLimitView, {
        make.center.equalTo(self.view);
        make.width.mas_equalTo(curWindowWidth * 280 / 375);
    });
    
    CJPayMasReMaker(self.containerView, {
        make.edges.equalTo(self.combineLimitView);
    });
    
    [self.combineLimitView updateWithButtonModel:self.limitModel];
}

- (CJPayBytePayBalanceLimitView *)combineLimitView {
    if (!_combineLimitView) {
        _combineLimitView = [CJPayBytePayBalanceLimitView new];
        @weakify(self);
        _combineLimitView.closeClickBlock = ^{
            @strongify(self);
            [self dismissSelfWithCompletionBlock:^{
                CJ_CALL_BLOCK(self.actionBlock, YES);
            }];
        };
        _combineLimitView.confirmPayBlock = ^{
            @strongify(self);
            [self dismissSelfWithCompletionBlock:^{
                CJ_CALL_BLOCK(self.actionBlock, NO);
            }];
        };
    }
    return _combineLimitView;
}

@end
