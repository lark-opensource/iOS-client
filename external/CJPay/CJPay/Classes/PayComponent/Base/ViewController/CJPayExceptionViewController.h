//
//  CJPayExceptionViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/11/10.
//

#import "CJPayThemeBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayExceptionViewController : CJPayThemeBaseViewController

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) void(^closeblock)(void);

- (instancetype)initWithMainTitle:(nullable NSString *)mainTitle
                     subTitle:(nullable NSString *)subTitle
                  buttonTitle:(nullable NSString *)buttonTitle;


+ (void)gotoThrotterPageWithAppId:(NSString *)appId
                      merchantId:(NSString *)merchantId
                           fromVC:(UIViewController *)referVC
                      closeBlock:(void(^ _Nullable)(void))closeBlock
                          source:(NSString *)source;

@end

NS_ASSUME_NONNULL_END
