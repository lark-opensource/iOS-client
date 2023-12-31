//
//  BDTouTiaoWebViewBridgeEngine.m
//  TTBridgeUnify
//
//  Created by lizhuopeng on 2019/9/2.
//

#import "BDTouTiaoWebViewBridgeEngine.h"
#import "TTBridgeDefines.h"
#import <JavaScriptCore/JSContext.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <JavaScriptCore/JSExport.h>
#import <BDAssert/BDAssert.h>
#import <BDMonitorProtocol/BDMonitorProtocol.h>
#import "TTRexxarWebViewAdapter.h"

static NSString * kJSHandleMessageMethod = @"_handleMessageFromApp";



static void invokeJSBCallbackWithCommand(TTBridgeCommand *command,
                                         TTBridgeMsg msg,
                                         NSDictionary *response,
                                         TTWebViewBridgeEngine *engine,
                                         void (^resultBlock)(NSString *result, TTBridgeMsg resultMsg)) {
    if (!command) {
        return;
    }
    command.bridgeMsg = msg;
    command.params = response;
    command.endTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    NSString *jsonCommand = [command wrappedParamsString];
    NSString *kJSObject = [NSString stringWithFormat:@"Native2JSBr%@",@"idge"];
    NSString *invokeJS = [NSString stringWithFormat:@";window.%@ && %@.%@ && %@.%@(%@)", kJSObject, kJSObject, kJSHandleMessageMethod, kJSObject, kJSHandleMessageMethod, jsonCommand];
    tt_dispatch_async_main_thread_safe(^{
        [engine evaluateJavaScript:invokeJS completionHandler:^(id result, NSError *error) {
            NSString *resultStr = nil;
            TTBridgeMsg resultMsg = TTBridgeMsgSuccess;
            if (!result) {
                resultMsg = TTBridgeMsgCodeUndefined;
            }
            else {
                if ([result isKindOfClass:NSString.class]){
                    resultStr = result;
                    if ([resultStr containsString:@"404"]) {
                        resultMsg = TTBridgeMsgCode404;
                    }
                }
                else if ([result isKindOfClass:NSDictionary.class]){
                    NSDictionary *resultDic = result;
                    NSString *errorCode = resultDic[@"__err_code"];
                    if ([errorCode isKindOfClass:NSString.class] && [errorCode containsString:@"404"]) {
                        resultMsg = TTBridgeMsgCode404;
                    }
                    NSData * data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
                    resultStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                }
                else {
                    resultMsg = TTBridgeMsgUnknownError;
                }
            }

            if (resultBlock) {
                resultBlock(resultStr, resultMsg);
            }
        }];
    });
}

@implementation TTBridgeCommand (TTBridgeExtension)

+ (instancetype)commandWithMethod:(NSString *)method params:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [params mutableCopy];
    mutableParams[@"func"] = method;
    mutableParams[@"__msg_type"] = params[@"__msg_type"] ?: @"call";
    TTBridgeCommand *command = [[TTBridgeCommand alloc] initWithDictonary:[mutableParams copy]];
    return command;
}

@end


@interface BDTouTiaoWebViewBridgeEngine ()<WKScriptMessageHandler>

@property (nonatomic, weak) NSObject *sourceObject;

@end



@interface WKWebView ()

@property (nonatomic, strong) TTWebViewBridgeEngine *tt_engine;

@end

@implementation BDTouTiaoWebViewBridgeEngine
{
    TTBridgeRegister *_bridgeRegister;
}
@synthesize sourceObject = _sourceObject;

