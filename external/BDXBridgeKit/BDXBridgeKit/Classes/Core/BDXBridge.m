//
//  BDXBridge.m
//  BDXBridge
//
//  Created by Lizhen Hu on 2020/5/28.
//

#import "BDXBridge+Internal.h"
#import "BDXBridgeMethod.h"
#import "BDXBridgeEvent.h"
#import "BDXBridgeContext.h"
#import "BDXBridgeDefinitions.h"
#import "BDXBridgeInvocationGuarder.h"
#import "BDXBridgeEngineProtocol.h"
#import "BDXBridgeContainerProtocol.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridgeModel.h"
#import "BDXBridgeEventCenter.h"
#import <BDAssert/BDAssert.h>
#include <dlfcn.h>
#include <mach-o/getsect.h>
#include <mach-o/dyld.h>
#include <crt_externs.h>

//extern const struct mach_header *_NSGetMachExecuteHeader(void);

static Class<BDXBridgeEngineProtocol> s_engineClass;
static BOOL s_isDevelopmentMode;

@interface BDXBridge ()

@property (class, nonatomic, strong, readonly) Class<BDXBridgeEngineProtocol> engineClass;
@property (class, nonatomic, assign, readonly) BOOL isDevelopmentMode;
@property (class, nonatomic, strong, readonly) NSArray<NSString *> *standardBridgeMethodNames;
@property (class, nonatomic, strong, readonly) NSMutableDictionary<NSString *, BDXBridgeMethod *> *globalMethods;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, BDXBridgeMethod *> *localMethods;

@end

@implementation BDXBridge

+ (void)registerEngineClass:(Class<BDXBridgeEngineProtocol>)engineClass inDevelopmentMode:(BOOL)inDevelopmentMode
{
    Protocol *engineProtocol = @protocol(BDXBridgeEngineProtocol);
    BDAssert([engineClass conformsToProtocol:engineProtocol], @"The passed in class should conform to protocol '%@'.", NSStringFromProtocol(engineProtocol));
    BDAssert(!s_engineClass, @"The engine class implementing protocol '%@' has been set already.", NSStringFromProtocol(engineProtocol));
    s_engineClass = engineClass;
    s_isDevelopmentMode = inDevelopmentMode;
    
    registerGlobalMethods(BDX_BRIDGE_INTERNAL_METHODS_SECTION, nil);
    registerGlobalMethods(BDX_BRIDGE_EXTERNAL_METHODS_SECTION, nil);
    
    //add observer for capturing screen notification
    if (@available(iOS 11.0 , *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenCapturedDidChange:) name:UIScreenCapturedDidChangeNotification object:nil];
    }
}

+ (void)registerDefaultGlobalMethodsWithFilter:(BDXBridgeMethodFilter)filter
{
    registerGlobalMethods(BDX_BRIDGE_DEFAULT_METHODS_SECTION, filter);
}

+ (Class<BDXBridgeEngineProtocol>)engineClass
{
    BDAssert(s_engineClass, @"The engine class implementing protocol '%@' hasn't been set yet.", NSStringFromProtocol(@protocol(BDXBridgeEngineProtocol)));
    return s_engineClass;
}

+ (BOOL)isDevelopmentMode
{
    return s_isDevelopmentMode;
}

- (instancetype)initWithContainer:(id<BDXBridgeContainerProtocol>)container
{
    self = [super init];
    if (self) {
        _engine = [[(Class)self.class.engineClass alloc] initWithContainer:container];
        _localMethods = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (NSMutableDictionary<NSString *, BDXBridgeMethod *> *)globalMethods
{
    static NSMutableDictionary *methods = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        methods = [NSMutableDictionary dictionary];
    });
    return methods;
}

+ (NSArray<NSString *> *)standardBridgeMethodNames
{
    static NSArray<NSString *> *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[
            @"x.chooseMedia",
            @"x.getAPIParams",
            @"x.getAppInfo",
            @"x.getSettings",
            @"x.getUserInfo",
            @"x.showLoading",
            @"x.hideLoading",
            @"x.login",
            @"x.logout",
            @"x.open",
            @"x.close",
            @"x.reportALog",
            @"x.reportADLog",
            @"x.reportAppLog",
            @"x.reportMonitorLog",
            @"x.request",
            @"x.scanCode",
            @"x.showModal",
            @"x.showToast",
            @"x.downloadFile",
            @"x.uploadImage",
            @"x.previewImages",
            @"x.share",
            @"x.bindPhone",
            @"x.sendSMS",
            @"x.makePhoneCall",
            @"x.checkPermission",
            @"x.getStorageInfo",
            @"x.getStorageItem",
            @"x.setStorageItem",
            @"x.removeStorageItem",
            @"x.getContainerID",
            @"x.getDebugInfo",
            @"x.getMethodList",
            @"x.canIUse",
            @"x.subscribeEvent",
            @"x.unsubscribeEvent",
            @"x.publishEvent",
            @"x.vibrate",
            @"x.connectSocket",
            @"x.closeSocket",
            @"x.sendSocketData",
            @"x.setCalendarEvent",
            @"x.getCalendarEvent",
            @"x.removeCalendarEvent",
            @"x.createCalendarEvent",
            @"x.readCalendarEvent",
            @"x.deleteCalendarEvent",
            @"x.configureStatusBar",
            @"x.showActionSheet",
            @"x.getCaptureScreenStatus",

            // Some non-standard methods sneak in, just put a placeholder here to make up for that stupid mistake.
            @"x.openPDF",
            @"x.openPanel",
            @"x.uploadSensitiveImage",
        ];
    });
    return names;
}

