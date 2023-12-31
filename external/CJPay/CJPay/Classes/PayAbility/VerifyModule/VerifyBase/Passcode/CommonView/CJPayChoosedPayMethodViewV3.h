//
//  CJPayChoosedPayMethodViewV3.h
//  Pods
//
//  Created by xutianxi on 2023/03/01.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayDefaultChannelShowConfig;
@class CJPayOutDisplayInfoModel;

/// 支付中更改支付方式视图
@interface CJPayChoosedPayMethodViewV3 : UIView

@property (nonatomic, assign) BOOL canChangeCombineStatus; //是否可修改组合支付状态（O项目可修改，六位密码暂不支持）
@property (nonatomic, strong) CJPayOutDisplayInfoModel *outDisplayInfoModel;

@property (nonatomic, copy) void(^clickedPayMethodBlock)(void); //支付方式点击事件
@property (nonatomic, copy) void(^clickedCombineBankPayMethodBlock)(void); //组合支付切换银行卡点击事件

@property (nonatomic, strong, readonly) UIView *normalPayClickView; // “普通支付方式”按钮点击热区
@property (nonatomic, strong, readonly) UIView *combinePayClickView; //“组合支付方式”按钮点击热区

- (instancetype)initIsCombinePay:(BOOL)isCombinePay;
// 根据支付方式数据更新视图
- (void)updateContentByChannelConfigs:(NSArray<CJPayDefaultChannelShowConfig *>*)configs;
//修改 支付title
- (void)updatePayTypeTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