+ (void)_call:(TTWebViewBridgeEngine *)engine method:(NSString *)method params:(NSDictionary *)params {
    if (!engine) {
          return;
      }
      __weak typeof(engine) weakEngine = engine;
      void (^invockBlock)(void) = ^{
          TTBridgeCommand *command = [TTBridgeCommand commandWithMethod:method params:params];
          command.protocolType = TTPiperProtocolInjection;
          command.startTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
          command.bridgeType = TTBridgeTypeCall;
    
          if (![engine respondsToBridge:command.bridgeName]) {
              BOOL shouldCallbackUnregisteredCommand = [TTBridgeRegister bridgeEngine:engine shouldCallbackUnregisteredCommand:command];
              if (!shouldCallbackUnregisteredCommand) {
                  return;
              }
          }
          __auto_type completion = ^(TTBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
              if (msg != TTBridgeMsgSuccess) {
                  NSString *monitorName = [NSString stringWithFormat:@"%@%@",@"js",@"bridge_invoke_method"];
                  [BDMonitorProtocol hmdTrackService:monitorName
                                              metric:@{}
                                            category:@{@"status_code": @(msg),
                                                       @"engine_type" : @(engine.engineType),
                                                       @"version" : @"2.0",
                                                       @"method_name" : command.bridgeName ?: @""
                                            }
                                               extra:@{@"webpage_url" : engine.sourceURL.absoluteString ?: @"",}];
              }
              command.bridgeMsg = msg;
              [TTBridgeRegister bridgeEngine:engine willCallbackBridgeCommand:command];
              invokeJSBCallbackWithCommand(command, msg, response, weakEngine, ^(NSString *result, TTBridgeMsg resultMsg) {
                  if (resultMsg != TTBridgeMsgSuccess) {
                      NSString *monitorName = [NSString stringWithFormat:@"%@%@",@"js",@"bridge_callback"];
                      [BDMonitorProtocol hmdTrackService:monitorName
                                                  metric:@{}
                                                category:@{@"status_code": @(resultMsg),
                                                           @"engine_type" : @(engine.engineType),
                                                           @"version" : @"2.0",
                                                           @"method_name" : command.bridgeName ?: @""
                                                }
                                                   extra:@{@"webpage_url" : engine.sourceURL.absoluteString ?: @"",}];
                  }
                  if (resultBlock) {
                      resultBlock(result);
                  }
              });
          };
          if ([engine.bridgeRegister respondsToBridge:method]) {
              BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:engine shouldHandleLocalBridgeCommand:command];
              if (!shouldHandleBridge) {
                  return;
              }
              [engine.bridgeRegister executeCommand:command engine:engine completion:completion];
          }
          else {
              BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:engine shouldHandleGlobalBridgeCommand:command];
              if (!shouldHandleBridge) {
                  return;
              }
              [TTBridgeRegister.sharedRegister executeCommand:command engine:engine completion:completion];
          }
      };
      tt_dispatch_async_main_thread_safe(invockBlock);
}

- (void)dealloc {
    
}

- (void)installOnWKWebView:(WKWebView *)webView {
    if (webView.tt_engine) {
        BDAssert(NO, @"%@ already has a bridge engine.", webView);
        return;
    }
    BDParameterAssert(webView != nil);
    [[TTWebViewBridgeEngine webViewEngines] addObject:self];
    self.sourceObject = webView;
    webView.tt_engine = self;
    [webView.configuration.userContentController addScriptMessageHandler:self name:@"callMethodParams"];
    [webView.configuration.userContentController addScriptMessageHandler:self name:@"onMethodParams"];
}

- (void)uninstallFromWKWebView:(WKWebView *)webView {
    if (webView.tt_engine != self) {
        BDAssert(NO, @"%@ is not from %@.", self, webView);
        return;
    }
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"callMethodParams"];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"onMethodParams"];
    webView.tt_engine = nil;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *body = [message.body isKindOfClass:NSDictionary.class] ? message.body : nil;
    if (!body) {
        return;
    }
    if ([message.name isEqualToString:@"callMethodParams"]) {
        [self.class _call:self method:body[@"func"] params:body];
    } 
}


#pragma mark - TTBridgeEngine


- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    TTBridgeCommand *command = [TTBridgeCommand new];
    command.callbackID = eventName;
    command.bridgeName = eventName;
    command.messageType = @"event";
    command.bridgeType = TTBridgeTypeOn;
    command.eventID = [eventName copy];
    command.params = params;
    command.bridgeMsg = msg;

    __auto_type useNewVersion = ^(BOOL shouldRecordUndefinedAs404){
        command.params = params;
        invokeJSBCallbackWithCommand(command, msg, params, self, ^(NSString *result, TTBridgeMsg resultMsg) {
            if (resultMsg == TTBridgeMsgCodeUndefined && shouldRecordUndefinedAs404) {
                NSString *monitorName = [NSString stringWithFormat:@"%@%@_fire_event",@"jsbr",@"idge"];
                [BDMonitorProtocol hmdTrackService:monitorName
                                                   metric:@{}
                                                 category:@{@"status_code": @(TTBridgeMsgCode404),
                                                            @"engine_type" : @(self.engineType),
                                                            @"version" : @"1.0",
                                                            @"method_name" : command.bridgeName ?: @""
                                                 }
                                                    extra:@{@"webpage_url" : self.sourceURL.absoluteString ?: @"",}];
            }
            else if (resultMsg != TTBridgeMsgSuccess) {
                NSString *monitorName = [NSString stringWithFormat:@"%@%@_fire_event",@"jsbr",@"idge"];
                [BDMonitorProtocol hmdTrackService:monitorName
                          metric:@{}
                        category:@{@"status_code": @(resultMsg),
                                   @"engine_type" : @(self.engineType),
                                   @"version" : @"2.0",
                                   @"method_name" : command.bridgeName ?: @""
                        }
                           extra:@{@"webpage_url" : self.sourceURL.absoluteString ?: @"",}];
            }
            if (resultBlock) {
                resultBlock(result);
            }
        });
        
    };
    // When there is no need to use TTRexxarWebViewAdapter, use new SDK.
    if (NSClassFromString(@"TTRexxarWebViewAdapter") == nil) {
        useNewVersion(NO);
        return;
    }
    NSString *jsonCommand = [command wrappedParamsString];
    __auto_type jsFormat = @stringify(
        (function(data) {
            function checkResultFailded(res) {
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
            var result = JSON.stringify('no function');
            if (window.Toutiao%@ && window.Toutiao%@._handleMessageFromToutiao) {
                var _tmpData = JSON.parse(JSON.stringify(data)), _tmpParams = data.__params;
                if (_tmpParams.data && typeof _tmpParams.data === 'object') {
                    _tmpData.__params = _tmpParams.data;
                    _tmpData.__params.ret = _tmpParams.ret;
                }
                result = Toutiao%@._handleMessageFromToutiao(_tmpData);
            }
            if (window.Native2%@ && window.Native2%@._handleMessageFromApp) {
                result = window.Native2%@._handleMessageFromApp(data);
            }
            return result;
        })(%@)
    );
    NSString *piperName = [self decodeBase64String:@"SlNCcmlkZ2U="];
    __auto_type invokeJS = [NSString stringWithFormat:jsFormat,piperName,piperName,piperName,piperName,piperName,piperName,jsonCommand];
    [self evaluateJavaScript:invokeJS completionHandler:^(NSString * result, NSError *error) {
        TTBridgeMsg status = TTBridgeMsgSuccess;

        if (error) {
            status = TTBridgeMsgUnknownError;;
        }
        else {
            NSDictionary *dict = nil;
            if ([result isKindOfClass:NSString.class]) {
                if ([result containsString:@"no function"]) {
                    status = TTBridgeMsgCodeUndefined;
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
                  status = is404 ? TTBridgeMsgCode404 : TTBridgeMsgSuccess;
            }
        }
        if (status != TTBridgeMsgSuccess) {
            NSString *monitorName = [NSString stringWithFormat:@"%@%@_fire_event",@"js",@"bridge"];
           [BDMonitorProtocol hmdTrackService:monitorName
                                       metric:@{}
                                     category:@{@"status_code": @(status),
                                                @"version" : @"1.0",
                                                @"method_name" : command.bridgeName ?: @""
                                     }
                                        extra:@{@"webpage_url" : self.sourceURL.absoluteString ?: @"",}];
        }
        if (resultBlock) {
            resultBlock(result);
        }
    }];
}

- (NSURL *)sourceURL{
    if ([self.sourceObject isKindOfClass:[WKWebView class]]) {
        return self.wkWebView.tt_commitURL ?: self.wkWebView.URL;
    }
    return nil;
}

- (NSString *)decodeBase64String:(NSString *)base64String {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];    if (data.length > 0) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end
