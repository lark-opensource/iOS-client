//
//  CJPayAllBankCardListViewController.h
//  Pods
//
//  Created by wangxiaohong on 2020/12/30.
//

#import "CJPayThemedCommonListViewController.h"
#import "CJPayMemAuthInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayAllBankCardListViewController : CJPayThemedCommonListViewController

@property (nonatomic, copy) NSArray<CJPayBaseListViewModel *> *viewModels;
@property (nonatomic, strong) CJPayMemAuthInfo *authInfo;
@property (nonatomic, copy) NSDictionary *passParams;

NS_ASSUME_NONNULL_END

@end
