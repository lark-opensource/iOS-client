//
//  IESJSMethodManager.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/7/19.
//

#import "IESJSMethodManager.h"
#import "IESBridgeEngine.h"
#import "IESBridgeMessage.h"
#import <ByteDanceKit/ByteDanceKit.h>

// JSBridge
#define IES_JS_BRIDGE_METHOD(method) [IESJSMethod jsMethodWithBridgeName:[@"SlNCcmlkZ2U=" btd_base64DecodedString] methodName:method]

// ToutiaoJSBridge
#define IES_TOUTIAO_JS_BRIDGE_METHOD(method) [IESJSMethod jsMethodWithBridgeName:[@"VG91dGlhb0pTQnJpZGdl" btd_base64DecodedString] methodName:method]

// Native2JSBridge
#define IES_NATIVE2JS_BRIDGE_METHOD(method) [IESJSMethod jsMethodWithBridgeName:[@"TmF0aXZlMkpTQnJpZGdl" btd_base64DecodedString] methodName:method]

// JS2NativeBridge
#define IES_JS2NATIVE_BRIDGE_METHOD(method) [IESJSMethod jsMethodWithBridgeName:[@"SlMyTmF0aXZlQnJpZGdl" btd_base64DecodedString] methodName:method]

#define IES_GLOBAL_BRIDGE_METHOD(method) [IESJSMethod jsMethodWithBridgeName:@"window" methodName:method]

NSString * const IESJSMethodKeyInvokeMethod = @"IESJSMethodKeyInvokeMethod";
NSString * const IESJSMethodKeyHandleMessageFromNative = @"IESJSMethodKeyHandleMessageFromNative";
NSString * const IESJSMethodKeyFetchQueue = @"IESJSMethodKeyFetchQueue";

NSString * const IESPiperOnMethodParamsHandler = @"onMethodParams";

typedef void (^IESJSMethodEnumerationHandler)(IESJSMethod *method, BOOL defined, BOOL last, BOOL *stop);

#pragma mark - IESJSMethod

@interface IESJSMethod ()

@property (nonatomic, copy) NSString *bridgeName;
@property (nonatomic, copy) NSString *methodName;

@end

@implementation IESJSMethod

+ (instancetype)jsMethodWithBridgeName:(NSString *)bridgeName methodName:(NSString *)methodName
{
    IESJSMethod *jsMethod = [[self alloc] init];
    jsMethod.bridgeName = [bridgeName copy];
    jsMethod.methodName = [methodName copy];
    return jsMethod;
}

- (NSString *)fullName
{
    return [NSString stringWithFormat:@"%@.%@", self.bridgeName, self.methodName];
}

@end

#pragma mark - IESJSMethodManager

@interface IESJSMethodManager ()

@property (nonatomic, weak) id<IESBridgeExecutor> executor;

@end

@implementation IESJSMethodManager

static NSDictionary<NSString *, NSDictionary<IESPiperProtocolVersion, IESJSMethod *> *> *jsMethodMap(void) {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            IESJSMethodKeyInvokeMethod: @{
                    IESPiperProtocolVersion2_0: IES_GLOBAL_BRIDGE_METHOD(@"callMethodParams"),
                    IESPiperProtocolVersion3_0: IES_JS2NATIVE_BRIDGE_METHOD(@"_invokeMethod"),
            },
            IESJSMethodKeyHandleMessageFromNative: @{
                    IESPiperProtocolVersion1_0: IES_TOUTIAO_JS_BRIDGE_METHOD(@"_handleMessageFromToutiao"),
                    IESPiperProtocolVersion2_0: IES_NATIVE2JS_BRIDGE_METHOD(@"_handleMessageFromApp"),
                    IESPiperProtocolVersion3_0: IES_JS_BRIDGE_METHOD(@"_handleMessageFromApp"),
            },
            IESJSMethodKeyFetchQueue: @{
                    IESPiperProtocolVersion1_0: IES_TOUTIAO_JS_BRIDGE_METHOD(@"_fetchQueue"),
                    IESPiperProtocolVersion2_0: IES_NATIVE2JS_BRIDGE_METHOD(@"_fetchQueue"),
                    IESPiperProtocolVersion3_0: IES_JS_BRIDGE_METHOD(@"_fetchQueue"),
            },
        };
    });
    return map;
}

+ (NSString *)injectionScriptWithJSMethod:(IESJSMethod *)method messageHandler:(NSString *)messageHandler
{
    // Tricky code for supporting old JS method `window.callMethodParams`.
    NSString *format =
    [method.methodName isEqualToString:@"callMethodParams"]
    ?
    @stringify(
               try {
                    if (typeof %@ !== 'object') {
                        %@ = {};
                    }
                    %@.%@ = function(name, params) {
                        if (typeof params === 'object') {
                            %@(JSON.stringify(params));
                        }
                    };
                } catch (e) {}
               )
    :
    @stringify(
               try {
                   if (typeof %@ !== 'object') {
                       %@ = {};
                   }
                   %@.%@ = function(params) {
                       if (typeof params === 'string') {
                           %@(params);
                       }
                   };
                } catch (e) {}
               );
    return [NSString stringWithFormat:format, method.bridgeName, method.bridgeName, method.bridgeName, method.methodName, messageHandler];
}

