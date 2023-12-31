//
//  BDPJSBridgeCenter.m
//  Timor
//
//  Created by 王浩宇 on 2019/8/29.
//

#import "BDPJSBridgeCenter.h"
#import "BDPJSBridgeInstancePlugin.h"
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPWeakProxy.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/NSObject+Tracing.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import <objc/runtime.h>
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/OPAPIFeatureConfig.h>
#import <OPFoundation/BDPTimorClient.h>
#import <ECOProbe/OPMonitor.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPJSBridgeUtil.h"
#import <OPFoundation/BDPAppContext.h>
#import <OPFoundation/BDPMonitorHelper.h>

#define isEmptyStr(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)

#define BDPJSBRIDGE_METHOD_LIST_CAPACITY 5

#define kH5SuccessKey  @"onSuccess"  //onSuccess、onFailed是jsbridge转换后的名称，实际开发者回调名写的是success、fail
#define kH5FailedKey   @"onFailed"
#define kH5CallbackKey   @"callback"

@interface BDPJSBridgeCenter ()

@property (nonatomic, strong) NSMapTable<NSString *, NSNumber *>               *methodSyncList;     // 插件 - 同/异步模式记录
@property (nonatomic, strong) NSMapTable<NSString *, NSNumber *>               *methodThreadList;   // 插件 - 线程模式记录
@property (nonatomic, strong) NSMapTable<NSString *, BDPJSBridgeContextMethod> *methodContextList;  // 插件 - 上下文方法(API)
@property (nonatomic, strong) NSMapTable<NSString *, BDPJSBridgeInstanceClass> *methodInstanceList; // 插件 - 类实例方法(API)
@end

@implementation BDPJSBridgeCenter

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)defaultCenter
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _methodSyncList = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableStrongMemory capacity:BDPJSBRIDGE_METHOD_LIST_CAPACITY];
        _methodThreadList = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableStrongMemory capacity:BDPJSBRIDGE_METHOD_LIST_CAPACITY];
        _methodInstanceList = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory capacity:BDPJSBRIDGE_METHOD_LIST_CAPACITY];
        _methodContextList = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableStrongMemory capacity:BDPJSBRIDGE_METHOD_LIST_CAPACITY];
    }
    return self;
}

#pragma mark - Method Mode Getter
/*-----------------------------------------------*/
//      Method Mode Getter - 方法(API)模式获取
/*-----------------------------------------------*/
+ (BOOL)obtainMethodSynchronize:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine
{
    if (!isEmptyStr(method.name)) {
        // 根据全名获取方法 API 同/异步模式
        // 优先尝试获取上下文方法
        // 💡上下文方法全名拼写规则：[方法名].[方法类型].[上下文 UniqueID]
        NSString *fullName = [NSString stringWithFormat:@"%@.%@.%@", method.name, @(engine.bridgeType), engine.uniqueID.fullString];
        NSNumber *mode = [[[self defaultCenter] methodSyncList] objectForKey:fullName];
        if ([mode isKindOfClass:[NSNumber class]]) {
            return [mode boolValue];
        }
        
        // 未获取成功则尝试获取类实例方法(获取顺序对齐 invokeMethod 调用顺序)
        // 💡类实例方法全名拼写规则：[方法名].[方法类型]
        fullName = [NSString stringWithFormat:@"%@.%@", method.name, @(engine.bridgeType)];
        mode = [[[self defaultCenter] methodSyncList] objectForKey:fullName];
        if ([mode isKindOfClass:[NSNumber class]]) {
            return [mode boolValue];
        }
    }
    return NO;
}

#pragma mark - Invoke Method
/*-----------------------------------------------*/
//          Invoke Method - 方法(API)调用
/*-----------------------------------------------*/
+ (void)invokeMethod:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(BDPJSBridgeCallback)completion
{
    // 优先尝试调用「上下文 ContextMethod」不存在时再调用「类实例方法 InstanceMethod」
    [[self defaultCenter] invokeContextMethod:method engine:engine completion:^(BDPJSBridgeCallBackType type, NSDictionary *dic) {
        if (type != BDPJSBridgeCallBackTypeNoHandler) {
            BDPLogError(@"invoke context error method=%@, engine=%@, result=%@", method.name, engine.uniqueID.fullString, @(type));
            if (completion) {
                completion(type, dic);
            }
            return;
        }
        // 调用「类实例方法 InstanceMethod」
        [[self defaultCenter] invokeInstanceMethod:method engine:engine completion:completion];
    }];
    
    [BDPJSBridgeCenter monitorDowngradeAPIWithMethod:method uniqueID:engine.uniqueID];
}

