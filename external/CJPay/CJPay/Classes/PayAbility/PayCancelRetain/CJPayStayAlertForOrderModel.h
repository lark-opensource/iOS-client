//
//  CJPayStayAlertForOrderModel.h
//  Pods
//
//  Created by bytedance on 2021/5/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayStayAlertForOrderModel : NSObject

@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *skipPwdDowngradeTradeNo;
@property (nonatomic, assign) BOOL shouldShow;
@property (nonatomic, assign) BOOL hasShow;
@property (nonatomic, copy) NSDictionary *userRetainInfo;

- (instancetype)initWithTradeNo:(NSString *)tradeNo;
- (BOOL)shouldShowWithIdentifer:(NSString *)identifer;
- (BOOL)isSkipPwdDowngradeWithTradeNo:(NSString *)tradeNo;

@end

NS_ASSUME_NONNULL_END
