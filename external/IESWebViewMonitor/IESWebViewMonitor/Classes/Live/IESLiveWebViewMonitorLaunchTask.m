//
//  IESLiveWebViewMonitorLaunchTask.m
//
//  Created by renpengcheng on 2019/5/13.
//  Copyright © 2019 renpengcheng. All rights reserved.
//

#import "IESLiveWebViewMonitorLaunchTask.h"
#import "IESLiveWebViewMonitor+Private.h"
#import "IESLiveWebViewMonitor.h"
#import <objc/runtime.h>
#import <IESDI/IESDI.h>

@protocol IESLiveSettings;

@interface IESLiveWebViewMonitorLaunchTask()

@property (nonatomic, strong) id settings;

@end

@implementation IESLiveWebViewMonitorLaunchTask
Autowired(settings, IESLiveSettings)

+ (IESLiveWebViewMonitorLaunchTask*)shared {
    static IESLiveWebViewMonitorLaunchTask *task;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        task = [[IESLiveWebViewMonitorLaunchTask alloc] init];
    });
    return task;
}

+ (void)startMonitorIESLiveWebView {
    NSDictionary *monitorSetting = nil;
    if ([self.shared.settings respondsToSelector:@selector(dictionaryForKey:)]) {
        monitorSetting = [self.shared.settings performSelector:@selector(dictionaryForKey:)
                                            withObject:@"ies_live_webview_monitor_config"];
    }
    if (monitorSetting.count) {
        NSArray *classNames = [monitorSetting objectForKey:@"classes"];
        NSMutableSet<Class>*classes = [NSMutableSet set];
        [classNames enumerateObjectsUsingBlock:^(NSString *className, NSUInteger idx, BOOL * _Nonnull stop) {
            Class cls = NSClassFromString(className);
            if (cls) {
                [classes addObject:cls];
            }
        }];
        NSDictionary *setting = [monitorSetting objectForKey:@"setting"];
        if (classes.count) {
            [IESLiveWebViewMonitor startMonitorWithClasses:[classes copy] setting:setting];
        }
    }
}

@end

