//
//  FCFileMonitorSetup.m
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/17.
//

#import "FCFileMonitorSetup.h"
#import <LKLoadable/Loadable.h>
#import "SecurityComplianceDebug-Swift.h"
#import "FCFileMonitorInterface.h"

#import "NSData+Monitor.h"
#import "NSFileManager+Monitor.h"

@implementation FCFileMonitorSetup

@end

LoadableRunloopIdleFuncBegin(FCFileMonitorSetup)

if ([FCFileMonitor isEnabled]) {
    NSArray<Class<FCFileMonitorInterface>> *interfaces = @[
        NSData.class,
        NSFileManager.class,
        NSFileHandle.class,
    ];
    
    for (Class<FCFileMonitorInterface> interface in interfaces) {
        [interface setupMonitor];
    }
}

LoadableRunloopIdleFuncEnd(FCFileMonitorSetup)
