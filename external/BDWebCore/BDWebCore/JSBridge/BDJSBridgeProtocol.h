//
//  BDJSBridgeProtocol.h
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2019/12/30.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDJSBridgeCoreDefines.h"
#import "BDJSBridgeMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDJSBridgeProtocol : NSObject

@property(nonatomic, weak, readonly) WKWebView *webView;

@property(nonatomic, copy) NSString *jsObjectName;
@property(nonatomic, copy) NSString *callbackMethodName;
@property(nonatomic, copy, readonly) NSString *callbackFullName;
@property(nonatomic, copy) NSString *fetchQueueMethodName;
@property(nonatomic, copy, readonly) NSString *fetchQueueFullName;
@property(nonatomic, copy, readonly) NSString *scriptNeedBeInjected;
@property(nonatomic, copy, readonly) NSArray<NSString *> *injectedObject;
@property(nonatomic, strong, readonly) NSSet<NSString *> *scriptMessageHandlerNames;

- (instancetype)initWithWebView:(WKWebView *)webView NS_DESIGNATED_INITIALIZER;
- (BOOL)respondsToScriptMessageName:(NSString *)name;
- (BOOL)respondsToFetchQueueInvoke:(NSString *)jsString;
- (BOOL)respondsToCallbackInvoke:(NSString *)jsString;
- (BOOL)respondsToNavigationAction:(NSString *)actionURLString;

- (NSString *)callbackJSStringWithMessage:(BDJSBridgeMessage *)message;
- (NSDictionary *)bridgeInfoWithCallbackInvoke:(NSString *)jsString;
- (void)callbackBridgeWithMessage:(BDJSBridgeMessage *)message resultBlock:(void (^)(NSString * _Nullable))resultBlock;
- (NSMutableDictionary *)wrappedDictionaryWithMessage:(BDJSBridgeMessage *)message;
- (void)fetchQueue:(void (^)(NSArray<BDJSBridgeMessage *> * _Nullable messages))block;

@end

NS_ASSUME_NONNULL_END
