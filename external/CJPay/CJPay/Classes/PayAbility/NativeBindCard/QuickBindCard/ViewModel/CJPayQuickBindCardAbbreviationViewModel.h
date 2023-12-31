//
//  CJPayQuickBindCardAbbreviationViewModel.h
//  Pods
//
//  Created by renqiang on 2021/6/30.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBindCardVCModel;
@interface CJPayQuickBindCardAbbreviationViewModel : CJPayBaseListViewModel

@property (nonatomic, weak) CJPayBindCardVCModel *bindCardVCModel;
@property (nonatomic, assign) NSInteger bindCardBankCount;
@property (nonatomic, assign) NSInteger banksLength;//列表最多要展示的银行卡数

@end

NS_ASSUME_NONNULL_END
