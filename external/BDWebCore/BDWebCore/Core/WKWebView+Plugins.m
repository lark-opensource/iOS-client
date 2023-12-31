//
//  WKWebView+Plugins.m
//  BDWebCore
//
//  Created by li keliang on 2019/6/27.
//

#import "WKWebView+Plugins.h"
#import "IWKPluginObject.h"
#import "IWKWebViewPluginHelper.h"
#import <objc/runtime.h>

@implementation WKWebView (ClassPlugin)

+ (NSTimeInterval)IWK_latestLoadPluginDate
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue] ?: 0;
}

+ (void)setIWK_latestLoadPluginDate:(NSTimeInterval)date
{
    objc_setAssociatedObject(self, @selector(IWK_latestLoadPluginDate), @(date), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSArray<IWKPluginObject *> *)IWK_plugins
{
    return objc_getAssociatedObject(self, _cmd) ?: @[];
}

+ (void)IWK_loadPlugin:(__kindof IWKPluginObject *)plugin
{
    NSParameterAssert([plugin isKindOfClass:IWKPluginObject.class]);
    
    @synchronized (self) {
        [IWKWebViewPluginHelper duplicateCheck:plugin inContainer:self.IWK_plugins];
        NSMutableArray *plugins = [NSMutableArray arrayWithArray:self.IWK_plugins];
        [plugins addObject:plugin];
        
        if ([plugin respondsToSelector:@selector(onLoad)]) {
            [plugin onLoad];
        }
        
        [self setIWK_latestLoadPluginDate:CACurrentMediaTime()];
        objc_setAssociatedObject(self, @selector(IWK_plugins), [plugins copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

+ (void)IWK_removePlugin:(__kindof IWKPluginObject *)plugin
{
    NSParameterAssert([plugin isKindOfClass:IWKPluginObject.class]);
    @synchronized (self) {
        NSMutableArray *plugins = [NSMutableArray arrayWithArray:self.IWK_plugins];
        [plugins removeObject:plugin];
        [self setIWK_latestLoadPluginDate:CACurrentMediaTime()];
        objc_setAssociatedObject(self, @selector(IWK_plugins), [plugins copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end

@implementation WKWebView (InstancePlugin)

- (NSTimeInterval)IWK_latestLoadPluginDate
{
    return [objc_getAssociatedObject(self, _cmd) doubleValue] ?: 0;
}

- (void)setIWK_latestLoadPluginDate:(NSTimeInterval)date
{
    objc_setAssociatedObject(self, @selector(IWK_latestLoadPluginDate), @(date), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<IWKPluginObject *> *)IWK_plugins
{
    return objc_getAssociatedObject(self, _cmd) ?: @[];
}

- (void)IWK_loadPlugin:(__kindof IWKPluginObject *)plugin
{
    NSParameterAssert([plugin isKindOfClass:IWKPluginObject.class]);
    @synchronized (self) {
        NSMutableArray<IWKPluginObject *> *plugins = (NSMutableArray<IWKPluginObject *> *)objc_getAssociatedObject(self, @selector(IWK_plugins));
        if (!plugins) {
            plugins = [[NSMutableArray alloc] init];
        }
        
        [IWKWebViewPluginHelper duplicateCheck:plugin inContainer:self.IWK_allPlugins];
        
        [plugins addObject:plugin];
        if ([plugin respondsToSelector:@selector(onLoad:)]) {
            [plugin onLoad:self];
        }
        
        [self setIWK_latestLoadPluginDate:CACurrentMediaTime()];
        objc_setAssociatedObject(self, @selector(IWK_plugins), plugins, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)IWK_removePlugin:(__kindof IWKPluginObject *)plugin
{
    NSParameterAssert([plugin isKindOfClass:IWKPluginObject.class]);
    @synchronized (self) {
        NSMutableArray<IWKPluginObject *> *plugins = (NSMutableArray<IWKPluginObject *> *)objc_getAssociatedObject(self, @selector(IWK_plugins));
        if (!plugins) {
            return;
        }
                
        [plugins removeObject:plugin];
        [self setIWK_latestLoadPluginDate:CACurrentMediaTime()];
        objc_setAssociatedObject(self, @selector(IWK_plugins), plugins, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)IWK_pluginsEnable
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setIWK_pluginsEnable:(BOOL)IWK_pluginsEnable
{
    objc_setAssociatedObject(self, @selector(IWK_pluginsEnable), @(IWK_pluginsEnable), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (__nullable id)IWK_triggerCustomEvent:(NSString *)event context:(NSDictionary * __nullable)context
{
    if (self.IWK_pluginsEnable) {
        IWKPluginHandleResultType result = [IWKPluginHelper runPlugins:self.IWK_allPlugins withHandleBlock:^id _Nullable(IWKPluginObject *plugin, NSDictionary *extra) {
            if (![plugin respondsToSelector:@selector(triggerCustomEvent:context:)]) {
                return IWKPluginHandleResultContinue;
            }
            return [plugin triggerCustomEvent:event context:context];
        }];
        
        if (result) {
            return result.value;
        }
    }
    return nil;
}

@end

@implementation WKWebView (Plugins)

- (NSArray<IWKPluginObject *> *)IWK_allPlugins
{
    @synchronized (self) {
        NSDictionary *pluginCacheStore = objc_getAssociatedObject(self, _cmd);
        NSTimeInterval latestUpdatePluginsDate = [pluginCacheStore[@"latestUpdatePluginsDate"] doubleValue];
        NSArray *plugins = pluginCacheStore[@"plugins"];
        
        BOOL needUpdatePlugins = NO;
        if (!latestUpdatePluginsDate || !plugins) {
            needUpdatePlugins = YES;
        } else if (latestUpdatePluginsDate < self.IWK_latestLoadPluginDate) {
            needUpdatePlugins = YES;
        } else {
            Class klass = self.class;
            do {
                if (latestUpdatePluginsDate < [klass IWK_latestLoadPluginDate]) {
                    needUpdatePlugins = YES;
                    break;
                }
            } while ((klass = class_getSuperclass(klass)) && [klass isKindOfClass:objc_getMetaClass("WKWebView")]);
        }
        
        if (needUpdatePlugins) {
            NSMutableArray *updatedPlugins = [NSMutableArray arrayWithArray:self.IWK_plugins];
            Class klass = self.class;
            do {
                [updatedPlugins addObjectsFromArray:[klass IWK_plugins]];
            } while ((klass = class_getSuperclass(klass)) && [klass isKindOfClass:objc_getMetaClass("WKWebView")]);

            [updatedPlugins sortUsingComparator:^NSComparisonResult(IWKPluginObject *obj1, IWKPluginObject *obj2) {
                return obj1.priority > obj2.priority ? NSOrderedAscending : NSOrderedDescending;
            }];
            
            plugins = updatedPlugins.copy;
            objc_setAssociatedObject(self, _cmd, @{
                @"latestUpdatePluginsDate" : @(CACurrentMediaTime()),
                @"plugins" : plugins
            }, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            return plugins;
        } else {
            return plugins;
        }
    }
}

@end
