//
//  IESBridgeEngine+BDWMAdapter.h
//  IESWebViewMonitor
//
//  Created by zhangxiao on 2021/7/26.
//

#import <IESJSBridgeCore/IESBridgeEngine.h>
#import "BDHMJSBErrorModel.h"

NS_ASSUME_NONNULL_BEGIN
@protocol BDHMWebViewJSBMonitorAdapterProtocol <NSObject>

- (BDHMJSBErrorModel *)bdwm_recieveFetchError:(IESBridgeEngine *)bridgeEngine handleMessage:(IESBridgeMessage *)message;

- (BDHMJSBErrorModel *)bdwm_recieveXRequestError:(IESBridgeEngine *)bridgeEngine handleMessage:(IESBridgeMessage *)message;

@end

@interface IESBridgeEngine (BDWMAdapter)

@property (nonatomic, weak, nullable) id<BDHMWebViewJSBMonitorAdapterProtocol> bdhm_jsbDelegate;


@end

NS_ASSUME_NONNULL_END
