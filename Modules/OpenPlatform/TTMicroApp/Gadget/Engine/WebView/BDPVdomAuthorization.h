//
//  BDPVdomAuthorization.h
//  Timor
//
//  Created by MacPu on 2019/12/9.
//

#import <Foundation/Foundation.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>

NS_ASSUME_NONNULL_BEGIN

/// 因为vdom是最提前加载了，所以这个时候没有BDPAuthorization。
/// 需要先临时创建一个auth，当有model之后在替换成common的auth
@interface BDPVdomAuthorization : NSObject <BDPJSBridgeAuthorizationProtocol>

@end

NS_ASSUME_NONNULL_END
