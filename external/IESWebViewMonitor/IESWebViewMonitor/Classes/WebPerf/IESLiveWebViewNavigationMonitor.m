//
//  IESLiveWebViewNavigationMonitor.m
//  IESWebViewMonitor
//
//  Created by renpengcheng on 2019/8/11.
//

#import "IESLiveWebViewNavigationMonitor.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "BDWebViewDelegateRegister.h"
#import <objc/runtime.h>
#import "BDHybridMonitorDefines.h"

@implementation IESLiveWebViewNavigationMonitor

static NSMutableSet *monitoredClass = nil;
+ (BOOL)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting {
    BOOL navigationMonitor = [setting[kBDWMNavigationMonitor] boolValue];
    BOOL onlyMonitorNavigationFinish = [setting[kBDWMOnlyMonitorNavigationFinish] boolValue];
    if (!navigationMonitor) {
        return NO;
    }

    if ([setting[kBDWMWebCoreMonitor] boolValue]) { // webCore 开关控制
        Class pWebCoreTriggerClass = NSClassFromString(@"IESLiveWebCoreTrigger");
        SEL pWebCoreTriggerSel = NSSelectorFromString(@"startMonitorWithClasses:setting:");
        if ([pWebCoreTriggerClass respondsToSelector:pWebCoreTriggerSel]) { // 有 webCore
            Method pWebCoreTriggerMethod = class_getClassMethod(pWebCoreTriggerClass, pWebCoreTriggerSel);
            IMP pWebCoreTriggerImp = method_getImplementation(pWebCoreTriggerMethod);
            ((void(*)(Class, SEL, id, id))pWebCoreTriggerImp)(pWebCoreTriggerClass, pWebCoreTriggerSel, classes, setting);
        }
    } else {
        [BDWebViewDelegateRegister startMonitorWithClasses:classes onlyMonitorNavigationFinish:onlyMonitorNavigationFinish];
    }
    return YES;
}

@end
