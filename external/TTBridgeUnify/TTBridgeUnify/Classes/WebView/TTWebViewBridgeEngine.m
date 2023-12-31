//
//  TTWebViewBridgeEngine.m
//  NewsInHouse
//
//  Created by lizhuopeng on 2018/10/23.
//

#import "TTWebViewBridgeEngine.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <BDAssert/BDAssert.h>
#import "TTBridgeAuthManager.h"
#import "TTBridgeUnify_internal.h"

void TTWebViewBridgeEngineSwapInstanceMethods(Class cls, SEL original, SEL replacement)
{
    Method originalMethod = class_getInstanceMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);
    
    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);
    
    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}




@interface WKWebView ()

@property (nonatomic, strong) TTWebViewBridgeEngine *tt_engine;

@end

@implementation WKWebView (TTBridge)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TTWebViewBridgeEngineSwapInstanceMethods(WKWebView.class, NSSelectorFromString(@"dealloc"), @selector(wkbridgeengine_dealloc));
    });
}

- (void)wkbridgeengine_dealloc {
    [self tt_uninstallBridgeEngine];
    [self wkbridgeengine_dealloc];
}

- (void)tt_installBridgeEngine:(TTWebViewBridgeEngine *)bridge {
    [bridge installOnWKWebView:self];
}

- (void)tt_uninstallBridgeEngine {
    [self.tt_engine uninstallFromWKWebView:self];
}

- (void)setTt_engine:(TTWebViewBridgeEngine *)tt_engine {
    objc_setAssociatedObject(self, @selector(tt_engine), tt_engine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (TTWebViewBridgeEngine *)tt_engine {
    return objc_getAssociatedObject(self, @selector(tt_engine));
}

@end

static NSHashTable* kWebViewEngines = nil;

@interface TTWebViewBridgeEngine ()

@property(nonatomic, strong) TTBridgeRegister *bridgeRegister;

@end

@implementation TTWebViewBridgeEngine

- (instancetype)init {
    return [self initWithAuthorization:TTBridgeAuthManager.sharedManager];
}

- (instancetype)initWithAuthorization:(id<TTBridgeAuthorization>)authorization {
    self = [super init];
    if (self) {
        [TTBridgeRegister _doRegisterIfNeeded];
        [TTBridgeForwarding.sharedInstance _installAssociatedPluginsOnEngine:self];
        _authorization = authorization;
        _schemaInterceptionEnabled = YES;
    }
    return self;
}

- (void)dealloc {
    
}

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params {
    [self fireEvent:bridgeName params:params];
}

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:bridgeName msg:TTBridgeMsgSuccess params:params resultBlock:resultBlock];
}

- (void)callbackBridge:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:bridgeName msg:msg params:params resultBlock:resultBlock];
}

- (TTBridgeRegisterEngineType)engineType {
    return TTBridgeRegisterWebView;
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id result, NSError *error))completionHandler {
    if (![NSThread isMainThread]) {
        BDAssert(NO, @"Must evaluate JS in main thread.");
        return;
    }
    if ([self.sourceObject isKindOfClass:[WKWebView class]]) {
        [self.wkWebView evaluateJavaScript:javaScriptString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (completionHandler) {
                completionHandler(result, nil);
            }
        }];
    }
}

- (void)fireEvent:(TTBridgeName)eventName params:(NSDictionary *)params {
    [self fireEvent:eventName params:params resultBlock:nil];
}

- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params {
    [self fireEvent:eventName msg:msg params:params resultBlock:nil];
}

- (void)fireEvent:(TTBridgeName)eventName params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:eventName msg:TTBridgeMsgSuccess params:params resultBlock:resultBlock];
}

- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [NSException raise:NSGenericException format:@"Please use subclass instance to call this method!"];
}

+ (void)postEventNotification:(TTBridgeName)bridgeName params:(NSDictionary *)params {
    [self postEventNotification:bridgeName msg:TTBridgeMsgSuccess params:params resultBlock:nil];
}

+ (void)postEventNotification:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    for (TTWebViewBridgeEngine* engine in kWebViewEngines) {
        [engine fireEvent:bridgeName msg:msg params:params resultBlock:resultBlock];
    }
}

- (WKWebView *)wkWebView {
    return [self.sourceObject isKindOfClass:[WKWebView class]] ? (WKWebView *)self.sourceObject : nil;
}

- (void)installOnWKWebView:(WKWebView *)webView {
    [NSException raise:NSGenericException format:@"Please use subclass instance to call this method!"];
}

- (void)uninstallFromWKWebView:(WKWebView *)webView {
    [NSException raise:NSGenericException format:@"Please use subclass instance to call this method!"];
}

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName {
    return [self.bridgeRegister respondsToBridge:bridgeName] ?: [TTBridgeRegister.sharedRegister respondsToBridge:bridgeName];
}

- (TTBridgeRegister *)bridgeRegister {
    if (!_bridgeRegister) {
        _bridgeRegister = TTBridgeRegister.new;
        _bridgeRegister.engine = self;
    }
    return _bridgeRegister;
}

- (NSURL *)sourceURL {
    BDAssert(NO, @"Don't use TTWebViewBridgeEngine instance call this method! Please use subclass instance.");
    if ([self.sourceObject isKindOfClass:[WKWebView class]]) {
        return self.wkWebView.URL;
    }
    return nil;
}

- (UIViewController *)sourceController {
    return [self.class correctTopViewControllerFor:(UIView *)self.sourceObject];
}

+ (UIViewController*)correctTopViewControllerFor:(UIResponder*)responder
{
    UIResponder *topResponder = responder;
    for (; topResponder; topResponder = [topResponder nextResponder]) {
        if ([topResponder isKindOfClass:[UIViewController class]]) {
            UIViewController *viewController = (UIViewController *)topResponder;
            while (viewController.parentViewController && viewController.parentViewController != viewController.navigationController && viewController.parentViewController != viewController.tabBarController) {
                viewController = viewController.parentViewController;
            }
            return viewController;
        }
    }
    if(!topResponder && [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)])
    {
        topResponder = [[[UIApplication sharedApplication] delegate].window rootViewController];
    }
    
    return (UIViewController*)topResponder;
}

+ (NSHashTable *)webViewEngines {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kWebViewEngines = [NSHashTable weakObjectsHashTable];
    });
    return kWebViewEngines;
}

@end
