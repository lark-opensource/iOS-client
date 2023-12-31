//
//  CJPayNativeBindCardPlugin.h
//  Aweme
//
//  Created by 陈博成 on 2023/5/6.
//

#ifndef CJPayNativeBindCardPlugin_h
#define CJPayNativeBindCardPlugin_h

NS_ASSUME_NONNULL_BEGIN

typedef void (^BDPayBindCardCompletion)(CJPayBindCardResult type, NSString *errorMsg);

@class CJPayBindCardSharedDataModel;
@class CJPayCreateOneKeySignOrderResponse;

@protocol CJPayNativeBindCardPlugin <NSObject>

- (void)bindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel;
- (void)startOneKeySignOrderFromVC:(UIViewController *)fromVC
                    signOrderModel:(NSDictionary *)model
                         extParams:(NSDictionary *)extDict
         createSignOrderCompletion:(void (^)(CJPayCreateOneKeySignOrderResponse *))createSignOrderCompletion
                        completion:(void (^)(BOOL))completion;
- (void)queryOneKeySignState;

- (void)bindCardHomePageFromJsbWithParam:(NSDictionary *)param;

- (void)quickBindCardFromJsbWithParam:(NSDictionary *)param;
//独立绑卡
- (void)onlyBindCardWithCommonModel:(CJPayBindCardSharedDataModel *)commonModel params:(NSDictionary *)params completion:(BDPayBindCardCompletion)completion stopLoadingBlock:(void(^)(void))stopLoadingBlock;

@end

NS_ASSUME_NONNULL_END
#endif
