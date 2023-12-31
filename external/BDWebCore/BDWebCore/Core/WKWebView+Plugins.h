//
//  WKWebView+Plugins.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/27.
//

#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

@class IWKPluginObject;

@interface WKWebView (ClassPlugin)

@property (nonatomic, readonly, class) NSArray<IWKPluginObject<IWKClassPlugin> *> *IWK_plugins;

+ (void)IWK_loadPlugin:(__kindof IWKPluginObject<IWKClassPlugin> *)plugin;

@end

@interface WKWebView (InstancePlugin)

@property (readonly) NSArray<IWKPluginObject<IWKInstancePlugin> *> *IWK_plugins;

@property (readwrite) BOOL IWK_pluginsEnable;

- (void)IWK_loadPlugin:(__kindof IWKPluginObject<IWKInstancePlugin> *)plugin;
- (void)IWK_removePlugin:(__kindof IWKPluginObject<IWKInstancePlugin> *)plugin;

- (__nullable id)IWK_triggerCustomEvent:(NSString *)event context:(NSDictionary * __nullable)context;

@end

@interface WKWebView (Plugins)

@property (readonly) NSArray<IWKPluginObject *> *IWK_allPlugins;

@end

NS_ASSUME_NONNULL_END
