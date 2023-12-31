//
//  CJPayStateView.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/26.
//

#import "CJPayStateView.h"
#import "CJPayUIMacro.h"
#import "CJPayCurrentTheme.h"
#import "CJPayImageLabelStateView.h"
#import "NSBundle+CJPay.h"
#import "CJPayBrandPromoteABTestManager.h"

@interface CJPayStateView()<CJPayImageLabelStateViewDelegate>
// 分开写，是因为loading有旋转的效果
@property (nonatomic, strong) CJPayImageLabelStateView *stateView;
@property (nonatomic, assign) CJPayStateType stateType;
@property (nonatomic, copy) NSDictionary<NSNumber *, CJPayStateShowModel *> *showConfig;

@end

@implementation CJPayStateView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.whiteColor;
        self.stateType = CJPayStateTypeNone;
    }
    return self;
}

- (void)setupUI{
    [self addSubview:self.stateView];
    
    CJPayMasMaker(self.stateView, {
        make.top.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self, {
        make.bottom.equalTo(self.stateView);
    });
}

- (void)startState:(CJPayStateType) state {
    if (self.stateType == state) {
        return;
    }
    if (self.stateView && self.stateView.superview) {
        [self.stateView removeFromSuperview];//用于支付状态demo测试
    }
    self.stateType = state;
    [self p_setShowConfigs];
    self.stateView = [[CJPayImageLabelStateView alloc] initWithModel:[self.showConfig objectForKey:@(state)]];
    [self setupUI];
}

- (void)updateShowConfigsWithType:(CJPayStateType)type model:(CJPayStateShowModel *)model {
    NSMutableDictionary *mutableConfig = [NSMutableDictionary dictionaryWithDictionary:self.showConfig ?: @{}];
    if ([mutableConfig btd_objectForKey:@(type) default:nil]) {
        return;
    }
    [mutableConfig addEntriesFromDictionary:@{@(type) : model}];
    self.showConfig = [mutableConfig copy];
}

#pragma mark - Private Method

- (void)p_setShowConfigs {    
    CJPayStateShowModel *timeOutModel = [CJPayStateShowModel new];
    timeOutModel.titleStr = Check_ValidString(self.pageDesc) ? self.pageDesc : CJPayLocalizedStr(@"支付超时");
    timeOutModel.iconName = @"cj_pay_timeout_icon";
    timeOutModel.iconBackgroundColor = [UIColor cj_ff9f00ff];
    
    CJPayStateShowModel *netExceptionModel = [CJPayStateShowModel new];
    netExceptionModel.titleStr = CJPayLocalizedStr(@"网络超时");
    netExceptionModel.iconName = @"cj_pay_timeout_icon";
    netExceptionModel.iconBackgroundColor = [UIColor cj_ff9f00ff];
    
    CJPayStateShowModel *waitingModel = [CJPayStateShowModel new];
    waitingModel.titleStr = Check_ValidString(self.pageDesc) ? self.pageDesc : CJPayLocalizedStr(@"支付处理中");
    waitingModel.iconName = @"cj_new_pay_processing_icon";
    waitingModel.iconBackgroundColor = [UIColor clearColor];
    
    CJPayStateShowModel *failedModel = [CJPayStateShowModel new];
    failedModel.titleStr = Check_ValidString(self.pageDesc) ? self.pageDesc : CJPayLocalizedStr(@"支付失败");
    failedModel.iconName = @"cj_pay_failed_icon";
    failedModel.iconBackgroundColor = [UIColor cj_f85959ff];
    
    [self updateShowConfigsWithType:CJPayStateTypeFailure model:failedModel];
    [self updateShowConfigsWithType:CJPayStateTypeTimeOut model:timeOutModel];
    [self updateShowConfigsWithType:CJPayStateTypeWaiting model:waitingModel];
    [self updateShowConfigsWithType:CJPayStateTypeNetException model:netExceptionModel];
}

+ (NSMutableAttributedString *)p_titleAttributedStrWithFrontStr:(NSString *)frontStr latterStr:(NSString *)latterStr {
    NSDictionary *frontMsgAttributes = @{NSFontAttributeName : [UIFont cj_boldFontOfSize:20]};
    NSDictionary *middleMsgAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:22]};
    NSDictionary *latterMsgAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:24]};
    NSMutableAttributedString *middleAttr = [[NSMutableAttributedString alloc] initWithString:@"￥" attributes:middleMsgAttributes];
    [middleAttr addAttribute:NSBaselineOffsetAttributeName value:@(-1.5) range:NSMakeRange(0, middleAttr.length)];
    [middleAttr addAttribute:NSKernAttributeName value:@(-4) range:NSMakeRange(0,1)];
    NSMutableAttributedString *latterAttr = [[NSMutableAttributedString alloc] initWithString:latterStr attributes:latterMsgAttributes];
    [latterAttr addAttribute:NSBaselineOffsetAttributeName value:@(-1.5) range:NSMakeRange(0, latterStr.length)];
    NSMutableAttributedString *titleAttributedStr = [[NSMutableAttributedString alloc] initWithString:CJString(frontStr) attributes:frontMsgAttributes];
    [titleAttributedStr appendAttributedString:middleAttr];
    [titleAttributedStr appendAttributedString:latterAttr];
    return titleAttributedStr;
}

+ (NSMutableAttributedString *)updateTitleWithContent:(NSString *)text desc:(NSString *)desc {
    NSString *frontStr = [NSString stringWithFormat:@"%@",text ?: CJPayLocalizedStr(@"支付成功")];
    return [self p_titleAttributedStrWithFrontStr:frontStr latterStr:desc];
}

+ (NSMutableAttributedString *)updateTitleWithContent:(NSString *)text amount:(NSString *)amount {
    NSString *frontStr = [NSString stringWithFormat:@"%@",text ?: CJPayLocalizedStr(@"支付成功")];
    NSString *latterStr = [NSString stringWithFormat:@"%.2f", [amount floatValue] * 0.01];
    return [self p_titleAttributedStrWithFrontStr:frontStr latterStr:latterStr];
}

+ (NSMutableAttributedString *)updateTitleWithContent:(NSString *)text {
    return [[NSMutableAttributedString alloc] initWithString:CJString(text) attributes:@{NSFontAttributeName : [UIFont cj_boldFontOfSize:20]}];
}

#pragma mark - Getter

- (void)clickBtn:(NSString *)buttonName {
    if (self.delegate) {
        [self.delegate stateButtonClick:buttonName];
    }
}

@end
