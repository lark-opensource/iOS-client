//
//  CJPayQuickBindCardAbbreviationViewModel.m
//  Pods
//
//  Created by renqiang on 2021/6/30.
//

#import "CJPayQuickBindCardAbbreviationViewModel.h"
#import "CJPayQuickBindCardAbbreviationView.h"
#import "CJPayBindCardVCModel.h"

@implementation CJPayQuickBindCardAbbreviationViewModel

- (Class)getViewClass {
    return [CJPayQuickBindCardAbbreviationView class];
}

- (CGFloat)viewHeight {
    return 48;
}

@end
