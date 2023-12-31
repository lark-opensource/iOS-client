//
//  CJPayUnionBindCardPlugin.h
//  CJPayUnionBindCardPlugin
//
//  Created by 高航 on 2022/3/7.
//

#ifndef CJPayUnionBindCardPlugin_h
#define CJPayUnionBindCardPlugin_h

NS_ASSUME_NONNULL_BEGIN

@class CJPayBindCardSharedDataModel;
@protocol CJPayUnionBindCardPlugin <NSObject>


// 从收银台进入云闪付绑卡入口
- (void)bindCardWithCommonModel:(nonnull CJPayBindCardSharedDataModel *)bindCardCommonModel completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock;


// 从绑卡首页进入云闪付绑卡入口，请求云闪付绑卡下单接口，根据接口返回调起指定的页面
- (void)createUnionOrderWithBindCardModel:(nonnull CJPayBindCardSharedDataModel *)commonModel fromVC:(nonnull UIViewController *)fromVC completionBlock:(nonnull void (^)(BOOL isOpenedSuccess, UIViewController *firstVC))completionBlock;

//新用户在二要素页进行加验，目前只有活体
- (void)authAdditionalVerifyType:(NSString *)verifyType loadingStart:(void (^)(void))loadingStartBlock loadingStopBlock:(void (^)(void))loadingStopBlock;

- (void)createPromotionOrder:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayUnionBindCardPlugin_h */
