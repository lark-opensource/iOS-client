//
//  CJPayChooseDyPayMethodGroupModel.h
//  Aweme
//
//  Created by 利国卿 on 2022/12/8.
//

#import <Foundation/Foundation.h>
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayDefaultChannelShowConfig;
@interface CJPayChooseDyPayMethodGroupModel : NSObject

@property (nonatomic, assign) CJPayPayMethodType methodGroupType; //分组类型
@property (nonatomic, copy) NSString *methodGroupTitle; //分组标题，例如“支付工具”、“资金渠道”
@property (nonatomic, copy) NSString *creditPayDesc; //月付的描述文案（目前仅“资金渠道”分组使用）
@property (nonatomic, assign) NSInteger displayNewBankCardCount; //展示的新卡支付方式数量（仅“支付工具”分组使用，包含“添加银行卡支付”）
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig *> *methodList; //该分组下的支付方式
@property (nonatomic, copy) NSString *addBankCardFoldDesc; // 添加新卡折叠/展开文案
@property (nonatomic, copy) NSArray<NSNumber *> *subPayTypeIndexList; //该分组下支付方式的index list

@end

NS_ASSUME_NONNULL_END
