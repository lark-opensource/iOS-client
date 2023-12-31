//
//  CJPayChoosedPayMethodView.h
//  Pods
//
//  Created by xutianxi on 2022/11/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayDefaultChannelShowConfig;

/// 支付中更改支付方式视图
@interface CJPayChoosedPayMethodView : UIView

@property (nonatomic, assign) BOOL isCombinedPay;

@property (nonatomic, copy) void(^clickedPayMethodBlock)(void); //支付方式点击事件

- (instancetype)initIsCombinePay:(BOOL)isCombinePay;
// 根据支付方式数据更新视图
- (void)updateContentByChannelConfigs:(NSArray<CJPayDefaultChannelShowConfig *>*)configs;

@end

NS_ASSUME_NONNULL_END
