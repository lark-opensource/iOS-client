//
//  CJPayOuterBridgePluginManager.h
//  CJPay
//
//  Created by liyu on 2020/1/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayOuterBridgeProtocol <NSObject>

- (void)didReceive:(NSDictionary *)data WithCallback:(void(^)(id))callback inViewController:(UIViewController *)webVC;

@end

@interface CJPayOuterBridgePluginManager : NSObject

+ (void)registerOuterBridge:(id<CJPayOuterBridgeProtocol>)bridgeInstance forMethod:(NSString *)name;

+ (nullable id<CJPayOuterBridgeProtocol>)bridgeForMethod:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
