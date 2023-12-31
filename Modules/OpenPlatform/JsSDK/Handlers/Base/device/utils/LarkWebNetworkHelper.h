//
//  LarkWebNetworkHelper.h
//  LarkWeb
//
//  Created by 李论 on 2019/12/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GatewayIPInfoData: NSObject

@property (nonatomic, assign) NSInteger code;
@property (nonatomic, strong) NSString* errMsg;
@property (nonatomic, strong) NSString* routerIP;

@end

@interface LarkWebNetworkHelper : NSObject

+ (GatewayIPInfoData *)gatewayInfo;

@end

NS_ASSUME_NONNULL_END