+ (void)registerGlobalMethod:(BDXBridgeMethod *)method
{
    NSString *methodName = method.methodName;
    BDAssert(methodName.length > 0, @"The local method name should not be empty.");

    // Only register development method in development mode.
    if (!self.isDevelopmentMode && method.isDevelopmentMethod) {
        return;
    }
    
    if ([methodName hasPrefix:@"x."]) {
        BDAssert([self.standardBridgeMethodNames containsObject:methodName], @"Only standard method names are supposed to have prefix 'x.', but global method named '%@' isn't a standard one.", methodName);
    }

    BDAssert(!self.globalMethods[method.methodName], @"The global method named '%@' has been registered already.", method.methodName);
    self.globalMethods[methodName] = method;
    
    BDXBridgeEngineCallHandler callHandler = [self wrappedCallHandlerWithMethod:method];
    [self.engineClass registerGlobalMethodWithMethodName:methodName authType:method.authType engineTypes:method.engineTypes callHandler:callHandler];
    
    bdx_alog_info(@"Register global method named '%@' of class '%@'.", methodName, NSStringFromClass(method.class));
}

+ (void)deregisterGlobalMethodNamed:(NSString *)methodName
{
    if (methodName.length == 0) {
        return;
    }
    
    self.globalMethods[methodName] = nil;
    [self.engineClass deregisterGlobalMethodWithMethodName:methodName];
    
    bdx_alog_info(@"Deregister global method named '%@'.", methodName);
}

- (void)registerLocalMethod:(BDXBridgeMethod *)method
{
    NSString *methodName = method.methodName;
    BDAssert(methodName.length > 0, @"The local method name should not be empty.");
    
    // Only register development method in development mode.
    if (!self.class.isDevelopmentMode && method.isDevelopmentMethod) {
        return;
    }
    
    if ([methodName hasPrefix:@"x."]) {
        BDAssert([self.class.standardBridgeMethodNames containsObject:methodName], @"Only standard local method names are supposed to have prefix 'x.', but local method named '%@' isn't a standard one.", methodName);
    }

    self.localMethods[methodName] = method;

    BDXBridgeEngineCallHandler callHandler = [self.class wrappedCallHandlerWithMethod:method];
    [self.engine registerLocalMethodWithMethodName:methodName authType:method.authType engineTypes:method.engineTypes callHandler:callHandler];

    bdx_alog_info(@"Register local method named '%@' of class '%@'.", methodName, NSStringFromClass(method.class));
}

- (void)deregisterLocalMethodNamed:(NSString *)methodName
{
    if (methodName.length == 0) {
        return;
    }

    self.localMethods[methodName] = nil;
    [self.engine deregisterLocalMethodWithMethodName:methodName];

    bdx_alog_info(@"Deregister local method named '%@'.", methodName);
}

- (void)fireEvent:(BDXBridgeEvent *)event
{
    BDAssert(event.eventName.length > 0, @"The event name should not be nil.");
    bdx_alog_info(@"Fire event: %@.", event);
    [self.engine fireEventWithEventName:event.eventName params:event.params];
}

+ (NSDictionary<NSString *,BDXBridgeMethod *> *)registeredGlobalMethods
{
    return [self.globalMethods copy];
}

- (NSDictionary<NSString *,BDXBridgeMethod *> *)registeredLocalMethods
{
    return [self.localMethods copy];
}

- (NSDictionary<NSString *, BDXBridgeMethod *> *)mergedMethodsForEngineType:(BDXBridgeEngineType)engineType
{
    // The global methods will be overridden by the local ones.
    NSMutableDictionary<NSString *, BDXBridgeMethod *> *methods = [NSMutableDictionary dictionary];
    __auto_type enumerateBlock = ^(NSString *key, BDXBridgeMethod *obj, BOOL *stop) {
        if (obj.engineTypes & engineType) {
            methods[key] = obj;
        }
    };
    [self.class.globalMethods enumerateKeysAndObjectsUsingBlock:enumerateBlock];
    [self.localMethods enumerateKeysAndObjectsUsingBlock:enumerateBlock];
    return [methods copy];
}