/*-----------------------------------------------*/
//          Invoke Method - 方法(API)调用
/*-----------------------------------------------*/
//+ (void)invokeMethod:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(BDPJSBridgeCallback)completion
//{
//    [BDPJSBridgeCenter invokeOriginalMethod:method
//                                     engine:engine
//                                 completion:completion];
    //如果JSAPI在开关白名单，则优先走 OPAPIManager 的新逻辑，即使调度失败也支持老逻辑的兜底
//    if([BDPRouteMediator sharedManager].isJSAPIInAllowlist&&[BDPRouteMediator sharedManager].isJSAPIInAllowlist(method.name)){
        // 尝试调用新版 API, 新版API统一了 ContextMethod 和 InstanceMethod
//        [OPAPIManager.shared invokeWithMethod:method engine:engine callback:^(OPAPICode * _Nonnull code, NSDictionary<NSString *,id> * _Nonnull data) {
//            if(BDPApiCode2CallBackType(code)!=BDPJSBridgeCallBackTypeNoHandler){
//                if (completion) {
//                    completion(BDPApiCode2CallBackType(code), data);
//                }
//            }else{
//                [BDPJSBridgeCenter invokeOriginalMethod:method
//                                                 engine:engine
//                                             completion:completion];
//            }
//        }];
//    }else{
//        [BDPJSBridgeCenter invokeOriginalMethod:method
//                                         engine:engine
//                                     completion:completion];
//    }
//}

//+(void)invokeOriginalMethod:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(BDPJSBridgeCallback)completion
//{
//    // 优先尝试调用「上下文 ContextMethod」不存在时再调用「类实例方法 InstanceMethod」
//    [[self defaultCenter] invokeContextMethod:method engine:engine completion:^(BDPJSBridgeCallBackType type, NSDictionary *dic) {
//        if (type != BDPJSBridgeCallBackTypeNoHandler) {
//            if (completion) {
//                completion(type, dic);
//            }
//            return;
//        }
//        // 调用「类实例方法 InstanceMethod」
//        [[self defaultCenter] invokeInstanceMethod:method engine:engine completion:^(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response) {
//            if (status != BDPJSBridgeCallBackTypeNoHandler) {
//                if (completion) {
//                    completion(status, response);
//                }
//                return;
//            }
//        }];
//    }];
//}

#pragma mark - Context Method
/*-----------------------------------------------*/
//         Context Method - 上下文方法(API)
/*-----------------------------------------------*/
+ (void)registerContextMethod:(NSString *)method isSynchronize:(BOOL)isSynchronize isOnMainThread:(BOOL)isOnMainThread engine:(BDPJSBridgeEngine)engine type:(BDPJSBridgeMethodType)type handler:(BDPJSBridgeContextMethod)handler
{
    if (!isEmptyStr(method) && handler) {
        // 提前获取访问内容，减少循环中内存地址的重复访问，提高效率
        NSString *uniqueIDString = engine.uniqueID.fullString;
        NSMapTable *methodSyncList = [[self defaultCenter] methodSyncList];
        NSMapTable *methodThreadList = [[self defaultCenter] methodThreadList];
        NSMapTable *methodContextList = [[self defaultCenter] methodContextList];
    
        // 预先计算出 type 中包含的方法类型，并注册该类型的方法，避免调用时循环查找，提高效率
        [self enumerateSingleType:^(BDPJSBridgeMethodType singleType) {
            if ((type & singleType) > 0) {
                // 💡上下文方法全名拼写规则：[方法名].[方法类型].[上下文 UniqueID]
                NSString *fullName = [NSString stringWithFormat:@"%@.%@.%@", method, @(singleType), uniqueIDString];
                [methodContextList setObject:handler forKey:fullName];
                [methodSyncList setObject:@(isSynchronize) forKey:fullName];
                [methodThreadList setObject:@(isOnMainThread) forKey:fullName];
            }
        }];
    }
}

