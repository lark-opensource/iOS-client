//
//  CJPaySubPayTypeGroupInfo.h
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/21.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
// 验密页进入选卡页所需额外数据
@interface CJPaySubPayTypeGroupInfo : JSONModel

@property (nonatomic, copy) NSString *groupType; //分组类型，类型的枚举有：“payment_tool”,代表“支付工具”；“finance_channel”，代表“资金渠道”
@property (nonatomic, copy) NSString *groupTitle; //分组标题，例如“支付工具”、“资金渠道”
@property (nonatomic, copy) NSString *creditPayDesc; //月付的描述文案
@property (nonatomic, assign) NSInteger displayNewBankCardCount; //展示的新卡数量（不包含“添加银行卡支付”）
@property (nonatomic, copy) NSString *addBankCardFoldDesc; // 添加新卡折叠、展开文案
@property (nonatomic, copy) NSArray<NSNumber *> *subPayTypeIndexList; //该分组下支付方式的index list

@end

NS_ASSUME_NONNULL_END
