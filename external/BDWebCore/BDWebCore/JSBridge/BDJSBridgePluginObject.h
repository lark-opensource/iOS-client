//
//  BDJSBridgePluginObject.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2019/12/30.
//

#import "IWKPluginObject.h"
#import "BDJSBridgeProtocol.h"
#import "BDJSBridgeCoreDefines.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import "BDJSBridgeExecutorManager.h"

NS_ASSUME_NONNULL_BEGIN



@interface BDJSBridgePluginObject : IWKPluginObject<IWKInstancePlugin>

@property(nonatomic, weak) WKWebView *webView;
@property(nonatomic, strong, readonly) BDJSBridgeExecutorManager *executorManager;

- (void)fireEvent:(NSString *)eventName status:(BDJSBridgeStatus)status params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock;

- (void)addBridgeProtocol:(BDJSBridgeProtocol *)bridgeProtocol;

- (void)removeAllProtocol;

@end

NS_ASSUME_NONNULL_END
