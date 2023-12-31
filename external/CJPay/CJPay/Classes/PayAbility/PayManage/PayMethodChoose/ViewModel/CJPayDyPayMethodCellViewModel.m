//
//  CJPayDyPayMethodCellViewModel.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/23.
//

#import "CJPayDyPayMethodCellViewModel.h"
#import "CJPaySDKMacro.h"
#import "CJPayDyPayMethodCell.h"
#import "CJPayDefaultChannelShowConfig.h"

@implementation CJPayDyPayMethodCellViewModel

- (UIColor *)topMarginColor {
    return [UIColor clearColor];
}

- (CGFloat)topMarginHeight {
    return self.needAddTopLine ? 13.5 : 0.0;
}

- (Class)getViewClass {
    return [CJPayDyPayMethodCell class];
}

- (CGFloat)viewHeight {
    CJPayDefaultChannelShowConfig *config = self.showConfig;
    // cell需要分两行展示
    CGFloat viewHeight = 0;
    if (Check_ValidString(config.subTitle) || (config.canUse && Check_ValidString(config.discountStr))) {
        if (Check_ValidString(config.descTitle)) {
            // 底部有固定背书文案
            viewHeight = 82;
        } else {
            viewHeight = 59;
        }
    } else {
        if (Check_ValidString(config.descTitle)) {
            // 底部有固定背书文案
            viewHeight = 59;
        } else {
            viewHeight = 52;
        }
    }
    return viewHeight;
}

- (void)startLoading
{
    if ([self.cell isKindOfClass:[CJPayDyPayMethodCell class]]) {
        [((CJPayDyPayMethodCell *)self.cell) startLoading];
    }
}

- (void)stopLoading
{
    if ([self.cell isKindOfClass:[CJPayDyPayMethodCell class]]) {
        [((CJPayDyPayMethodCell *)self.cell) stopLoading];
    }
}
@end
