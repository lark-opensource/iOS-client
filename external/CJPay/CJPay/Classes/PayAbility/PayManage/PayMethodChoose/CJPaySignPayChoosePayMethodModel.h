//
//  CJPaySignPayChoosePayMethodModel.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;
@interface CJPaySignPayChoosePayMethodModel : NSObject

@property (nonatomic, copy) NSString *groupTitle; // 分组的标题
@property (nonatomic, assign) NSInteger displayNewBankCardCount; //展示的新卡支付方式数量
@property (nonatomic, copy) NSArray<CJPayDefaultChannelShowConfig *> *methodList; //该分组下的支付方式

@end

NS_ASSUME_NONNULL_END
