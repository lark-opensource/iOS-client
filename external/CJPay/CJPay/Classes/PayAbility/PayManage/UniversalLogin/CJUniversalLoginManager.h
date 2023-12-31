//
//  CJUniversalLoginManager.h
//  CJPay
//
//  Created by 王新华 on 10/29/19.
//

#import <Foundation/Foundation.h>
#import "CJPayNavigationController.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUniversalLoginModel.h"
#import "CJPayLoadingManager.h"

#define CJPayUniversalLoginSuccess @"CJPayUniversalLoginSuccess"
NS_ASSUME_NONNULL_BEGIN

@protocol CJUniversalLoginProviderDelegate <CJPayBaseLoadingProtocol>

@property (nonatomic, strong) UIViewController *referVC;
@property (nonatomic, assign) BOOL continueProgressWhenLoginSuccess;

- (void)loadData:(void(^ _Nullable)(CJPayUniversalLoginModel * _Nullable loginModel, BOOL isThrottle)) completion;

- (NSString *)getAppId;

- (NSString *)getMerchantId;

- (NSString *)getSourceName;

@end

typedef NS_ENUM(NSUInteger, CJUniversalLoginResultType) {
    CJUniversalLoginResultTypeFailed,
    CJUniversalLoginResultTypeSuccess,
    CJUniversalLoginResultTypeError,
    CJUniversalLoginResultTypeHasLogin,
};


@interface CJUniversalLoginManager : NSObject

@property (nonatomic, strong, readonly) CJPayNavigationController *universalLoginNavi;

+ (CJUniversalLoginManager *)bindManager:(id<CJUniversalLoginProviderDelegate>)dataDelegate;

- (void)execLogin:(void(^ _Nullable)(CJUniversalLoginResultType type, CJPayUniversalLoginModel * _Nullable loginModel))completionBlock;

- (void)cleanLoginEvent;

@end

NS_ASSUME_NONNULL_END
