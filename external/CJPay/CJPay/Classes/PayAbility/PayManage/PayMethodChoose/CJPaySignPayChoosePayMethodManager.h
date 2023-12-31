//
//  CJPaySignPayChoosePayMethodManager.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayBDCreateOrderResponse;
@class CJPayFrontCashierContext;
@class CJPaySignPayChoosePayMethodGroupModel;

typedef NS_ENUM(NSUInteger, CJPayChannelType);

@protocol CJPaySignPayChoosePayMethodDelegate <NSObject>

// 更改选中的支付方式
- (void)changePayMethod:(CJPayFrontCashierContext *_Nonnull)payContext loadingView:(UIView *_Nullable)view;

@optional
// 展示选卡页
- (void)pushChoosePayMethodVC:(UIViewController *)vc animated:(BOOL)animated;
// 埋点
- (void)trackEvent:(NSString *_Nonnull)event params:(NSDictionary *_Nullable)params;
// 获取payContext.extParams
- (NSDictionary *)payContextExtParams;

@end

@interface CJPaySignPayChoosePayMethodManager : NSObject

@property (nonatomic, weak) id<CJPaySignPayChoosePayMethodDelegate> delegate;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;

@property (nonatomic, assign) CGFloat height; //调用方可指定选卡页高度
@property (nonatomic, assign) BOOL hasChangePayMethod; // 标识是否切换过支付方式
@property (nonatomic, assign) BOOL closeChoosePageAfterChangeMethod; //更改支付方式后是否关闭选卡页
@property (nonatomic, assign) BOOL needUpdatePayMethodList; //标识是否需要使用新的response 来更新切卡页

// 初始化方法
- (instancetype)initWithOrderResponse:(CJPayBDCreateOrderResponse *)response;

// 前往O项目唤端支付的选卡页
- (void)gotoSignPayChooseDyPayMethod;

//获取切卡页应该展示的分区以及卡片数据
- (void)getChoosePayMethodList:(nullable void(^)(NSArray<CJPaySignPayChoosePayMethodGroupModel *> *))completionBlock;

// 埋点上报
- (void)trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params;

//关闭切卡页
- (void)closeSignPayChooseDyPayMethod;

//设置优先扣款卡
+ (void)setMemberFirstPayMethod:(NSDictionary *)bizParams needLoading:(BOOL)needLoading completion:(void(^)(BOOL isSuccess))completion;

// 获取payMode
+ (NSString *)getPayMode:(CJPayChannelType)channelType;

@end

NS_ASSUME_NONNULL_END
