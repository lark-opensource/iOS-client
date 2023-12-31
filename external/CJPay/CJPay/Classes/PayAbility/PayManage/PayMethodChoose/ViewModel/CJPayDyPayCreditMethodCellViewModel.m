//
//  CJPayDyPayCreditMethodCellViewModel.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/27.
//

#import "CJPayDyPayCreditMethodCellViewModel.h"
#import "CJPayDyPayCreditMethodCell.h"
#import "CJPaySDKMacro.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
@implementation CJPayDyPayCreditMethodCellViewModel

- (Class)getViewClass {
    return [CJPayDyPayCreditMethodCell class];
}

- (CGFloat)viewHeight {
    CJPayDefaultChannelShowConfig *config = self.showConfig;
    NSArray *creditPayMethods = [NSArray new];
    if ([config.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)config.payChannel;
        creditPayMethods = payChannel.payTypeData.creditPayMethods;
    }
    
    CGFloat viewHeight = 0;
    if (Check_ValidString(config.subTitle)) { //月付有副标题，则展示副标题不展示分期栏
        viewHeight = 82;
    } else if (config.canUse) { //月付可用
        if (Check_ValidArray(creditPayMethods)) { //有分期数据
            viewHeight = 132;
        } else if (Check_ValidString(config.discountStr)) { //无分期数据但有营销标签
            viewHeight = 82;
        } else {
            viewHeight = 59;
        }
    } else { //月付不可用
        viewHeight = 59;
    }
    
    return viewHeight;
}

- (CGFloat)topMarginHeight {
    return 0.0;
}

@end
