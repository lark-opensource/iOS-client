//
//  BDLynxBridge+BDLMAdapter.h
//  IESWebViewMonitor
//
//  Created by zhangxiao on 2021/7/26.
//

#import <Lynx/BDLynxBridge.h>
#import "BDHMJSBErrorModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDHMLynxJSBMonitorAdapterProtocol <NSObject>

- (BDHMJSBErrorModel *)bdlm_recieveFetchError:(BDLynxBridge *)lynxBridge willCallback:(BDLynxBridgeSendMessage *)message;

- (BDHMJSBErrorModel *)bdlm_recieveXRequestError:(BDLynxBridge *)lynxBridge willCallback:(BDLynxBridgeSendMessage *)message;

@end

@interface BDLynxBridge (BDLMAdapter)

@property (nonatomic, weak, nullable) id<BDHMLynxJSBMonitorAdapterProtocol> bdhm_jsbDelegate;

@end

NS_ASSUME_NONNULL_END