+ (void)clearContextMethod:(BDPUniqueID *)uniqueID
{
    // 提前获取访问内容，减少循环中内存地址的重复访问，提高效率
    NSString *uniqueIDString = uniqueID.fullString;
    NSMapTable *methodSyncList = [[self defaultCenter] methodSyncList];
    NSMapTable *methodThreadList = [[self defaultCenter] methodThreadList];
    NSMapTable *methodContextList = [[self defaultCenter] methodContextList];
    
    // 清理上下文方法(API) - 小程序后台被彻底杀死时
    NSArray<NSString *> *keys = [[[[self defaultCenter] methodContextList] keyEnumerator] allObjects];
    for (NSString *key in keys) {
        if ([key hasSuffix:uniqueIDString]) {
            [methodSyncList removeObjectForKey:key];
            [methodThreadList removeObjectForKey:key];
            [methodContextList removeObjectForKey:key];
        }
    }
}

- (void)invokeContextMethod:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(BDPJSBridgeCallback)completion
{
    // 根据 Engine 类型拼写完整 API 调用名
    // 💡上下文方法全名拼写规则：[方法名].[方法类型].[上下文 UniqueID]
    NSString *fullName = [NSString stringWithFormat:@"%@.%@.%@", method.name, @(engine.bridgeType), engine.uniqueID.fullString];
    
    // API 未实现，则进入 NoHandler 回调，并尝试开始寻找 InstanceMethod 类实例方法
    BDPJSBridgeContextMethod handler = [self.methodContextList objectForKey:fullName];
    if (!handler) {
        if (completion) {
            completion(BDPJSBridgeCallBackTypeNoHandler, nil);
        }
        return;
    }
    
    // 权限校验
    BOOL isOnMainThread = [[self.methodThreadList objectForKey:fullName] boolValue];
    if (engine.authorization && [engine.authorization respondsToSelector:@selector(checkAuthorization:engine:completion:)]) {
        [engine.authorization checkAuthorization:method engine:engine completion:^(BDPAuthorizationPermissionResult result) {
            // 权限申请成功
            if (result == BDPAuthorizationPermissionResultEnabled) {
                if (!isOnMainThread || (isOnMainThread && [NSThread isMainThread])) {
                    handler(method.params, completion);
                } else {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        handler(method.params, completion);
                    });
                }
                return;
            }

            // 权限申请失败
            if (completion) {
                completion(BDPMatchCallBackByPermissionResult(result), nil);
            }
        }];
        return;
    }
    
    // 无权限管理器时，不允许任何 API 调用
    if (completion) {
        completion(BDPJSBridgeCallBackTypeNoAuthorization, nil);
    }
}

#pragma mark - Instance Method
/*-----------------------------------------------*/
//        Instance Method - 类实例方法(API)
/*-----------------------------------------------*/
+ (void)registerInstanceMethod:(NSString *)method isSynchronize:(BOOL)isSynchronize isOnMainThread:(BOOL)isOnMainThread class:(Class)class type:(BDPJSBridgeMethodType)type
{
    if (!isEmptyStr(method) && class) {
        // 提前获取访问内容，减少循环中内存地址的重复访问，提高效率
        NSMapTable *methodSyncList = [[self defaultCenter] methodSyncList];
        NSMapTable *methodThreadList = [[self defaultCenter] methodThreadList];
        NSMapTable *methodInstanceList = [[self defaultCenter] methodInstanceList];
        
        // 预先计算出 type 中包含的方法类型，并注册该类型的方法，避免调用时循环查找，提高效率
        [self enumerateSingleType:^(BDPJSBridgeMethodType singleType) {
            if ((type & singleType) > 0) {
                // 💡类实例方法全名拼写规则：[方法名].[方法类型]
                NSString *fullName = [NSString stringWithFormat:@"%@.%@", method, @(singleType)];
                [methodInstanceList setObject:class forKey:fullName];
                [methodSyncList setObject:@(isSynchronize) forKey:fullName];
                [methodThreadList setObject:@(isOnMainThread) forKey:fullName];
            }
        }];
    }
}

//+ (void)registerInstanceMethod:(NSString *)method isSynchronize:(BOOL)isSynchronize isOnMainThread:(BOOL)isOnMainThread class:(Class)class type:(BDPJSBridgeMethodType)type
//{
    // 尝试注册为新版 OPAPI (兼容逻辑，后续完全下掉老版本API后可改为直接注册)
