//
//  CJPayIAPRetainUtil.h
//  Aweme
//
//  Created by chenbocheng.moon on 2023/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayIAPType);
@class CJIAPProduct;

@interface CJPayIAPRetainUtil : NSObject

@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *merchantId;
@property (nonatomic, copy) NSString *merchantKey;
@property (nonatomic, assign) BOOL orderInProgress;
//埋点用
@property (nonatomic, assign) BOOL isRetainShown;

- (void)iapConfigWithAppid:(NSString *)appId merchantId:(NSString *)merchantId uid:(NSString *)uid;
- (BOOL)showRetainPopWithIapType:(CJPayIAPType)iapType
                           error:(NSError *)error
                      completion:(void(^)(void))completionBlock;
- (void)showLoading:(NSString *)productId;

@end

NS_ASSUME_NONNULL_END
