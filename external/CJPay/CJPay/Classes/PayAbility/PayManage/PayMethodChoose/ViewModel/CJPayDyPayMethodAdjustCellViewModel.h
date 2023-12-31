//
//  CJPayDyPayMethodAdjustCellViewModel.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/23.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDyPayMethodAdjustCellViewModel : CJPayBaseListViewModel

@property (nonatomic, assign) BOOL isInFoldStatus; //标识是否处于折叠状态
@property (nonatomic, copy) void (^clickBlock)(BOOL isFold);
@property (nonatomic, copy) NSString *addBankCardFoldDesc; // 添加新卡折叠/展开文案

@end

NS_ASSUME_NONNULL_END
