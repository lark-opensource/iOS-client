//
//  BDJSBridgePluginObject.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2019/12/30.
//

#import "BDJSBridgePluginObject.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import "BDJSBridgeMessage.h"
#import "BDJSBridgeSimpleExecutor.h"
#import "BSJSBridgeProtocolV1.h"
#import "BDJSBridgeProtocolV2.h"
#import "BDJSBridgeProtocolV3.h"

@interface BDJSBridgePluginObject ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, BDJSBridgeProtocol *> *protocols;

@end

@implementation BDJSBridgePluginObject

@synthesize executorManager = _executorManager;

- (void)onLoad:(id)container {
    [self addBridgeProtocol:[[BDJSBridgeProtocolV3 alloc] initWithWebView:container]];
    [self addBridgeProtocol:[[BDJSBridgeProtocolV2 alloc] initWithWebView:container]];
    [self addBridgeProtocol:[[BSJSBridgeProtocolV1 alloc] initWithWebView:container]];
    [self.executorManager addExecutor:BDJSBridgeSimpleExecutor.new];
    self.webView = container;
}


//- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
//{
//    WKWebView *webView = message.webView;
//    if (!webView) {
//        NSParameterAssert(webView);
//        return;
//    }
//
//}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler
{
    return IWKPluginHandleResultContinue;
}

- (void)fireEvent:(NSString *)eventName status:(BDJSBridgeStatus)status params:(NSDictionary *)params resultBlock:(void (^)(NSString * _Nonnull))resultBlock {
    BDJSBridgeMessage *message = [[BDJSBridgeMessage alloc] init];
     message.messageType = BDJSBridgeMessageTypeEvent;
     message.callbackID = eventName;
     message.params = params;
     message.status = status;
    
    // 这个方法里的代码理应放在 BDJSBridgeProtocol 中，但因需用 JS 写大量代码，拆开后再组装反而会增加维护成本，因此这部分逻辑放这里维护
    __auto_type jsFormat = @stringify(
          (function(data) {
              function checkResultFailed(res) {
                  try {
                      res = JSON.parse(res);
                  } catch(e) {
                  }
                  if (res === 'no function') return true;
                  if (typeof res === 'object') {
                      if (res.__err_code === 'cb404') return true;
                      if (res.__err_code === 'ev404') return true;
                  }
                  return false;
              }
              function updateData(data) {
                  if (data.__params.__data) {
                      data.__params.data = data.__params.__data;
                      delete data.__params.__data;
                  }
              }
              var result = JSON.stringify('no function');
              var _tmpData = JSON.parse(JSON.stringify(data));
              if (window.JSBridge && window.JSBridge._handleMessageFromApp) {
                  updateData(_tmpData);
                  result = window.JSBridge._handleMessageFromApp(_tmpData);
              }
              if (checkResultFailed(result) && window.Native2JSBridge && window.Native2JSBridge._handleMessageFromApp) {
                  updateData(_tmpData);
                  result = window.Native2JSBridge._handleMessageFromApp(_tmpData);
              }
              if (checkResultFailed(result) && window.ToutiaoJSBridge && window.ToutiaoJSBridge._handleMessageFromToutiao) {
                  result = window.ToutiaoJSBridge._handleMessageFromToutiao(data);
              }
              return result;
          })(%@)
    );
    __auto_type jsString = [NSString stringWithFormat:jsFormat, message.wrappedParamsString];
    [self.webView evaluateJavaScript:jsString completionHandler:^(NSString *  _Nullable result, NSError * _Nullable error) {
        BDJSBridgeStatus status = BDJSBridgeStatusSucceed;
        if (error) {
            status = BDJSBridgeStatusUnknownError;
        }
        else {
            NSDictionary *dict = nil;
            if ([result isKindOfClass:NSString.class]) {
                if ([result containsString:@"no function"]) {
                    status = BDJSBridgeStatusUndefined;
                }
                else {
                    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
                    dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                }
            }
            else if ([result isKindOfClass:NSDictionary.class]) {
                dict = (NSDictionary *)result;
            }
            if (dict) {
                NSString *description = dict[@"__err_code"];
                  BOOL is404 = [description isEqualToString:@"cb404"] || [description isEqualToString:@"ev404"];
                  status = is404 ? BDJSBridgeStatus404 : BDJSBridgeStatusSucceed;
            }
        }
        !resultBlock ?: resultBlock(result);
    }];
}

- (void)addBridgeProtocol:(BDJSBridgeProtocol *)bridgeProtocol {
    self.protocols[NSStringFromClass(bridgeProtocol.class)] = bridgeProtocol;
}

- (void)removeAllProtocol {
    NSMutableString *js = [[NSMutableString alloc] init];
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDJSBridgeProtocol * _Nonnull protocol, BOOL * _Nonnull stop) {
        for (NSString *name in protocol.scriptMessageHandlerNames) {
           [self.webView.configuration.userContentController removeScriptMessageHandlerForName:name];
        }
        [protocol.injectedObject enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [js appendFormat:@"delete %@;\n", obj];
        }];
    }];
    if (js.length > 0) {
        [self.webView evaluateJavaScript:js.copy completionHandler:nil];
    }
    [self.protocols removeAllObjects];
}

- (BDJSBridgeExecutorManager *)executorManager {
    if (!_executorManager) {
        _executorManager = BDJSBridgeExecutorManager.new;
    }
    return _executorManager;
}

- (NSMutableDictionary<NSString *, BDJSBridgeProtocol *> *)protocols {
    if (!_protocols) {
        _protocols = NSMutableDictionary.dictionary;
    }
    return _protocols;
}

- (NSString *)uniqueID {
    return @"BDJSBridgePluginObject";
}

//#pragma - mark Override
//- (IWKPluginObjectPriority)priority {
//    return -100000;
//}

@end
