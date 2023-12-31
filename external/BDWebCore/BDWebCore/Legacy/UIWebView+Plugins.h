//
//  UIWebView+Plugins.h
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#import <UIKit/UIKit.h>
#import <BDWebCore/IWKPluginObject_UIWebView.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWebView (ClassPlugin)

@property (readonly, class) NSArray<IWKPluginObject_UIWebView<IWKClassPlugin> *> *IWK_plugins;

+ (void)IWK_loadPlugin:(__kindof IWKPluginObject_UIWebView<IWKClassPlugin> *)plugin;

@end


@interface UIWebView (InstancePlugin)

@property (readonly) NSArray<IWKPluginObject_UIWebView<IWKInstancePlugin> *> *IWK_plugins;

@property (readwrite) BOOL IWK_pluginsEnable;

- (void)IWK_loadPlugin:(__kindof IWKPluginObject_UIWebView<IWKInstancePlugin> *)plugin;

- (__nullable id)IWK_triggerCustomEvent:(NSString *)event context:(NSDictionary * __nullable)context;

@end

@interface UIWebView (Plugins)

@property (readonly) NSArray<IWKPluginObject_UIWebView *> *IWK_allPlugins;

@end

NS_ASSUME_NONNULL_END
