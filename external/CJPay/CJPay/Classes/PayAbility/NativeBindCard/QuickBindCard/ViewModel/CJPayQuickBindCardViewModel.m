//
//  CJPayQuickBindCardViewModel.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayQuickBindCardViewModel.h"

#import "CJPayQuickBindCardTableViewCell.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayQuickBindCardViewModel

- (Class)getViewClass
{
    return [CJPayQuickBindCardTableViewCell class];
}

- (CGFloat)viewHeight
{
    if (self.viewStyle == CJPayBindCardStyleCardCenter) {
        return 60;
    }
    return 52;
}

- (void)startLoading
{
    if ([self.cell isKindOfClass:[CJPayQuickBindCardTableViewCell class]]) {
        [((CJPayQuickBindCardTableViewCell *)self.cell) startLoading];
    }
}

- (void)stopLoading
{
    if ([self.cell isKindOfClass:[CJPayQuickBindCardTableViewCell class]]) {
        [((CJPayQuickBindCardTableViewCell *)self.cell) stopLoading];
    }
}

@end