//    if ([OPAPIRegistry registerInstanceMethod:method isSynchronize:isSynchronize isOnMainThread:isOnMainThread class:class type:type]) {
//        BDPLogInfo([NSString stringWithFormat:@"OPAPIRegistry registerInstanceMethod with name:%@", method]);
//    }
    
//    if (!isEmptyStr(method) && class) {
//        // 提前获取访问内容，减少循环中内存地址的重复访问，提高效率
//        NSMapTable *methodSyncList = [[self defaultCenter] methodSyncList];
//        NSMapTable *methodThreadList = [[self defaultCenter] methodThreadList];
//        NSMapTable *methodInstanceList = [[self defaultCenter] methodInstanceList];
//
//        // 预先计算出 type 中包含的方法类型，并注册该类型的方法，避免调用时循环查找，提高效率
//        [self enumerateSingleType:^(BDPJSBridgeMethodType singleType) {
//            if ((type & singleType) > 0) {
//                // 💡类实例方法全名拼写规则：[方法名].[方法类型]
//                NSString *fullName = [NSString stringWithFormat:@"%@.%@", method, @(singleType)];
//                [methodInstanceList setObject:class forKey:fullName];
//                [methodSyncList setObject:@(isSynchronize) forKey:fullName];
//                [methodThreadList setObject:@(isOnMainThread) forKey:fullName];
//            }
//        }];
//    }
//}

// 类实例方法(API) - 调用
- (void)invokeInstanceMethod:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(BDPJSBridgeCallback)completion
{
    // 根据 Engine 类型拼写完整 API 调用名
    // 💡类实例方法全名拼写规则：[方法名].[方法类型]
    NSString *fullName = [NSString stringWithFormat:@"%@.%@", method.name, @(engine.bridgeType)];
    
    // 寻找 InstanceMethod 类实例方法
    BDPJSBridgeInstanceClass class = [self.methodInstanceList objectForKey:fullName];
    if (!class) {
        BDPLogError(@"invoke instance method find no class fullname=%@, engine=%@", fullName, engine.uniqueID.fullString);
        if (completion) {
            completion(BDPJSBridgeCallBackTypeNoHandler, nil);
        }
        return;
    }
    
    // 权限校验
    BOOL isOnMainThread = [[self.methodThreadList objectForKey:fullName] boolValue];
    if (engine.authorization && [engine.authorization respondsToSelector:@selector(checkAuthorization:engine:completion:)]) {
        [engine.authorization checkAuthorization:method engine:engine completion:^(BDPAuthorizationPermissionResult result) {
            // 权限申请成功
            if (result == BDPAuthorizationPermissionResultEnabled) {
                [self invoke:method engine:engine completion:completion isOnMainThread:isOnMainThread];
                return;
            }
            
            // 权限申请失败
            if (completion) {
                completion(BDPMatchCallBackByPermissionResult(result), nil);
            }
        }];
        return;
    }
    
    // 无权限管理器时，不允许任何 API 调用
    if (completion) {
        completion(BDPJSBridgeCallBackTypeNoAuthorization, nil);
    }
}

