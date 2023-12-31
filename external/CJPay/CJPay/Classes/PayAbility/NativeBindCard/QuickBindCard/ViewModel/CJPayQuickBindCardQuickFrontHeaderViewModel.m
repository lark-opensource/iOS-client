//
//  CJPayQuickBindCardHeaderViewModel.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayQuickBindCardQuickFrontHeaderViewModel.h"

#import "CJPayQuickBindCardHeaderView.h"
#import "CJPayQuickBindCardFooterView.h"
#import "CJPayUIMacro.h"
#import "CJPayQuickBindCardQuickFrontHeaderView.h"
#import "CJPayCommonListViewController.h"

@implementation CJPayQuickBindCardFooterViewModel

- (Class)getViewClass
{
    return [CJPayQuickBindCardFooterView class];
}

- (CGFloat)viewHeight
{
    return 48;
}

@end

@implementation CJPayQuickBindCardHeaderViewModel

- (Class)getViewClass
{
    return [CJPayQuickBindCardHeaderView class];
}

- (CGFloat)viewHeight
{
    CGSize mainTitleSize = [self.title cj_sizeWithFont:[UIFont cj_boldFontOfSize:16] width:self.viewController.tableView.cj_width - 32 - 32];
    CGSize subTitleSize = Check_ValidString(self.subTitle) ? [self.subTitle cj_sizeWithFont:[UIFont cj_fontOfSize:12] width:self.viewController.tableView.cj_width - 32 - 32] : CGSizeMake(self.viewController.tableView.cj_width - 32 - 32, 0);
    return 94 + mainTitleSize.height + subTitleSize.height;
}

@end

@implementation CJPayQuickBindCardQuickFrontHeaderViewModel

- (Class)getViewClass {
    return [CJPayQuickBindCardQuickFrontHeaderView class];
}

- (CGFloat)viewHeight {
    if (Check_ValidString(self.subTitle)) {
        return 67;
    }
    return 48;
}

@end
