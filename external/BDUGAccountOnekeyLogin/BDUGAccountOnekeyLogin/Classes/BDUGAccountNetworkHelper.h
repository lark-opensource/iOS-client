//
//  BDUGAccountNetworkHelper.h
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/7/29.
//

#import <Foundation/Foundation.h>
#import "BDUGAccountOneKeyDef.h"

NS_ASSUME_NONNULL_BEGIN


@interface BDUGAccountNetworkHelper : NSObject

/**
 获取当前流量卡的运营商，没有开启流量时获取的是主卡运营商
 @return 运营商类型
 */
+ (BDUGAccountCarrierType)carrierType;

/**
 获取网络类型
 @return 当前网络类型
 */
+ (BDUGAccountNetworkType)networkType;

@end

NS_ASSUME_NONNULL_END