// 类实例方法(API) - Objective-Runtime调用
- (void)invoke:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine completion:(BDPJSBridgeCallback)completion isOnMainThread:(BOOL)isOnMainThread
{
    // 尝试创建 InstanceMethod 的类实例
    BDPJSBridgeInstancePlugin *plugin = [self getInstancePlugin:method engine:engine];
    BDPJSBridgeEngine proxyEngine = (BDPJSBridgeEngine)engine.bdp_weakProxy;
    // 优先寻找universal实现
    if ([self handledByUniversalInvoke:method plugin:plugin proxyEngine:proxyEngine completion:completion isOnMainThread:isOnMainThread]) {
        return;
    }
    // 没有找到universal实现，则使用小程序专用实现
    SEL selector = NSSelectorFromString([method.name stringByAppendingString:@"WithParam:callback:engine:controller:"]);
    if (![plugin respondsToSelector:selector]) {
        // 后续不会再有其他实现了，所以这里没找到就需要回调
        BDPLogError(@"can not find old selector for app=%@, method=%@", engine.uniqueID.fullString, method.name);
        if (completion) {
            completion(BDPJSBridgeCallBackTypeNoHandler, nil);
        }
        return;
    }

    NSMethodSignature *signature = [plugin methodSignatureForSelector:selector];
    if (!signature) {
        // 后续不会再有其他实现了，所以这里没找到就需要回调
        BDPLogError(@"can not generator old selector signature for app=%@, method=%@", engine.uniqueID.fullString, method.name);
        if (completion) {
            completion(BDPJSBridgeCallBackTypeNoHandler, nil);
        }
        return;
    }

    /**
     从源头预防插件开发不规范导致engine对象被强持有, 出现内存泄漏或延迟释放
     务必放在`getInstancePlugin:engine:`之后, 避免关联对象拿不到而创建多个Plugin实例
     */
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = plugin;
    invocation.selector = selector;

    NSDictionary *params = method.params;
    UIViewController *controller = engine.bridgeController;

    [invocation setArgument:&params atIndex:2];
    [invocation setArgument:&completion atIndex:3];
    [invocation setArgument:&proxyEngine atIndex:4];
    [invocation setArgument:&controller atIndex:5];
    if (!isOnMainThread || (isOnMainThread && [NSThread isMainThread])) {
        BDPExecuteTracing(^{
            [invocation invoke];
        });
        return;
    }
    [invocation bdp_tracingPerformSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
}

/// 尝试使用universal api来处理事件，并返回是否处理
/// @param method 封装了api name 参数等信息的结构化数据
/// @param plugin 实现api的类实例
/// @param proxyEngine 派发api的engine
/// @param completion api处理完成回调
/// @param isOnMainThread 是否主线程处理
/// @return 该API是否被处理
- (BOOL)handledByUniversalInvoke:(BDPJSBridgeMethod *)method
                          plugin:(BDPJSBridgeInstancePlugin*)plugin
                     proxyEngine:(BDPJSBridgeEngine)proxyEngine
                      completion:(BDPJSBridgeCallback)completion
                  isOnMainThread:(BOOL)isOnMainThread {
    // 新版OP系列universal api, 声明为UNIVERSAL_APIHANDLER
    NSString *opSelectorStr = [method.name stringByAppendingString:@"WithParam:context:callback:"];
    SEL opSelector = NSSelectorFromString(opSelectorStr);
    // 老版BDP系列universal api, 声明为BDP_HANDLER
    NSString *bdpSelectorStr = [method.name stringByAppendingString:@"WithParam:callback:context:"];
    SEL bdpSelector = NSSelectorFromString(bdpSelectorStr);
    if (![plugin respondsToSelector:opSelector] && ![plugin respondsToSelector:bdpSelector]) {
        // plugin没有实现univeral api，只有原版小程序专用BDP_EXPORT_HANDLER，则不能被universal api进行处理
        return NO;
    }
    BDPAppContext *context = [[BDPAppContext alloc] init];
    // TODO: 此处强转类型需要适配确认
    context.controller = proxyEngine.bridgeController;
    context.engine = (id<BDPEngineProtocol>)proxyEngine;
    [self assicateEngine:proxyEngine context:context];
    // 优先寻找UNIVERSAL_APIHANDLER的实现, 如果有新实现，走新实现，否则寻找老的universal实现
    if ([self internalInvokeSelector:method selector:opSelector useOPAPI:YES context:context completion:completion isOnMainThread:isOnMainThread plugin:plugin]) {
        return YES;
    } else {
        return [self internalInvokeSelector:method selector:bdpSelector useOPAPI:NO context:context completion:completion isOnMainThread:isOnMainThread plugin:plugin];
    }
}

/// 内部动态调用universal api的真正实现
/// @param method 封装了api的参数等信息的结构
/// @param selector api对应的selector
/// @param useOPAPI 是否使用新版op系列api，由mina配置
/// @param context api调用上下文， 包含engine和controller
/// @param completion api完成回调
/// @param isOnMainThread 是否在主线程执行该api
/// @param plugin 实现该api的类实例
/// @return 是否成功派发调用
- (BOOL)internalInvokeSelector:(BDPJSBridgeMethod *)method selector:(SEL)selector useOPAPI:(BOOL)useOPAPI context:(BDPAppContext *)context completion:(BDPJSBridgeCallback)completion isOnMainThread:(BOOL)isOnMainThread plugin:(BDPJSBridgeInstancePlugin*)plugin {
    if ([plugin respondsToSelector:selector]) {
        NSMethodSignature *signature = [plugin methodSignatureForSelector:selector];
        if (!signature) {
            // 如果不能生成signature，则调用失败
            return NO;
        }
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = plugin;
        invocation.selector = selector;

        NSDictionary *params = method.params;
        [invocation setArgument:&params atIndex:2];
        if (useOPAPI) {
            [invocation setArgument:&context atIndex:3];
            [invocation setArgument:&completion atIndex:4];
        } else {
            [invocation setArgument:&completion atIndex:3];
            [invocation setArgument:&context atIndex:4];
        }
        if (!isOnMainThread || (isOnMainThread && [NSThread isMainThread])) {
            BDPExecuteTracing(^{
                [invocation invoke];
            });
            return YES;
        }
        [invocation bdp_tracingPerformSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
        return YES;
    }
    // 如果找不到方法声明，则调用失败
    return NO;
}

- (BDPJSBridgeInstancePlugin *)getInstancePlugin:(BDPJSBridgeMethod *)method engine:(BDPJSBridgeEngine)engine
{
    // 根据 Engine 类型拼写完整 API 调用名
    // 💡类实例方法全名拼写规则：[方法名].[方法类型]
    NSString *fullName = [NSString stringWithFormat:@"%@.%@", method.name, @(engine.bridgeType)];
    
    // 寻找 InstanceMethod 类实例方法
    BDPJSBridgeInstanceClass class = [self.methodInstanceList objectForKey:fullName];
    if (![class isSubclassOfClass:[BDPJSBridgeInstancePlugin class]]) {
        return nil;
    }
    
    BDPJSBridgeInstancePlugin *plugin = nil;
    BDPJSBridgePluginMode pluginType = [class pluginMode];
    
    // 插件模式 - 每次使用新实例(默认)
    if (pluginType == BDPJSBridgePluginModeNewInstance) {
        plugin = [[class alloc] init];
        
    // 插件模式 - 全局单例
    } else if (pluginType == BDPJSBridgePluginModeGlobal) {
        plugin = [class sharedPlugin];
        
    // 插件模式 - 跟随 JavaScriptEngine 生命周期
    } else {
        // 关联引用来保证同一个 JavaScriptEngine 下只有一个 plugin 实例
        NSString *className = NSStringFromClass(class);
        plugin = objc_getAssociatedObject(engine, NSSelectorFromString(className));
        if (!plugin) {
            plugin = [[class alloc] init];
            objc_setAssociatedObject(engine, NSSelectorFromString(className), plugin, OBJC_ASSOCIATION_RETAIN);
        }
    }
    
    return plugin;
}

- (void)assicateEngine:(BDPJSBridgeEngine)engine context:(BDPAppContext *)context {
    BDPAppContext *c = objc_getAssociatedObject(engine, _cmd);
    if (!c) {
        objc_setAssociatedObject(engine, _cmd, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
+ (void)enumerateSingleType:(void(^)(BDPJSBridgeMethodType singleType))block
{
    if (block) {
        block(BDPJSBridgeMethodTypeNativeApp);
        block(BDPJSBridgeMethodTypeWebApp);
        block(BDPJSBridgeMethodTypeCard);
        block(BDPJSBridgeMethodTypeBlock);
    }
}

- (BOOL)isOnMainThreadFullName:(NSString *)fullName {
    BOOL isOnMainThread = [[self.methodThreadList objectForKey:fullName] boolValue];
    return isOnMainThread;
}

- (Class)classForFullName:(NSString *)fullName {
    BDPJSBridgeInstanceClass mClass = [self.methodInstanceList objectForKey:fullName];
    return mClass;
}

+ (void)monitorDowngradeAPIWithMethod:(BDPJSBridgeMethod *)method uniqueID:(OPAppUniqueID *)uniqueID {
    OPMonitorEvent *event = BDPMonitorWithName(kEventName_op_client_api_downgrade, uniqueID);
    event.addCategoryValue(kEventKey_api_name, method.name)
         .addCategoryValue(@"param.keys", [method.params allKeys])
         .flush();
}

@end

