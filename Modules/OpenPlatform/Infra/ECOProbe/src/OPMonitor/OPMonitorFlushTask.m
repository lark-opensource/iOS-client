//
//  OPMonitorFlushTask.m
//  ECOProbe
//
//  Created by qsc on 2021/5/23.
//

#import "OPMonitorFlushTask.h"
@interface OPMonitorFlushTask()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) FlushTaskBlock task;
@end


@implementation OPMonitorFlushTask

- (instancetype)initTaskWithName:(NSString *)name task:(FlushTaskBlock)task {
    self = [super init];
    if (self) {
        self.name = name;
        self.task = task;
    }
    return self;
}

- (void)executeOnMonitor:(OPMonitorEvent *)monitor {
    if (self.task) {
        self.task(monitor);
    }
}

@end
