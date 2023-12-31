//
//  CJPayBankCardActivityHeaderViewModel.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBankCardActivityHeaderViewModel.h"
#import "CJPayBankCardActivityHeaderCell.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonListViewController.h"

@implementation CJPayBankCardActivityHeaderViewModel

- (Class)getViewClass {
    return [CJPayBankCardActivityHeaderCell class];
}

- (CGFloat)getViewHeight {
    
    if (self.ifShowSubTitle && Check_ValidString(self.subTitle)) {
        CGSize subTitleSize = [self.subTitle cj_sizeWithFont:[UIFont cj_fontOfSize:12] maxSize:CGSizeMake(self.viewController.tableView.cj_width - 28, 20)];
        return (self.viewController.tableView.cj_width - 28 - subTitleSize.width < 28) ? 98 : 80;
    } else {
        return 64;
    }
}

@end