+ (void)screenCapturedDidChange:(NSNotification *)noti
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if ([noti.object isKindOfClass:UIScreen.class]) {
        UIScreen *screen = noti.object;
        [params setValue:@(screen.isCaptured) forKey:@"capturing"];
    }
    
    BDXBridgeEvent *event = [BDXBridgeEvent eventWithEventName:@"x.captureScreenStatus" params:params];
    [BDXBridgeEventCenter.sharedCenter publishEvent:event];
}

#pragma mark - Helpers

+ (BDXBridgeEngineCallHandler)wrappedCallHandlerWithMethod:(BDXBridgeMethod *)method
{
    return ^(id<BDXBridgeContainerProtocol> container, NSDictionary *params, BDXBridgeEngineCompletionHandler completionHandler) {
        // Using the invocation guarder to ensure the completion handler is explicitly invoked.
        NSString *message = [NSString stringWithFormat:@"The completion handler for '%@' should be invoked once and only once.", method.methodName];
        BDXBridgeInvocationGuarder *invocationGuarder = [[BDXBridgeInvocationGuarder alloc] initWithMessage:message];
        BDXBridgeMethodCompletionHandler wrappedCompletionHandler = ^(BDXBridgeModel *resultModel, BDXBridgeStatus *status) {
            [invocationGuarder invoke];

            // Transform model to json.
            BDXBridgeStatusCode statusCode = status ? status.statusCode : BDXBridgeStatusCodeSucceeded;
            NSString *message = status.message;
            NSDictionary *result = nil;
            if (resultModel) {
                BDAssert([resultModel isKindOfClass:method.resultModelClass], @"The result model should be kind of class '%@', instead of '%@'.", method.resultModelClass, resultModel.class);
                NSError *error = nil;
                result = [MTLJSONAdapter JSONDictionaryFromModel:resultModel error:&error];
                BDAssert(!error, @"Failed to parse result model: %@.", error.localizedDescription);
                if (error && !status) {
                    statusCode = BDXBridgeStatusCodeInvalidResult;
                    message = error.localizedDescription;
                }
            }
            
            result = ({
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:result];
                if ([resultModel.extraInfo isKindOfClass:NSDictionary.class]) {  // Add extra info.
                    [dict addEntriesFromDictionary:resultModel.extraInfo];
                }
                dict[@"__status_message__"] = status.message;   // Add status message.
                [dict copy];
            });
            
            bdx_alog_info(@"Complete bridge method named '%@' with status [%@: %@] and result [%@].", method.methodName, @(statusCode), message, resultModel);
            bdx_invoke_block(completionHandler, statusCode, result, message);
        };
        
        BDXBridgeModel *paramModel = nil;
        if (method.paramModelClass) {
            NSError *error = nil;
            paramModel = [MTLJSONAdapter modelOfClass:method.paramModelClass fromJSONDictionary:params error:&error];
            if (error) {
                bdx_invoke_block(wrappedCompletionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidParameter message:error.localizedDescription]);
                return;
            }
        }
        
        bdx_alog_info(@"Call bridge method named '%@' with parameters [%@]", method.methodName, paramModel);
        [method.context setWeakObject:container forKey:BDXBridgeContextContainerKey];
        paramModel.bridgeContext = method.context;
        [method callWithParamModel:paramModel completionHandler:wrappedCompletionHandler];
    };
}

static void enumerateSectionDataStrings(const char *section, void(^handler)(NSString *string)) __attribute__((no_sanitize("address")))
{
#ifndef __LP64__
    const struct mach_header *mhp = (struct mach_header *)_NSGetMachExecuteHeader();
#else
    const struct mach_header_64 *mhp = (struct mach_header_64 *)_NSGetMachExecuteHeader();
#endif
    unsigned long size = 0;
    char **memory = (char **)getsectiondata(mhp, BDX_BRIDGE_SEGMENT, section, &size);
    for (int i = 0; i < size/sizeof(char **); ++i) {
        char *string = memory[i];
#if __has_feature(address_sanitizer)
        if (string == NULL) {
            continue;
        }
#endif
        bdx_invoke_block(handler, [NSString stringWithUTF8String:string]);
    }
}

static void registerGlobalMethods(const char *section, BDXBridgeMethodFilter filter)
{
    enumerateSectionDataStrings(section, ^(NSString *string) {
        Class methodClass = NSClassFromString(string);
        if (methodClass) {
            BDXBridgeMethod *method = [methodClass new];
            BOOL shouldRegister = YES;
            if (filter) {
                shouldRegister = filter(method);
            }
            if (shouldRegister) {
                [BDXBridge registerGlobalMethod:method];
            }
        }
    });
}

@end
