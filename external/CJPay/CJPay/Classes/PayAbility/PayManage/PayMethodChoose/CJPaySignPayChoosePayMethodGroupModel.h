//
//  CJPaySignPayChoosePayMethodGroupModel.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;

@interface CJPaySignPayChoosePayMethodGroupModel : NSObject

@property (nonatomic, copy) NSString *groupTitle; // 分组的标题
@property (nonatomic, assign) NSInteger displayNewBankCardCount; //展示的新卡支付方式数量
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig *> *subPayTypeIndexList;

@end

NS_ASSUME_NONNULL_END
