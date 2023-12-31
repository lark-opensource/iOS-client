//
//  CJPayQuickBindCardTipsViewModel.m
//  Pods
//
//  Created by xiuyuanLee on 2021/3/4.
//

#import "CJPayQuickBindCardTipsViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayQuickBindCardTipsView.h"
#import "CJPayCommonListViewController.h"

@implementation CJPayQuickBindCardTipsViewModel

- (NSString *)getContent {
    return CJPayLocalizedStr(@"其他银行输入卡号添加");
}

- (Class)getViewClass {
    return [CJPayQuickBindCardTipsView class];
}

- (CGFloat)getViewHeight {
    return 30 + [[self getContent] cj_sizeWithFont:[UIFont cj_fontOfSize:13] maxSize:CGSizeMake(self.viewController.tableView.cj_width - 32, CGFLOAT_MAX)].height;
}

@end