+ (NSString *)injectionScriptWithJSMethods:(NSArray<IESJSMethod *> *)methods messageHandler:(NSString *)messageHandler
{
    NSMutableString *script = [NSMutableString string];
    [methods enumerateObjectsUsingBlock:^(IESJSMethod *obj, NSUInteger idx, BOOL *stop) {
        [script appendString:[self injectionScriptWithJSMethod:obj messageHandler:messageHandler]];
    }];
    return script;
}

+ (instancetype)managerWithBridgeExecutor:(id<IESBridgeExecutor>)bridgeExecutor
{
    IESJSMethodManager *manager = [[self alloc] init];
    manager.executor = bridgeExecutor;
    return manager;
}

- (NSDictionary<IESPiperProtocolVersion, IESJSMethod *> *)allJSMethodsForKey:(NSString *)key
{
    return jsMethodMap()[key];
}

- (NSArray<IESPiperProtocolVersion> *)allHandlerNames {
    return @[IESPiperProtocolVersion1_0, IESPiperProtocolVersion2_0, IESPiperProtocolVersion3_0];
}

- (void)queryPreferredJSMethodForKey:(NSString *)key withHandler:(IESJSMethodQueryingHandler)handler
{
    [self enumerateAllMethodsForKey:key withHandler:^(IESJSMethod *method, BOOL defined, BOOL last, BOOL *stop) {
        if (method && defined) {
            !handler ?: handler(method);
            *stop = YES;
        } else if (last) {
            !handler ?: handler(nil);
        }
    }];
}

- (void)checkAllJSMethodsDefinedForKey:(NSString *)key withHandler:(IESJSMethodCheckingHandler)handler
{
    [self enumerateAllMethodsForKey:key withHandler:^(IESJSMethod *method, BOOL defined, BOOL last, BOOL *stop) {
        !handler ?: handler(method, defined);
    }];
}

- (void)enumerateAllMethodsForKey:(NSString *)key withHandler:(IESJSMethodEnumerationHandler)handler
{
    NSDictionary<IESPiperProtocolVersion, IESJSMethod *> *methodsDic = [self allJSMethodsForKey:key];
    NSMutableArray *methods = NSMutableArray.array;
    [methodsDic enumerateKeysAndObjectsUsingBlock:^(IESPiperProtocolVersion _Nonnull key, IESJSMethod * _Nonnull obj, BOOL * _Nonnull stop) {
        [methods addObject:obj];
    }];
    void (^executeBlock)(NSUInteger);
    __block __weak typeof(executeBlock) weakExecuteBlock = executeBlock;
    weakExecuteBlock = executeBlock = ^(NSUInteger index) {
        if (index >= methods.count) {
            return;
        }
        
        IESJSMethod *method = methods[index];
        NSString *js = [NSString stringWithFormat:@"!!(window.%@ && window.%@)", method.bridgeName, method.fullName];
        __strong typeof(weakExecuteBlock) strongExecuteBlock = weakExecuteBlock;
        [self.executor ies_executeJavaScript:js completion:^(NSNumber *result, NSError *error) {
            BOOL stop = NO;
            !handler ?: handler(method, result.boolValue, index == methods.count - 1, &stop);
            if (!stop) {
                strongExecuteBlock(index + 1);
            }
        }];
    };
    
    executeBlock(0);
}

- (void)deleteAllPipers
{
    NSMutableString *js = [[NSMutableString alloc] init];
    [jsMethodMap().allValues enumerateObjectsUsingBlock:^(NSDictionary<NSNumber *, IESJSMethod *> * _Nonnull methodsDic, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *methods = NSMutableArray.array;
        [methodsDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, IESJSMethod * _Nonnull obj, BOOL * _Nonnull stop) {
            [methods addObject:obj];
        }];
        [methods enumerateObjectsUsingBlock:^(IESJSMethod *method, NSUInteger idx, BOOL *stop) {
            NSString *objectToDelete = [method.bridgeName isEqualToString:@"window"] ? method.methodName : method.bridgeName;
            [js appendFormat:@"delete %@;\n", objectToDelete];
        }];
    }];
    
    // Append the hardcoded injection in UIWebView which is intended to support old version JSSDK.
#if __has_include(<IESJSBridgeCore/UIWebView+IESBridgeExecutor.h>)
    if ([self.executor isKindOfClass:NSClassFromString(@"VUlXZWJWaWV3".btd_base64DecodedString)]) {
        [js appendFormat:@"delete %@;\n", IESPiperOnMethodParamsHandler];
    }
#endif
    
    if (js.length > 0) {
        [self.executor ies_executeJavaScript:[js copy] completion:nil];
    }
    
    // Remove all injected user scripts in WKWebView.
    if ([self.executor isKindOfClass:WKWebView.class]) {
        WKWebView *webView = (WKWebView *)self.executor;
        [webView.configuration.userContentController removeScriptMessageHandlerForName:IESPiperOnMethodParamsHandler];
        IESJSMethodManager *jsMethodManager = [IESJSMethodManager managerWithBridgeExecutor:self.executor];
        [jsMethodManager.allHandlerNames enumerateObjectsUsingBlock:^(IESPiperProtocolVersion  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [webView.configuration.userContentController removeScriptMessageHandlerForName:obj];
        }];
    }
}

@end
