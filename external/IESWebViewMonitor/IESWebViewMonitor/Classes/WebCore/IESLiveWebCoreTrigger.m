//
//  IESLiveWebCoreTrigger.m
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2020/1/10.
//

#import "IESLiveWebCoreTrigger.h"
#import "IESLiveWKWebCoreTrigger.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import <objc/runtime.h>

@implementation IESLiveWebCoreTrigger

+ (void)startMonitorWithClasses:(NSSet *)classes setting:(NSDictionary *)setting {
    for (Class cls in classes) {
        if ([cls isKindOfClass:object_getClass([WKWebView class])]) {
            __kindof IWKPluginObject *tigger = [IESLiveWKWebCoreTrigger new];
            objc_setAssociatedObject(tigger, pluginWKAssociatedKey, cls, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [(WKWebView *)cls IWK_loadPlugin:tigger];
        }
    };
}

@end
