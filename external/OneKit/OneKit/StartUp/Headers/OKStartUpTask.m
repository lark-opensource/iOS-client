//
//  OKStartUpTask.m
//  OKStartUp
//
//  Created by bob on 2020/1/13.
//

#import "OKStartUpTask.h"
#import "OKStartUpScheduler.h"
#import "OKApplicationInfo.h"

OKStartUpTaskPriority const OKStartUpTaskPriorityDefault = 0;
OKStartUpTaskPriority const OKStartUpTaskPriorityLow = -100;
OKStartUpTaskPriority const OKStartUpTaskPriorityHigh = 100;

@interface OKStartUpTask ()

@end

@implementation OKStartUpTask

- (instancetype)init {
    self = [super init];
    if (self) {
        self.priority = OKStartUpTaskPriorityDefault;
        self.taskIdentifier = NSStringFromClass(self.class);
        self.customTaskAfterBlock = nil;
        self.customTaskAfterBlock = nil;
        self.enabled = YES;
    }
    
    return self;
}

- (void)start {
    NSString *reason = [NSString stringWithFormat:@"OneKit: %@ must override %@ in a subclass", NSStringFromClass([self class]), NSStringFromSelector(@selector(startWithLaunchOptions:))];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:reason
                                 userInfo:nil];
}

- (void)startWithLaunchOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    NSString *reason = [NSString stringWithFormat:@"OneKit: %@ must override %@ in a subclass", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:reason
                                 userInfo:nil];
}

- (void)scheduleTask {
    [[OKStartUpScheduler sharedScheduler] addTask:self];
}

@end
